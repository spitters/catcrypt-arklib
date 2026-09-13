# CatCrypt ArkLib

Interoperability between [CatCrypt Core](https://github.com/spitters/CatCrypt-core)
and [ArkLib](https://github.com/Verified-zkEVM/ArkLib), the Lean 4 formalization of
interactive oracle reductions (IORs) and SNARKs, in Lean 4. The package states
argument soundness and knowledge soundness as predicates over CatCrypt `SPComp`
games, proves composition lemmas for them, and transfers `ProbComp` probability
bounds into these predicates through
[catcrypt-vcvio](https://github.com/spitters/catcrypt-vcvio).

**Documentation:** [API reference](https://spitters.github.io/catcrypt-arklib/)

The library is the single module `CatCryptArkLib` (`import CatCryptArkLib`). Its
declarations live in the namespace `CatCrypt.Crypto.Bridges.ArkLib`.

## Contents

| Group | Main definitions and theorems |
|---|---|
| Soundness predicates | `ArgumentSoundness ε game`: every adversary `A` has `prTrue (game A) Heap.empty ≤ ε`. `KnowledgeSoundness`: one extractor for all adversaries (∃E ∀A). `WeakKnowledgeSoundness`: an extractor per adversary (∀A ∃E). `KnowledgeSoundness.toWeak` |
| Monotonicity | `argumentSoundness_mono`, `knowledgeSoundness_mono` |
| Composition | `argumentSoundness_reduce` (a per-adversary reduction inequality transfers the bound), `argumentSoundness_add_reduce` (a game bounded by the sum of two reduced games has error `ε₁ + ε₂`), `argumentSoundness_amplify` (a game bounded by `q` times a reduced game has error `q * ε`). The reduction inequalities are hypotheses. |
| Transfer from VCV-io | `argumentSoundness_probCompLift`: per-adversary bounds `Pr[= true \| game A] ≤ ε` on `ProbComp Bool` games give `ArgumentSoundness` of the lifted games. `argumentSoundness_of_probEvent`: per-adversary bounds `Pr[pred \| exec A] ≤ ε` on `ProbComp` executions give `ArgumentSoundness` of the lifted, `Bool`-valued executions. |
| Transfer from ArkLib | `verifierSoundness_iff_argumentSoundness`: ArkLib's `Verifier.soundness init impl langIn langOut verifier ε` holds iff `ArgumentSoundness ε` holds for the game `verifierSoundnessGame`, in which the adversary (`VerifierSoundnessAdv`: a prover, a witness and an input statement outside `langIn`) runs ArkLib's interaction and wins when the verifier outputs a statement in `langOut`; a failed run counts as a loss. `argumentSoundness_of_verifierSoundness` is the forward direction. `probEvent_optionT_eq_probOutput_any` turns ArkLib's `OptionT ProbComp` event into a `ProbComp Bool` output. `verifierSoundness_mono`: monotonicity in the error bound. |

Adversary types are `Type*`, because ArkLib's provers live in `Type 1`.

The package declares no axioms and uses no `native_decide`.

## What is not included

- A transfer from ArkLib's `Verifier.knowledgeSoundness` into
  `KnowledgeSoundness`; the CatCrypt predicate uses the same quantifier order
  (∃E ∀A) and is not formally related to ArkLib's.
- Soundness theorems for the BCS transformation or the Fiat–Shamir transformation.
  `argumentSoundness_add_reduce` and `argumentSoundness_amplify` are the
  composition shapes such theorems take; the reduction inequalities are supplied
  by the caller.
- Theorems about specific IORs, polynomial commitment schemes or SNARKs.

## Dependencies

Pinned in `lakefile.lean` and `lake-manifest.json`:

- [CatCrypt Core](https://github.com/spitters/CatCrypt-core), required from the
  sibling directory `../CatCrypt-core`
- [catcrypt-vcvio](https://github.com/spitters/catcrypt-vcvio), required from the
  sibling directory `../catcrypt-vcvio`
- [ArkLib](https://github.com/Verified-zkEVM/ArkLib) at commit `dca90385fb`
- [VCV-io](https://github.com/Verified-zkEVM/VCV-io), at the revision resolved
  through ArkLib and catcrypt-vcvio (`f9dc47d9da` in `lake-manifest.json`)
- [Mathlib](https://github.com/leanprover-community/mathlib4) `v4.33.1`

Toolchain: `leanprover/lean4:v4.33.1` (see `lean-toolchain`).

## Build

`lake build` builds the default target, the `CatCryptArkLib` library. See
[BUILDING.md](BUILDING.md).

## Documentation

- **API reference:** [doc-gen4](https://spitters.github.io/catcrypt-arklib/)
- **Changelog:** [CHANGELOG.md](CHANGELOG.md) ·
  **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md) ·
  **Third-party notices:** [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

## References

- E. Ben-Sasson, A. Chiesa, N. Spooner. *Interactive Oracle Proofs.* TCC 2016.
- [ArkLib](https://github.com/Verified-zkEVM/ArkLib),
  `ArkLib/OracleReduction/Security/Basic.lean` — the soundness definitions this
  package refers to.

## Citing

See `CITATION.cff`. The accompanying paper:

> B. Spitters. *CatCrypt: From Rust to Cryptographic Security in Lean.*
> Cryptology ePrint Archive, Paper 2026/604.
> <https://eprint.iacr.org/2026/604.pdf>

## License

MIT. See `LICENSE`. Dependencies carry their own licenses; see
`THIRD_PARTY_NOTICES.md`.
