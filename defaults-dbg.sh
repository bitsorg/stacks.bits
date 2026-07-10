package: defaults-dbg
version: v1
# Debug axis (optional): layer this to get a debug build, omit it for opt.
#
# Touches ONLY CMAKE_BUILD_TYPE — deliberately NOT CXXFLAGS — so it never
# clobbers a compiler profile's flags in the last-wins env merge. CMake recipes
# (the CMakeRecipe helper) pick up Debug (-g -O0) from this. Autotools recipes
# that ignore CMAKE_BUILD_TYPE would need their own knob; add it here if some
# externals need it.
env:
  CMAKE_BUILD_TYPE: "Debug"
# Distinct store hashes (env is hashed) AND a distinct CVMFS tree, so a debug
# build never overwrites the matching opt build.
append_arch: -dbg
---
