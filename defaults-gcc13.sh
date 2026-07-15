package: defaults-gcc13
version: v1
# Compiler axis. Owns the C++ standard for this compiler: gcc13's maximum stable
# standard is C++20 (C++23 is still experimental in gcc13). The base
# defaults-release no longer sets -std, so the standard is defined here.
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++20"
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v13.2.0-alice1
# Appended verbatim to the arch string; the leading '-' is the separator (bits
# does not assume one). Distinct store hashes AND CVMFS tree per compiler.
append_arch: -gcc13
---
