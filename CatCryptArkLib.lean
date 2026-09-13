/-
Copyright (c) 2026 CatCrypt Contributors. All rights reserved.
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
and an equivalence between ArkLib's `Verifier.soundness` predicate and
`ArgumentSoundness` of an explicit CatCrypt game
(`verifierSoundness_iff_argumentSoundness`).

In that game the adversary (`VerifierSoundnessAdv`) is a cheating prover
together with its witness types, a witness and an input statement outside
`langIn`; the game (`verifierSoundnessGame`) runs ArkLib's reduction and
outputs `true` exactly when the execution does not fail and the verifier's
output statement lies in `langOut`. ArkLib's bound is a `probEvent` over an
`OptionT ProbComp` computation; `probEvent_optionT_eq_probOutput_any` rewrites it
as `Pr[= true | ·]` of a `ProbComp Bool` computation in which failure maps to
`false`, and `VCVioBridge.prTrue_probCompLift` transports that into
`prTrue (probCompLift ·)`.

## Main definitions

* `ArgumentSoundness` — all adversaries succeed with prob ≤ ε
* `KnowledgeSoundness` — ∃ universal extractor. ∀ adversary. extraction fails ≤ ε
* Reduction composition: `argumentSoundness_reduce`, `argumentSoundness_add_reduce`,
  `argumentSoundness_amplify`
* `VerifierSoundnessAdv`, `verifierSoundnessGame` — ArkLib's soundness experiment
  as a CatCrypt game
* `verifierSoundness_iff_argumentSoundness`, `argumentSoundness_of_verifierSoundness`

## Design Notes

* ArkLib uses `ℝ≥0` (NNReal) for error bounds; CatCrypt uses `ℝ≥0∞` (ENNReal).
  The transfer states the CatCrypt bound as the coercion `(ε : ℝ≥0∞)` of ArkLib's
  `ε : ℝ≥0`; the two bounds are equivalent.
* `ArgumentSoundness` is universe-polymorphic in the adversary type, since an
  ArkLib prover carries its state types and lives in `Type 1`.
* `KnowledgeSoundness` uses ∃E ∀A (universal extractor) matching ArkLib's form.

## References

* [Ben-Sasson, Chiesa, Spooner — Interactive Oracle Proofs, TCC 2016]
* [Verified-zkEVM/ArkLib — Security/Basic.lean]
-/

open CatCrypt.Core CatCrypt.Prob CatCrypt.Crypto
open scoped ENNReal NNReal

@[expose] public section

namespace CatCrypt.Crypto.Bridges.ArkLib

/-! ## Abstract Soundness Predicates -/

/-- Abstract soundness: every adversary wins `game` with probability at most `ε`.
    ArkLib's `Verifier.soundness` is equivalent to this predicate for
    `verifierSoundnessGame` (`verifierSoundness_iff_argumentSoundness`). -/
def ArgumentSoundness {Adv : Type*} (ε : ℝ≥0∞)
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
theorem argumentSoundness_mono {Adv : Type*} {g : Adv → SPComp Bool}
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
theorem argumentSoundness_reduce {Adv₁ Adv₂ : Type*}
    {game₁ : Adv₁ → SPComp Bool} {game₂ : Adv₂ → SPComp Bool}
    (ε : ℝ≥0∞) (reduce : Adv₂ → Adv₁)
    (h_reduce : ∀ A, prTrue (game₂ A) CatCrypt.Core.Heap.empty ≤ prTrue (game₁ (reduce A)) CatCrypt.Core.Heap.empty)
    (h : ArgumentSoundness ε game₁) :
    ArgumentSoundness ε game₂ :=
  fun A => le_trans (h_reduce A) (h (reduce A))

/-- Additive composition via reductions: game reduces to sum of two sub-games.
    This captures BCS-style composition (IOR error + binding error). -/
@[aesop safe apply]
theorem argumentSoundness_add_reduce {Adv Adv₁ Adv₂ : Type*}
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
theorem argumentSoundness_amplify {Adv₁ Adv₂ : Type*}
    {game₁ : Adv₁ → SPComp Bool} {game₂ : Adv₂ → SPComp Bool}
    {ε : ℝ≥0∞} (q : ℝ≥0∞)
    (reduce : Adv₂ → Adv₁)
    (h_amp : ∀ A, prTrue (game₂ A) CatCrypt.Core.Heap.empty ≤ q * prTrue (game₁ (reduce A)) CatCrypt.Core.Heap.empty)
    (h : ArgumentSoundness ε game₁) :
    ArgumentSoundness (q * ε) game₂ :=
  fun A => le_trans (h_amp A) (by gcongr; exact h _)

/-! ## Transfer from VCVio probability bounds

These connect `ArgumentSoundness` to `ProbComp`-level bounds (VCVio `probOutput`
/ `probEvent`). The lift is the VCVio bridge's `probCompLift`; the key identity
is `prTrue_probCompLift`. -/

open CatCrypt.Crypto.VCVioBridge

/-- `ArgumentSoundness` of a `probCompLift`ed game is equivalent to the
    per-adversary bound `Pr[= true | game A] ≤ ε` on the `ProbComp Bool` game. -/
theorem argumentSoundness_probCompLift_iff {Adv : Type*}
    (game : Adv → ProbComp Bool) {ε : ℝ≥0∞} :
    ArgumentSoundness ε (fun A => probCompLift (game A)) ↔
      ∀ A, Pr[= true | game A] ≤ ε := by
  simp only [ArgumentSoundness, prTrue_probCompLift]

/-- A per-adversary `Pr[= true | game A] ≤ ε` bound on a `ProbComp Bool` game
    lifts to `ArgumentSoundness` of the `probCompLift`ed game. -/
theorem argumentSoundness_probCompLift {Adv : Type*}
    (game : Adv → ProbComp Bool) {ε : ℝ≥0∞}
    (h : ∀ A, Pr[= true | game A] ≤ ε) :
    ArgumentSoundness ε (fun A => probCompLift (game A)) :=
  (argumentSoundness_probCompLift_iff game).2 h

/-- A per-adversary `probEvent` bound `Pr[pred | exec A] ≤ ε` on a `ProbComp`
    execution lifts to `ArgumentSoundness` of the `Bool`-valued, `probCompLift`ed
    execution. -/
theorem argumentSoundness_of_probEvent {Adv : Type*} {β : Type}
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

/-- The probability of an event `p` in an `OptionT` computation equals the
    probability that the underlying computation returns `some a` with `p a`,
    written as `Pr[= true | ·]` of the `Bool`-valued map in which failure
    (`none`) is sent to `false`. -/
theorem probEvent_optionT_eq_probOutput_any {m : Type → Type} [Monad m] [LawfulMonad m]
    [MonadLiftT m SPMF] [LawfulMonadLiftT m SPMF] {α : Type}
    (mx : OptionT m α) (p : α → Prop) [DecidablePred p] :
    Pr[p | mx] = Pr[= true | (fun o : Option α => o.any (fun a => decide (p a))) <$> mx.run] := by
  rw [← probEvent_true_eq_probOutput, probEvent_map]
  simp only [probEvent_eq_tsum_indicator, OptionT.probOutput_eq,
    tsum_option _ ENNReal.summable, Set.indicator_apply]
  simp

/-! ## Transfer from ArkLib's `Verifier.soundness`

ArkLib's soundness experiment, stated as a CatCrypt game. The adversary chooses
the witness types, a witness, a prover and an input statement outside `langIn`;
the game runs ArkLib's reduction with the given verifier, maps a failed
execution to `false`, and otherwise outputs whether the verifier's output
statement lies in `langOut`. For a proof system (`langOut` the accepting
statements) the winning event is acceptance of a false statement. -/

section ArkLibSoundness
open OracleComp OracleSpec ProtocolSpec
open scoped Classical

variable {ι : Type} {oSpec : OracleSpec ι}
  {StmtIn : Type} {StmtOut : Type}
  {n : ℕ} {pSpec : ProtocolSpec n} [∀ i, SampleableType (pSpec.Challenge i)]
  {σ : Type} (init : ProbComp σ) (impl : QueryImpl oSpec (StateT σ ProbComp))

/-- An adversary in ArkLib's soundness experiment for `verifier`: witness types,
    a witness, a (cheating) prover, and an input statement outside `langIn`. -/
structure VerifierSoundnessAdv (langIn : Set StmtIn)
    (verifier : Verifier oSpec StmtIn StmtOut pSpec) where
  /-- The prover's input witness type. -/
  WitIn : Type
  /-- The prover's output witness type. -/
  WitOut : Type
  /-- The prover's input witness. -/
  witIn : WitIn
  /-- The cheating prover. -/
  prover : Prover oSpec StmtIn WitIn StmtOut WitOut pSpec
  /-- The input statement. -/
  stmtIn : StmtIn
  /-- The input statement lies outside the input language. -/
  stmtIn_not_mem : stmtIn ∉ langIn

/-- The execution of ArkLib's reduction in the soundness experiment, as the
    `OptionT ProbComp` computation appearing in `Verifier.soundness`: the oracle
    implementation `impl` extended with uniform challenges, run from an initial
    state drawn from `init`. -/
noncomputable def verifierSoundnessRun {langIn : Set StmtIn}
    {verifier : Verifier oSpec StmtIn StmtOut pSpec} (A : VerifierSoundnessAdv langIn verifier) :
    OptionT ProbComp ((FullTranscript pSpec × StmtOut × A.WitOut) × StmtOut) :=
  let pImpl : QueryImpl (oSpec + [pSpec.Challenge]ₒ) (StateT σ ProbComp) :=
    impl.addLift challengeQueryImpl
  letI reduction := Reduction.mk A.prover verifier
  OptionT.mk do (simulateQ pImpl (reduction.run A.stmtIn A.witIn).run).run' (← init)

/-- ArkLib's soundness experiment as a `ProbComp Bool` game: `true` exactly when
    the execution does not fail and the verifier's output statement lies in
    `langOut`. -/
noncomputable def verifierSoundnessGame {langIn : Set StmtIn} (langOut : Set StmtOut)
    {verifier : Verifier oSpec StmtIn StmtOut pSpec} (A : VerifierSoundnessAdv langIn verifier) :
    ProbComp Bool :=
  (fun o => o.any (fun r => decide (r.2 ∈ langOut))) <$> (verifierSoundnessRun init impl A).run

/-- ArkLib's `Verifier.soundness` with error `ε : ℝ≥0` is equivalent to
    `ArgumentSoundness (ε : ℝ≥0∞)` of the lifted `verifierSoundnessGame`, with
    adversaries `VerifierSoundnessAdv langIn verifier`. -/
theorem verifierSoundness_iff_argumentSoundness
    (langIn : Set StmtIn) (langOut : Set StmtOut)
    (verifier : Verifier oSpec StmtIn StmtOut pSpec) (ε : ℝ≥0) :
    Verifier.soundness init impl langIn langOut verifier ε ↔
      ArgumentSoundness (ε : ℝ≥0∞)
        (fun A : VerifierSoundnessAdv langIn verifier =>
          probCompLift (verifierSoundnessGame init impl langOut A)) := by
  rw [argumentSoundness_probCompLift_iff]
  constructor
  · intro h A
    unfold verifierSoundnessGame
    rw [← probEvent_optionT_eq_probOutput_any]
    exact h A.WitIn A.WitOut A.witIn A.prover A.stmtIn A.stmtIn_not_mem
  · intro h WitIn WitOut witIn prover stmtIn hstmt
    have hA := h ⟨WitIn, WitOut, witIn, prover, stmtIn, hstmt⟩
    unfold verifierSoundnessGame at hA
    rw [← probEvent_optionT_eq_probOutput_any] at hA
    exact hA

/-- A proof of ArkLib's `Verifier.soundness` with error `ε : ℝ≥0` gives
    `ArgumentSoundness (ε : ℝ≥0∞)` of the lifted `verifierSoundnessGame`. -/
theorem argumentSoundness_of_verifierSoundness
    {langIn : Set StmtIn} {langOut : Set StmtOut}
    {verifier : Verifier oSpec StmtIn StmtOut pSpec} {ε : ℝ≥0}
    (h : Verifier.soundness init impl langIn langOut verifier ε) :
    ArgumentSoundness (ε : ℝ≥0∞)
      (fun A : VerifierSoundnessAdv langIn verifier =>
        probCompLift (verifierSoundnessGame init impl langOut A)) :=
  (verifierSoundness_iff_argumentSoundness init impl langIn langOut verifier ε).1 h

/-- Monotonicity of ArkLib's `Verifier.soundness` in the error bound: a soundness
    proof with error `ε₁` is also a soundness proof for any `ε₂ ≥ ε₁`. -/
theorem verifierSoundness_mono
    {langIn : Set StmtIn} {langOut : Set StmtOut}
    {verifier : Verifier oSpec StmtIn StmtOut pSpec} {ε₁ ε₂ : NNReal} (hle : ε₁ ≤ ε₂)
    (h : Verifier.soundness init impl langIn langOut verifier ε₁) :
    Verifier.soundness init impl langIn langOut verifier ε₂ := by
  intro WitIn WitOut witIn prover stmtIn hstmt
  exact le_trans (h WitIn WitOut witIn prover stmtIn hstmt) (by exact_mod_cast hle)

end ArkLibSoundness

end CatCrypt.Crypto.Bridges.ArkLib
