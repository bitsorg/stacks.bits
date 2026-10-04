# stacks.bits

`stacks.bits` is the shared base for building the **LCG software stack** with [`bits`](https://github.com/bitsorg/bits). It contains no package recipes of its own apart from two meta-packages: the ~1,100 recipes live in [`lcg.bits`](https://github.com/bitsorg/lcg.bits). This repository is the policy layer on top of them. It defines the build environment, the compiler, build-type and release profiles, the package families and the CVMFS publish layout, and it selects which `lcg.bits` branch a build uses. Its build types and CVMFS layout reproduce **lcgcmake**.

It is designed to reproduce **lcgcmake** build types and CVMFS installation layout, so if you know lcgcmake, the mapping below should feel familiar.

---

## Table of Contents
- [Repository Discovery & Provider Model](#repository-discovery--provider-model)
- [Mapping `bits` to lcgcmake](#mapping-bits-to-lcgcmake)
- [The `defaults-release.sh` Profile](#the-defaults-releasesh-profile)
  - [The `system:` Block](#the-system-block)
- [Command-Line Usage](#command-line-usage)
  - [Composing Profiles](#composing-profiles)
  - [Previewing Publish Paths](#previewing-publish-paths)
- [Branches and Releases](#branches-and-releases)
- [Package Families](#package-families)
- [Local Development](#local-development)
  - [Building Packages](#building-packages)
  - [Using the Module Environment](#using-the-module-environment)
  - [Building the Full Stack](#building-the-full-stack)
  - [Iteration Workflow](#iteration-workflow)
- [The S3 Content Store & Certification](#the-s3-content-store--certification)
  - [Store Inspection & Management](#store-inspection--management)
- [CI Pipelines](#ci-pipelines)
- [Files Overview](#files-overview)

---

## Repository Discovery & Provider Model

`bits` resolves recipes along an ordered search path (`BITS_PATH`), seeded from `bits.rc` (`search_path`) or the environment. Prefferably, beyond local `*.bits` checkouts and with zero configuration, a repository can be pulled in on demand by a *repository-provider* package — an ordinary recipe carrying `provides_repository: true` whose `source` points at a recipe repo. When `bits` meets one while scanning dependencies it clones the source into `sw/REPOS/<pkg>/<hash>/`, adds it to `BITS_PATH`, and rescans — repeating for nested providers until the graph is stable. Each provider's commit hash is folded into every package's build hash, so bumping a pool triggers a rebuild.

**`lcg.bits` is itself a versioned package.** Its provider recipe is just:

```yaml
package: lcg.bits
version: "1"
tag: "main"                 # which branch/commit of the recipe pool to clone
provides_repository: true
always_load: true
source: https://github.com/bitsorg/lcg.bits
```

`stacks.bits` does `requires: lcg.bits` and pins its version with `overrides: lcg.bits: tag: "%(release)s"` — so the **release label selects the exact recipe-pool branch** (see [Branches and Releases](#branches-and-releases)). Groups like `key4hep.bits` / `ship.bits` are provider repos too: they can start from their own defaults or reuse this model.

---

## Mapping `bits` to lcgcmake

| lcgcmake concept | `bits` equivalent | Where it lives |
|---|---|---|
| `BINARY_TAG` = `arch-os-comp-buildtype` | architecture string `<os>_<machine>` + `append_arch` suffixes, e.g. `ubuntu2510_x86-64-gcc15-dbg` | compiler/build-type profiles |
| `LCG_COMP` / `LCG_COMPVERS` (gcc13, clang…) | `defaults-gcc13/14/15`, `defaults-clang` (each `append_arch: -gccNN` / `-clang`) | this repo |
| `LCG_BUILD_TYPE` (`opt`, `dbg`, `o2g`…) → `CMAKE_BUILD_TYPE` | base sets `RELWITHDEBINFO`; `defaults-dbg` sets `Debug` (`append_arch: -dbg`) | this repo |
| Release (`dev3`, `dev4`, `LCG_107`) as a path level | the `{release}` slot in the CVMFS templates | `defaults-devN` / branch / tag |
| `heptools-devN.cmake` (version pins for a release) | `defaults-devN` `overrides:` | this repo |
| `generators/` directory grouping | `package_family: MCGenerators` (fnmatch list) | `defaults-release` |
| `/cvmfs/…/lcg/releases/<LCG_VERSION>/[<group>/]<pkg>/<ver>/<platform>` | `…/releases/<release>/[<family>/]<pkg>/<version>/<arch>`: symlinks to `…/<arch>/Packages/<pkg>/<tag>` | `defaults-release` templates |
| `LCG_external_package` / `LCG_AA_project` version | recipe `version:`/`tag:` in `lcg.bits`, overridable per release | `lcg.bits` + `defaults-devN` |

---

## The `defaults-release.sh` Profile

`defaults-release` is the base profile every build inherits. Its top-level keys:

| Key | Purpose | Hashed? |
|---|---|---|
| `package` / `version` | identifies the pseudo-package | — |
| `requires` | what the base pulls in (here: `lcg.bits`, the recipe pool) | yes |
| `env:` | build environment exported to **every** package (`CXXFLAGS`, `CFLAGS`, `CMAKE_BUILD_TYPE`, `MACOSX_DEPLOYMENT_TARGET`, `ENABLE_IPO`) | **yes** — folded into every package hash, so a flag change yields a distinct, reproducible identity |
| `variables:` | `%(name)s` template values used in overrides/recipes — notably `release` | indirectly (only through what they expand) |
| `overrides:` | per-package field overrides (`source`/`tag`/`version`), e.g. `lcg.bits: tag: "%(release)s"` | yes (changes the resolved recipe) |
| `package_family:` | fnmatch map assigning the `{family}` path segment (see [Package Families](#package-families)) | no (a path concern) |
| `system:` | deployment/policy — see below | **no** — never folded into package hashes |

### The `system:` Block

The **`system:` block** holds everything about *where and how* things build and publish, deliberately kept out of the package hash (the same binary can be published to different paths without changing identity):

| `system:` field | Meaning |
|---|---|
| `sandbox_network` | build-sandbox network policy (`on`/`off`); recipes may still override per package |
| `build_oversubscribe` | parallelism factor (e.g. `1.25` → `-j` slightly above core count) |
| `prefix` | the CVMFS root, e.g. `/cvmfs/bits.cern.ch/lcg` |
| `cvmfs_user_prefix` | root for per-user (non-admin) publishes: `<user_prefix>/<login>` |
| `cvmfs_packages_template` | where each package is published, once per build arch (tokens `{arch}`,`{pkg}`,`{tag}`) |
| `cvmfs_releases_template` | release view: symlinks to the packages (tokens `{release}`,`{family}`,`{pkg}`,`{version}`,`{arch}`) |
| `cvmfs_views_template` | the release's merged view (`bin/ lib/ include/ …` + `setup.sh`) |
| `cvmfs_modules_template` | modulefile publish path |
| `cvmfs_shared_path_template` | noarch/shared publish path |
| `remote_store` | the **S3 content store** for reuse + upload, e.g. `b3://<bucket>::rw` (see [The S3 Content Store](#the-s3-content-store--certification)) |
| `certify_group` | group name stamped into the signed common manifest |
| `manifests_remote` | git repo where build/common manifests are recorded |

The current templates:

```
prefix:   /cvmfs/bits.cern.ch/lcg
packages: {prefix}/{arch}/Packages/{pkg}/{tag}
modules:  {prefix}/{arch}/Modules/modulefiles/{pkg}
shared:   {prefix}/noarch/{pkg}/{tag}
releases: {prefix}/releases/{release}/{family}{pkg}/{version}/{arch}
views:    {prefix}/views/{release}/{arch}
```

Packages are published once per build arch (`{arch}`, e.g. `x86_64-el9-gcc14-opt`) under their version-revision `{tag}`; a package already there is not sent again. A release is a view of symlinks to them under `releases/<release>/`, plus a merged view under `views/<release>/<arch>`, both made only when asked for (`bits cvmfs publish --release-view`). `{release}` collapses out when it is the trunk (`main`), and `{family}` collapses for externals.

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
| Release line | `dev3`, `dev4` | the `release` label and that line's version pins (dev3: ROOT, HepMC3, DD4hep from master; dev4: ROOT 6.40.00) | none |
| Layout | `nightly` | release views under `nightlies/{release}/{day}/` | none |

The C++ standard is owned by the **compiler axis** (gcc13/14 → c++20, gcc15 → c++23, clang → c++20), never by the base or the build-type/feature profiles — so `dbg`/`cuda` compose with any compiler without clobbering `-std`.

### Previewing Publish Paths

`bits cvmfs-path -c . --defaults <chain> --package <pkg> --version <v> --platform <p>` prints the exact publish path a build would use — handy to preview where a chain lands before building.

---

## Branches and Releases

One value — the `release` label — names **three things at once**: the CVMFS `{release}` path slot, the **`lcg.bits` branch** to build against (`overrides: lcg.bits: tag: "%(release)s"`), and the tag `stacks.bits` will converge to. `bits` resolves it, highest precedence first:

1. an explicit, non-trunk `release:` in the chosen defaults (`dev3`, `dev4`, a tagged `LCG_107`),
2. else the **working-directory branch name** (`-patches` stripped, so `LCG_107-patches` → `LCG_107`),
3. else **`main`** — the default: build `lcg.bits` `main`, and (because `main` collapses out of the path) publish with no release level (old behaviour).

The effective release **must exist as an `lcg.bits` branch** — that branch *is* the recipe pool. Check out `feature-x` in your working copy and the build tracks `lcg.bits` `feature-x` and, when a release view is made, links it under `…/releases/feature-x/…`; the packages themselves share the one `…/<arch>/Packages` tree, each under its own version-revision. `dev3`/`dev4` move the branch **and** the slot together.

---

## Package Families

`bits` assigns each package a family via fnmatch on `package_family:` in `defaults-release.sh`; the family becomes a path segment (`…/releases/<release>/MCGenerators/pythia8/…`). There is **no `default:` family**, so anything unlisted is an external and its segment collapses out — matching lcgcmake, where a package's home is its directory, not its dependency graph. `MCGenerators` mirrors lcgcmake's `generators/` tree; core/AA packages like `ROOT`, `HepMC`, `Geant4` stay externals.

---

## Local Development

Building is done with `bits`; exploring and using the resulting module environment is done with **`bitsenv`**, the [Environment Modules] front-end. A build installs to `sw/<arch>/[<family>/]<pkg>/<ver>-<rev>/` and generates a modulefile named `<package>/<version>` that `bitsenv` can then load.

### Building Packages

**Build** a single package (work dir defaults to `sw`, arch auto-detected):

```bash
bits build externals --defaults gcc14::opt --set release=LCG_110   # x86_64-el9-gcc14-opt
bits build ROOT      --defaults gcc15::dbg --set release=LCG_110   # x86_64-el9-gcc15-dbg
bits build externals --defaults gcc14::opt::cuda --set release=LCG_110
```

(The architecture names assume `--architecture x86_64-el9`, as recorded above.) Packages are reused across groups only when the compiler and build type match as well: Key4hep, SHiP and ATLAS use `gcc15`, LHCb uses `gcc14`. A `dev4` nightly would be `--defaults gcc15::opt::nightly::dev4`; it needs an `lcg.bits` `dev4` branch, which does not exist yet.

The base sets no `-std`: the compiler profile owns the C++ standard, and `dbg`, `opt` and `cuda` never touch `CXXFLAGS`, so they combine with any compiler. A compiler profile is therefore needed for a complete build. Profiles are merged left to right (later scalars win); see [Defaults Profiles](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#18-defaults-profiles).

### Choosing a release

One value, `release`, names both the `lcg.bits` branch to build against (`overrides: lcg.bits: tag: "%(release)s"` in `defaults-release.sh`) and the `{release}` level of the CVMFS path. `bits` resolves it, highest precedence first:

1. `--set release=LCG_110` on the command line, or an explicit `release:` in a chosen profile (`dev3`, `dev4`);
2. the branch of this checkout, with a trailing `-patches` stripped (`LCG_110-patches` gives `LCG_110`);
3. `main`: build `lcg.bits` `main` and publish with no release level in the path.

Prefer `--set release=…`. It is what every stacks-based community uses, and since a `--set` value also enters the package hashes, choosing the release another way builds packages that are not reused from what other groups built. The release must exist as an `lcg.bits` branch: currently `main` and `LCG_110` (and `devel`). `dev3` and `dev4` need `lcg.bits` branches of the same name, which do not exist yet.

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
| Release (`dev3`, `dev4`, `LCG_110`) | the `release` label: `lcg.bits` branch and `{release}` path level |
| `heptools-devN.cmake` version pins | `overrides:` in `defaults-dev3/dev4` |
| `generators/` grouping | `package_family: MCGenerators` in `defaults-release.sh` |
| `LCG_external_package` versions | recipe `version:`/`tag:` in `lcg.bits` |

Packages listed under `package_family: MCGenerators` (pythia8, sherpa, herwig3, …) are installed under `…/releases/<release>/MCGenerators/`; everything else is an external with no family level.

### Building a community on this base

A community overlay is a `defaults-<group>.sh` that `requires: stacks.bits`, overrides the `lcg.bits` and `stacks.bits` tags with `%(release)s`, and sets its own `system:` prefix and templates. It must not set `env:` or `package_family`, which are hashed, if its packages are to be reused across groups. Examples: [key4hep.bits](https://github.com/bitsorg/key4hep.bits), [ship.bits](https://github.com/bitsorg/ship.bits), [lhcb.bits](https://github.com/bitsorg/lhcb.bits), [atlas.bits](https://github.com/bitsorg/atlas.bits); [testbed.bits](https://github.com/bitsorg/testbed.bits) reruns a group's build against test services. Those overlays select the release the same way (`--set release=LCG_110`), so the release must also exist as a `stacks.bits` branch (`main`, `LCG_110`).

### Licences and publishing

Licence data (`license:`, `redistributable:`, `acknowledgment:`) is kept in the `lcg.bits` recipes; see [Licence and compliance data](https://github.com/bitsorg/lcg.bits#licence-and-compliance-data). Audit the closure of this stack with `bits compliance --defaults gcc14::opt externals generators`, run in an `LCG_110` checkout (`bits compliance` takes no `--set`, so the release comes from the branch). Publishing to CVMFS, certification and nightly or on-commit builds run in [bits-console](https://gitlab.cern.ch/buncic/bits-console) (LCG community, with `externals` and `generators` as its pinned packages); see [Publishing, Trust and Release Tasks](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md#8-publishing-trust-and-release-tasks).

### Iteration Workflow

**Iterate**: edit a recipe in `lcg.bits` on a branch, re-run `bits build` (only what changed rebuilds — see [The S3 Content Store](#the-s3-content-store--certification) on reuse), and `bits clean` to reset the build area. Because the local install tree already carries the family/arch layout, what you test locally is exactly what gets published.

---

## The S3 Content Store & Certification

Three artefacts, deliberately separate:

- **S3 content store** — a *content-addressed* cache of build tarballs (`TARS/<arch>/store/<hash>/…`, hash-only). Identical inputs → identical hash → identical binary, so any builder can **reuse** a prebuilt package instead of rebuilding. This is why the store exists: it makes builds fast and reproducible across machines and CI, and it's the substrate certification trusts. Configured via `system.remote_store` (`b3://<bucket>::rw`); credentials in `~/.bits/s3keys` (or `$BITS_AWS_KEYS_FILE`), store override `$BITS_S3_STORE`.
- **CVMFS tree** — the *path-addressed* deployment users actually mount: packages at `…/<arch>/Packages/<pkg>/<tag>`, releases as symlink views at `…/releases/<release>/[<family>/]<pkg>/<version>/<arch>`.
- **Signed common manifest** — the *trust unit*: what a client verifies before reusing a binary.

Reuse happens automatically at build time: for each dependency `bits` resolves a hash and, if that object is already in the store (`from_remote_store`, with `--check-store`), downloads it rather than building. A finished build uploads its tarball for the next consumer. (`bits build --reuse-policy relaxed --reuse-base <build_id>` can graft a deployed release's binaries.)

```bash
bits build <pkg> …            # checks the store, builds only what's missing, uploads results
bits publish <pkg> …          # relocates the install to its CVMFS path and streams it
                              #   to the ingestion spool → the release tree
bits certify …                # merges published build manifests into ONE common manifest,
                              #   validates every content hash against the S3 store, and
                              #   signs it with the release Ed25519 key (clients trust this)
```

`certify` is what turns a pile of uploaded tarballs into something safe to reuse: it checks each hash really is in the store and signs the result. `certify_group`, `manifests_remote` (and the release key) configure it.

### Store Inspection & Management

**Inspect / verify / clean the store** with `bits store`:

```bash
bits store ls   --arch A --group G --package P --version V   # list (manifest-aware selection)
bits store verify [--arch A] [--deep] [--orphans]            # integrity check vs manifests
bits store rm   <selection> [-n]                             # delete (e.g. --orphans, --expired); -n dry-run
bits store gc                                                # reachability GC: roots = hashes in the
                                                            #   verified signed manifest; fail-closed
```

Normally you don't run publish/certify by hand — the bits-console cvmfs-prepub pipeline does it (see [CI Pipelines](#ci-pipelines)). Locally you mostly `build` + `enter`/`setenv` to test, and use `bits store` to inspect what reuse will pull.

---

## CI Pipelines

A commit to `lcg.bits` **or** `stacks.bits` (including a GitLab pull-mirror sync) can fire a **designated pipeline** configured and saved in **bits-console**, giving nightly/CI-style rebuilds without redefining the build here.

- The build definition (packages, platforms, defaults chain, providers, publish/certify) is authored in the console's **Build modal → "Save as pipeline"** and stored at `communities/<GROUP>/pipelines/<PIPELINE>.json`.
- A small `.gitlab-ci.yml` in the recipe repo only *fires* it. `lcg.bits` ships one that multi-project-triggers bits-console with `BITS_GROUP: LCG`, `BITS_PIPELINE: on-commit`; the downstream `run-group-pipeline` job fans out one cvmfs-prepub build (build → publish → certify) per enabled entry. `stacks.bits` can carry an analogous file.

One-time setup (GitLab UI):

1. bits-console → Settings → CI/CD → **Token Access** → add the recipe project to the `CI_JOB_TOKEN` allowlist.
2. If the recipe repo is a pull-mirror, enable **Mirroring → "Trigger pipelines for mirror updates"** (the `.gitlab-ci.yml` must be on the mirrored branch).
3. In the console, build the stack in the Build modal, tick the options, and **Save as pipeline**, naming it to match `BITS_PIPELINE`.

The same saved pipeline can also run on a schedule (nightly) or on demand from the console — the commit trigger is just one entry point.

---

## Files Overview

| File | Role |
|---|---|
| `defaults-release.sh` | base: `system:` (layout, sandbox, source mode), `env:`, `release` variable, `package_family`, `requires: lcg.bits` |
| `defaults-gcc13/14/15.sh`, `defaults-clang.sh` | compiler axis |
| `defaults-opt.sh`, `defaults-dbg.sh` | build-type axis |
| `defaults-cuda.sh` | CUDA feature |
| `defaults-dev3.sh`, `defaults-dev4.sh` | release lines with their version pins and disabled packages |
| `defaults-nightly.sh` | nightly view layout |
| `externals.sh`, `generators.sh` | meta-packages for the externals and the generator set |

## More information

- [bits build](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#bits-build), [Repository Provider Feature](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#13-repository-provider-feature) and [CVMFS Publishing Pipeline](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md#26-cvmfs-publishing-pipeline) in the bits Reference; [bits-providers](https://github.com/bitsorg/bits-providers): the provider registry
- [lcg.bits README](https://github.com/bitsorg/lcg.bits#readme): the recipe pool, its branches and licence data
- bits [User Guide](https://github.com/bitsorg/bits/blob/main/docs/USERGUIDE.md), [Cookbook](https://github.com/bitsorg/bits/blob/main/docs/COOKBOOK.md), [Reference](https://github.com/bitsorg/bits/blob/main/docs/REFERENCE.md)
- [bits-console](https://gitlab.cern.ch/buncic/bits-console): CI builds and CVMFS publishing

## License

GPL-3.0-or-later; see [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT).
