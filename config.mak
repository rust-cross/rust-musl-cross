# By default, cross compilers are installed to ./output under the top-level
# musl-cross-make directory and can later be moved wherever you want them.
# To install directly to a specific location, set it here. Multiple targets
# can safely be installed in the same location. Some examples:

OUTPUT = /usr/local/musl

# By default, latest supported release versions of musl and the toolchain
# components are used. You can override those here, but the version selected
# must be supported (under hashes/ and patches/) to work. For musl, you
# can use "git-refname" (e.g. git-master) instead of a release. Setting a
# blank version for gmp, mpc, mpfr and isl will suppress download and
# in-tree build of these libraries and instead depend on pre-installed
# libraries when available (isl is optional and not set by default).
# Setting a blank version for linux will suppress installation of kernel
# headers, which are not needed unless compiling programs that use them.

# BINUTILS_VER =
GCC_VER = 11.2.0

MUSL_VER = 1.2.5

# GMP_VER =
# MPC_VER =
# MPFR_VER =
# ISL_VER =
# LINUX_VER =

# By default source archives are downloaded with wget. curl is also an option.

# DL_CMD = wget -c -O
DL_CMD = curl -C - -L -o

# Something like the following can be used to produce a static-linked
# toolchain that's deployable to any system with matching arch, using
# an existing musl-targeted cross compiler. This only # works if the
# system you build on can natively (or via binfmt_misc and # qemu) run
# binaries produced by the existing toolchain (in this example, i486).

# COMMON_CONFIG += CC="i486-linux-musl-gcc -static --static" CXX="i486-linux-musl-g++ -static --static"

# Recommended options for smaller build for deploying binaries:

COMMON_CONFIG += CFLAGS="-g0 -Os -w" CXXFLAGS="-g0 -Os -w" LDFLAGS="-s"

# Recommended options for faster/simpler build:

COMMON_CONFIG += --disable-nls
GCC_CONFIG += --enable-languages=c,c++
GCC_CONFIG += --disable-libquadmath --disable-decimal-float
GCC_CONFIG += --disable-multilib

# You can keep the local build path out of your toolchain binaries and
# target libraries with the following, but then gdb needs to be told
# where to look for source files.

COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=
