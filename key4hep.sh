package: key4hep
description: Key4hep full software stack meta-package
version: "1"
license: Apache-2.0
requires:
  - lcg.bits
  - CMake
  - podio
  - EDM4hep
  - DD4hep
  - Gaudi
  # Version pins below align the key4hep subtree with LCG_109 (heptools-devkey),
  # where bits' recipe defaults are ahead. Pins set both version and tag, so
  # github recipes use the vNN-NN tag string and the acts tarball uses its
  # plain version. These apply only to this metapackage's build, leaving
  # externals.sh/generators.sh on the recipe defaults.
  # k4fwcore + k4simgeant4 are repinned NEWER than devkey (together): devkey's
  # k4simgeant4 v0.1.0pre17 (its latest tag) is incompatible with Gaudi v40r2's
  # Property API, so we track its `main`, which needs k4FWCore::putCellIDEncoding
  # — present in k4fwcore v01-06 (latest tag) but not the devkey v01-04. If other
  # k4* consumers break against k4fwcore v01-06, they likely need bumping too.
  - k4fwcore = v01-06
  - k4edm4hep2lcioconv = v00-13
  - k4marlinwrapper = v00-13
  - k4geo
  - k4simgeant4 = main
  - k4reco
  - k4gen
  - k4reccalorimeter
  - k4gaudipandora = v0.1.0
  - k4mljettagger
  - k4actstracking = v00-02
  - LCIO
  - marlin
  - marlinutil
  - marlintrk
  - kaltest
  - ddkaltest
  - raida = v01-11
  - GSL
  - aidatt
  - kkmcee
  - ipython
  - mold
  # iLCSoft / FCC / Marlin top-level packages
  - acts = 44.4.0
  - cedviewer
  - cldconfig
  - clicperformance
  - clupatra
  - conddbmysql
  - conformaltracking
  - ddmarlinpandora
  - ddml
  - fcalclusterer
  - fcc_config
  - fccanalyses
  - fccdetectors
  - fccsw
  - forwardtracking
  - garlic
  - genfit
  - ildperformance
  - k4_project_template
  - k4clue
  - k4generatorsconfig
  - k4rectracker
  - k4simdelphes
  - lcfiplus
  - lctuple
  - marlindd4hep
  - marlinfastjet
  - marlinkinfitprocessors
  - marlinmlflavortagging
  - marlinreco
  - marlintrkprocessors
  - opendatadetector
  - pandoraanalysis
  - physsim
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
---
