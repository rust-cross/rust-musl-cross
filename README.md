# rust-musl-cross

Docker images for compiling static Rust binaries using [musl-cross-make][],
inspired by [rust-musl-builder](https://github.com/emk/rust-musl-builder)

[![Docker Image](https://img.shields.io/docker/pulls/messense/rust-musl-cross.svg?maxAge=2592000)](https://hub.docker.com/r/messense/rust-musl-cross/)
[![Build Status](https://travis-ci.org/messense/rust-musl-cross.svg?branch=master)](https://travis-ci.org/messense/rust-musl-cross)

## Prebuilt images

Currently we have the following [prebuilt Docker images on Docker Hub](https://hub.docker.com/r/messense/rust-musl-cross/).

| Rust toolchain | Cross Compile Target                | Docker Image Tag    |
|----------------|-------------------------------------|---------------------|
| stable         | x86\_64-unknown-linux-musl          | x86\_64-musl        |
| stable         | i686-unknown-linux-musl             | i686-musl           |
| stable         | arm-unknown-linux-musleabi          | arm-musleabi        |
| stable         | arm-unknown-linux-musleabihf        | arm-musleabihf      |
| stable         | armv7-unknown-linux-musleabihf      | armv7-musleabihf    |
| stable         | mips-unknown-linux-musl             | mips-musl           |
| stable         | mipsel-unknown-linux-musl           | mipsel-musl         |

To use `armv7-unknown-linux-musleabihf` target for example, first pull the image:

```bash
docker pull messense/rust-musl-cross:armv7-musleabihf
```

Then you can do:

```bash
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src messense/rust-musl-cross:armv7-musleabihf'
rust-musl-builder cargo build --release
```

This command assumes that `$(pwd)` is readable and writable by uid 1000, gid 1000. It will output binaries in `armv7-unknown-linux-musleabihf`.
At the moment, it doesn't attempt to cache libraries between builds, so this is best reserved for making final release builds.

## How it works

`rust-musl-cross` uses [musl-libc][], [musl-gcc][] with the help of [musl-cross-make][] to make it easy to compile, and the new
[rustup][] `target` support.  It includes static versions of several
libraries:

- The standard `musl-libc` libraries.
- OpenSSL, which is needed by many Rust applications.

## Making OpenSSL work

If your application uses OpenSSL, you will also need to take a few extra steps
to make sure that it can find OpenSSL's list of trusted certificates,
which is stored in different locations on different Linux distributions.
You can do this using [`openssl-probe`](https://crates.io/crates/openssl-probe) as follows:

```rust
extern crate openssl_probe;

fn main() {
    openssl_probe::init_ssl_cert_env_vars();
    //... your code
}
```


[musl-libc]: http://www.musl-libc.org/
[musl-gcc]: http://www.musl-libc.org/how.html
[musl-cross-make]: https://github.com/richfelker/musl-cross-make
[rustup]: https://www.rustup.rs/

## License

Licensed under [The MIT License](./LICENSE)
