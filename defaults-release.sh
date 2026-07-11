package: defaults-release
version: v1
system:
  sandbox_network: "off"
  build_oversubscribe: 1.25
  # CVMFS path templates
  prefix:                     "/cvmfs/sft-nightlies-test.cern.ch/lcg/releases"
  cvmfs_user_prefix:          "/cvmfs/sft-nightlies-test.cern.ch/lcg/user" 
  cvmfs_path_template:        "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"

env:
  CXXFLAGS: "-fPIC -g -O2"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  MACOSX_DEPLOYMENT_TARGET: '14.0'
  ENABLE_IPO: 'OFF'

variables:
  lcgversion: main

requires:
  - lcg.bits

overrides:
  lcg.bits:
    tag: "%(lcgversion)s"
---
