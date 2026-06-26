package: defaults-gcc15
version: v1
env:
  # GCC-Toolchain exports the highest C++ standard the compiler supports (26 on
  # gcc15). This profile caps the stack at c++23 — gcc15's c++26 is still
  # experimental — so pin CXXSTD here, the same way defaults-lcg pins '20'.
  # CXXFLAGS derives the -std flag from the (capped) value.
  CXXSTD: '23'
  CXXFLAGS: "-fPIC -g -O2 -std=c++${CXXSTD:-23}"
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v15.2.0-alice1
# Appended verbatim to the arch string; the leading '-' is the separator, (bits does not assume one)
append_arch: -gcc15-dbg
---
