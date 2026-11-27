#!/usr/bin/env bash
set -euo pipefail

probe_dir=$(cd "$(dirname "$0")" && pwd)
mathlib_olean="$probe_dir/../../.lake/packages/mathlib/.lake/build/lib/lean/Mathlib.olean"
if [ ! -f "$mathlib_olean" ]; then
  echo "Missing parent project's Mathlib cache: $mathlib_olean" >&2
  exit 1
fi

mkdir -p "$probe_dir/.lake/packages"
if [ ! -e "$probe_dir/.lake/packages/mathlib" ]; then
  ln -s ../../../../.lake/packages/mathlib "$probe_dir/.lake/packages/mathlib"
fi
