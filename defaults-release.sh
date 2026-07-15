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
  # THE release label — single source of truth for BOTH the lcg.bits recipe branch
  # (the override below feeds it as %(release)s) and the CVMFS {release} path slot.
  # `main` is the trunk sentinel: `bits` resolves the effective release as
  #   explicit non-trunk release: (dev3/dev4/LCG_NNN) -> working-dir branch -> main
  # so this default reproduces the old behaviour — build lcg.bits `main`, and,
  # because a `main` release collapses the {release}/ segment out, publish with no
  # release level in the path. Check out a recipe branch and the build tracks the
  # matching lcg.bits branch and publishes under /releases/<branch>/…; set an
  # explicit release: (dev3/dev4/a tag) to name a dedicated one. The value that is
  # in effect must exist as an lcg.bits branch — that is the recipe pool.
  release: main

requires:
  - lcg.bits

overrides:
  lcg.bits:
    tag: "%(release)s"
---
