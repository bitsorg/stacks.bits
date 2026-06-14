package: defaults-gcc15
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++23"
  CXXSTD: '23'
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v15.2.0-alice1
# Appended verbatim to the arch string; the leading '-' is the separator, (bits does not assume one)
append_arch: -gcc15-dbg
---
