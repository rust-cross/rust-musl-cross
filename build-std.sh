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
  # Find the GCC library directory dynamically (using the highest version)
  if [ -d "/usr/local/musl/lib/gcc/$TARGET" ]; then
    GCC_LIB_DIR=$(find /usr/local/musl/lib/gcc/"$TARGET" -maxdepth 1 -type d -name "[0-9]*" | sort -V | tail -n 1)
  else
    GCC_LIB_DIR=""
  fi
  
  if [ -z "$GCC_LIB_DIR" ]; then
    echo "Warning: GCC library directory not found, using default RUSTFLAGS"
    export RUSTFLAGS="-L/usr/local/musl/$TARGET/lib"
  else
    echo "Found GCC library directory: $GCC_LIB_DIR"
    export RUSTFLAGS="-L/usr/local/musl/$TARGET/lib -L$GCC_LIB_DIR"
  fi
  ./target/release/build-sysroot "$TARGET"
  
  # Copy self-contained objects
  mkdir -p "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained"
  cp /usr/local/musl/"$TARGET"/lib/*.o "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained/"
  # Copy GCC C runtime objects if they exist
  if [ -n "$GCC_LIB_DIR" ]; then
    if ls "$GCC_LIB_DIR"/c*.o 1> /dev/null 2>&1; then
      cp "$GCC_LIB_DIR"/c*.o "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained/"
    else
      echo "Warning: GCC C runtime objects not found in $GCC_LIB_DIR, skipping"
    fi
  else
    echo "Warning: GCC library directory not found, skipping C runtime objects"
  fi
  
  # Cleanup
  cd /tmp
  rm -rf build-sysroot /root/.cargo/registry /root/.cargo/git

fi
