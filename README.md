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

## Proof idea distillation

The current experiment asks one AI to read an existing Lean proof and write an
informal LaTeX sketch of at most 500 words with explicit lemma-sized gaps. A second
AI, without the original proof, attempts an informal proof of each gap and
checks that the pieces yield the target theorem. The first pilot target is
`GlobalTheory.Hk.RayForm.comb_injective`. Its draft is
[`harness/RayFormCombInjectiveSketch.tex`](harness/RayFormCombInjectiveSketch.tex)
(render locally with `pdflatex` to obtain a PDF); the first
[informal review](harness/reviews/ray_form_comb_injective_20261125T041253Z/assessment.md)
proved both gaps and closed the argument without tool calls. See
[PROOF_IDEA_DISTILLATION_PLAN.md](PROOF_IDEA_DISTILLATION_PLAN.md).

Future sketches use [the LaTeX summarizer prompt](harness/prompts/latex_sketch_summarizer.md).

The previous `normPrimes_short_interval_lower` summary and its generator were
removed from the working tree after the target changed. They remain available
in Git history. The next stage is selecting another target for the same process.

## Earlier definition discovery experiment

The earlier workflow reads relevant proofs, proposes a Lean-checked definition,
analyzes theorems that may benefit from it, and then gives a separate proof
agent the definition and an isolated theorem statement. Its plan remains in
Git history.

The earlier 80/20 split tooling remains available for optional experiments:

Create a reproducible 80/20 split of the `GlobalInterpolation` theorems:

```bash
python3 scripts/split_theorems.py --seed 0 --output theorem-split.json
```

The JSON manifest lists source file, line, declaration name, kind, and file hash
for each theorem. It also records the Git revision and seed. Files ending in
`Statement.lean` are omitted by default because they often wrap results proved
elsewhere. The main `normPrimes_short_interval_lower` theorem is forced into the
test set. Use `--holdout FILE:NAME` to choose other held-out theorems.

This split does not restrict definition discovery and is not required for the
main workflow. A theorem whose proof was read during discovery is a
retrospective case. A token-savings claim needs matched proof attempts with
and without the definition, each with a fresh context.

Generate and Lean-check the first isolated test task:

```bash
python3 -B scripts/make_isolated_target.py
```

This writes `harness/NormPrimesTask.lean` with the target proof left blank and
`harness/NormPrimesTask.check.json` with the reproducibility hashes and checks.
The task file is meant to fail compilation until a proof is supplied.
