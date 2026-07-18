import Lake
open Lake DSL

package catcryptArklib where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩
  ]

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
  "https://github.com/Verified-zkEVM/ArkLib" @ "v4.30.0"

-- mathlib last so its pinned transitive deps win, matching the shared olean cache.
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.30.0"
