FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Make sure we have basic dev tools for building C libraries.  Our goal
# here is to support the musl-libc builds and Cargo builds needed for a
# large selection of the most popular crates.
#
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        curl \
        file \
        git \
        sudo \
        xutils-dev \
        unzip \
        ca-certificates \
        python3 \
        python3-pip \
        autoconf \
        autoconf-archive \
        automake \
        flex \
        bison \
        llvm-dev \
        libclang-dev \
        clang \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install cross-signed Let's Encrypt R3 CA certificate
COPY lets-encrypt-r3-cross-signed.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

ARG TARGET=x86_64-unknown-linux-musl
ENV RUST_MUSL_CROSS_TARGET=$TARGET
ARG RUST_MUSL_MAKE_VER=0.9.9
ARG RUST_MUSL_MAKE_CONFIG=config.mak

COPY $RUST_MUSL_MAKE_CONFIG /tmp/config.mak
RUN cd /tmp && curl -Lsq -o musl-cross-make.zip https://github.com/richfelker/musl-cross-make/archive/v$RUST_MUSL_MAKE_VER.zip && \
    unzip -q musl-cross-make.zip && \
    rm musl-cross-make.zip && \
    mv musl-cross-make-$RUST_MUSL_MAKE_VER musl-cross-make && \
    cp /tmp/config.mak /tmp/musl-cross-make/config.mak && \
    cd /tmp/musl-cross-make && \
    export TARGET=$TARGET && \
    make -j$(nproc) > /tmp/musl-cross-make.log && \
    make install >> /tmp/musl-cross-make.log && \
    ln -s /usr/local/musl/bin/$TARGET-strip /usr/local/musl/bin/musl-strip && \
    cd /tmp && \
    rm -rf /tmp/musl-cross-make /tmp/musl-cross-make.log

RUN mkdir -p /home/rust/libs /home/rust/src

# Set up our path with all our binary directories, including those for the
# musl-gcc toolchain and for our Rust toolchain.
ENV PATH=/root/.cargo/bin:/usr/local/musl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV TARGET_CC=$TARGET-gcc
ENV TARGET_CXX=$TARGET-g++
ENV TARGET_HOME=/usr/local/musl/$TARGET
ENV TARGET_C_INCLUDE_PATH=$TARGET_HOME/include/

# We'll build our libraries in subdirectories of /home/rust/libs.  Please
# clean up when you're done.
WORKDIR /home/rust/libs

RUN export CC=$TARGET_CC && \
    export C_INCLUDE_PATH=$TARGET_C_INCLUDE_PATH && \
    echo "Building zlib" && \
    VERS=1.2.11 && \
    CHECKSUM=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1 && \
    cd /home/rust/libs && \
    curl -sqLO https://zlib.net/zlib-$VERS.tar.gz && \
    echo "$CHECKSUM zlib-$VERS.tar.gz" > checksums.txt && \
    sha256sum -c checksums.txt && \
    tar xzf zlib-$VERS.tar.gz && cd zlib-$VERS && \
    ./configure --static --archs="-fPIC" --prefix=$TARGET_HOME && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf zlib-$VERS.tar.gz zlib-$VERS checksums.txt

# The Rust toolchain to use when building our image
ARG TOOLCHAIN=stable
# Install our Rust toolchain and the `musl` target.  We patch the
# command-line we pass to the installer so that it won't attempt to
# interact with the user or fool around with TTYs.  We also set the default
# `--target` to musl so that our users don't need to keep overriding it
# manually.
# Chmod 755 is set for root directory to allow access execute binaries in /root/.cargo/bin (azure piplines create own user).
#
# Remove docs and more stuff not needed in this images to make them smaller
RUN chmod 755 /root/ && \
    curl https://sh.rustup.rs -sqSf | \
    sh -s -- -y --profile minimal --default-toolchain $TOOLCHAIN && \
    rustup target add $TARGET || rustup component add --toolchain $TOOLCHAIN rust-src && \
    rustup component add --toolchain $TOOLCHAIN rustfmt clippy && \
    rm -rf /root/.rustup/toolchains/$TOOLCHAIN-$(uname -m)-unknown-linux-gnu/share/

RUN echo "[target.$TARGET]\nlinker = \"$TARGET-gcc\"\n" > /root/.cargo/config

# Build std sysroot for targets that doesn't have official std release
ADD Xargo.toml /tmp/Xargo.toml
ADD build-std.sh .
RUN bash build-std.sh

ENV RUSTUP_HOME=/root/.rustup
ENV CARGO_HOME=/root/.cargo
ENV CARGO_BUILD_TARGET=$TARGET

ENV CFLAGS_armv7_unknown_linux_musleabihf='-mfpu=vfpv3-d16'

# Expect our source code to live in /home/rust/src
WORKDIR /home/rust/src
