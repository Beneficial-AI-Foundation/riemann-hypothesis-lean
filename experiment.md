# Proof Sketch Reconstruction Experiment

## Scope

The first pilot studies `GlobalTheory.Hk.RayForm.comb_injective`, a theorem in
[`RayClassIdealCountEqNcardShiftedBinaryForm.lean`](src/Development/AbelianVarietyTheory/Proofs/GlobalInterpolation/RayClassIdealCountEqNcardShiftedBinaryForm.lean).
Its Lean proof occupies about 26 lines. It does not directly invoke another
named theorem from this project; most of its length handles complex arithmetic,
integer casts, and the conversion from zero coordinate differences to equality
of integer pairs. The roughly 5,900 lines of transitive project imports are a
rough dependency-size measure, not material summarized or reviewed in this run.

## Sketch and review

The frozen [LaTeX sketch](harness/RayFormCombInjectiveSketch.tex) contains 103
English words and two explicit gaps. Gap 1 isolates the coefficient of the
second complex number by taking the imaginary part after multiplication by
the conjugate of the first. Gap 2 rewrites equality of two integer combinations
as a zero combination of their coordinate differences. The sketch targets only
`comb_injective`, not every theorem in its imported modules.

On 2026-11-25, a fresh account-authenticated `codex exec` thread reviewed the
sketch using the [account workflow](harness/ACCOUNT_INFORMAL_REVIEW_WORKFLOW.md).
The reviewer received the target statement, the frozen sketch, and the listed
allowed facts. Its [original answer](harness/reviews/ray_form_comb_injective_20261125T041253Z/answer.txt)
gave a substantive informal proof of each gap and then reconstructed the full
injectivity argument. Both gaps and the overall connection passed this
**informal reconstructibility** check. The answer also used the elementary
injectivity of the integer embeddings into the reals and complexes; future
sketches could list this background fact explicitly.

The run completed with exit status 0. Its JSONL log contains one assistant
message and no tool items. Codex reported 18,105 input tokens, including 13,952
cached tokens, 787 output tokens, and 19 reasoning output tokens; the model
identifier and elapsed time were not recorded. The frozen sketch SHA-256 is
`0a042202d371ff57b982f8761e83bb99b76a6e9360847850d757eda320858a61`.
The full [assessment and run artifacts](harness/reviews/ray_form_comb_injective_20261125T041253Z/assessment.md)
are retained for inspection.

## Interpretation

This result shows that another AI could reconstruct the selected theorem's
informal proof from the sketch. It does not certify a new Lean proof or validate
the project's imported dependency chain. The reviewer ran in an empty working
directory and made no observed tool calls, but the `read-only` sandbox did not
block reads of other filesystem paths. The run therefore provides a behavioral
isolation check, not a filesystem-level guarantee that the original proof was
inaccessible.
