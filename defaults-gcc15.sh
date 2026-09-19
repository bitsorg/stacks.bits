package: defaults-gcc15
version: v1
env:
  CXXSTD: '23'
  CXXFLAGS: "-fPIC -g -O2 -std=c++${CXXSTD:-23}"
overrides:
  GCC-Toolchain:
    source: https://gitlab.cern.ch/bits/gcc-toolchain
    tag: v15.3.0-bits1
append_arch: -gcc15
---
