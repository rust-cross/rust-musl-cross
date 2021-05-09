#!/bin/bash
set -ex

# x86_64-unknown-linux-musl
docker build -t messense/rust-musl-cross:x86_64-musl .
# aarch64-unknown-linux-musl
docker build --build-arg TARGET=aarch64-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-aarch64 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak -t messense/rust-musl-cross:aarch64-musl .
# arm-unknown-linux-musleabi
docker build --build-arg TARGET=arm-unknown-linux-musleabi --build-arg OPENSSL_ARCH=linux-armv4 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:arm-musleabi .
# arm-unknown-linux-musleabihf
docker build --build-arg TARGET=arm-unknown-linux-musleabihf --build-arg OPENSSL_ARCH=linux-armv4 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:arm-musleabihf .
# armv5te-unknown-linux-musleabi
docker build --build-arg TARGET=armv5te-unknown-linux-musleabi --build-arg OPENSSL_ARCH=linux-armv4 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:armv5te-musleabi .
# armv7-unknown-linux-musleabihf
docker build --build-arg TARGET=armv7-unknown-linux-musleabihf --build-arg OPENSSL_ARCH=linux-armv4 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:armv7-musleabihf .
# armv7-unknown-linux-musleabi
docker build --build-arg TARGET=armv7-unknown-linux-musleabi --build-arg OPENSSL_ARCH=linux-armv4 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:armv7-musleabi .
# i686-unknown-linux-musl
docker build --build-arg TARGET=i686-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-elf --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:i686-musl .
# i586-unknown-linux-musl
docker build --build-arg TARGET=i586-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-elf --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:i586-musl .
# mips-unknown-linux-musl
docker build --build-arg TARGET=mips-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-mips32 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:mips-musl .
# mipsel-unknown-linux-musl
docker build --build-arg TARGET=mipsel-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-mips32 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak.32 -t messense/rust-musl-cross:mipsel-musl .
# mips64-unknown-linux-muslabi64
docker build --build-arg TARGET=mips64-unknown-linux-muslabi64 --build-arg OPENSSL_ARCH=linux64-mips64 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak -t messense/rust-musl-cross:mips64-muslabi64 .
# mips64el-unknown-linux-muslabi64
docker build --build-arg TARGET=mips64el-unknown-linux-muslabi64 --build-arg OPENSSL_ARCH=linux64-mips64 --build-arg RUST_MUSL_MAKE_CONFIG=config.mak -t messense/rust-musl-cross:mips64el-muslabi64 .
# powerpc64le-unknown-linux-musl
docker build --build-arg TARGET=powerpc64le-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-ppc64le --build-arg RUST_MUSL_MAKE_CONFIG=config.mak --build-arg TOOLCHAIN=nightly -t messense/rust-musl-cross:powerpc64le-musl .
# s390x-unknown-linux-musl
docker build --build-arg TARGET=s390x-unknown-linux-musl --build-arg OPENSSL_ARCH=linux64-s390x --build-arg RUST_MUSL_MAKE_CONFIG=config.mak --build-arg TOOLCHAIN=nightly -t messense/rust-musl-cross:s390x-musl .
