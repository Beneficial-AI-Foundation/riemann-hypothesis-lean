# Contributing to riemann-hypothesis-lean

Thanks for your interest in contributing. This repository holds a vendored copy
of a third-party Lean 4 proof of the Riemann Hypothesis (from
<https://alpo.ge>), together with a small Python **harness** for "proof idea
distillation" experiments over those sources. This guide covers how to work on
the harness and how to send a change. It follows the shared contribution standard
used across the [Beneficial AI Foundation](https://github.com/Beneficial-AI-Foundation)
projects.

## What is and isn't built here

- `src/` is the vendored Lean archive — about 1.3 GB and ~175,000 files,
  extracted unmodified, and it needs Mathlib. It is **not compiled for this
  listing**, and CI does not build it. Reproduce the download from the archive
  as described in the [README](README.md).
- `scripts/`, `tests/` and `harness/` are the Python experiment harness. This is
  what you build, test and change here.

## Prerequisites

- **Python 3** (3.12 or newer recommended). The harness and its tests use only
  the Python standard library — there is nothing to `pip install`.
- Optional, only to render or re-run experiments: `pdflatex` (to turn a LaTeX
  sketch into a PDF) and whatever AI CLI a given experiment's workflow doc names.

## Building and testing

```sh
python -m compileall -q scripts tests harness   # syntax-check the harness
python -m unittest discover -s tests -t .        # run the unit tests
```

The harness scripts are run directly, from the repository root, e.g.:

```sh
python3 scripts/split_theorems.py --seed 0 --output theorem-split.json
python3 -B scripts/make_isolated_target.py
```

CI (`.github/workflows/ci.yml`) runs the two commands above (compile check +
`unittest`) on Linux for every push and pull request. It does not build the Lean
sources (see above).

## Submitting a change

1. **Branch** off `main` (or fork the repository).
2. Keep each pull request focused. If you change a harness script, add or update a
   test in `tests/` for the behaviour you change.
3. Make sure `python -m unittest discover -s tests -t .` passes and CI is green.
4. Write a clear PR description: what changed, why, and how you verified it.
5. By contributing, you certify the
   [Developer Certificate of Origin](https://developercertificate.org/) — add a
   `Signed-off-by: Your Name <you@example.com>` line to your commits
   (`git commit -s`). Note that the vendored Lean sources under `src/` keep the
   licence of their upstream author; your contribution covers the harness, not
   that archive.

## Reporting issues

Open a GitHub issue with a clear title, what you expected, what happened, and the
command and inputs that reproduce it. Security-sensitive reports can be sent
privately to **support@beneficialaifoundation.org** instead of a public issue.

## Code of conduct

Be respectful and constructive. Harassment or abuse is not tolerated. Maintainers
may remove comments, commits or contributions that don't meet this standard.
