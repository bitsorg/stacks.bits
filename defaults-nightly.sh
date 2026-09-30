package: defaults-nightly
version: v1
# Nightly LAYOUT overlay — compose LAST, before the stream:
#   --defaults gcc15::opt::nightly::dev4
# Moves the release VIEWS from releases/{release}/ to nightlies/{release}/{day}/
# and views/{release}/{day}/ (the LCG nightly layout). Packages keep their one
# shared home ({prefix}/{arch}/Packages), so a nightly publishes only what
# changed. system: is NOT hashed: nightly-vs-release never changes identity.
# {day} is filled by bits (auto UTC weekday, or --day) and collapses when unset.
system:
  cvmfs_releases_template:    "{prefix}/nightlies/{release}/{day}/{family}{pkg}/{version}/{arch}"
  cvmfs_views_template:       "{prefix}/views/{release}/{day}/{arch}"
---
