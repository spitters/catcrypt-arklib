import Lake
open Lake DSL

package catcryptArklib where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩
  ]
  -- `-E <kind>` reports Lean messages of that kind as errors. `hasSorry` is the
  -- kind Lean attaches to a declaration whose proof term reaches `sorryAx`, so
  -- building this package refuses such a declaration and no separate step has to
  -- read the build's output. The word in a comment, a docstring or a string
  -- literal carries no such message; a declaration reaching `sorryAx` through a
  -- tactic carries one even though the word appears nowhere in its source.
  moreLeanArgs := #["-E", "hasSorry"]

@[default_target]
lean_lib CatCryptArkLib where
  -- Module root `CatCryptArkLib.*`; declared namespace stays `CatCrypt.Crypto.Bridges.ArkLib`.
  -- The ArkLib (interactive-oracle-reduction soundness) interoperability bridge, split
  -- out of CatCryptCore so core carries no ArkLib dependency. It transports ArkLib bounds
  -- through the VCVio bridge, hence the `catcryptVcvio` dep. Downstream
  -- `CatCrypt.Crypto.Bridges.ArkLibTypes` shims re-export this package.
  -- The library is the single module `CatCryptArkLib`; git tracks no empty
  -- directory, so a submodule glob fails in a clean clone.
  globs := #[.one `CatCryptArkLib]

require catcryptCore from git
  "https://github.com/spitters/CatCrypt-core.git" @ "lean-upgrade-4.35"

require catcryptVcvio from git
  "https://github.com/spitters/catcrypt-vcvio.git" @ "lean-upgrade-4.35"

require ArkLib from git
  "https://github.com/Verified-zkEVM/ArkLib" @ "bc367f8d53f603a48c5502e1ad7d39b7b3be725c"

-- mathlib last so its pinned transitive deps win, matching the shared olean cache.
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.35.0"
