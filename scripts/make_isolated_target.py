#!/usr/bin/env python3
"""Generate and check the first held-out Lean theorem task."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

if __package__:
    from .split_theorems import DEFAULT_HOLDOUT, ROOT
else:
    from split_theorems import DEFAULT_HOLDOUT, ROOT


HOLE = "  -- Insert a proof here.\n"
TARGET = "GlobalTheory.Hk.normPrimes_short_interval_lower"
FORBIDDEN = "Development.AbelianVarietyTheory.Proofs.GlobalInterpolation.NormPrimesImagQuadShortIntervalLowerBound"


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def extract(manifest: dict) -> tuple[str, str, str]:
    if manifest.get("schema") != "theorem-split/v1":
        raise ValueError("unsupported split manifest")
    matches = [x for x in manifest["test"] if
               (x["file"], x["name"]) == (DEFAULT_HOLDOUT[0].as_posix(), DEFAULT_HOLDOUT[1])]
    if len(matches) != 1:
        raise ValueError("target must occur exactly once in the test split")
    entry = matches[0]
    path = ROOT / entry["file"]
    source = path.read_text(encoding="utf-8")
    if sha256(source) != entry["source_sha256"]:
        raise ValueError("target source hash differs from split manifest")
    lines = source.splitlines(keepends=True)
    line = entry["line"] - 1
    if line < 0 or line >= len(lines):
        raise ValueError("target line is out of range")
    prefix = "".join(lines[:line])
    rest = "".join(lines[line:])
    pattern = rf"\Atheorem {re.escape(DEFAULT_HOLDOUT[1])}\b[^\n]* := by\n"
    match = re.match(pattern, rest)
    if match is None:
        raise ValueError("expected a single-line target statement ending in := by")
    if not rest.endswith("\nend GlobalTheory.Hk\n"):
        raise ValueError("target is not the final declaration in its namespace")
    statement = match.group()
    proof = rest[match.end(): -len("\nend GlobalTheory.Hk\n")]
    if not proof.strip() or not proof.startswith("  "):
        raise ValueError("could not locate the original proof")
    imports = re.findall(r"^import ([^\s]+)$", prefix, re.MULTILINE)
    if not imports or any(x == FORBIDDEN or x.startswith(FORBIDDEN + ".") for x in imports):
        raise ValueError("target module is imported by the task")
    task = prefix + statement + HOLE + "\nend GlobalTheory.Hk\n"
    return task, proof, prefix


def lean_check(source: str) -> dict:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".lean", encoding="utf-8") as file:
        file.write(source)
        file.flush()
        result = subprocess.run(["lake", "env", "lean", file.name], cwd=ROOT,
                                text=True, capture_output=True)
    return {"passed": result.returncode == 0, "output": (result.stdout + result.stderr).strip()}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=Path("theorem-split.json"))
    parser.add_argument("--output", type=Path, default=Path("harness/NormPrimesTask.lean"))
    parser.add_argument("--report", type=Path, default=Path("harness/NormPrimesTask.check.json"))
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    task, proof, prefix = extract(manifest)
    if any(x in task for x in ("import " + FORBIDDEN + "\n", "import " + FORBIDDEN + "Statement\n")):
        raise ValueError("forbidden import found")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(task, encoding="utf-8")
    # The elaboration probe uses sorry only in a temporary file. The distributed task has no sorry.
    checks = {
        "statement_elaborates": lean_check(task.replace(HOLE, "  sorry\n")),
        "original_proof_passes": lean_check(task.replace(HOLE, proof)),
        "empty_proof_rejected": lean_check(task.replace(HOLE, "")),
        "direct_reference_rejected": lean_check(task.replace(HOLE, f"  exact {TARGET}\n")),
        "target_absent_from_imports": lean_check(prefix + f"#check {TARGET}\n"),
    }
    checks["statement_elaborates"]["passed"] &= "declaration uses `sorry`" in checks["statement_elaborates"]["output"]
    if not (checks["statement_elaborates"]["passed"] and
            checks["original_proof_passes"]["passed"] and
            all(not checks[name]["passed"] for name in
                ("empty_proof_rejected", "direct_reference_rejected", "target_absent_from_imports"))):
        raise RuntimeError("Lean isolation checks failed:\n" + json.dumps(checks, indent=2))
    report = {
        "schema": "isolated-theorem-task/v1",
        "source_revision": manifest["source_revision"],
        "split_seed": manifest["seed"],
        "manifest_sha256": sha256(args.manifest.read_text(encoding="utf-8")),
        "task_sha256": sha256(task),
        "target": TARGET,
        "checks": {
            "statement_elaborates": checks["statement_elaborates"]["passed"],
            "original_proof_passes": checks["original_proof_passes"]["passed"],
            "empty_proof_rejected": not checks["empty_proof_rejected"]["passed"],
            "direct_reference_rejected": not checks["direct_reference_rejected"]["passed"],
            "target_absent_from_imports": not checks["target_absent_from_imports"]["passed"],
        },
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {args.output} and {args.report}")


if __name__ == "__main__":
    main()
