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

require catcryptCore from git
  "https://github.com/spitters/CatCrypt-core.git" @ "2adfac7c5162ab0e89c9b494d53ee4b2fdc75613"

require catcryptVcvio from git
  "https://github.com/spitters/catcrypt-vcvio.git" @ "75e2e38c55b6d9340465407a2d45f3c17c01ad9d"

require ArkLib from git
  "https://github.com/Verified-zkEVM/ArkLib" @ "dca90385fb40dd5eb8da9145da6348ed17f5cd8b"

-- mathlib last so its pinned transitive deps win, matching the shared olean cache.
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.33.1"
