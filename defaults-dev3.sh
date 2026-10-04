package: defaults-dev3
version: v1
# The "dev3" nightly stream (mirrors lcgcmake heptools-dev3). It does NOT change
# `release`: the recipes come from whatever lcg.bits branch `release` selects
# (e.g. --set release=LCG_110), and only the packages below follow the head of
# their development branch. Its views go to nightlies/dev3/{day}/ and
# views/dev3/{day}/ so dev3 and dev4 never collide; {day} is filled by bits
# (UTC weekday, or --day). system: is not hashed. The C++ standard/toolchain
# come from the compiler axis (defaults-gccNN / defaults-clang).
system:
  cvmfs_releases_template:    "{prefix}/nightlies/dev3/{day}/{family}{pkg}/{version}/{arch}"
  cvmfs_views_template:       "{prefix}/views/dev3/{day}/{arch}"

overrides:
  # Per-package pins mirroring lcgcmake heptools-dev3: the core stack tracks
  # upstream master (built from git), on top of the release branch's recipes.
  # Sources are the git repos used by the git-ready recipes (root.sh; common.bits
  # hepmc3/dd4hep). version derives from the tag (%(tag_basename)s → "master"),
  # the label that lands in the CVMFS path; tag is the git ref built.
  ROOT:                                # lcgcmake: ROOT HEAD (GIT root.git)
    source: "https://github.com/root-project/root.git"
    version: "%(tag_basename)s"
    tag: "master"
  hepmc3:                              # lcgcmake: hepmc3 HEAD (GIT HepMC3.git)
    source: "https://gitlab.cern.ch/hepmc/HepMC3.git"
    version: "%(tag_basename)s"
    tag: "master"
  DD4hep:                              # lcgcmake: DD4hep master (GIT DD4hep.git)
    source: "https://github.com/AIDASoft/DD4hep.git"
    version: "%(tag_basename)s"
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
