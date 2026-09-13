# Building

## The library

Requires [elan](https://github.com/leanprover/elan). The pinned toolchain is
`leanprover/lean4:v4.33.1` (see `lean-toolchain`).

`lakefile.lean` requires CatCrypt Core from `../CatCrypt-core` and catcrypt-vcvio
from `../catcrypt-vcvio`, so clone both next to this repository first:

```
git clone https://github.com/spitters/CatCrypt-core ../CatCrypt-core
git clone https://github.com/spitters/catcrypt-vcvio ../catcrypt-vcvio
```

Then, from the repository root:

```
lake exe cache get    # pull the Mathlib olean cache
lake build
```

`lake build` builds the default target, the `CatCryptArkLib` library. The package
passes `-E hasSorry` to Lean (see `lakefile.lean`), so a declaration whose proof
reaches `sorry` fails the build. The Mathlib cache covers Mathlib only; ArkLib,
VCV-io, CatCrypt Core and catcrypt-vcvio are compiled from source on the first
build.

## The documentation

**API reference** (`docbuild/`, doc-gen4) — per-declaration HTML for the library.
The documentation build is its own package, so doc-gen4 does not become a
dependency of code that requires the library:

```
cd docbuild && lake update && lake exe cache get && lake build CatCryptArkLib:docs
```

Output in `docbuild/.lake/build/doc/` (open `index.html`). The hosted copy at
<https://spitters.github.io/catcrypt-arklib/> is this build, published by
`.github/workflows/docs.yml`.
