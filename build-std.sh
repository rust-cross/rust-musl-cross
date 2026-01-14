#!/bin/bash
set -e
if [[ "$TOOLCHAIN" = "nightly" && ("$TARGET" =~ ^s390x) ]]
then
  export CARGO_NET_GIT_FETCH_WITH_CLI=true
  export CARGO_UNSTABLE_SPARSE_REGISTRY=true

  HOST=$(rustc -Vv | grep 'host:' | awk '{print $2}')
  # patch unwind for s390x
  if [[ "$TARGET" = "s390x-unknown-linux-musl" ]]
  then
    cd "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/src/rust"
	patch -p1 < /tmp/s390x-unwind.patch
	cd -
  fi

  # Build and install the sysroot builder tool
  cd /tmp
  cp -r /home/rust/src/build-sysroot .
  cd build-sysroot
  cargo build --release
  
  # Build the sysroot using rustc-build-sysroot
  export RUSTFLAGS="-L/usr/local/musl/$TARGET/lib -L/usr/local/musl/lib/gcc/$TARGET/11.2.0/"
  ./target/release/build-sysroot "$TARGET"
  
  # Copy self-contained objects
  mkdir -p "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained"
  cp /usr/local/musl/"$TARGET"/lib/*.o "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained/"
  cp /usr/local/musl/lib/gcc/"$TARGET"/11.2.0/c*.o "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained/"
  
  # Cleanup
  cd /tmp
  rm -rf build-sysroot /root/.cargo/registry /root/.cargo/git

fi
