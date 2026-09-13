# Third-party notices

This package is released under the MIT license (see `LICENSE`). It contains no
source code copied from the projects below; it requires them as Lake dependencies,
which are fetched from their own repositories at build time and remain under
their own licenses.

| Project | License | Repository | Use |
|---|---|---|---|
| ArkLib | Apache-2.0 | <https://github.com/Verified-zkEVM/ArkLib> | `Verifier`, `Verifier.soundness` and the interactive-oracle-reduction definitions |
| VCV-io | Apache-2.0 | <https://github.com/Verified-zkEVM/VCV-io> | `ProbComp`, `OracleComp`, `probEvent`, `probOutput` |
| Mathlib | Apache-2.0 | <https://github.com/leanprover-community/mathlib4> | mathematical library (`ℝ≥0`, `ℝ≥0∞`) |
| CatCrypt Core | MIT | <https://github.com/spitters/CatCrypt-core> | `SPComp`, `prTrue` |
| catcrypt-vcvio | MIT | <https://github.com/spitters/catcrypt-vcvio> | `probCompLift`, `prTrue_probCompLift` |

The transitive dependencies of these projects are listed in `lake-manifest.json`;
each carries the license stated in its repository.
