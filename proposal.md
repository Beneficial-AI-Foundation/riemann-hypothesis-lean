## Direction1: Verify the Rust MCP SDK

The [Rust MCP SDK](https://github.com/modelcontextprotocol/rust-sdk) is a separate verification direction from the quasi-Riemann conjecture concept-discovery project. Start with the Streamable HTTP server's Host/Origin checks: examine how the SDK decides whether a request's Host and Origin are allowed, then try to prove a corresponding property in Lean using Aeneas-generated code.

This is an exploratory first target. Some Host/Origin functions have already been translated to Lean, but their parsers and library calls still need work, and no property has been proved yet. Continue from the [extraction notes](../../rust-sdk/verification/host_origin/README.md), recording what can be translated, what must be modeled, and how much effort a meaningful proof takes. Use that experience to judge how difficult broader Rust SDK verification would be and what to try next.

# Direction2: Discover New Mathematical Structures from the Quasi-Riemann Conjecture

## Goal

Use the quasi-Riemann conjecture as the mathematical testbed for discovering new structures. The primary goal is to extract mathematically meaningful definitions, relationships, and reusable lemmas from work on the conjecture, then formalize and investigate them in Lean. A useful outcome may be a new invariant, decomposition, correspondence, or class of objects that clarifies the problem, even if it does not immediately prove the conjecture.

Identify the precise statement and mathematical setting of the quasi-Riemann conjecture before selecting source material or formalization targets. Record the source and version of that statement, the exact repository commit if using an existing formalization, Lean and Mathlib versions, and the selected modules. Distinguish established results from proposed structures and conjectural claims.

## Three Roles

The roles separate structure discovery from independent testing. Lower proof cost can support a structure's usefulness, but it is not the main criterion for mathematical value.

1. **Discovery Agent:** Study the conjecture and permitted source material, propose new structures and their motivating examples, formalize definitions, and prove supporting lemmas where possible.
2. **Experimental Agent:** Investigate held-out problems with the frozen structure library available; seek new consequences, connections, or proofs.
3. **Baseline Agent:** Investigate the same problems with the same original prerequisites but without the new library.

For controlled comparisons, the experimental and baseline agents use the same model, tools, prompt format, and per-target budget. Each starts with a clean context; neither sees the other's attempts or an existing proof of its target.

## Procedure

1. Fix the conjecture's precise formulation. Inventory relevant definitions, examples, partial results, theorem statements, proofs, imports, and dependencies in the chosen sources. Start with a coherent, nontrivial part of the problem.
2. Search for recurring patterns and gaps in the current language. Propose candidate structures with explicit definitions, examples and nonexamples, and a clear account of what each structure captures.
3. Formalize the candidates in Lean. Prove consistency checks and supporting lemmas where possible; record unproved claims separately. Review whether each candidate is genuinely informative rather than a restatement of an existing definition.
4. Freeze a candidate library and test it on new questions or held-out results related to the conjecture. For targets with known proofs, hide those proofs and forbid direct use of the target theorem or an equivalent result.
5. Compare investigations with and without the library where a controlled comparison is meaningful. Check submitted proofs with Lean, document new consequences and failed attempts, and revise the structures using fresh questions rather than the same held-out targets.

## Dependency Graph Split and Leakage Control

When using an existing Lean formalization with checked theorems, use `probe-lean` or Lean dependency information to identify which declarations each theorem uses. Direct edges from prerequisites to their users, choose a topological cut, and place earlier theorems in training and later eligible theorems in testing. Training results must not depend, directly or transitively, on test targets.

Dependency separation alone is insufficient. Check for equivalent statements, duplicate lemmas, and shared proof files that expose target proofs. If hiding one theorem requires editing a module, build an isolated test module that preserves its statement and permitted imports but omits its proof. Give both testing agents identical original prerequisites; the experimental agent alone receives the frozen structure library. Run targets separately so a failure on one does not block the others.

Keep each experiment on a fixed source revision. For an independent replication, choose a new valid split and design structures afresh without carrying over feedback from its test set.

## Evaluation

Evaluate the discovered mathematical structures first: whether their definitions are precise and nontrivial, whether they have illuminating examples or counterexamples, whether they reveal relationships that were previously hard to state, and whether they yield reusable results or new lines of attack on the quasi-Riemann conjecture. Clearly separate proved results from plausible but open consequences, and document independent mathematical review of claims of novelty.

As secondary evidence, compare checked proofs per target at the same budget. Among successful proofs, compare actual thinking-token usage if the API exposes it. Report wall time and proof length separately; neither is a substitute for thinking tokens. Record discovery effort separately from test-time savings. Where possible, test definitions alone and then definitions with lemmas on the same held-out targets. Lean compilation establishes formal correctness of stated claims; mathematical value requires interpretation, reuse, or a substantive new consequence.

## First Step

Locate and fix an authoritative formulation of the quasi-Riemann conjecture, identify a small coherent body of source results, and produce one Lean-checked candidate structure with examples and a useful consequence. Then test whether it illuminates a fresh question related to the conjecture before automating the workflow.
