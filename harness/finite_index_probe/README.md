# Single-module probe project

This Lake project checks the source of
`Development.AbelianVarietyTheory.Proofs.GlobalInterpolation.IsSSRepOfFiniteIndex`
through the `ProbeTarget.lean` symlink. It depends on the parent `tree` package
for the imported modules, but its only default target is `ProbeTarget`.

From this directory:

```sh
bash prepare.sh
MATHLIB_NO_CACHE_ON_UPDATE=1 lake build +ProbeTarget:olean
MATHLIB_NO_CACHE_ON_UPDATE=1 probe-lean extract . \
  --library ProbeTarget --module ProbeTarget \
  --skip-verify --skip-enrich \
  --output /tmp/finite-index-probe.json
```

`probe-lean` must be built for Lean v4.33.1, matching `lean-toolchain`.
The extract describes declarations in `ProbeTarget`; imported declarations
from the parent package appear by name as dependencies but are not themselves
extracted as project atoms. The import closure must still be built. The link
ensures the target proof is read from the original source, with no copied proof
to go stale.
The two `--skip-*` flags omit verification-status work, since this setup is for
dependency inspection. They do not remove the need to load the target's imports.

The Lake manifest pins local paths to the parent project's dependency cache.
`prepare.sh` makes that existing Mathlib cache visible to probe-lean's cache
check. The generated `.lake` directory is disposable; the parent package's
source and build outputs are reused rather than rebuilt as library targets.

To inspect the target's direct dependencies after extraction:

```sh
jq '.data["probe:GlobalTheory.FiniteIndexSemisimple.isSSRep_of_finiteIndex"] |
  {type_dependencies: .["type-dependencies"],
   term_dependencies: .["term-dependencies"]}' /tmp/finite-index-probe.json
```
