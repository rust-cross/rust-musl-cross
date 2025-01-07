#!/bin/bash
set -e
if [[ "$TOOLCHAIN" = "nightly" ]]
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

  cargo install xargo --git https://github.com/AverseABFun/xargo.git
  cargo new --lib custom-std
  cd custom-std
  cp /tmp/Xargo.toml .
  rustc -Z unstable-options --print target-spec-json --target "$TARGET" | tee "$TARGET.json"
  RUSTFLAGS="-L/usr/local/musl/$TARGET/lib -L/usr/local/musl/lib/gcc/$TARGET/11.2.0/" xargo build --target "$TARGET"
  cp -r "/root/.xargo/lib/rustlib/$TARGET" "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/"
  mkdir "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained"
  cp /usr/local/musl/"$TARGET"/lib/*.o "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained/"
  cp /usr/local/musl/lib/gcc/"$TARGET"/11.2.0/c*.o "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/self-contained/"
  cd ..
  rm -rf /root/.xargo /root/.cargo/registry /root/.cargo/git custom-std

  # compile libunwind
  if [[ "$TARGET" = "powerpc64le-unknown-linux-musl" ]]
  then
    cargo run --manifest-path /tmp/compile-libunwind/Cargo.toml -- --target "$TARGET" "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/src/rust/src/llvm-project/libunwind" out
    cp out/libunwind*.a "/root/.rustup/toolchains/$TOOLCHAIN-$HOST/lib/rustlib/$TARGET/lib/"
    rm -rf out /tmp/compile-libunwind
  fi
fi
