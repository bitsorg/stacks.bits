package: defaults-dev3
version: v1
# The "dev3" release line (mirrors lcgcmake heptools-dev3). Overriding the single
# `release` label re-points THREE things at once to dev3: the CVMFS {release}
# slot, the lcg.bits recipe branch (overrides: lcg.bits: tag: "%(release)s" in
# defaults-release), and the target stacks.bits tag. This replaces the old
# `append_arch: -dev3` — a release is a path level, not a platform suffix
# (lcgcmake BINARY_TAG is arch-os-comp-buildtype only). The C++ standard/toolchain
# still come from the compiler axis (defaults-gccNN / defaults-clang).
variables:
  release: dev3

overrides:
  # Per-package version pins for this release go here (e.g. ROOT/DD4hep/HepMC3 to
  # an upstream development tag), on top of whatever the lcg.bits `dev3` branch
  # already provides. Confirm recipe names/sources against lcg.bits before adding.
---
