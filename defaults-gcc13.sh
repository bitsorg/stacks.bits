package: defaults-gcc13
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2"
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v13.2.0-alice1
# Appended verbatim to the arch string; the leading '-' is the separator, (bits does not assume one)
append_arch: -gcc13
---
