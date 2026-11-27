# Informal review assessment

- Target: `GlobalTheory.FiniteIndexSemisimple.isSSRep_of_finiteIndex`
- Sketch SHA-256: `c08ac68b703e4b5cb99f37d9418b0db2acdc6a909a5d30530a4443877596e842`
- Input SHA-256: `62c3df140ec0af43269133a175776de5f18542be000717d896fd91230da98ace`
- Reviewer: fresh account-authenticated `codex exec` thread in an empty `/tmp` directory
- Run: exit status 0, completed turn, one assistant message and no tool items in JSONL

## Gap decisions

- Gap 1: **informally proved** by decomposing each vector along the two invariant summands and applying the projection.
- Gap 2: **informally proved** by checking right multiplication by `N` leaves `T` unchanged, then permuting left cosets under left multiplication.
- Gap 3: **informally proved** by decomposing `v` as `Pv + (v - Pv)` and using equivariance to show kernel invariance.
- Full argument: **closes informally**. The answer checks the conjugated projections map into and fix `W`, the finite coset count is nonzero in characteristic zero, and the normalized sum meets Gap 3's hypotheses.

This supports informal reconstructibility of the frozen sketch. It is not a new Lean proof or a filesystem-level isolation guarantee: the reviewer made no observed tool calls, but its `read-only` sandbox did not prohibit filesystem reads.

The first launch attempt from the workspace sandbox failed before any review because Codex could not initialize on a read-only filesystem; its empty output and error are retained in `FiniteIndexSemisimpleSketch_20261127T095039Z/`.
