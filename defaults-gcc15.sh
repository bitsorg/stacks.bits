package: defaults-gcc15
version: v1
env:
  # gcc15 builds the stack at C++23, matching lcgcmake (its compilerWrapper.sh
  # selects -std=c++23 for gcc >= 15.0; gcc 13/14 -> c++20) and Gaudi v40, whose
  # gcc15 support is only validated "with C++23 enabled" (Gaudi CHANGELOG). Under
  # gcc15 + C++20 the Gaudi v40 concept headers (IInterface::cast<>,
  # Property::operator=) fail to compile in the key4hep consumers.
  #
  # -std=c++23 in CXXFLAGS is the definitive default standard: every recipe that
  # does not set its own CMAKE_CXX_STANDARD inherits it, while recipes that pass
  # -DCMAKE_CXX_STANDARD=NN still override it (CMake emits its standard flag after
  # CXXFLAGS). It also makes ROOT auto-select C++23 (root.sh derives
  # CMAKE_CXX_STANDARD from CXXFLAGS), and Gaudi then inherits the standard from
  # ROOT. CXXSTD is the named knob recipes pass as -DCMAKE_CXX_STANDARD=${CXXSTD:-20}.
  CXXFLAGS: "-fPIC -g -O2 -std=c++23"
  CXXSTD: '23'
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v15.2.0-alice1
# Appended verbatim to the arch string; the leading '-' is the separator
# (bits does not assume one) -> ubuntu2510_x86-64-gcc15-dbg.
append_arch: -gcc15-dbg
---
