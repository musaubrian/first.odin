#+feature dynamic-literals
package first

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:strings"
import "core:time"

Command :: struct {
	args:        []string,
	working_dir: string,
}

WORK_DIR :: "."

usage :: proc() {
	fmt.printfln(
		`%s is a thin wrapper over the odin build system inspired by nob.h

Usage: %s

   timings  Show build timings (adds -show-timings to build args)
   release  Build odin with the speed optimizations (-o:speed)
   help     Prints this help message
        `,
		os.args[0],
		os.args[0],
	)
	os.exit(0)
}


main :: proc() {
	DEFAULT_BUILD_ARGS := []string{"-vet", "-vet-style"}
	rebuild()

	show_timings := false
	release_mode := false
	for arg_index in 1 ..< len(os.args) {
		arg := os.args[arg_index]
		switch arg {
		case "timings":
			show_timings = true
		case "release":
			release_mode = true
		case "help":
			usage()
		case:
			fmt.printfln("Unknown arg <%s>", arg)
			os.exit(3)
		}
	}

	commit_state, commit_hash, c_err_msg := run_command(
		Command{args = []string{"git", "rev-parse", "--verify", "HEAD"}, working_dir = WORK_DIR},
	)
	if !commit_state.success {fatal(c_err_msg)}

	tag_state, tag, _ := run_command(
		Command {
			args = []string{"git", "describe", "--tags", "--abbrev=0"},
			working_dir = WORK_DIR,
		},
	)
	default_tag := "v0.0.0-debug"
	if !tag_state.success {fmt.eprintln("[WARN]: No tags found using default ", default_tag); tag = default_tag}

	hash_opt := fmt.aprintf("-define:COMMIT=%s", strings.trim_right(commit_hash, "\n"))
	tag_opt := fmt.aprintf("-define:TAG=%s", strings.trim_right(tag, "\n"))

	build_args := [dynamic]string{"odin", "build", WORK_DIR, hash_opt, tag_opt}
	for default_arg in DEFAULT_BUILD_ARGS {append(&build_args, default_arg)}
	if show_timings {append(&build_args, "-show-timings")}
	if release_mode {append(&build_args, "-o:speed")}

	build_state, _, build_err := run_command(Command{args = build_args[:]})
	if !build_state.success {fatal(build_err)}

}


run_command :: proc(
	cmd: Command,
) -> (
	state: os2.Process_State,
	contents: string,
	err_msg: string,
) {

	process_desc: os2.Process_Desc = {
		working_dir = cmd.working_dir,
		command     = cmd.args,
	}

	fmt.printfln("[CMD] %s", strings.join(cmd.args, " "))
	process_state, stdout, stderr, process_err := os2.process_exec(process_desc, context.allocator)
	if process_err != nil {
		return os2.Process_State{success = false}, "", os2.error_string(process_err)
	}

	defer {
		delete(stdout)
		delete(stderr)
	}
	// fmt.printfln("process_state: %v\nstdout: %s\nstderr: %s", process_state, stdout, stderr)
	return process_state, strings.clone(cast(string)stdout), strings.clone(cast(string)stderr)
}


rebuild :: proc() {
	bin_modified_time, bin_mtime_err := os2.last_write_time_by_name(os.args[0])
	if bin_mtime_err != nil {
		fatal(os2.error_string(bin_mtime_err))
	}
	bin_src_modified_time, bin_src_mtime_err := os2.last_write_time_by_name("./first/first.odin")
	if bin_src_mtime_err != nil {
		fatal(os2.error_string(bin_src_mtime_err))
	}

	diff := time.diff(bin_modified_time, bin_src_modified_time)
	if diff < 0 {return}

	fmt.println("[FIRST] src changed, rebuilding...")
	rebuild_state, rebuild_out, rebuild_err := run_command(
		Command {
			args = []string{"odin", "build", "first", "-out:first.bin"},
			working_dir = WORK_DIR,
		},
	)
	if !rebuild_state.success {fatal(rebuild_err)}
	// run ourself again as a subprocess
	// should probably find sth like execvp
	rerun_cmds := [dynamic]string{"first.bin"}
	for old_arg in os.args[1:] {append(&rerun_cmds, old_arg)}
	rerun_state, rerun_out, rerun_err := run_command(
		Command{args = rerun_cmds[:], working_dir = WORK_DIR},
	)

	if rerun_out != "" {fmt.print(rerun_out)}
	if rerun_err != "" {fmt.eprint(rerun_err)}
	os.exit(rerun_state.exit_code)
}


fatal :: proc(message: string) {
	fmt.eprintln("[ERROR]: ", message)
	os.exit(1)
}

