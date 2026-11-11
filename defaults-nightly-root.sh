package: defaults-nightly-root
version: v1
# ROOT nightly: ROOT from git (root_release: master, or a tag such as v6-36-02),
# published as a merged view only, under nightlies/ROOT/{arch}/{release}/{day}.
# Packages keep their shared home. Use: --defaults gcc14::dbg::nightly-root
variables:
  root_release: master

system:
  cvmfs_releases_template:    ""
  cvmfs_views_template:       "{prefix}/nightlies/ROOT/{arch}/{release}/{day}/{root_release}"

overrides:
  ROOT:
    source: "https://github.com/root-project/root.git"
    version: "%(tag_basename)s"
    tag: "%(root_release)s"
---
