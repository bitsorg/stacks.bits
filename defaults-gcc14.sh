package: defaults-gcc14
version: v1
# Compiler axis (one of gcc13/gcc14/gcc15/clang). Owns ONLY the toolchain and the
# arch tag; flag policy (CXXFLAGS/CFLAGS/CMAKE_BUILD_TYPE) stays in the base
# profile so it is not clobbered by the last-wins env merge when profiles layer.
#
# Building the compiler as a hashed dependency (rather than relying on the image's
# system gcc) makes the matrix image-independent: every external `requires:
# GCC-Toolchain`, so its version folds into each dependent's hash automatically.
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v14.2.0-alice1          # TODO: confirm the tag you actually build
# Appended verbatim to the arch string (the leading '-' is the separator; bits
# does not assume one). Gives this compiler its own store hashes AND its own
# CVMFS install tree, so gcc14 never overwrites gcc13/gcc15 on deployment.
append_arch: -gcc14
---
