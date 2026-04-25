#!/bin/bash
# Compare the glue ratio (types-excluded) between HEAD and a base ref.
# Fail if the PR regresses the ratio by more than TOLERANCE points.
#
# Usage: ./glue-ratio-check.sh
# Optional env: TOLERANCE (default 0), BASE_REF (default origin/main)
#
# Drop this script and glue-ratio.sh into your project's scripts/,
# and call it from your CI (see ci-workflow.yml).

set -euo pipefail

TOLERANCE="${TOLERANCE:-0}"
BASE_REF="${BASE_REF:-origin/main}"

cd "$(dirname "$0")/.."

# Current ratio (HEAD)
current=$(bash scripts/glue-ratio.sh --metric)

# Ratio on the comparison base — extract only lib/ from the base
# then measure with the HEAD script (which knows --metric).
# This avoids false positives if the script has evolved.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/scripts"
cp scripts/glue-ratio.sh "$tmp/scripts/"
git archive "$BASE_REF" lib/ | tar -x -C "$tmp"

base=$(cd "$tmp" && bash scripts/glue-ratio.sh --metric)

delta=$((current - base))

echo "Glue ratio (types-excluded)"
echo "  Base ($BASE_REF): ${base}%"
echo "  HEAD:             ${current}%"
echo "  Delta:            $([ "$delta" -ge 0 ] && echo "+")${delta} pts"
echo "  Tolerance:        +${TOLERANCE} pts"

if [ "$delta" -gt "$TOLERANCE" ]; then
  echo ""
  echo "FAIL: glue ratio rose by ${delta} pts (tolerance +${TOLERANCE})."
  echo "Check whether:"
  echo "  - some glue can be extracted into lib/mappings/ or lib/adapters/"
  echo "  - a new file is miscategorized in scripts/glue-ratio.sh"
  echo "  - business logic should be added in counterweight"
  exit 1
fi

if [ "$delta" -lt 0 ]; then
  echo ""
  echo "OK: ratio down, glue extracted or business expanded."
else
  echo ""
  echo "OK: ratio stable."
fi
