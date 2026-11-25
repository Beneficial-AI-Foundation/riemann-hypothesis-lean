#!/usr/bin/env python3
"""Count directly referenced project theorem source lines from a probe-lean extract.

The extract records imported constants by name only. This script resolves theorem
names against the target module's transitive project imports and counts each
source declaration once. It does not expand imported theorems' own dependencies.
"""

import argparse
import json
import re
from pathlib import Path


DECL = re.compile(r"^(?:(?:private|protected|noncomputable|unsafe|partial)\s+)*(theorem|lemma)\s+([^\s(:{]+)")
FRAME = re.compile(r"^(namespace|section)\b(?:\s+([^\s]+))?")
END = re.compile(r"^end(?:\s|$)")


def imported_project_files(source: Path, src_root: Path) -> set[Path]:
    seen: set[Path] = set()
    pending = [source]
    while pending:
        path = pending.pop()
        if path in seen:
            continue
        seen.add(path)
        for line in path.read_text().splitlines():
            if line.startswith("import "):
                for module in line[7:].split():
                    child = src_root.joinpath(*module.split(".")).with_suffix(".lean")
                    if child.is_file():
                        pending.append(child)
    return seen


def theorem_spans(path: Path) -> list[tuple[str, int, int]]:
    lines = path.read_text().splitlines()
    frames: list[tuple[str, str]] = []
    found: list[tuple[str, int, int]] = []
    for index, line in enumerate(lines):
        # Top-level Lean commands begin in column zero in this project's sources.
        if not line or line[0].isspace():
            continue
        frame = FRAME.match(line)
        if frame:
            frames.append((frame.group(1), frame.group(2) or ""))
            continue
        if END.match(line):
            if frames:
                frames.pop()
            continue
        match = DECL.match(line)
        if not match:
            continue
        name = match.group(2)
        if name.startswith("_root_."):
            full_name = name.removeprefix("_root_.")
        else:
            prefix = ".".join(value for kind, value in frames if kind == "namespace" and value)
            full_name = f"{prefix}.{name}" if prefix else name
        end = index
        for next_index in range(index + 1, len(lines)):
            if lines[next_index] and not lines[next_index][0].isspace():
                break
            if lines[next_index].strip():
                end = next_index
        found.append((full_name, index + 1, end + 1))
    return found


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extract", type=Path, help="probe-lean extract JSON")
    parser.add_argument("--theorem", default="GlobalTheory.SquareAgree.mem_kerPD")
    parser.add_argument("--source", type=Path, default=Path("src/Development/AbelianVarietyTheory/Proofs/TwistedOperators/MemKerPD.lean"))
    parser.add_argument("--src-root", type=Path, default=Path("src"))
    args = parser.parse_args()

    data = json.loads(args.extract.read_text())["data"]
    key = "probe:" + args.theorem
    target = data[key]
    dependencies = set(target.get("dependencies", []))
    dependencies.update(target.get("term-dependencies-external", []))
    dependencies.update(target.get("type-dependencies-external", []))

    files = imported_project_files(args.source, args.src_root)
    index: dict[str, list[tuple[Path, int, int]]] = {}
    for path in files:
        for name, start, end in theorem_spans(path):
            index.setdefault("probe:" + name, []).append((path, start, end))

    results = []
    ambiguous = []
    for dependency in sorted(dependencies):
        matches = index.get(dependency, [])
        if len(matches) > 1:
            ambiguous.append(dependency)
            continue
        if matches:
            path, start, end = matches[0]
            results.append({"name": dependency.removeprefix("probe:"), "path": str(path),
                            "start": start, "end": end, "lines": end - start + 1})
        elif dependency in data and data[dependency].get("kind") == "theorem":
            atom = data[dependency]
            span = atom.get("code-text", {})
            start, end = span.get("lines-start"), span.get("lines-end")
            if isinstance(start, int) and isinstance(end, int):
                results.append({"name": dependency.removeprefix("probe:"),
                                "path": str(args.source), "start": start,
                                "end": end, "lines": end - start + 1})
            else:
                ambiguous.append(dependency)

    target_span = target.get("code-text", {})
    target_start, target_end = target_span.get("lines-start"), target_span.get("lines-end")
    target_lines = (target_end - target_start + 1
                    if isinstance(target_start, int) and isinstance(target_end, int) else None)
    dependency_lines = sum(item["lines"] for item in results)
    print(json.dumps({"theorem": args.theorem, "scope": "direct project theorem dependencies",
                      "count": len(results), "dependency_lines": dependency_lines,
                      "target_lines": target_lines,
                      "total_theorem_lines_with_target": (dependency_lines + target_lines
                                                          if target_lines is not None else None),
                      "dependencies": results, "ambiguous": ambiguous}, ensure_ascii=False, indent=2))
    if ambiguous:
        raise SystemExit("Cannot give an exact count: ambiguous theorem source locations")


if __name__ == "__main__":
    main()
