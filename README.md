# stacks.bits

Defaults and options for building the **LCG software stack** with [`bits`](../bits). This repository ships no package recipes of its own — those live in [`lcg.bits`](../lcg.bits), a pool of ~1100 recipes. `stacks.bits` is the *policy* layer: it declares the compiler/build-type/release options, the CVMFS publish layout, and the package families, and it points every build at the matching `lcg.bits` branch.

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
| `/cvmfs/…/lcg/releases/<LCG_VERSION>/[<group>/]<pkg>/<ver>/<platform>` | `…/releases/<release>/<family>/<pkg>/<tag>/<platform>` | `defaults-release` templates |
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
| `prefix` | the CVMFS root, e.g. `/cvmfs/sft-nightlies-test.cern.ch/lcg` |
| `cvmfs_user_prefix` | root for per-user (non-admin) publishes: `<user_prefix>/<login>` |
| `cvmfs_releases_template` | per-package publish path (tokens `{release}`,`{family}`,`{pkg}`,`{tag}`,`{platform}`) |
| `cvmfs_modules_template` | modulefile publish path |
| `cvmfs_shared_path_template` | noarch/shared publish path |
| `remote_store` | the **S3 content store** for reuse + upload, e.g. `b3://<bucket>::rw` (see [The S3 Content Store](#the-s3-content-store--certification)) |
| `certify_group` | group name stamped into the signed common manifest |
| `manifests_remote` | git repo where build/common manifests are recorded |

The current templates:

```
prefix:   /cvmfs/sft-nightlies-test.cern.ch/lcg
releases: {prefix}/releases/{release}/{family}{pkg}/{tag}/{platform}
shared:   {prefix}/releases/{release}/noarch/{pkg}/{tag}
modules:  {prefix}/releases/{release}/{platform}/Modules/modulefiles/{pkg}
```

`{release}` collapses out when it is the trunk (`main`), and `{family}` collapses for externals — so a plain external on the default line lands at `…/releases/<pkg>/<tag>/<platform>`, exactly the pre-release layout.

> `stacks.bits` does not set `remote_store`/`certify_group`/`manifests_remote` itself — locally you pass the store on the command line (or `~/.bits/s3keys`), and in CI bits-console supplies them as job variables. 

---

## Command-Line Usage

Options are **composable profiles** combined with `::`. `release` is always the implicit base (auto-prepended), so you only name the overlays:

```bash
bits build ROOT --defaults gcc15            # release + gcc15   (c++23, RelWithDebInfo)
bits build ROOT --defaults gcc15::dbg       # + Debug build type
bits build ROOT --defaults gcc13::dev4      # gcc13, ROOT 6.40 pinned, release "dev4"
bits build ROOT --defaults clang::cuda      # clang + CUDA knobs
```

### Composing Profiles

The profiles fall on independent **axes**, each contributing an `append_arch` suffix (so the arch string is the `bits` `BINARY_TAG`):

| Axis | Profiles | Sets | `append_arch` |
|---|---|---|---|
| Compiler | `gcc13`, `gcc14`, `gcc15`, `clang` | `GCC-Toolchain` tag (or `prefer_system` for clang) + the C++ standard in `CXXFLAGS` | `-gcc13` … `-clang` |
| Build type | *(base)*, `dbg` | `CMAKE_BUILD_TYPE` = `RELWITHDEBINFO` / `Debug` | `-dbg` |
| Feature | `cuda` | CUDA knobs (`ENABLE_CUDA`, never `CXXFLAGS`) | `-cuda` |
| Feature | `oracle` | adds the Oracle client packages (`oracledb`, `cx_oracle`); Linux-only, changes no build env | *(none — same tree)* |
| Release | *(base)*, `dev3`, `dev4` | the `release` label + per-package version pins | *(none — release is a path level, not an arch suffix)* |

The C++ standard is owned by the **compiler axis** (gcc13/14 → c++20, gcc15 → c++23, clang → c++20), never by the base or the build-type/feature profiles — so `dbg`/`cuda` compose with any compiler without clobbering `-std`.

### Previewing Publish Paths

`bits cvmfs-path -c . --defaults <chain> --package <pkg> --version <v> --platform <p>` prints the exact publish path a build would use — handy to preview where a chain lands before building.

---

## Branches and Releases

One value — the `release` label — names **three things at once**: the CVMFS `{release}` path slot, the **`lcg.bits` branch** to build against (`overrides: lcg.bits: tag: "%(release)s"`), and the tag `stacks.bits` will converge to. `bits` resolves it, highest precedence first:

1. an explicit, non-trunk `release:` in the chosen defaults (`dev3`, `dev4`, a tagged `LCG_107`),
2. else the **working-directory branch name** (`-patches` stripped, so `LCG_107-patches` → `LCG_107`),
3. else **`main`** — the default: build `lcg.bits` `main`, and (because `main` collapses out of the path) publish with no release level (old behaviour).

The effective release **must exist as an `lcg.bits` branch** — that branch *is* the recipe pool. Check out `feature-x` in your working copy and the build tracks `lcg.bits` `feature-x` and publishes under `…/releases/feature-x/…`, isolated from `main`. `dev3`/`dev4` move the branch **and** the slot together.

---

## Package Families

`bits` assigns each package a family via fnmatch on `package_family:` in `defaults-release.sh`; the family becomes a path segment (`…/releases/<release>/MCGenerators/pythia8/…`). There is **no `default:` family**, so anything unlisted is an external and its segment collapses out — matching lcgcmake, where a package's home is its directory, not its dependency graph. `MCGenerators` mirrors lcgcmake's `generators/` tree; core/AA packages like `ROOT`, `HepMC`, `Geant4` stay externals.

---

## Local Development

Building is done with `bits`; exploring and using the resulting module environment is done with **`bitsenv`**, the [Environment Modules] front-end. A build installs to `sw/<arch>/[<family>/]<pkg>/<ver>-<rev>/` and generates a modulefile named `<package>/<version>` that `bitsenv` can then load.

### Building Packages

**Build** a single package (work dir defaults to `sw`, arch auto-detected):

```bash
bits build ROOT --defaults gcc15
bits build ROOT --defaults gcc15 -a ubuntu2510_x86-64-gcc15 -w /scratch/sw
bits deps  ROOT --defaults gcc15        # inspect the dependency tree first
```

### Using the Module Environment

**Discover** the built modules:

```bash
bitsenv q                    # list every available module (alias: bitsenv query)
bitsenv q pythia             # ...matching a regexp
```

**Test / use** a package in its module environment — three ways (`bitsenv [-p <platform>] [-m <modules dir>] <verb>`):

```bash
# a) interactive subshell with the module(s) loaded; `exit` to leave.
bitsenv enter ROOT/v6.38.00
bitsenv enter ROOT/v6.38.00,Geant4/v11.4.1     # several modules, comma-separated

# b) run ONE command in the environment (exit code preserved):
bitsenv setenv ROOT/v6.38.00 -c root -b        # everything after -c runs as-is

# c) inject the environment into your CURRENT shell (note the backticks):
eval `bitsenv printenv ROOT/v6.38.00`
bitsenv checkenv ROOT/v6.38.00                 # sanity-check the module env
```

### Building the Full Stack

**Build the full stack** via the meta-packages in this repo — they pull in the whole set as dependencies:

```bash
bits build externals  --defaults gcc15        # libraries, tools, Python, ML, core
bits build generators --defaults gcc15        # event generators (MCGenerators family)
```

### Iteration Workflow

**Iterate**: edit a recipe in `lcg.bits` on a branch, re-run `bits build` (only what changed rebuilds — see [The S3 Content Store](#the-s3-content-store--certification) on reuse), and `bits clean` to reset the build area. Because the local install tree already carries the family/arch layout, what you test locally is exactly what gets published.

---

## The S3 Content Store & Certification

Three artefacts, deliberately separate:

- **S3 content store** — a *content-addressed* cache of build tarballs (`TARS/<arch>/store/<hash>/…`, hash-only). Identical inputs → identical hash → identical binary, so any builder can **reuse** a prebuilt package instead of rebuilding. This is why the store exists: it makes builds fast and reproducible across machines and CI, and it's the substrate certification trusts. Configured via `system.remote_store` (`b3://<bucket>::rw`); credentials in `~/.bits/s3keys` (or `$BITS_AWS_KEYS_FILE`), store override `$BITS_S3_STORE`.
- **CVMFS release tree** — the *path-addressed* deployment users actually mount (`…/releases/<release>/<family>/<pkg>/<tag>/<platform>`).
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
bits gc                                                      # reachability GC: roots = hashes in the
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
| `defaults-release.sh` | base: `system:` (paths/store/policy), `env:`, `release` label, `package_family`, requires `lcg.bits` |
| `defaults-gcc13/14/15.sh`, `defaults-clang.sh` | compiler axis (toolchain tag + C++ standard) |
| `defaults-dbg.sh` | `Debug` build type |
| `defaults-cuda.sh` | CUDA feature knobs (`-cuda` tree) |
| `defaults-oracle.sh` | oracle flag: adds `oracledb`/`cx_oracle` (Linux-only, same tree) |
| `defaults-dev3.sh`, `defaults-dev4.sh` | release lines: `release` label + heptools-devN version pins |
| `externals.sh`, `generators.sh` | meta-packages that pull in the externals / generator sets |

[Environment Modules]: https://modules.readthedocs.io/
