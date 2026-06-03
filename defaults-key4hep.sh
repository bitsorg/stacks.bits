package: defaults-key4hep
version: v1
overrides:
 -  k4fwcore = v01-06
  - k4edm4hep2lcioconv = v00-13
  - k4marlinwrapper = v00-13
  - k4simgeant4 = main
  - k4gaudipandora = v0.1.0
  - k4actstracking = v00-02
  - acts = 44.4.0

disable:
  # GENIE needs ROOT's removed TPythia6/TMCParticle classes (gone after ROOT
  # 6.30); LCG_109 also comments it out. Re-enable once a standalone EGPythia6
  # package provides those classes.
  - GENIE
  # fastnlo_toolkit's fnlo-tk-yodaout uses YODA/HistoBin1D.h, removed in yoda
  # 2.x; LCG_109 pins no fastnlo version (not built). Re-enable when bumped to a
  # yoda-2 release or built --without-yoda.
  - fastnlo_toolkit
---
