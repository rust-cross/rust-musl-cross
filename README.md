# rust-musl-cross

[![Docker Image](https://img.shields.io/docker/pulls/messense/rust-musl-cross.svg?maxAge=2592000)](https://hub.docker.com/r/messense/rust-musl-cross/)
[![Build](https://github.com/messense/rust-musl-cross/workflows/Build/badge.svg)](https://github.com/messense/rust-musl-cross/actions?query=workflow%3ABuild)
[![Bors enabled](https://bors.tech/images/badge_small.svg)](https://app.bors.tech/repositories/48252)

> 🚀 Help me to become a full-time open-source developer by [sponsoring me on GitHub](https://github.com/sponsors/messense)

Docker images for compiling static Rust binaries using [musl-cross-make][],
inspired by [rust-musl-builder](https://github.com/emk/rust-musl-builder)

## Prebuilt images

Currently we have the following [prebuilt Docker images on Docker Hub](https://hub.docker.com/r/messense/rust-musl-cross/),
 supports x86_64(amd64) and aarch64(arm64) architectures.

| Rust toolchain | Cross Compile Target                        | Docker Image Tag    |
|----------------|---------------------------------------------|---------------------|
| stable         | aarch64-unknown-linux-musl                  | aarch64-musl        |
| stable         | arm-unknown-linux-musleabi                  | arm-musleabi        |
| stable         | arm-unknown-linux-musleabihf                | arm-musleabihf      |
| stable         | armv5te-unknown-linux-musleabi              | armv5te-musleabi    |
| stable         | armv7-unknown-linux-musleabi                | armv7-musleabi      |
| stable         | armv7-unknown-linux-musleabihf              | armv7-musleabihf    |
| stable         | i586-unknown-linux-musl                     | i586-musl           |
| stable         | i686-unknown-linux-musl                     | i686-musl           |
| stable         | mips-unknown-linux-musl                     | mips-musl           |
| stable         | mipsel-unknown-linux-musl                   | mipsel-musl         |
| stable         | mips64-unknown-linux-muslabi64              | mips64-muslabi64    |
| stable         | mips64el-unknown-linux-muslabi64            | mips64el-muslabi64  |
| nightly        | powerpc64-unknown-linux-musl                | powerpc64-musl      |
| nightly        | powerpc64le-unknown-linux-musl              | powerpc64le-musl    |
| stable         | x86\_64-unknown-linux-musl                  | x86\_64-musl        |

To use `armv7-unknown-linux-musleabihf` target for example, first pull the image:

```bash
docker pull messense/rust-musl-cross:armv7-musleabihf
# Also available on ghcr.io
# docker pull ghcr.io/messense/rust-musl-cross:armv7-musleabihf
```

Then you can do:

```bash
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src messense/rust-musl-cross:armv7-musleabihf'
rust-musl-builder cargo build --release
```

This command assumes that `$(pwd)` is readable and writable. It will output binaries in `armv7-unknown-linux-musleabihf`.
At the moment, it doesn't attempt to cache libraries between builds, so this is best reserved for making final release builds.

## How it works

`rust-musl-cross` uses [musl-libc][], [musl-gcc][] with the help of [musl-cross-make][] to make it easy to compile, and the new
[rustup][] `target` support.


## Use beta/nightly Rust

Currently we install stable Rust by default, if you want to switch to beta/nightly Rust, you can do it by extending
from our Docker image, for example to use beta Rust for target `x86_64-unknown-linux-musl`:

```dockerfile
FROM messense/rust-musl-cross:x86_64-musl
RUN rustup update beta && \
    rustup target add --toolchain beta x86_64-unknown-linux-musl
```

## Strip binaries

You can use the `musl-strip` command inside the image to strip binaries, for example:

```bash
docker run --rm -it -v "$(pwd)":/home/rust/src messense/rust-musl-cross:armv7-musleabihf musl-strip /home/rust/src/target/release/example
```

[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[musl-cross-make]: https://github.com/richfelker/musl-cross-make
[rustup]: https://www.rustup.rs/

## License

Licensed under [The MIT License](./LICENSE)
