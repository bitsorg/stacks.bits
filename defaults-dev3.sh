package: defaults-dev3
version: v1
# The "dev3" release line (mirrors lcgcmake heptools-dev3). Overriding the single
# `release` label re-points THREE things at once to dev3: the CVMFS {release}
# slot, the lcg.bits recipe branch (overrides: lcg.bits: tag: "%(release)s" in
# defaults-release), and the target stacks.bits tag. This replaces the old
# `append_arch: -dev3` — a release is a path level, not a platform suffix
# (lcgcmake BINARY_TAG is arch-os-comp-buildtype only). The C++ standard/toolchain
# still come from the compiler axis (defaults-gccNN / defaults-clang).
variables:
  release: dev3

overrides:
  # Per-package version pins for this release, mirroring lcgcmake heptools-dev3:
  # the core stack tracks upstream HEAD/master (built from git), on top of whatever
  # the lcg.bits `dev3` branch provides. version is the label that lands in the
  # CVMFS path; tag is the git ref built.
  ROOT:                                # lcgcmake: ROOT HEAD (GIT root.git)
    source: "https://github.com/root-project/root.git"
    version: "HEAD"
    tag: "master"
  hepmc3:                              # lcgcmake: hepmc3 HEAD (GIT HepMC3.git)
    source: "https://gitlab.cern.ch/hepmc/HepMC3.git"
    version: "HEAD"
    tag: "master"
  DD4hep:                              # lcgcmake: DD4hep master (GIT DD4hep.git)
    source: "https://github.com/AIDASoft/DD4hep.git"
    version: "master"
    tag: "master"
  Gaudi:                               # lcgcmake: Gaudi master (GIT Gaudi.git)
    source: "https://gitlab.cern.ch/gaudi/Gaudi.git"
    version: "master"
    tag: "master"

disable:
  # Same removals as dev4 — dev3 tracks ROOT HEAD (even newer than dev4's 6.40),
  # so it hits the same breakages.
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
