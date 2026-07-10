package: defaults-gcc15
version: v1
# Compiler axis. gcc15's default C++ standard is c++26 (still experimental); cap
# the stack at c++23. The standard must live in CXXFLAGS because recipes read the
# -std flag from there (e.g. the ROOT recipe); the compiler profile is the right
# owner of CXXFLAGS since it is always in the chain. The debug/cuda profiles must
# NOT set CXXFLAGS (they set CMAKE_BUILD_TYPE / ENABLE_CUDA), so this -std is never
# clobbered by the last-wins env merge.
env:
  CXXSTD: '23'
  CXXFLAGS: "-fPIC -g -O2 -std=c++${CXXSTD:-23}"
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v15.2.0-alice1
# Compiler tag ONLY — the debug axis lives in defaults-dbg (append_arch: -dbg).
# Fusing them here (the old "-gcc15-dbg") made every gcc15 build claim the debug
# tree, so an opt gcc15 build and a debug one collided on the same CVMFS path.
append_arch: -gcc15
---
