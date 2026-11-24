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

The current experiment summarizes the proof of
`GlobalTheory.Hk.normPrimes_short_interval_lower` in informal Markdown of at
most 500 words, then tests whether a fresh agent can reconstruct the Lean proof
from that summary. See [PROOF_IDEA_DISTILLATION_PLAN.md](PROOF_IDEA_DISTILLATION_PLAN.md).

The English summarizer prompt is in
[`harness/prompts/norm_primes_summarizer.md`](harness/prompts/norm_primes_summarizer.md).
To render its task without calling a model, run
`python3 -B scripts/run_summary_agent.py --dry-run`. To run the read-only
summarizer, run `python3 -B scripts/run_summary_agent.py`; it writes
`harness/NormPrimesProofIdea.md` and a JSON provenance record. This stage
creates the summary only; it does not test a separate proof agent.
The proof-agent implementation and matched baseline are the next planned stage;
their isolation and validation requirements are recorded in the plan.

## Earlier definition discovery experiment

The earlier workflow reads relevant proofs, proposes a Lean-checked definition,
analyzes theorems that may benefit from it, and then gives a separate proof
agent the definition and an isolated theorem statement. See
[THEOREM_DISCOVERY_HARNESS_PLAN.md](THEOREM_DISCOVERY_HARNESS_PLAN.md).

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
