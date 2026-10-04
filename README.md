# stacks.bits

`stacks.bits` is the shared base for building the **LCG software stack** with [`bits`](https://github.com/bitsorg/bits). It contains no package recipes of its own apart from two meta-packages: the ~1,100 recipes live in [`lcg.bits`](https://github.com/bitsorg/lcg.bits). This repository is the policy layer on top of them. It defines the build environment, the compiler, build-type and release profiles, the package families and the CVMFS publish layout, and it selects which `lcg.bits` branch a build uses. Its build types and CVMFS layout reproduce **lcgcmake**.

It is also the foundation the other LCG-based communities build on. Their overlays `requires: stacks.bits` and add only their own CVMFS namespace and version pins, so they inherit the same environment and their packages hash like the ones built here and are reused from the binary store:

```
key4hep.bits ┐
ship.bits    │
lhcb.bits    ├── requires ──▶ stacks.bits ── requires ──▶ lcg.bits (recipes)
atlas.bits   │
testbed.bits ┘
```

Packages are reused across groups only when the compiler and build type match as well: Key4hep, SHiP and ATLAS use `gcc15`, LHCb uses `gcc14`.

## Prerequisites

- `bits` installed: see the [bits README](https://github.com/bitsorg/bits#installation) and [system requirements](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#2-installation--prerequisites).
- Linux (the LCG platforms built in CI: `x86_64-el8`, `x86_64-el9`, `x86_64-el10`, `aarch64-el9`, `x86_64-ubuntu2204`, `x86_64-ubuntu2404`, `x86_64-ubuntu2604`) or macOS (deployment target 14.0; Homebrew supplies the system layer). To build for another Linux version, use `--docker -a <arch>` ([Docker support](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#22-docker-support)).
- The GCC compiler is built as part of the stack from [gcc-toolchain](https://gitlab.cern.ch/bits/gcc-toolchain) (the tag depends on the compiler profile); `clang` uses the clang of the host or image.
- The full `externals` stack is large; see [Speed up large builds](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md#speed-up-large-builds) for `--parallel` and binary-store reuse.

## Getting started

```bash
bits init stacks.bits && cd stacks.bits     # or: git clone -b LCG_110 https://github.com/bitsorg/stacks.bits
bits use build --architecture x86_64-el9 --defaults gcc14::opt --set release=LCG_110
bits build --dry-run ROOT                   # what would be reused and what built
bits build ROOT                             # ROOT and its dependencies
bits enter ROOT/latest                      # shell with ROOT loaded; `exit` to leave
```

`bits use build` records the options once for this directory (an explicit flag still wins); the architecture becomes `x86_64-el9-gcc14-opt`. Check the machine with `bits doctor`. `bits build externals` builds every external (libraries, tools, Python, ML, ROOT, Geant4) and `bits build generators` the MC generators; `bits q` lists the built modules. To build elsewhere, `export BITS_WORK_DIR=/path/to/sw`.

This README describes the `LCG_110` branch. For a direct build clone that branch (`-b LCG_110`), the one matching `--set release`; the published `main` may lag behind it.

`bits` clones the `lcg.bits` branch named by the release (`LCG_110` here) into the work directory on first use. Any package of `lcg.bits` can be built the same way by its `package:` name. If the work directory holds several architectures, pass `-a <arch>` to `bits q`/`bits enter`. See [Managing Environments](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#6-managing-environments) for `bits load` and `bits setenv`.

## Notes for LCG stack users

### Composing profiles

Profiles are combined with `::`. `release` (`defaults-release.sh`) is always the base and is prepended automatically, so you name only the overlays. Profiles fall on independent axes; each appends a suffix to the architecture, in chain order:

| Axis | Profiles | Sets | Arch suffix |
|---|---|---|---|
| Compiler | `gcc13`, `gcc14`, `gcc15`, `clang` | `GCC-Toolchain` tag (`v13.2.0-alice1`, `v14.2.0-alice2`, `v15.3.0-bits1`), or clang with the system gcc runtime; the C++ standard (C++20, C++23 for gcc15) | `-gcc13` … `-clang` |
| Build type | `opt`, `dbg` | `CMAKE_BUILD_TYPE` = `RELWITHDEBINFO` / `Debug` | `-opt` / `-dbg` |
| Feature | `cuda` | `ENABLE_CUDA`, `CMAKE_CUDA_ARCHITECTURES` | `-cuda` |
| Nightly stream | `dev3`, `dev4` | version pins on top of the `release` branch (dev3: ROOT, HepMC3, DD4hep from master; dev4: ROOT 6.40.00) and the nightly paths `nightlies/devN/{day}/` | none |
| Layout | `nightly` | release views under `nightlies/{release}/{day}/` | none |

Pick one compiler and one build type, in that order, so the suffix matches the LCG platform name:

```bash
bits build externals --defaults gcc14::opt --set release=LCG_110   # x86_64-el9-gcc14-opt
bits build ROOT      --defaults gcc15::dbg --set release=LCG_110   # x86_64-el9-gcc15-dbg
bits build externals --defaults gcc14::opt::cuda --set release=LCG_110
```

(The architecture names assume `--architecture x86_64-el9`, as recorded above.) Packages are reused across groups only when the compiler and build type match as well: Key4hep, SHiP and ATLAS use `gcc15`, LHCb uses `gcc14`. A `dev4` nightly is `--defaults gcc15::opt::dev4 --set release=LCG_110`: the LCG_110 recipes with the dev4 pins, published under `nightlies/dev4/{day}/`. A plain release-branch nightly adds `nightly` instead: `--defaults gcc15::opt::nightly --set release=LCG_110`.

The base sets no `-std`: the compiler profile owns the C++ standard, and `dbg`, `opt` and `cuda` never touch `CXXFLAGS`, so they combine with any compiler. A compiler profile is therefore needed for a complete build. Profiles are merged left to right (later scalars win); see [Defaults Profiles](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#18-defaults-profiles).

### Choosing a release

One value, `release`, names both the `lcg.bits` branch to build against (`overrides: lcg.bits: tag: "%(release)s"` in `defaults-release.sh`) and the `{release}` level of the CVMFS path. `bits` resolves it, highest precedence first:

1. `--set release=LCG_110` on the command line, or an explicit `release:` in a chosen profile;
2. the branch of this checkout, with a trailing `-patches` stripped (`LCG_110-patches` gives `LCG_110`);
3. `main`: build `lcg.bits` `main` and publish with no release level in the path.

Prefer `--set release=…`. It is what every stacks-based community uses, and since a `--set` value also enters the package hashes, choosing the release another way builds packages that are not reused from what other groups built. The release must exist as an `lcg.bits` branch: currently `main` and `LCG_110` (and `devel`). The `dev3`/`dev4` streams do not change the release; they add pins on top of it.

### CVMFS layout

`defaults-release.sh` declares the layout under `system:`, which is not part of any package hash, so the same binary can be published to different paths:

```
prefix:   /cvmfs/bits.cern.ch/lcg
packages: {prefix}/{arch}/Packages/{pkg}/{tag}                       # once per build arch
modules:  {prefix}/{arch}/Modules/modulefiles/{pkg}
shared:   {prefix}/noarch/{pkg}/{tag}
releases: {prefix}/releases/{release}/{family}{pkg}/{version}/{arch} # symlinks to packages
views:    {prefix}/views/{release}/{arch}                            # merged view + setup.sh
user:     {prefix}/user/<login>                                      # non-admin publishes
```

A package already published for an arch is not sent again; release and view symlink trees are made only when requested. `{release}` collapses for `main`, and `{family}` collapses for externals. In CI, bits-console injects the authoritative prefix for the LCG community (`cvmfs_prefix` in its community config); it must agree with the value here, otherwise the publish is refused. Preview a path without building:

```bash
bits cvmfs-path --defaults gcc14::opt --set release=LCG_110 --admin --kind releases --package ROOT --version v6.40.02
```

### Mapping to lcgcmake

| lcgcmake | bits / stacks.bits |
|---|---|
| `BINARY_TAG` `arch-os-comp-buildtype` | architecture + `append_arch` suffixes, e.g. `…-gcc14-opt` |
| `LCG_COMP` / `LCG_COMPVERS` | `defaults-gcc13/14/15`, `defaults-clang` |
| `LCG_BUILD_TYPE` (`opt`, `dbg`) | `defaults-opt`, `defaults-dbg` |
| Release (`LCG_110`) | the `release` label: `lcg.bits` branch and `{release}` path level |
| Nightly stream (`dev3`, `dev4`) | `defaults-dev3/dev4`: pins on top of the release, `nightlies/devN/{day}/` paths |
| `heptools-devN.cmake` version pins | `overrides:` in `defaults-dev3/dev4` |
| `generators/` grouping | `package_family: MCGenerators` in `defaults-release.sh` |
| `LCG_external_package` versions | recipe `version:`/`tag:` in `lcg.bits` |

Packages listed under `package_family: MCGenerators` (pythia8, sherpa, herwig3, …) are installed under `…/releases/<release>/MCGenerators/`; everything else is an external with no family level.

### Building a community on this base

A community overlay is a `defaults-<group>.sh` that `requires: stacks.bits`, overrides the `lcg.bits` and `stacks.bits` tags with `%(release)s`, and sets its own `system:` prefix and templates. It must not set `env:` or `package_family`, which are hashed, if its packages are to be reused across groups. Examples: [key4hep.bits](https://github.com/bitsorg/key4hep.bits), [ship.bits](https://github.com/bitsorg/ship.bits), [lhcb.bits](https://github.com/bitsorg/lhcb.bits), [atlas.bits](https://github.com/bitsorg/atlas.bits); [testbed.bits](https://github.com/bitsorg/testbed.bits) reruns a group's build against test services. Those overlays select the release the same way (`--set release=LCG_110`), so the release must also exist as a `stacks.bits` branch (`main`, `LCG_110`).

### Licences and publishing

Licence data (`license:`, `redistributable:`, `acknowledgment:`) is kept in the `lcg.bits` recipes; see [Licence and compliance data](https://github.com/bitsorg/lcg.bits#licence-and-compliance-data). Audit the closure of this stack with `bits compliance --defaults gcc14::opt externals generators`, run in an `LCG_110` checkout (`bits compliance` takes no `--set`, so the release comes from the branch). Publishing to CVMFS, certification and nightly or on-commit builds run in [bits-console](https://gitlab.cern.ch/buncic/bits-console) (LCG community, with `externals` and `generators` as its pinned packages); see [Publishing, Trust and Release Tasks](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#8-publishing-trust-and-release-tasks).

## Files

| File | Role |
|---|---|
| `defaults-release.sh` | base: `system:` (layout, sandbox, source mode), `env:`, `release` variable, `package_family`, `requires: lcg.bits` |
| `defaults-gcc13/14/15.sh`, `defaults-clang.sh` | compiler axis |
| `defaults-opt.sh`, `defaults-dbg.sh` | build-type axis |
| `defaults-cuda.sh` | CUDA feature |
| `defaults-dev3.sh`, `defaults-dev4.sh` | nightly streams: version pins, disabled packages and nightly paths, on top of the release |
| `defaults-nightly.sh` | nightly view layout |
| `externals.sh`, `generators.sh` | meta-packages for the externals and the generator set |

## More information

- [bits build](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#bits-build), [Repository Provider Feature](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#13-repository-provider-feature) and [CVMFS Publishing Pipeline](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#26-cvmfs-publishing-pipeline) in the bits Reference; [bits-providers](https://github.com/bitsorg/bits-providers): the provider registry
- [lcg.bits README](https://github.com/bitsorg/lcg.bits#readme): the recipe pool, its branches and licence data
- bits [User Guide](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md), [Cookbook](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md), [Reference](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md)
- [bits-console](https://gitlab.cern.ch/buncic/bits-console): CI builds and CVMFS publishing

## License

GPL-3.0-or-later; see [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT).
