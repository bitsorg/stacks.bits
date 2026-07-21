package: generators
description: Physics event generators meta-package (and their generator-only deps)
version: "1"
license: GPL-3.0-or-later
requires:
  - lcg.bits
  - CMake
  - SFGen
  - apfel
  - contur
  - sherpa
  - sherpa-openmpi
  - herwig3
  - rivet
  - mcutils
  - mcfm
  - madgraph5amc
  - "powheg-box-v2:(?!osx)"
  - feynhiggs
  - vbfnlo
  - FORM
  - njet
  - qgraf
  - gosam_contrib
  - gosam
  - thepeg
  - evtgen
  - hijing
  - starlight
  - qd
  - hepmcanalysis
  - mctester
  - herwig
  - crmc
  - hydjet
  - tauola
  - hydjetcpp
  - alpgen
  - pyquen
  - baurmc
  - professor
  - jhu
  - superchic
  - hoppet
  - hto4l
  - prophecy4f
  - ampt
  - thep8i
  - epos4
  - geneva
  - recola_SM_ATGC_WARSAW
  - RELAX
  - unigen
  # GENIE dropped: 2.12.6 needs ROOT's built-in Pythia6 interface, removed
  # upstream in ROOT 6.36. GENIE is only used by SHiP, which owns its own
  # recipe (ship.bits: GENIE 3 + ROOTEGPythia6) — experiments provide such
  # dependencies themselves rather than shaping the common ROOT build.
  - babayaga
  - bhlumi
  - cepgen
  - fastnlo_toolkit
  - guinea_pig
  - lhapdfsets
  - rapidsim
  - whizard
  - dpmjet
  - compilebox
  - HepMC
  - heputils
  - photos
  - pyslha
  - pythia6
  - tauolacpp
  - yoda
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
---
