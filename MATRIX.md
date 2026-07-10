# Build matrix without a file per combination

The externals/generators matrix — compiler × debug × cuda — is expressed by
**composing single-axis defaults fragments**, not by one `defaults-*.sh` per
combination. bits layers a chain `--defaults a::b::c`: `append_arch` values
collect in order, `overrides` deep-merge, `requires` union, and `env` is
last-wins per key.

## The fragments (one per axis value, not per combination)

| Axis        | Fragments                                             | Owns |
|-------------|-------------------------------------------------------|------|
| base        | `release` (or `lcg`, `lhcb`)                          | common flags, `requires: lcg.bits` |
| compiler    | `gcc13` · `gcc14` · `gcc15` · `clang`                 | toolchain `override`, `append_arch: -gccNN`, and any `-std` pin (in CXXFLAGS) |
| debug       | `dbg` (omit for opt)                                  | `CMAKE_BUILD_TYPE: Debug`, `append_arch: -dbg` |
| cuda        | `cuda` (omit for CPU-only)                            | `ENABLE_CUDA: ON`, `append_arch: -cuda` |

Four compilers + `dbg` + `cuda` + base = **7 files cover 4×2×2 = 16 variants**.
Adding a 5th compiler or a 3rd toggle is additive, not multiplicative.

## How to build a cell

```
bits build --defaults release::gcc15::dbg::cuda <package>   # gcc15, debug, cuda
bits build --defaults release::gcc14              <package>   # gcc14, opt, no cuda
bits build --defaults release::clang::cuda        <package>   # clang, opt, cuda
```

The effective architecture becomes e.g. `…-gcc15-dbg-cuda`, giving each cell its
own install/CVMFS tree.

## Two invariants (why each axis sets BOTH a hash input and append_arch)

1. **Hash separation.** Every axis must change the package hash so the
   content-addressed store never reuses one cell's tarball for another. A
   toolchain `override`, an added `requires`, or an `env` change already does
   this. For a pure toggle that changes binaries without changing a recipe input,
   use `track_env:` (it folds the chosen env value into the hash).

2. **Path separation.** Every axis must also add an `append_arch` qualifier so the
   CVMFS install path and tarball name differ. Without it, gcc14 and gcc15 (or opt
   vs dbg) land on the same `<arch>/<pkg>/<ver>-<rev>` path and overwrite each
   other on deployment.

You need **both** halves. This is the same collision class as building in a fixed
`/cvmfs` prefix: a shared hash means a store collision, a shared path means a
deployment overwrite.

## Rules of thumb

- Only the **compiler** fragment sets `CXXFLAGS` (it always sits in the chain and
  owns the `-std`). `dbg`/`cuda` set `CMAKE_BUILD_TYPE`/`ENABLE_CUDA` only, never
  `CXXFLAGS`, so the last-wins env merge can't drop the compiler's `-std`.
- Prefer building the compiler as a package (`overrides: GCC-Toolchain: {tag}`)
  so the matrix is image-independent and the compiler folds into every
  dependent's hash. Keep the OS/glibc in the platform (docker image); keep
  compiler/debug/cuda in these fragments.
- In bits-console, wire the axes as checkboxes and expand each cell to
  `release::<compiler>::[dbg]::[cuda]` — no hand-edited defaults.
