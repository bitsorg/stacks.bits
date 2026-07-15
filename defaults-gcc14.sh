package: defaults-gcc14
version: v1
# Compiler axis (one of gcc13/gcc14/gcc15/clang). Owns the toolchain, the arch
# tag, and the C++ standard: gcc14's maximum stable standard is C++20 (C++23 is
# still experimental in gcc14). The base defaults-release no longer sets -std.
#
# Building the compiler as a hashed dependency (rather than relying on the image's
# system gcc) makes the matrix image-independent: every external `requires:
# GCC-Toolchain`, so its version folds into each dependent's hash automatically.
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++20"
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v14.2.0-alice1          # TODO: confirm the tag you actually build
# Appended verbatim to the arch string (the leading '-' is the separator; bits
# does not assume one). Gives this compiler its own store hashes AND its own
# CVMFS install tree, so gcc14 never overwrites gcc13/gcc15 on deployment.
append_arch: -gcc14
---
