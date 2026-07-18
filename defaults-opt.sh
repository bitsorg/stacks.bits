package: defaults-opt
version: v1
# Optimised axis — the LCG "-opt" flavour, made EXPLICIT so the CVMFS release
# path/arch carries a `-opt` qualifier (…-gcc13-opt) alongside its `-dbg` sibling,
# per LCG naming. Layer exactly one of defaults-opt / defaults-dbg per build; opt
# is the normal default (console/pipeline).
#
# Reaffirms the base RELWITHDEBINFO (-O2 -g) build type. Touches ONLY
# CMAKE_BUILD_TYPE — deliberately NOT CXXFLAGS — so it never clobbers a compiler
# profile's flags in the last-wins env merge (mirrors defaults-dbg.sh).
env:
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
# Distinct store hashes (env is hashed) AND a distinct CVMFS tree, so an opt build
# and its dbg sibling never overwrite each other.
append_arch: -opt
---
