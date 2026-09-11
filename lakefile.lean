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
  globs := #[.andSubmodules `CatCryptArkLib]

require catcryptCore from "../CatCrypt-core"

require catcryptVcvio from "../catcrypt-vcvio"

require ArkLib from git
  "https://github.com/Verified-zkEVM/ArkLib" @ "dca90385fb40dd5eb8da9145da6348ed17f5cd8b"

-- mathlib last so its pinned transitive deps win, matching the shared olean cache.
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.33.1"
