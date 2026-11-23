# CatCrypt ArkLib

Interoperability between [CatCrypt Core](https://github.com/spitters/CatCrypt-core)
and [ArkLib](https://github.com/Verified-zkEVM/ArkLib), the Lean 4 formalization of
interactive oracle reductions (IORs) and SNARKs. The package states argument soundness
and knowledge soundness as predicates over CatCrypt `SPComp` games, proves composition
lemmas for them, and transfers ArkLib's verifier soundness and `ProbComp` probability
bounds into these predicates through
[catcrypt-vcvio](https://github.com/spitters/catcrypt-vcvio).

The library is the single module `CatCryptArkLib`, with declarations in the namespace
`CatCrypt.Crypto.Bridges.ArkLib`. The package declares no axioms and uses no
`native_decide`.

## Soundness predicates

A family of games indexed by adversaries has argument soundness with error `ε` when every
adversary wins with probability at most `ε`
([`ArgumentSoundness`](CatCryptArkLib.lean#L82)). Knowledge soundness asks for one
extractor that works for every adversary
([`KnowledgeSoundness`](CatCryptArkLib.lean#L89)), the quantifier order of ArkLib's
definition; it implies the weaker form with an extractor per adversary
([`KnowledgeSoundness.toWeak`](CatCryptArkLib.lean#L100)). Both predicates are monotone in
the error ([`argumentSoundness_mono`](CatCryptArkLib.lean#L108),
[`knowledgeSoundness_mono`](CatCryptArkLib.lean#L113)). Adversary types range over all
universes, because ArkLib's provers live in `Type 1`.

## Composition

If every adversary's success in one game is bounded by the success of a reduced adversary
in a second game, a soundness bound for the second game carries over to the first
([`argumentSoundness_reduce`](CatCryptArkLib.lean#L128)). If the success in a game is
bounded by the sum of the successes of two reduced adversaries, and the first game has
error `ε₁` for every adversary, then each adversary `A` wins with probability at most `ε₁`
plus the success of the explicit adversary `reduce₂ A` in the second game
([`prTrue_le_add_reduce`](CatCryptArkLib.lean#L142)). This is the concrete form of
BCS-style composition, with the information-theoretic error of an IOR and the advantage of
a reduction against a computational binding game. When both games are bounded for every
adversary the errors add ([`argumentSoundness_add_reduce`](CatCryptArkLib.lean#L157)); a
game bounded by `q` times a reduced game has error `q * ε`
([`argumentSoundness_amplify`](CatCryptArkLib.lean#L171)). The reduction inequalities are
hypotheses of these theorems.

## Transfer from VCV-io and ArkLib

For `ProbComp Bool` games lifted into CatCrypt, argument soundness with error `ε` holds if
and only if the output measure `𝒟[game A] {true}` is at most `ε` for every adversary
([`argumentSoundness_probCompLift_iff`](CatCryptArkLib.lean#L190)); per-adversary bounds
`Pr{let b ← exec A}[pred b] ≤ ε` on `ProbComp` executions give argument soundness of the
lifted `Bool`-valued executions
([`argumentSoundness_of_probEvent`](CatCryptArkLib.lean#L207)).

ArkLib's `Verifier.soundness init impl langIn langOut verifier ε` holds if and only if
argument soundness with error `ε` holds for an explicit game
([`verifierSoundness_iff_argumentSoundness`](CatCryptArkLib.lean#L289)). In that game
([`verifierSoundnessGame`](CatCryptArkLib.lean#L281)) the adversary
([`VerifierSoundnessAdv`](CatCryptArkLib.lean#L251)) is a cheating prover with a witness
and an input statement outside `langIn`; it runs ArkLib's interaction and wins when the
verifier outputs a statement in `langOut`, and a failed run counts as a loss. ArkLib's
event over an `OptionT ProbComp` execution equals the output probability of `true` in a
`ProbComp Bool` computation in which failure maps to `false`
([`probEvent_optionT_eq_probOutput_any`](CatCryptArkLib.lean#L223)).

## Further reading

- [API reference](https://spitters.github.io/catcrypt-arklib/) (doc-gen4)
- [BUILDING.md](BUILDING.md): building the library and the documentation
- [CHANGELOG.md](CHANGELOG.md), [CONTRIBUTING.md](CONTRIBUTING.md),
  [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

## References

- E. Ben-Sasson, A. Chiesa, N. Spooner. *Interactive Oracle Proofs.* TCC 2016.
- [ArkLib](https://github.com/Verified-zkEVM/ArkLib),
  `ArkLib/OracleReduction/Security/Basic.lean`: the soundness definitions this package
  refers to.

## Citing

See `CITATION.cff`. The accompanying paper:

> B. Spitters. *CatCrypt: From Rust to Cryptographic Security in Lean.*
> Cryptology ePrint Archive, Paper 2026/604.
> <https://eprint.iacr.org/2026/604.pdf>

## License

MIT. See `LICENSE`. Dependencies carry their own licenses; see
`THIRD_PARTY_NOTICES.md`.
