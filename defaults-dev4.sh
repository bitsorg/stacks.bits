package: defaults-dev4
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  MACOSX_DEPLOYMENT_TARGET: '14.0'
  ENABLE_IPO: 'OFF'

# Stack-wide globals (compiler flags, sandbox_network, MACOSX_DEPLOYMENT_TARGET,
# …) live in defaults-release, which is now always the base of the chain — so
# `--defaults dev4` behaves like `release::dev4`. This profile only adds dev
# overlays on top.

overrides:
  # ROOT >= 6.40 is needed on macOS for Apple-clang / Xcode compatibility; other
  # platforms keep the recipe's default ROOT version. The ":osx" matcher (arch
  # regex, anchored at the start of the architecture string) gates this override
  # to macOS architectures only.
  "ROOT:osx":
    version: "v6.40.00"
    tag: "v6-40-00"

disable:
  # GENIE needs ROOT's removed TPythia6/TMCParticle classes (gone after ROOT
  # 6.30); LCG_109 also comments it out. Re-enable once a standalone EGPythia6
  # package provides those classes.
  - GENIE
  # fastnlo_toolkit's fnlo-tk-yodaout uses YODA/HistoBin1D.h, removed in yoda
  # 2.x; LCG_109 pins no fastnlo version (not built). Re-enable when bumped to a
  # yoda-2 release or built --without-yoda.
  - fastnlo_toolkit
  - compilebox
---
