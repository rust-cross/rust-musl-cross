#!/bin/bash
# x86_64-unknown-linux-musl
docker build -t messense/rust-musl-cross:x86_64-musl .
# arm-unknown-linux-musleabi
docker build --build-arg TARGET=arm-unknown-linux-musleabi --build-arg OPENSSL_ARCH=linux-generic32 -t messense/rust-musl-cross:arm-musleabi .
# arm-unknown-linux-musleabihf
docker build --build-arg TARGET=arm-unknown-linux-musleabihf --build-arg OPENSSL_ARCH=linux-generic32 -t messense/rust-musl-cross:arm-musleabihf .
# armv7-unknown-linux-musleabihf
docker build --build-arg TARGET=armv7-unknown-linux-musleabihf --build-arg OPENSSL_ARCH=linux-generic32 -t messense/rust-musl-cross:armv7-musleabihf .
# i686-unknown-linux-musl
docker build --build-arg TARGET=i686-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-generic32 -t messense/rust-musl-cross:i686-musl .
# mips-unknown-linux-musl
docker build --build-arg TARGET=mips-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-generic32 -t messense/rust-musl-cross:mips-musl .
# mipsel-unknown-linux-musl
docker build --build-arg TARGET=mipsel-unknown-linux-musl --build-arg OPENSSL_ARCH=linux-generic32 -t messense/rust-musl-cross:mipsel-musl .
