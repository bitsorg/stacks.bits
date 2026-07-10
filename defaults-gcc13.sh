package: defaults-gcc13
version: v1
# Compiler axis only. No CXXFLAGS here: it exactly duplicated the base profile, so
# setting it again only risked clobbering base flags in the last-wins env merge
# without changing anything. gcc13 uses its compiler-default standard; add
# CXXSTD/-std to CXXFLAGS here only if you want to pin one (as gcc15 does).
overrides:
  GCC-Toolchain:
    source: https://github.com/alisw/gcc-toolchain
    tag: v13.2.0-alice1
# Appended verbatim to the arch string; the leading '-' is the separator (bits
# does not assume one). Distinct store hashes AND CVMFS tree per compiler.
append_arch: -gcc13
---
