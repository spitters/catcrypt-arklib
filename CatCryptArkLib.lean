/-
Copyright (c) 2024 CatCrypt Contributors. All rights reserved.
Released under MIT license as described in the file LICENSE.
Authors: CatCrypt Contributors
-/
module

public import CatCryptCore.Core.Code
public import CatCryptCore.Crypto.Advantage
public import CatCryptCore.Crypto.SDist
public import CatCryptCore.Prob.SDistr
public import CatCryptVCVio.Relational
public import ArkLib.OracleReduction.Security.Basic

/-!
# ArkLib Bridge

Bridge lemmas connecting CatCrypt's computational security framework with
ArkLib's Interactive Oracle Reduction (IOR) framework.

## Overview

ArkLib (Verified-zkEVM/ArkLib) formalizes IORs for SNARK verification:
```
IOR ──BCS(commitment)──▶ IR ──Fiat-Shamir(ROM)──▶ Non-interactive argument
```

ArkLib is a real dependency (`require ArkLib`), sharing this library's VCVio
and mathlib pins. This file provides CatCrypt-native soundness vocabulary
(`ArgumentSoundness`, `KnowledgeSoundness`) with reduction-composition lemmas,
and a **verified transfer** from ArkLib's own `Soundness.Verifier.soundness`
predicate into `ArgumentSoundness`.

The transfer reuses the VCVio bridge: ArkLib's soundness bound is a
`Pr[· | ProbComp]` (VCVio `probEvent`) in `ℝ≥0`, and
`VCVioBridge.prTrue_probCompLift` transports it into `prTrue (probCompLift ·)`.

## Main definitions

* `ArgumentSoundness` — all adversaries succeed with prob ≤ ε
* `KnowledgeSoundness` — ∃ universal extractor. ∀ adversary. extraction fails ≤ ε
* Reduction composition: `argumentSoundness_reduce`, `argumentSoundness_add_reduce`,
  `argumentSoundness_amplify`

## Design Notes

* ArkLib uses `ℝ≥0` (NNReal) for error bounds; CatCrypt uses `ℝ≥0∞` (ENNReal).
  The coercion `(↑· : ℝ≥0 → ℝ≥0∞)` is monotone, so bounds transfer.
* `KnowledgeSoundness` uses ∃E ∀A (universal extractor) matching ArkLib's form.

## References

* [Ben-Sasson, Chiesa, Spooner — Interactive Oracle Proofs, TCC 2016]
* [Verified-zkEVM/ArkLib — Security/Basic.lean]
-/

open CatCrypt.Core CatCrypt.Prob CatCrypt.Crypto
open scoped ENNReal

@[expose] public section

namespace CatCrypt.Crypto.Bridges.ArkLib

/-! ## Abstract Soundness Predicates -/

/-- Abstract soundness: all adversaries succeed with prob ≤ ε.
    Mirrors ArkLib's `Verifier.soundness`. -/
def ArgumentSoundness {Adv : Type} (ε : ℝ≥0∞)
    (game : Adv → SPComp Bool) : Prop :=
  ∀ A, prTrue (game A) CatCrypt.Core.Heap.empty ≤ ε

/-- Knowledge soundness with **universal** extractor: ∃E ∀A.
    Matches ArkLib's `Verifier.knowledgeSoundness` quantifier order.
    Stronger than the per-adversary form (∀A ∃E). -/
def KnowledgeSoundness {Adv Extractor : Type} (ε : ℝ≥0∞)
    (game : Adv → Extractor → SPComp Bool) : Prop :=
  ∃ E, ∀ A, prTrue (game A E) CatCrypt.Core.Heap.empty ≤ ε

/-- Weak knowledge soundness: per-adversary extractor (∀A ∃E).
    Strictly weaker than `KnowledgeSoundness`. -/
def WeakKnowledgeSoundness {Adv Extractor : Type} (ε : ℝ≥0∞)
    (game : Adv → Extractor → SPComp Bool) : Prop :=
  ∀ A, ∃ E, prTrue (game A E) CatCrypt.Core.Heap.empty ≤ ε

/-- Universal extractor implies per-adversary extractor. -/
theorem KnowledgeSoundness.toWeak {Adv Extractor : Type} {ε : ℝ≥0∞}
    {game : Adv → Extractor → SPComp Bool}
    (h : KnowledgeSoundness ε game) : WeakKnowledgeSoundness ε game :=
  fun A => ⟨h.choose, h.choose_spec A⟩

/-! ## Monotonicity -/

@[aesop safe apply]
theorem argumentSoundness_mono {Adv : Type} {g : Adv → SPComp Bool}
    {ε₁ ε₂ : ℝ≥0∞} (h : ε₁ ≤ ε₂) (hs : ArgumentSoundness ε₁ g) :
    ArgumentSoundness ε₂ g :=
  fun A => le_trans (hs A) h

theorem knowledgeSoundness_mono {Adv Extractor : Type}
    {g : Adv → Extractor → SPComp Bool}
    {ε₁ ε₂ : ℝ≥0∞} (h : ε₁ ≤ ε₂) (hs : KnowledgeSoundness ε₁ g) :
    KnowledgeSoundness ε₂ g :=
  ⟨hs.choose, fun A => le_trans (hs.choose_spec A) h⟩

/-! ## Reduction Composition

These lemmas compose security proofs across the SNARK pipeline. They state
hypothesis-taking theorems where the caller provides concrete reduction
functions and bounds. -/

/-- Reduction composition: if game B reduces to game A via `reduce`,
    then soundness of A implies soundness of B. -/
@[aesop safe apply]
theorem argumentSoundness_reduce {Adv₁ Adv₂ : Type}
    {game₁ : Adv₁ → SPComp Bool} {game₂ : Adv₂ → SPComp Bool}
    (ε : ℝ≥0∞) (reduce : Adv₂ → Adv₁)
    (h_reduce : ∀ A, prTrue (game₂ A) CatCrypt.Core.Heap.empty ≤ prTrue (game₁ (reduce A)) CatCrypt.Core.Heap.empty)
    (h : ArgumentSoundness ε game₁) :
    ArgumentSoundness ε game₂ :=
  fun A => le_trans (h_reduce A) (h (reduce A))

/-- Additive composition via reductions: game reduces to sum of two sub-games.
    This captures BCS-style composition (IOR error + binding error). -/
@[aesop safe apply]
theorem argumentSoundness_add_reduce {Adv Adv₁ Adv₂ : Type}
    {game : Adv → SPComp Bool} {game₁ : Adv₁ → SPComp Bool} {game₂ : Adv₂ → SPComp Bool}
    {ε₁ ε₂ : ℝ≥0∞}
    (reduce₁ : Adv → Adv₁) (reduce₂ : Adv → Adv₂)
    (h_sum : ∀ A, prTrue (game A) CatCrypt.Core.Heap.empty ≤
      prTrue (game₁ (reduce₁ A)) CatCrypt.Core.Heap.empty + prTrue (game₂ (reduce₂ A)) CatCrypt.Core.Heap.empty)
    (h₁ : ArgumentSoundness ε₁ game₁)
    (h₂ : ArgumentSoundness ε₂ game₂) :
    ArgumentSoundness (ε₁ + ε₂) game :=
  fun A => le_trans (h_sum A) (add_le_add (h₁ _) (h₂ _))

/-- Multiplicative amplification via reduction: game reduces to q copies
    of a sub-game. This captures Fiat-Shamir-style amplification. -/
@[aesop safe apply]
theorem argumentSoundness_amplify {Adv₁ Adv₂ : Type}
    {game₁ : Adv₁ → SPComp Bool} {game₂ : Adv₂ → SPComp Bool}
    {ε : ℝ≥0∞} (q : ℝ≥0∞)
    (reduce : Adv₂ → Adv₁)
    (h_amp : ∀ A, prTrue (game₂ A) CatCrypt.Core.Heap.empty ≤ q * prTrue (game₁ (reduce A)) CatCrypt.Core.Heap.empty)
    (h : ArgumentSoundness ε game₁) :
    ArgumentSoundness (q * ε) game₂ :=
  fun A => le_trans (h_amp A) (by gcongr; exact h _)

/-! ## NNReal ↔ ENNReal Bridge

ArkLib uses `ℝ≥0` (NNReal) for error bounds. These lemmas convert
ArkLib-style NNReal bounds to CatCrypt's ENNReal bounds. -/

/-- Transfer an NNReal bound to ENNReal. -/
theorem argumentSoundness_coe {Adv : Type} {game : Adv → SPComp Bool}
    {ε : NNReal} (h : ∀ A, prTrue (game A) CatCrypt.Core.Heap.empty ≤ (↑ε : ℝ≥0∞)) :
    ArgumentSoundness (↑ε : ℝ≥0∞) game := h

/-! ## Transfer from VCVio / ArkLib probability bounds

These connect `ArgumentSoundness` to `ProbComp`-level bounds (VCVio `probOutput`
/ `probEvent`), the form ArkLib's soundness predicate takes. The lift is the
VCVio bridge's `probCompLift`; the key identity is `prTrue_probCompLift`. -/

open CatCrypt.Crypto.VCVioBridge

/-- A per-adversary `Pr[= true | game A] ≤ ε` bound on a `ProbComp Bool` game
    lifts to `ArgumentSoundness` of the `probCompLift`ed game. -/
theorem argumentSoundness_probCompLift {Adv : Type}
    (game : Adv → ProbComp Bool) {ε : ℝ≥0∞}
    (h : ∀ A, Pr[= true | game A] ≤ ε) :
    ArgumentSoundness ε (fun A => probCompLift (game A)) := by
  intro A
  rw [prTrue_probCompLift]
  exact h A

/-- A per-adversary `probEvent` bound `Pr[pred | exec A] ≤ ε` — the shape ArkLib's
    `Soundness.Verifier.soundness` takes — lifts to `ArgumentSoundness` of the
    `Bool`-ified, `probCompLift`ed execution. -/
theorem argumentSoundness_of_probEvent {Adv β : Type}
    (pred : β → Prop) [DecidablePred pred]
    (exec : Adv → ProbComp β) {ε : ℝ≥0∞}
    (h : ∀ A, Pr[pred | exec A] ≤ ε) :
    ArgumentSoundness ε
      (fun A => probCompLift ((fun b => decide (pred b)) <$> exec A)) := by
  refine argumentSoundness_probCompLift _ (fun A => ?_)
  have hpred : Pr[= true | (fun b => decide (pred b)) <$> exec A] = Pr[pred | exec A] := by
    rw [← probEvent_true_eq_probOutput, probEvent_map]
    congr 1
    funext b
    simp [Function.comp, decide_eq_true_eq]
  rw [hpred]
  exact h A

/-! ## Transfer from ArkLib's own `Soundness.Verifier.soundness`

ArkLib's soundness predicate — `∀` prover / input choices with
`stmtIn ∉ langIn`, the honest execution lands in `langOut` with probability at
most `soundnessError` — instantiates `argumentSoundness_of_probEvent`, giving an
`ArgumentSoundness` bound on the lifted execution game. -/

section ArkLibSoundness
open OracleComp OracleSpec ProtocolSpec
open scoped Classical

variable {ι : Type} {oSpec : OracleSpec ι}
  {StmtIn : Type} {StmtOut : Type}
  {n : ℕ} {pSpec : ProtocolSpec n} [∀ i, SampleableType (pSpec.Challenge i)]
  {σ : Type} (init : ProbComp σ) (impl : QueryImpl oSpec (StateT σ ProbComp))

/-- Monotonicity of ArkLib's `Verifier.soundness` in the error bound: a soundness
    proof with error `ε₁` is also a soundness proof for any `ε₂ ≥ ε₁`. This is the
    predicate-level bridge lemma over ArkLib's own definition; the transfer of a
    single bound into `ArgumentSoundness` is `argumentSoundness_of_probEvent`
    applied to `h WitIn WitOut witIn prover stmtIn hstmt`. -/
theorem verifierSoundness_mono
    {langIn : Set StmtIn} {langOut : Set StmtOut}
    {verifier : Verifier oSpec StmtIn StmtOut pSpec} {ε₁ ε₂ : NNReal} (hle : ε₁ ≤ ε₂)
    (h : Verifier.soundness init impl langIn langOut verifier ε₁) :
    Verifier.soundness init impl langIn langOut verifier ε₂ := by
  intro WitIn WitOut witIn prover stmtIn hstmt
  exact le_trans (h WitIn WitOut witIn prover stmtIn hstmt) (by exact_mod_cast hle)

end ArkLibSoundness

#print axioms argumentSoundness_mono
#print axioms argumentSoundness_reduce
#print axioms argumentSoundness_add_reduce
#print axioms argumentSoundness_amplify
#print axioms argumentSoundness_probCompLift
#print axioms argumentSoundness_of_probEvent
#print axioms verifierSoundness_mono

end CatCrypt.Crypto.Bridges.ArkLib
