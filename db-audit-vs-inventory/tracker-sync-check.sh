#!/usr/bin/env bash
# ===========================================================================
#  tracker-sync-check.sh — detect that the migrations tracker has diverged
#  so far from the repo that the two sets share zero rows.
# ===========================================================================
#  The archetype case: someone applied SQL directly via Web Studio (Supabase
#  dashboard, pgAdmin, the SQL Editor in another tool), the tracker records
#  the version with its own format/timestamp, and the repo never sees it.
#  Three months later, the intersection of repo versions and tracker versions
#  is empty, and you don't know which migration mapped to which prod version.
# ===========================================================================

set -euo pipefail

PROD_URL="${PROD_URL:?set PROD_URL=postgres://...}"
MIG_DIR="${MIG_DIR:-supabase/migrations}"
TRACKER_TABLE="${TRACKER_TABLE:-supabase_migrations.schema_migrations}"
TRACKER_COL="${TRACKER_COL:-version}"

# Repo versions: extract from the migration filenames (timestamps).
ls "$MIG_DIR"/*.sql 2>/dev/null \
  | sed -E "s|.*/([0-9]+)_.*\.sql|\1|" | sort -u > /tmp/repo-versions.txt

# Production tracker versions.
psql "$PROD_URL" -tAc \
  "SELECT $TRACKER_COL FROM $TRACKER_TABLE ORDER BY 1" \
  | sed '/^$/d' | sort -u > /tmp/prod-versions.txt

REPO_COUNT=$( wc -l < /tmp/repo-versions.txt )
PROD_COUNT=$( wc -l < /tmp/prod-versions.txt )
COMMON_COUNT=$( comm -12 /tmp/repo-versions.txt /tmp/prod-versions.txt | wc -l )

echo "─── Migrations tracker sync ──────────────────────────────"
echo "  Repo versions:     $REPO_COUNT"
echo "  Prod tracker:      $PROD_COUNT"
echo "  Common:            $COMMON_COUNT"

if [ "$REPO_COUNT" -eq 0 ] || [ "$PROD_COUNT" -eq 0 ]; then
  echo "⚠ Empty side — cannot compute overlap."
  exit 1
fi

# Overlap as percentage of the smaller side.
SMALLER=$( [ "$REPO_COUNT" -lt "$PROD_COUNT" ] && echo "$REPO_COUNT" || echo "$PROD_COUNT" )
OVERLAP_PCT=$(( 100 * COMMON_COUNT / SMALLER ))
echo "  Overlap (smaller): ${OVERLAP_PCT}%"

if [ "$OVERLAP_PCT" -lt 90 ]; then
  echo "⚠ Tracker has drifted significantly. Investigate before the next baseline resync."
  exit 1
fi

echo "✓ Tracker in sync."
