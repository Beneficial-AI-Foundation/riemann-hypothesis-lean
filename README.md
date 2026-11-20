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
