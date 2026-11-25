#!/usr/bin/env bash
# Run a fresh, account-authenticated Codex review without giving it the repository as a workspace.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_dir/harness/ACCOUNT_INFORMAL_REVIEW_WORKFLOW.md"
sketch="$repo_dir/harness/RayFormCombInjectiveSketch.tex"
metadata="$repo_dir/harness/RayFormCombInjectiveSketch.json"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
result_dir="$repo_dir/harness/reviews/ray_form_comb_injective_$stamp"
workspace="$(mktemp -d /tmp/ray-form-review.XXXXXXXX)"

command -v codex >/dev/null
command -v jq >/dev/null
mkdir -p "$result_dir"

expected_hash="$(jq -r '.sketch_sha256' "$metadata")"
actual_hash="$(sha256sum "$sketch" | awk '{print $1}')"
if [[ "$actual_hash" != "$expected_hash" ]]; then
  printf 'Sketch hash differs from frozen metadata. Review not started.\n' >&2
  exit 1
fi

awk '
  /^REVIEW MESSAGE START$/ { in_message = 1; starts++; next }
  /^REVIEW MESSAGE END$/ { if (in_message) { in_message = 0; ends++ }; next }
  in_message { print }
  END { if (starts != 1 || ends != 1) exit 1 }
' "$workflow" > "$result_dir/input.txt"

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
