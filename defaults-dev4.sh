package: defaults-dev4
version: v1
# The "dev4" release line (mirrors lcgcmake heptools-dev4). Overriding the single
# `release` label re-points the CVMFS {release} slot, the lcg.bits recipe branch
# (%(release)s), and the target stacks.bits tag to dev4 together. Build flags
# (CFLAGS / CMAKE_BUILD_TYPE / MACOSX_DEPLOYMENT_TARGET / ENABLE_IPO) are inherited
# from defaults-release; the C++ standard comes from the compiler axis — so this
# file carries only the release label and its package-version overrides.
variables:
  release: dev4

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
