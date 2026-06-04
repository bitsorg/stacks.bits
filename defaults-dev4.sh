package: defaults-dev4
version: v1

# Stack-wide globals (compiler flags, sandbox_network, MACOSX_DEPLOYMENT_TARGET,
# …) live in defaults-release, which is now always the base of the chain — so
# `--defaults dev4` behaves like `release::dev4`. This profile only adds dev
# overlays on top.

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
