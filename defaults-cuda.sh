package: defaults-cuda
version: v1

variables:
  cuda: "true"

# Own install tree 
append_arch: -cuda

# Flags every package's build env inherits.
env:
  ENABLE_CUDA: "ON"                    # the on/off switch recipes test
  CMAKE_CUDA_ARCHITECTURES: "75;80;90" # valid for CUDA 12.4 (sm_90 max); 
----
