# Single-module probe for `mem_kerPD`

`ProbeTarget.lean` links to the original
`Development.AbelianVarietyTheory.Proofs.TwistedOperators.MemKerPD` source. Its
imports come from the parent `tree` package. The probe builds only this module
and the imports needed by it, rather than the parent's default targets.

From this directory:

```sh
bash prepare.sh
MATHLIB_NO_CACHE_ON_UPDATE=1 lake build +ProbeTarget:olean
MATHLIB_NO_CACHE_ON_UPDATE=1 probe-lean extract . \
  --library ProbeTarget --module ProbeTarget \
  --skip-verify --skip-enrich \
  --output /tmp/mem-ker-pd-probe.json
```

Inspect the theorem's extracted dependencies with:

```sh
jq '.data["probe:GlobalTheory.SquareAgree.mem_kerPD"] |
  {type_dependencies: .["type-dependencies"],
   term_dependencies: .["term-dependencies"],
   type_dependencies_external: .["type-dependencies-external"],
   term_dependencies_external: .["term-dependencies-external"]}' \
  /tmp/mem-ker-pd-probe.json
```

The extract contains declarations from `ProbeTarget`, including the local
`kerPD` definition. Imported declarations are listed as external dependencies
by name. The `--skip-*` options skip verification-status work; they do not skip
building imports. `probe-lean` must match Lean v4.33.1.

To count source lines of project theorems directly referenced by `mem_kerPD`,
run this from the repository root:

```sh
python3 harness/mem_ker_pd_probe/count_project_theorem_lines.py \
  /tmp/mem-ker-pd-probe.json
```

The script combines names from the extract with theorem declarations in the
project's transitive import files. It reports direct theorem dependencies only;
the extract does not include the imported theorems' own dependency graphs.

For the full transitive dependency closure, use the compiled Lean environment:

```sh
python3 harness/mem_ker_pd_probe/count_transitive_project_theorem_lines.py \
  /tmp/mem-ker-pd-probe.json
```

This script reads the target name from the probe JSON, follows constants in its
compiled proof and in every reachable project declaration, and maps them back
to source ranges. It reports both explicit `theorem`/`lemma` lines and all
reachable project declaration lines, deduplicated by file and line. Mathlib
constants are excluded. Use `--details` to list the explicit theorem sources.

The current detailed result is saved in `transitive-theorem-dependencies.json`.
To refresh it from the repository root after rebuilding and extracting the
probe, run:

```sh
python3 harness/mem_ker_pd_probe/count_transitive_project_theorem_lines.py \
  /tmp/mem-ker-pd-probe.json --details \
  > harness/mem_ker_pd_probe/transitive-theorem-dependencies.json
```
