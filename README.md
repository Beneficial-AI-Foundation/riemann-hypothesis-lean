# riemann-hypothesis-lean

Lean 4 sources of the proof of the Riemann Hypothesis found on Levent Alpöge's
website (https://alpo.ge), as linked from https://alpo.ge/remark.pdf.

The 14-part archive (`https://alpo.ge/lean.tar.gz.part01` … `part14`) was
downloaded on 2026-11-20, joined, and extracted unmodified.

To download the original archive yourself:

```bash
for i in $(seq -w 1 14); do
  curl -fLO "https://alpo.ge/lean.tar.gz.part$i"
done
cat lean.tar.gz.part* > lean.tar.gz
tar -xzf lean.tar.gz   # creates lean/
```

SHA-256 of the joined archive (check with `sha256sum lean.tar.gz`):
`9631b4f020199e580ba86178cb56c6e9b09f690c2369a80dc4334aa93f49c7fc`

If alpo.ge is unavailable, the same 14 parts are attached to this repo's
[release](https://github.com/DimitriosMitsios/riemann-hypothesis-lean/releases/tag/v2026-11-20).

## Theorem-level discovery split

Create a reproducible 80/20 split of the `GlobalInterpolation` theorems:

```bash
python3 scripts/split_theorems.py --seed 0 --output theorem-split.json
```

The JSON manifest lists source file, line, declaration name, kind, and file hash
for each theorem. It also records the Git revision and seed. Files ending in
`Statement.lean` are omitted by default because they often wrap results proved
elsewhere. The main `normPrimes_short_interval_lower` theorem is forced into the
test set. Use `--holdout FILE:NAME` to choose other held-out theorems.

This is a location split only. Before giving a test theorem to an AI, construct
an isolated Lean module that hides its existing proof and checks that the
permitted training material still compiles.
