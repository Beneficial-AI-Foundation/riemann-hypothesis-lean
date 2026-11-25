#!/usr/bin/env python3
"""Count transitive project theorem source lines for a probe-lean target.

The probe JSON supplies the target. Lean's imported environment supplies the
transitive constant graph, including dependencies of imported project theorems.
Only explicit `theorem`/`lemma` source declarations contribute to theorem lines.
Generated proof constants are reported separately with their owning source lines.
"""

import argparse
import json
import subprocess
from pathlib import Path

from count_project_theorem_lines import imported_project_files, theorem_spans


REPO = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = Path(
    "src/Development/AbelianVarietyTheory/Proofs/TwistedOperators/MemKerPD.lean"
)


def source_index(files: set[Path]) -> set[tuple[str, Path]]:
    index = {}
    for path in files:
        for name, start, end in theorem_spans(path):
            index[(name, path)] = (start, end)
    return set(index)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extract", type=Path, help="probe-lean extract JSON")
    parser.add_argument("--theorem", default="GlobalTheory.SquareAgree.mem_kerPD")
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--details", action="store_true", help="list source theorem declarations")
    args = parser.parse_args()

    extract = json.loads(args.extract.read_text())
    target = extract["data"]["probe:" + args.theorem]
    if target["kind"] != "theorem":
        parser.error("target is not a theorem")

    source = (REPO / args.source).resolve()
    src_root = REPO / "src"
    module = ".".join(source.relative_to(src_root).with_suffix("").parts)
    helper = Path(__file__).with_name("TransitiveTheoremDeps.lean")
    proc = subprocess.run(
        ["lake", "env", "lean", "--run", str(helper), module, args.theorem],
        cwd=REPO, text=True, capture_output=True, check=True,
    )

    imported = imported_project_files(source, src_root)
    explicit = source_index(imported)
    all_constants = []
    all_owner_lines: dict[Path, set[int]] = {}
    theorem_owner_lines: dict[Path, set[int]] = {}
    missing_ranges = []
    for line in proc.stdout.splitlines():
        name, source_module, owner, first, last, is_theorem = line.split("\t")
        path = src_root.joinpath(*source_module.split(".")).with_suffix(".lean")
        first, last = int(first), int(last)
        if not path.is_file() or first == 0 or last == 0:
            missing_ranges.append(name)
            continue
        all_owner_lines.setdefault(path, set()).update(range(first, last + 1))
        if is_theorem == "true":
            theorem_owner_lines.setdefault(path, set()).update(range(first, last + 1))
            all_constants.append((name, path, owner, first, last))

    explicit_deps = []
    for name, path, owner, first, last in all_constants:
        if (name, path) not in explicit:
            continue
        # Lean's declaration range is the source of truth for the exact span.
        explicit_deps.append({"name": name, "path": str(path.relative_to(REPO)),
                              "start": first, "end": last, "lines": last - first + 1})

    target_deps = [item for item in explicit_deps if item["name"] == args.theorem]
    if len(target_deps) != 1:
        raise ValueError("target theorem has no unique source range")
    theorem_lines = sum(item["lines"] for item in explicit_deps)
    result = {
        "target": args.theorem,
        "scope": "transitive project theorem dependencies",
        "reachable_project_constants": sum(1 for line in proc.stdout.splitlines() if line),
        "project_source_lines_for_all_reachable_constants": sum(map(len, all_owner_lines.values())),
        "project_source_files_for_all_reachable_constants": len(all_owner_lines),
        "lean_theorem_constants": len(all_constants),
        "explicit_theorem_declarations_including_target": len(explicit_deps),
        "explicit_theorem_lines_including_target": theorem_lines,
        "explicit_theorem_dependency_lines": theorem_lines - target_deps[0]["lines"],
        "proof_constant_owner_source_lines_including_theorems": sum(map(len, theorem_owner_lines.values())),
        "source_files_with_reachable_proof_constants": len(theorem_owner_lines),
        "missing_ranges": missing_ranges,
    }
    if args.details:
        result["explicit_theorems"] = sorted(explicit_deps, key=lambda item: item["name"])
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if missing_ranges:
        raise SystemExit("Some transitive proof constants have no project source range")


if __name__ == "__main__":
    main()
