package: defaults-nightly
version: v1
# Nightly LAYOUT overlay — compose LAST, before the stream:
#   --defaults gcc15::opt::nightly::dev4
# Redirects the CVMFS publish path from releases/{release}/ to
# nightlies/{release}/{day}/ (the LCG nightly layout). system: is NOT hashed, so
# nightly-vs-release changes only WHERE a package deploys, never its identity:
# the same (platform,hash) tarball is shared and referenced into the nightly tree.
# {day} is filled by bits (auto UTC weekday, or --day) and collapses when unset.
system:
  cvmfs_releases_template:    "{prefix}/nightlies/{release}/{day}/{family}{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/nightlies/{release}/{day}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/nightlies/{release}/{day}/noarch/{pkg}/{tag}"
---
