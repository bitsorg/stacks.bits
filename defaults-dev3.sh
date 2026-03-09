package: defaults-dev3
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  MACOSX_DEPLOYMENT_TARGET: '14.0'
  ENABLE_IPO: 'OFF'
  TEST_VAR2: 'ON'
  TEST_VAR: 'OFF'
  
overrides:
  ROOT:
    tag: 'master'
    source: 'https://github.com/root-project/root'
  hepmc3:
    tag: 'master'
  DD4Hep:
    tag: 'master'
---
