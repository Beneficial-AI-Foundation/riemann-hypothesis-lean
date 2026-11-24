## Direction1: Verify the Rust MCP SDK

The [Rust MCP SDK](https://github.com/modelcontextprotocol/rust-sdk) is a separate verification direction from the quasi-Riemann conjecture concept-discovery project. Start with the Streamable HTTP server's Host/Origin checks: examine how the SDK decides whether a request's Host and Origin are allowed, then try to prove a corresponding property in Lean using Aeneas-generated code.

This is an exploratory first target. Some Host/Origin functions have already been translated to Lean, but their parsers and library calls still need work, and no property has been proved yet. Continue from the [extraction notes](../../rust-sdk/verification/host_origin/README.md), recording what can be translated, what must be modeled, and how much effort a meaningful proof takes. Use that experience to judge how difficult broader Rust SDK verification would be and what to try next.

# Direction2: Distill the Proof Idea of a Subtheorem

## Goal

Start with the existing subtheorem `GlobalTheory.Hk.normPrimes_short_interval_lower`. Express its core argument in informal Markdown of at most 500 words. Test whether a fresh AI can reconstruct its Lean proof from the statement, permitted prerequisites, and that Markdown. Refine the Markdown to preserve proof success with fewer words or reduce reported thinking-token use without adding words.

This first experiment stays with that subtheorem and its necessary prerequisites. It does not audit the full proof chain ending in `RiemannHypothesis`.

## Method

1. Isolate both `sum_lam_zero_le_card_normPrimes` and `normPrimes_short_interval_lower` from their original proofs and equivalent ready-made lemmas.
2. Keep the original prerequisites fixed and initially omit the earlier `PrimeDetectingWeight` candidate library.
3. Produce an informal proof summary of at most 500 words, with the key intermediate claims and transformations.
4. Give that summary to a proof AI in a fresh context and check its output with Lean. Record failures as well as successes.
5. Compare against a no-summary baseline under the same model, tools, budget, dependencies, and prompt format. Revise and retest summaries in new contexts.

The proving-agent implementation will adapt only the needed process, isolation, transcript, and Lean-checking pieces from `/home/zhang-liao/auto_verify_dalek`. It must give each attempt a fresh workspace that cannot read the original target proof, earlier completed probe, or Git history. A separate harness check will judge the final Lean file; the agent's own success report is not sufficient.

Report success rate, Markdown length, input and output tokens, actual thinking tokens when available, wall time, and proof length separately. Repeated runs are needed because token use varies. Later, freeze a summary before testing whether its ideas help with a related theorem whose proof was not used to write it.

The detailed workflow is in [PROOF_IDEA_DISTILLATION_PLAN.md](PROOF_IDEA_DISTILLATION_PLAN.md). The earlier definition discovery experiment remains documented in [THEOREM_DISCOVERY_HARNESS_PLAN.md](THEOREM_DISCOVERY_HARNESS_PLAN.md).
