FROM ubuntu:22.04

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

# Install Let's Encrypt R3 CA certificate from https://letsencrypt.org/certificates/
COPY lets-encrypt-r3.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

ARG TARGET=x86_64-unknown-linux-musl
ENV RUST_MUSL_CROSS_TARGET=$TARGET
ARG RUST_MUSL_MAKE_CONFIG=config.mak

COPY $RUST_MUSL_MAKE_CONFIG /tmp/config.mak
RUN cd /tmp && \
    git clone --depth 1 https://github.com/richfelker/musl-cross-make.git && \
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
ENV TARGET_AR=$TARGET-ar
ENV TARGET_RANLIB=$TARGET-ranlib
ENV TARGET_HOME=/usr/local/musl/$TARGET
ENV TARGET_C_INCLUDE_PATH=$TARGET_HOME/include/

# pkg-config cross compilation support
ENV TARGET_PKG_CONFIG_ALLOW_CROSS=1
ENV TARGET_PKG_CONFIG_SYSROOT_DIR=$TARGET_HOME
ENV TARGET_PKG_CONFIG_PATH=$TARGET_HOME/lib/pkgconfig:/usr/local/musl/lib/pkgconfig
ENV TARGET_PKG_CONFIG_LIBDIR=$TARGET_PKG_CONFIG_PATH

# We'll build our libraries in subdirectories of /home/rust/libs.  Please
# clean up when you're done.
WORKDIR /home/rust/libs

RUN export CC=$TARGET_CC && \
    export C_INCLUDE_PATH=$TARGET_C_INCLUDE_PATH && \
    export AR=$TARGET_AR && \
    export RANLIB=$TARGET_RANLIB && \
    echo "Building zlib" && \
    VERS=1.2.13 && \
    CHECKSUM=b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30 && \
    cd /home/rust/libs && \
    curl -sqLO https://zlib.net/zlib-$VERS.tar.gz && \
    echo "$CHECKSUM zlib-$VERS.tar.gz" > checksums.txt && \
    sha256sum -c checksums.txt && \
    tar xzf zlib-$VERS.tar.gz && cd zlib-$VERS && \
    CFLAGS="-O3 -fPIC" ./configure --static --prefix=$TARGET_HOME && \
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
ADD s390x-unwind.patch /tmp/s390x-unwind.patch
ADD build-std.sh .
COPY compile-libunwind /tmp/compile-libunwind
RUN bash build-std.sh

ENV RUSTUP_HOME=/root/.rustup
ENV CARGO_HOME=/root/.cargo
ENV CARGO_BUILD_TARGET=$TARGET

ENV CFLAGS_armv7_unknown_linux_musleabihf='-mfpu=vfpv3-d16'

# Build statically linked binaries for MIPS targets
ENV CARGO_TARGET_MIPS_UNKNOWN_LINUX_MUSL_RUSTFLAGS='-C target-feature=+crt-static'
ENV CARGO_TARGET_MIPSEL_UNKNOWN_LINUX_MUSL_RUSTFLAGS='-C target-feature=+crt-static'
ENV CARGO_TARGET_MIPS64_UNKNOWN_LINUX_MUSLABI64_RUSTFLAGS='-C target-feature=+crt-static'
ENV CARGO_TARGET_MIPS64EL_UNKNOWN_LINUX_MUSLABI64_RUSTFLAGS='-C target-feature=+crt-static'

# Expect our source code to live in /home/rust/src
WORKDIR /home/rust/src
