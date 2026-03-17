# first.odin

Thin wrapper on top of odin's build system with inspiration taken from
[nob.h](https://github.com/tsoding/nob.h) and jai's `first.jai`.

> I have never used jai, just from what I could piece from online

This is more of a template for my usecase, meant to live with your codebase.
Since its just odin, it can take advantage of the entire language.

## Usage

1. Copy `first/` into your project (preferebly at the root or not, its yours now)
```
.
├── first
│   └── main.odin
└── your_code.odin
...
```

2. Build it once
```sh
odin build first/ -out:first.bin
```

3. From now on just run
```sh
./first.bin
```

It will rebuild itself if you change the source using  **Go Rebuild Urself™ Technology**
\*borrowed from nob

Example:

[https://github.com/musaubrian/smp](https://github.com/musaubrian/smp)

[![Demo](./.media/first_demo.mp4)]
<video src="./.media/first_demo.mp4" controls></video>


https://github.com/user-attachments/assets/f1be0d65-a841-4d01-aef3-9539059ea474

