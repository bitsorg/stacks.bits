# stacks.bits

Defaults and options for building the **LCG software stack** with
[`bits`](../bits). This repository ships no package recipes of its own — those
live in [`lcg.bits`](../lcg.bits), a pool of ~1100 recipes. `stacks.bits` is the
*policy* layer: it declares the compiler/build-type/release options, the CVMFS
publish layout, and the package families, and it points every build at the
matching `lcg.bits` branch.

It is designed to reproduce **lcgcmake** build types and CVMFS installation
layout, so if you know lcgcmake, the mapping below should feel familiar.

---

## 1. How `bits` maps to lcgcmake

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

The CVMFS templates (in `defaults-release.sh`, under `system:`):

```
prefix:   /cvmfs/sft-nightlies-test.cern.ch/lcg
releases: {prefix}/releases/{release}/{family}{pkg}/{tag}/{platform}
shared:   {prefix}/releases/{release}/noarch/{pkg}/{tag}
modules:  {prefix}/releases/{release}/{platform}/Modules/modulefiles/{pkg}
```

`{release}` collapses out of the path when it is the trunk (`main`), and
`{family}` collapses for externals — so a plain external on the default line lands
at `…/releases/<pkg>/<tag>/<platform>`, exactly the pre-release layout.

---

## 2. Selecting defaults on the command line

Options are **composable profiles** combined with `::`. `release` is always the
implicit base (auto-prepended), so you only name the overlays:

```
bits build ROOT --defaults gcc15            # release + gcc15   (c++23, RelWithDebInfo)
bits build ROOT --defaults gcc15::dbg       # + Debug build type
bits build ROOT --defaults gcc13::dev4      # gcc13, ROOT 6.40 pinned, release "dev4"
bits build ROOT --defaults clang::cuda      # clang + CUDA knobs
```

The profiles fall on independent **axes**, and each contributes an `append_arch`
suffix (so the arch string is the `bits` `BINARY_TAG`):

| Axis | Profiles | Sets | `append_arch` |
|---|---|---|---|
| Compiler | `gcc13`, `gcc14`, `gcc15`, `clang` | `GCC-Toolchain` tag (or `prefer_system` for clang) + the C++ standard in `CXXFLAGS` | `-gcc13` … `-clang` |
| Build type | *(base)*, `dbg` | `CMAKE_BUILD_TYPE` = `RELWITHDEBINFO` / `Debug` | `-dbg` |
| Feature | `cuda` | CUDA knobs (never `CXXFLAGS`) | `-cuda` |
| Release | *(base)*, `dev3`, `dev4` | the `release` label + per-package version pins | *(none — release is a path level, not an arch suffix)* |

The C++ standard is owned by the **compiler axis** (gcc13/14 → c++20,
gcc15 → c++23, clang → c++20), never by the base or the build-type/feature
profiles — so `dbg`/`cuda` compose with any compiler without clobbering `-std`.

`bits cvmfs-path -c . --defaults <chain> --package <pkg> --version <v> --platform <p>`
prints the exact publish path a build would use — handy to preview where a chain
lands before building.

---

## 3. Branches and releases

One value — the `release` label — names **three things at once**:

1. the CVMFS `{release}` path slot,
2. the **`lcg.bits` branch** to build against (`overrides: lcg.bits: tag: "%(release)s"`),
3. the tag `stacks.bits` will converge to for that release.

`bits` resolves it, highest precedence first:

1. an explicit, non-trunk `release:` in the chosen defaults (`dev3`, `dev4`, a
   tagged `LCG_107`),
2. else the **working-directory branch name** (a trailing `-patches` is stripped,
   so `LCG_107-patches` → `LCG_107`),
3. else **`main`** — the default, reproducing the old behaviour: build `lcg.bits`
   `main`, and (because `main` collapses out of the path) publish with no release
   level.

Consequences:

- The effective release **must exist as an `lcg.bits` branch** — that branch *is*
  the recipe pool. Creating the branch "opens" a release; tagging `stacks.bits`
  later freezes it.
- Check out a recipe branch `feature-x` in your working copy and the build
  automatically tracks `lcg.bits` `feature-x` and publishes under
  `…/releases/feature-x/…` — isolated from `main`, no collisions.
- `dev3`/`dev4` move the branch **and** the slot together (they set the `release`
  variable), on top of their version pins.

`BITS_RELEASE`-style env overrides are intentionally *not* consulted, so the
CVMFS slot and the `lcg.bits` branch can never drift apart.

---

## 4. Package families

`bits` assigns each package a family via fnmatch on the `package_family:` map in
`defaults-release.sh`; the family becomes a path segment
(`…/releases/<release>/MCGenerators/pythia8/…`). There is **no `default:`
family**, so anything unlisted is an external and its family segment collapses
out — matching lcgcmake, where a package's home is its directory, not its
dependency graph. `MCGenerators` mirrors lcgcmake's `generators/` tree (the
authoritative per-package classification); core/AA packages like `ROOT`,
`HepMC`, `Geant4` stay externals.

---

## 5. Local development → publish lifecycle

```
   edit recipes in lcg.bits (on a branch)      set the release
            │                                   (branch name, or --defaults devN)
            ▼                                          │
   bits build <pkg> --defaults <chain>  ◄──────────────┘
            │   builds against the lcg.bits branch = release,
            │   installs to <workDir>/<arch>/<family>/<pkg>/<ver-rev>/
            ▼
   bits publish  (or the cvmfs-prepub pipeline)
            │   reserves the CVMFS path (bits cvmfs-path),
            │   uploads the content-addressed tarball to the S3 store,
            ▼   publishes to /cvmfs/…/releases/<release>/<family>/<pkg>/<tag>/<platform>
   consumed via CVMFS + modulefiles
```

Locally you iterate with `bits build … --defaults …` on a branch; the install
tree already carries the family layout, so what you test locally is what gets
published. Publishing is normally done by the **bits-console** cvmfs-prepub
pipeline rather than by hand.

---

## 6. CI: commits can trigger predefined pipelines

A commit to `lcg.bits` **or** `stacks.bits` (including a GitLab pull-mirror sync)
can fire a **designated pipeline** that is configured and saved in **bits-console**,
giving nightly/CI-style rebuilds without redefining the build here.

- The build definition (packages, platforms, defaults chain, providers,
  publish/certify) is authored in the console's **Build modal → "Save as
  pipeline"** and stored at `communities/<GROUP>/pipelines/<PIPELINE>.json`.
- A small `.gitlab-ci.yml` in the recipe repo only *fires* it. `lcg.bits` already
  ships one that multi-project-triggers bits-console with `BITS_GROUP: LCG`,
  `BITS_PIPELINE: on-commit`; the downstream `run-group-pipeline` job fans out one
  cvmfs-prepub build per enabled entry. `stacks.bits` can carry an analogous file.

One-time setup (GitLab UI):

1. bits-console → Settings → CI/CD → **Token Access** → add the recipe project to
   the `CI_JOB_TOKEN` allowlist.
2. If the recipe repo is a pull-mirror, enable **Mirroring → "Trigger pipelines
   for mirror updates"** (the `.gitlab-ci.yml` must be on the mirrored branch).
3. In the console, build the stack in the Build modal, tick the options, and
   **Save as pipeline**, naming it to match `BITS_PIPELINE`.

The same saved pipeline can also be run on a schedule (nightly) or on demand from
the console — the commit trigger is just one entry point.

---

## Files

| File | Role |
|---|---|
| `defaults-release.sh` | base: CVMFS templates, `release` label, `package_family`, requires `lcg.bits` |
| `defaults-gcc13/14/15.sh`, `defaults-clang.sh` | compiler axis (toolchain tag + C++ standard) |
| `defaults-dbg.sh` | `Debug` build type |
| `defaults-cuda.sh` | CUDA feature knobs |
| `defaults-dev3.sh`, `defaults-dev4.sh` | release lines: `release` label + heptools-devN version pins |
| `externals.sh`, `generators.sh` | meta-packages that pull in the externals / generator sets |
