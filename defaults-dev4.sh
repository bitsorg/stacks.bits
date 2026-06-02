package: defaults-dev4
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  MACOSX_DEPLOYMENT_TARGET: '14.0'
  ENABLE_IPO: 'OFF'

overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v15.2.0-alice1

append_arch: gcc15-dbg
---
