package: defaults-clang
version: v1
# Compiler axis: build with clang instead of the gcc toolchain.
#
# Unlike the gcc profiles, this does not override GCC-Toolchain with a gcc tag —
# it selects clang as the compiler. The simplest wiring uses the clang shipped in
# the build image (prefer_system) and points CC/CXX at it; adjust to your setup:
#
#   * If your image provides clang, keep the prefer_system override below so
#     GCC-Toolchain resolves to the system compiler rather than building gcc.
#   * If you build a standalone LLVM/clang toolchain package, replace the override
#     with `overrides: { LLVM: { tag: ... } }` and add it to `requires`.
#
# CC/CXX go in env (which is hashed) so a clang variant gets distinct store
# hashes; append_arch gives it a distinct CVMFS tree.
env:
  CC: clang
  CXX: clang++
  # clang 20 (LLVM 20.1.7): maximum stable standard is C++20. The base
  # defaults-release no longer sets -std, so the standard is defined here.
  CXXFLAGS: "-fPIC -g -O2 -std=c++20"
overrides:
  GCC-Toolchain:
    prefer_system: ".*"          # use the image's clang; TODO: confirm for your image
append_arch: -clang
---
