#!/usr/bin/env python3
"""Make a reproducible theorem-level 80/20 split for the discovery experiment.

This stage writes a source-location manifest. It does not copy proof text or
claim that randomly separated theorems are independent.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = Path("src/Development/AbelianVarietyTheory/Proofs/GlobalInterpolation")
DEFAULT_HOLDOUT = (
    DEFAULT_SOURCE / "NormPrimesImagQuadShortIntervalLowerBound.lean",
    "normPrimes_short_interval_lower",
)
DECLARATION = re.compile(
    r"^\s*(?:@\[[^\]\n]*\]\s*)*"
    r"(?:(?:private|protected|nonrec)\s+)*"
    r"(theorem|lemma)\s+([^\s(:\[{]+)"
)


def strip_comments(source: str) -> str:
    """Blank Lean comments while preserving source line numbers."""
    result = []
    depth = 0
    in_string = False
    escaped = False
    index = 0
    while index < len(source):
        pair = source[index : index + 2]
        char = source[index]
        if depth:
            if pair == "/-":
                depth += 1
                result.extend("  ")
                index += 2
            elif pair == "-/":
                depth -= 1
                result.extend("  ")
                index += 2
            else:
                result.append("\n" if char == "\n" else " ")
                index += 1
        elif in_string:
            result.append("\n" if char == "\n" else " ")
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
        elif pair == "--":
            end = source.find("\n", index)
            if end < 0:
                result.extend(" " * (len(source) - index))
                break
            result.extend(" " * (end - index))
            index = end
        elif pair == "/-":
            depth = 1
            result.extend("  ")
            index += 2
        else:
            result.append(" " if char == '"' else char)
            in_string = char == '"'
            index += 1
    if depth:
        raise ValueError("unclosed Lean block comment")
    return "".join(result)


def inventory(root: Path, source_dir: Path, include_statement_files: bool = False) -> list[dict]:
    entries = []
    for path in sorted((root / source_dir).rglob("*.lean")):
        if not include_statement_files and path.name.endswith("Statement.lean"):
            continue
        relative = path.relative_to(root).as_posix()
        source = path.read_text(encoding="utf-8")
        digest = hashlib.sha256(source.encode("utf-8")).hexdigest()
        for line_number, line in enumerate(strip_comments(source).splitlines(), 1):
            match = DECLARATION.match(line)
            if match:
                entries.append(
                    {
                        "file": relative,
                        "line": line_number,
                        "kind": match.group(1),
                        "name": match.group(2),
                        "source_sha256": digest,
                    }
                )
    return entries


def split(entries: list[dict], seed: str, holdouts: list[tuple[str, str]]) -> tuple[list[dict], list[dict]]:
    if len(entries) < 2:
        raise ValueError("at least two theorem declarations are required")
    test_count = len(entries) - (4 * len(entries) // 5)
    holdout_set = set(holdouts)
    matched = {(entry["file"], entry["name"]) for entry in entries} & holdout_set
    if matched != holdout_set:
        raise ValueError(f"holdout theorem(s) missing: {sorted(holdout_set - matched)}")
    for file, name in matched:
        if sum(entry["file"] == file and entry["name"] == name for entry in entries) != 1:
            raise ValueError(f"holdout theorem is ambiguous: {file}:{name}")
    if len(matched) > test_count:
        raise ValueError("more forced holdouts than test slots")

    def rank(entry: dict) -> str:
        key = f'{seed}\0{entry["file"]}\0{entry["line"]}\0{entry["name"]}'
        return hashlib.sha256(key.encode("utf-8")).hexdigest()

    remaining = [entry for entry in entries if (entry["file"], entry["name"]) not in matched]
    chosen = sorted(remaining, key=lambda entry: (rank(entry), entry["file"], entry["line"]))[
        : test_count - len(matched)
    ]
    test_keys = {(entry["file"], entry["line"]) for entry in chosen}
    test_keys.update((entry["file"], entry["line"]) for entry in entries
                     if (entry["file"], entry["name"]) in matched)
    train = [entry for entry in entries if (entry["file"], entry["line"]) not in test_keys]
    test = [entry for entry in entries if (entry["file"], entry["line"]) in test_keys]
    return train, test


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", default="0", help="stable split seed (default: 0)")
    parser.add_argument("--include-statement-files", action="store_true")
    parser.add_argument(
        "--holdout", action="append", metavar="FILE:NAME",
        help="force a declaration into test; defaults to the norm-primes main theorem",
    )
    args = parser.parse_args()
    source_dir = args.source_dir
    if source_dir.is_absolute():
        source_dir = source_dir.relative_to(ROOT)
    if not (ROOT / source_dir).is_dir():
        parser.error(f"source directory does not exist: {source_dir}")

    raw_holdouts = args.holdout or [f"{DEFAULT_HOLDOUT[0]}:{DEFAULT_HOLDOUT[1]}"]
    try:
        if any(":" not in item or item.endswith(":") for item in raw_holdouts):
            raise ValueError("each --holdout must have the form FILE:NAME")
        holdouts = [tuple(item.rsplit(":", 1)) for item in raw_holdouts]
        entries = inventory(ROOT, source_dir, args.include_statement_files)
        train, test = split(entries, args.seed, holdouts)
    except (ValueError, OSError) as error:
        parser.error(str(error))

    revision = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.strip()
    manifest = {
        "schema": "theorem-split/v1",
        "source_revision": revision,
        "source_dir": source_dir.as_posix(),
        "seed": args.seed,
        "ratio": {"train": 80, "test": 20},
        "statement_files_included": args.include_statement_files,
        "forced_holdouts": [{"file": file, "name": name} for file, name in holdouts],
        "counts": {"train": len(train), "test": len(test), "total": len(entries)},
        "train": train,
        "test": test,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(train)} train / {len(test)} test; wrote {args.output}')


if __name__ == "__main__":
    main()
