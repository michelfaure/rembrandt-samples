#!/usr/bin/env bash
# ===========================================================================
#  02-vercel-example.sh — Vercel Ignored Build Step audit
# ===========================================================================
#  The setting `commandForIgnoringBuildStep` is a *project-level* config on
#  Vercel's side. It is NOT in `vercel.json` (which only carries
#  build/route/redirect declarations). You cannot find it by grepping the
#  repo. Updating it without reading the current value silently overwrites
#  whatever exclusion rule was there before.
#
#  This script reads the current value, compares with the intended target,
#  and refuses to apply an update that drops a previously-excluded path.
# ===========================================================================

set -euo pipefail

PROJECT_ID="${VERCEL_PROJECT_ID:?set VERCEL_PROJECT_ID}"
TARGET_COMMAND='git diff --quiet HEAD^ HEAD -- '\
'":(exclude)docs/" ":(exclude)*.md" ":(exclude)articles/" ":(exclude).claude/"'

# ---------------------------------------------------------------------------
# Step 1 — Read the current `commandForIgnoringBuildStep`.
# ---------------------------------------------------------------------------
CURRENT=$( vercel project ls --json | jq -r \
  --arg id "$PROJECT_ID" \
  '.[] | select(.id == $id) | .commandForIgnoringBuildStep // ""' )

echo "Current rule:"
echo "  $CURRENT"
echo
echo "Target rule:"
echo "  $TARGET_COMMAND"
echo

# ---------------------------------------------------------------------------
# Step 2 — Detect dropped exclusions.
# We extract the `:(exclude)PATH` arguments from each rule and compute the
# set difference. Any path that disappears is a SILENT REGRESSION.
# ---------------------------------------------------------------------------
extract_excludes() {
  echo "$1" | grep -oE ':\(exclude\)[^"]+' | sed 's/:(exclude)//' | sort -u
}

DROPPED=$( comm -23 \
  <(extract_excludes "$CURRENT") \
  <(extract_excludes "$TARGET_COMMAND") )

if [ -n "$DROPPED" ]; then
  echo "⚠ Paths REMOVED from the exclusion list:"
  echo "$DROPPED" | sed 's/^/  /'
  echo
  read -r -p "Confirm these paths SHOULD now trigger builds? (y/N) " ok
  [ "${ok,,}" = "y" ] || { echo "Aborted."; exit 1; }
else
  echo "✓ No path is dropped from the exclusion list."
fi

# ---------------------------------------------------------------------------
# Step 3 — Apply.
# ---------------------------------------------------------------------------
curl -fsSL \
  -X PATCH "https://api.vercel.com/v9/projects/$PROJECT_ID" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$( jq -n --arg cmd "$TARGET_COMMAND" \
        '{ commandForIgnoringBuildStep: $cmd }' )"

echo "✓ Vercel project $PROJECT_ID updated."
