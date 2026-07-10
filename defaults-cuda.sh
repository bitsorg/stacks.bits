package: defaults-cuda
version: v1
# CUDA axis (optional): layer this to enable CUDA, omit it for a CPU-only build.
# Sets only the CUDA knobs (never CXXFLAGS), so it composes with any compiler and
# debug/opt profile without clobbering their flags.

variables:
  cuda: "true"

# Distinct store hashes (env is hashed) AND a distinct CVMFS tree, so a CUDA build
# never overwrites the matching non-CUDA build.
append_arch: -cuda

# Flags every package's build env inherits.
env:
  ENABLE_CUDA: "ON"                    # the on/off switch recipes test
  CMAKE_CUDA_ARCHITECTURES: "75;80;90" # valid for CUDA 12.4 (sm_90 max)
---
