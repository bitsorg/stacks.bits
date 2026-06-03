package: defaults-key4hep
version: v1
overrides:
  # Only acts is genuinely pinned: bits' default acts 26.0.0 is too old for
  # k4actstracking (which needs the Acts Core + PluginDD4hep from the 44.x line),
  # so use the LCG_109 devkey acts 44.4.0 with the matching k4actstracking v00-02.
  #
  # The other devkey k4* versions are deliberately NOT pinned. They were written
  # for the EDM4hep-0.x era and do find_package(EDM4HEP 0.99 REQUIRED), which
  # EDM4hep 1.0 rejects under SameMajorVersion. bits' newer recipe defaults
  # (k4fwcore v01-05, k4edm4hep2lcioconv v00-14, k4marlinwrapper v00-14, ...)
  # request EDM4hep 1.0 and are the correct match for this stack, so they are
  # left on their defaults.
  - acts = 44.4.0
  - k4actstracking = v00-02
---
