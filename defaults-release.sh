package: defaults-release
version: v1
system:
  sandbox_network: "off"
  build_oversubscribe: 1.25
  # CVMFS path templates (lcgcmake layout):
  #   releases/<release>/[<family>/]<pkg>/<tag>/<platform>
  # {release} is baked by the build; {family} is per package (empty for externals,
  # "MCGenerators/" for generators — it carries its own trailing slash).
  prefix:                     "/cvmfs/sft-nightlies-test.cern.ch/lcg"
  cvmfs_user_prefix:          "{prefix}/user"
  cvmfs_releases_template:    "{prefix}/releases/{release}/{family}{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/releases/{release}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/releases/{release}/noarch/{pkg}/{tag}"

env:
  CXXFLAGS: "-fPIC -g -O2"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  MACOSX_DEPLOYMENT_TARGET: '14.0'
  ENABLE_IPO: 'OFF'

variables:
  # THE release label — single source of truth. It names three things at once:
  #   1. the CVMFS {release} slot in the templates above (baked at build time);
  #   2. the lcg.bits recipe branch (see the override below): %(release)s;
  #   3. the tag stacks.bits will converge to for this release.
  # It is an explicit label, NOT derived from the current branch — a build on any
  # stacks.bits branch targets whatever release is named here. The value must
  # exist as an lcg.bits branch (that is the recipe pool). dev3/dev4 override it,
  # moving the slot AND the branch together. NOT hashed (a variable, so the same
  # content under dev/dev3/dev4 stays one store object; only its CVMFS home moves).
  release: dev

requires:
  - lcg.bits

overrides:
  lcg.bits:
    tag: "%(release)s"
---
