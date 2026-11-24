#!/usr/bin/env python3
"""Run a read-only Codex agent to summarize the norm-primes proof."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src/Development/AbelianVarietyTheory/Proofs/GlobalInterpolation/NormPrimesImagQuadShortIntervalLowerBound.lean"
PROMPT = ROOT / "harness/prompts/norm_primes_summarizer.md"
DEFAULT_OUTPUT = ROOT / "harness/NormPrimesProofIdea.md"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def render_prompt() -> tuple[str, str, str]:
    source_hash = sha256(SOURCE.read_bytes())
    prompt_bytes = PROMPT.read_bytes()
    prompt = prompt_bytes.decode("utf-8")
    return prompt + f"\n\nTarget source SHA-256: `{source_hash}`\n", source_hash, sha256(prompt_bytes)


def validate_summary(summary: str) -> None:
    words = summary.split()
    if not summary.strip() or len(words) > 500:
        raise ValueError(f"summary must contain 1–500 words; found {len(words)}")
    if "```" in summary:
        raise ValueError("summary contains a code fence")
    for heading in ("## Main line", "## Distinctive moves", "## Essential prerequisites"):
        if heading not in summary:
            raise ValueError(f"missing heading: {heading}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--model", help="Codex model override")
    parser.add_argument("--dry-run", action="store_true", help="print the rendered prompt only")
    args = parser.parse_args()

    prompt, source_hash, prompt_hash = render_prompt()
    if args.dry_run:
        print(prompt)
        return

    with tempfile.TemporaryDirectory(prefix="norm-primes-summary-") as temporary:
        draft = Path(temporary) / "summary.md"
        command = ["codex", "exec", "--ephemeral", "--sandbox", "read-only",
                   "-C", str(ROOT), "-o", str(draft)]
        if args.model:
            command.extend(["--model", args.model])
        command.append("-")
        result = subprocess.run(command, input=prompt, text=True, cwd=ROOT,
                                capture_output=True)
        if result.returncode:
            raise RuntimeError(f"summarizer failed ({result.returncode}):\n{result.stderr[-4000:]}")
        summary = draft.read_text(encoding="utf-8")
        validate_summary(summary)
        if sha256(SOURCE.read_bytes()) != source_hash:
            raise RuntimeError("source changed while the summarizer was running")

    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(summary.rstrip() + "\n", encoding="utf-8")
    report = {
        "schema": "proof-idea-summary/v1",
        "target": "GlobalTheory.Hk.normPrimes_short_interval_lower",
        "source_sha256": source_hash,
        "prompt_sha256": prompt_hash,
        "summary_sha256": sha256(output.read_bytes()),
        "word_count": len(summary.split()),
        "model_override": args.model,
    }
    output.with_suffix(".json").write_text(json.dumps(report, indent=2) + "\n",
                                           encoding="utf-8")
    print(f"wrote {output} ({report['word_count']} words)")


if __name__ == "__main__":
    main()
