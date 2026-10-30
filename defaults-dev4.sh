package: defaults-dev4
version: v1
# The "dev4" nightly stream (mirrors lcgcmake heptools-dev4). It does NOT change
# `release`: the recipes come from whatever lcg.bits branch `release` selects
# (e.g. --set release=LCG_110), and only the packages below are pinned to fixed
# tags. Its views go to nightlies/dev4/{day}/ and views/dev4/{day}/; {day} is
# filled by bits (UTC weekday, or --day). system: is not hashed. Build flags are
# inherited from defaults-release; the C++ standard comes from the compiler axis.
system:
  cvmfs_releases_template:    "{prefix}/nightlies/dev4/{day}/{family}{pkg}/{version}/{arch}"
  cvmfs_views_template:       "{prefix}/views/dev4/{day}/{arch}"

overrides:
  # Version pins mirroring lcgcmake heptools-dev4: dev4 builds ROOT from the
  # v6-42-00-patches branch on ALL platforms — unlike dev3, which tracks ROOT HEAD.
  ROOT:                                # lcgcmake: ROOT v6-42-00-patches (GIT root.git)
    source: "https://github.com/root-project/root.git"
    version: "%(tag_basename)s"
    tag: "v6-42-00-patches"
  java:                                # lcgcmake: java 17.0.19p10
    version: "17.0.19p10"
    tag: "17.0.19p10"

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
