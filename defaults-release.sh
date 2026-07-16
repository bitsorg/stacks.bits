package: defaults-release
version: v1
system:
  sandbox_network: "off"
  build_oversubscribe: 1.25
  # Which source a recipe that declares BOTH a git source (source:/tag:) and cached
  # tarball sources (sources:) builds from: "tar" (default — reproducible cached
  # tarballs) or "git" (clone the upstream repo at tag:). A group flips this here to
  # switch its whole stack; a one-off build can override with BITS_SOURCE_MODE.
  # Recipes with only one source form are unaffected. Not hashed itself — the
  # resulting source/tag/commit differences already drive each package's hash.
  source_mode: "tar"
  # CVMFS path LAYOUT (lcgcmake: releases/<release>/[<family>/]<pkg>/<tag>/<platform>).
  # {release} is baked by the build; {family} is per package. {prefix} is the group
  # ROOT and is NOT declared here — it is an authorization boundary supplied by
  # bits-console (communities/<group>/ui-config.yaml: cvmfs_prefix), so a recipe
  # cannot redirect a build into another group's namespace. Only the layout below
  # the prefix lives here.
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

# Package families — the {family} path segment (…/releases/<release>/<family>/<pkg>/…).
# `bits` assigns each package a family via fnmatch on these lists (first match wins;
# no `default:`, so everything unlisted is an external and its family collapses out
# of the path). This mirrors lcgcmake's directory-based grouping: MCGenerators is
# the set of packages that LIVE in lcgcmake's generators/ tree, NOT the transitive
# dependency closure of generators.sh (that would sweep in shared externals like
# boost/python) nor only its direct requires (that would miss libs pulled in
# transitively, e.g. hepmc3/lhapdf). Names are the exact lcg.bits `package:` values.
package_family:
  MCGenerators:
    - FORM
    - alpgen
    - ampt
    - apfel
    - baurmc
    - cepgen
    - chaplin
    - collier
    - crmc
    - evtgen
    - feynhiggs
    - gosam
    - gosam_contrib
    - hepmcanalysis
    - heputils
    - herwig
    - hijing
    - hoppet
    - hto4l
    - hydjet
    - hydjetcpp        # lcgcmake hydjet++
    - jhu
    - lhapdf
    - looptools
    - madgraph5amc
    - mctester
    - mcutils
    - njet
    - openloops
    - photos
    - photoscpp        # lcgcmake photos++
    - powheg-box-v2
    - professor
    - prophecy4f
    - pyquen
    - pythia6
    - pythia8
    - qd
    - qgraf
    - rapidsim
    - recola
    - recola_SM
    - rivet
    - sherpa
    - starlight
    - superchic
    - syscalc
    - tauola
    - tauolacpp        # lcgcmake tauola++
    - thep8i
    - thepeg
    - vbfnlo
    - yoda
    # lcgcmake generators with no lcg.bits recipe yet — listed so they classify
    # automatically once a recipe is added:
    - agile
    - herwig++
    - jimmy
---
