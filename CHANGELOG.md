# Changelog

## Unreleased

- `prTrue_le_add_reduce`: additive composition with a per-adversary bound,
  `ε₁` plus the success of the explicit adversary `reduce₂ A` in the second game,
  for a computational second game.
- Lean 4.36, ArkLib `608f550b89`.

## 0.1.0-alpha.1

Initial release of the ArkLib interoperability package for CatCrypt Core
(Lean 4.33.1, Mathlib `v4.33.1`, ArkLib `dca90385fb`, catcrypt-vcvio).

- Soundness predicates over CatCrypt games: `ArgumentSoundness`,
  `KnowledgeSoundness` (∃E ∀A), `WeakKnowledgeSoundness` (∀A ∃E), and
  `KnowledgeSoundness.toWeak`.
- Monotonicity: `argumentSoundness_mono`, `knowledgeSoundness_mono`.
- Composition under caller-supplied reduction inequalities:
  `argumentSoundness_reduce`, `argumentSoundness_add_reduce`,
  `argumentSoundness_amplify`.
- Transfer of `ProbComp` bounds through catcrypt-vcvio's `probCompLift`:
  `argumentSoundness_probCompLift`, `argumentSoundness_of_probEvent`.
- Transfer from ArkLib: `verifierSoundness_iff_argumentSoundness`,
  `argumentSoundness_of_verifierSoundness` (ArkLib's `Verifier.soundness` as
  `ArgumentSoundness` of `verifierSoundnessGame`), `probEvent_optionT_eq_probOutput_any`,
  `argumentSoundness_probCompLift_iff`; `verifierSoundness_mono`.
- Documents: README, BUILDING, CONTRIBUTING, CITATION.cff, LICENSE (MIT),
  THIRD_PARTY_NOTICES; CI build with sorry and `native_decide` guards; doc-gen4
  workflow publishing to GitHub Pages.
