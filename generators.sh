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
  - powheg-box-v2
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
  # GENIE (2.12.6 and 3.x) unconditionally needs ROOT's TPythia6/TMCParticle
  # classes, removed from ROOT after 6.30; LCG_109 also has GENIE commented out.
  # Re-enable once a standalone EGPythia6 package provides those classes.
# - GENIE
  - babayaga
  - bhlumi
  - cepgen
  # fastnlo_toolkit has no version pinned in LCG_109 (not built there); its
  # fnlo-tk-yodaout uses YODA/HistoBin1D.h, removed in yoda 2.x. Disabled until
  # bumped to a yoda-2-compatible release or built --without-yoda.
# - fastnlo_toolkit
  - guinea_pig
  - lhapdfsets
  - rapidsim
  - whizard
  - dpmjet
# - compilebox
  - hepmc
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
