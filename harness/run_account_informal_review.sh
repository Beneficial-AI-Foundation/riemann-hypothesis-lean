#!/usr/bin/env bash
# Review the next frozen sketch in a fresh Codex thread outside the repository.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [harness/Sketch.tex]\n' "$0" >&2
  exit 2
fi
if [[ $# -eq 1 ]]; then
  sketch="$(realpath "$1")"
else
  mapfile -t candidates < <(jq -r 'select(.review_status == "draft_not_reviewed") | input_filename' \
    "$repo_dir"/harness/*Sketch.json | sort)
  if [[ ${#candidates[@]} -eq 0 ]]; then
    printf 'No unreviewed frozen sketch found. Pass a sketch path explicitly.\n' >&2
    exit 1
  fi
  sketch="${candidates[0]%.json}.tex"
fi
metadata="${sketch%.tex}.json"
if [[ ! -f "$sketch" || ! -f "$metadata" ]]; then
  printf 'Sketch and matching metadata JSON are required: %s\n' "$sketch" >&2
  exit 1
fi
target="$(jq -er '.target' "$metadata")"
gap_count="$(jq -er '.gap_count' "$metadata")"
actual_gap_count="$(rg -c '^\\paragraph\{Gap [0-9]+\.\}' "$sketch" || true)"
if [[ "$actual_gap_count" != "$gap_count" ]]; then
  printf 'Metadata says %s gaps, but sketch contains %s.\n' "$gap_count" "$actual_gap_count" >&2
  exit 1
fi
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
name="$(basename "$sketch" .tex)"
result_dir="$repo_dir/harness/reviews/${name}_$stamp"
workspace="$(mktemp -d /tmp/informal-review.XXXXXXXX)"

command -v codex >/dev/null
command -v jq >/dev/null
mkdir -p "$result_dir"

expected_hash="$(jq -r '.sketch_sha256' "$metadata")"
actual_hash="$(sha256sum "$sketch" | awk '{print $1}')"
if [[ "$actual_hash" != "$expected_hash" ]]; then
  printf 'Sketch hash differs from frozen metadata. Review not started.\n' >&2
  exit 1
fi

{
  cat <<EOF
You are independently checking whether an informal proof sketch can be
reconstructed. Use only the target and frozen sketch below. Do not call tools,
search for the original theorem, or use external files. Do not assume the target
theorem or an equivalent ready-made result.

Prove Gap 1 through Gap $gap_count in order. For each gap, give a short,
checkable informal proof using only the sketch's allowed facts and previously
proved gaps. If a gap fails, state the missing condition or possible
counterexample. Mark each gap "proved informally", "conditional or doubtful",
or "not proved". Then use only gaps you actually proved to reconstruct the
full argument, checking every intermediate step, quantifier, and hypothesis.
Report separately whether the full argument closes. Do not merely assert
that any step is obvious.

Target: $target (as stated in the frozen sketch).

Frozen sketch (LaTeX source; mathematical content is the review input):

\`\`\`tex
EOF
  cat "$sketch"
  printf '```\n'
} > "$result_dir/input.txt"

embedded_hash="$(awk '
  /^```tex$/ { in_tex = 1; next }
  in_tex && /^```$/ { exit }
  in_tex { print }
' "$result_dir/input.txt" | sha256sum | awk '{print $1}')"
if [[ "$embedded_hash" != "$expected_hash" ]]; then
  printf 'Embedded TeX differs from frozen sketch. Review not started.\n' >&2
  exit 1
fi

printf 'Working directory: %s\nResults: %s\n' "$workspace" "$result_dir"

run_status=0
codex exec \
  --ephemeral \
  --ignore-user-config \
  --skip-git-repo-check \
  --sandbox read-only \
  --cd "$workspace" \
  --json \
  --output-last-message "$result_dir/answer.txt" \
  - < "$result_dir/input.txt" > "$result_dir/events.jsonl" 2> "$result_dir/stderr.txt" \
  || run_status=$?

if ! jq -e . "$result_dir/events.jsonl" >/dev/null 2>&1; then
  printf 'Codex did not produce valid JSONL. Inspect stderr.txt.\n' >&2
  exit 1
fi

jq -r '
  select(.type == "item.started" or .type == "item.updated" or .type == "item.completed")
  | .item.type // empty
' "$result_dir/events.jsonl" | sort -u > "$result_dir/item_types.txt"

# Anything beyond message/reasoning items is treated as possible tool activity.
awk '$0 != "agent_message" && $0 != "reasoning" { print }' \
  "$result_dir/item_types.txt" > "$result_dir/possible_tool_items.txt"

if [[ -s "$result_dir/possible_tool_items.txt" ]]; then
  audit="possible tool activity; inspect events.jsonl"
else
  audit="no tool items observed in JSONL"
fi

if ! jq -e 'select(.type == "turn.completed")' \
  "$result_dir/events.jsonl" >/dev/null; then
  audit="$audit; no completed turn observed"
fi

if jq -e 'select(.type == "turn.failed" or .type == "error")' \
  "$result_dir/events.jsonl" >/dev/null; then
  audit="$audit; run reported failure"
fi

if [[ ! -s "$result_dir/answer.txt" ]]; then
  audit="$audit; no final answer saved"
fi

{
  printf 'Run time (UTC): %s\n' "$stamp"
  printf 'Target: %s\n' "$target"
  printf 'Gap count: %s\n' "$gap_count"
  printf 'Exit status: %s\n' "$run_status"
  printf 'Workspace: %s\n' "$workspace"
  printf 'Sketch SHA-256: %s\n' "$actual_hash"
  printf 'Input SHA-256: '
  sha256sum "$result_dir/input.txt" | awk '{print $1}'
  printf 'Audit: %s\n' "$audit"
  printf 'Interpretation: behavioral check only; filesystem read access is not blocked.\n'
} > "$result_dir/summary.txt"

cat "$result_dir/summary.txt"
printf 'Read %s and %s before assigning a review status.\n' \
  "$result_dir/answer.txt" "$result_dir/events.jsonl"
exit "$run_status"
