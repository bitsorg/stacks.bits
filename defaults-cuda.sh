package: defaults-cuda
version: v1
# Append "-cuda" to the architecture so CUDA-enabled builds live in their own
# install tree and never get mixed with the plain (CPU-only) binaries.
append_arch: cuda
# The `cuda` variable is the single switch that turns the CUDA stack on. It is
# consumed two ways:
#   * conditional dependencies -- recipes write `- "cuda:(?cuda)"`, which pulls
#     in the `cuda` package only when this variable is truthy;
#   * build-time CMake options -- recipes gate flags on $ENABLE_CUDA (below).
variables:
  cuda: "true"
env:
  ENABLE_CUDA: "ON"
  CMAKE_CUDA_ARCHITECTURES: "75;80;90"
disable:
  - Geant4
  - DD4Hep
  - Gaudi
#  - acts
#  - Garfield++
---
