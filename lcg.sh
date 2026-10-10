package: LCG
description: LCG meta-package (externals + generators)
version: "1"
license: Apache-2.0
requires:
  - lcg.bits
  - externals
  - generators
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
---
