# alpo-lean

Lean 4 sources unpacked from the 14-part archive referenced in https://alpo.ge/remark.pdf
(`https://alpo.ge/lean.tar.gz.part01` … `part14`), joined and extracted unmodified.

- Toolchain: see `lean-toolchain`
- Mathlib pin: see `lakefile.toml` / `lake-manifest.json`
- Entry points: `src/Statements.lean`, `src/Main.lean`

Build (unverified): `lake exe cache get && lake build`
