#!/usr/bin/env bash
# quarterly-enum-audit.sh
#
# Compare declared TypeScript enum constants against the actual values
# returned by SELECT DISTINCT on each enum-bearing column.
#
# Source article: Five silent failure modes I codified after 35 effective
# days of solo ERP coding — Mode 4 ("the count that lies").
#
# Run this quarterly. Calendar it. A semantic layer or whitelist that
# nobody audits drifts silently — SQL stays valid, queries return zero
# rows, and the agent confabulates a plausible business explanation
# ("there are no overdue invoices this month") where the real cause is
# structural ("the enum I'm querying no longer exists in the database").
#
# Usage
# -----
#   DATABASE_URL=postgres://...  bash quarterly-enum-audit.sh
#
# Exit codes
# ----------
#   0 — every declared enum matches the DB values
#   1 — at least one drift detected, see output for table/column
#   2 — infrastructure error (psql unreachable, file missing)

set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "✗ DATABASE_URL required" >&2
  exit 2
fi

# List of (table, column, ts_constant_name) tuples to audit.
# Edit this for your project. The ts_constant_name is the constant
# exported from your codebase, used to grep the declared values.
TARGETS=(
  "enrollments|status|ENROLLMENT_VALID_STATUSES"
  "contacts|status|CONTACT_VALID_STATUSES"
  "due_dates|status|DUE_DATE_VALID_STATUSES"
)

DRIFT=0

for tuple in "${TARGETS[@]}"; do
  IFS='|' read -r table col const <<< "$tuple"

  # Pull DB values
  db_values=$(psql "$DATABASE_URL" -At -c \
    "SELECT DISTINCT $col FROM $table WHERE $col IS NOT NULL ORDER BY 1;" \
    | sort -u)

  # Pull TS values from the constant declaration (regex-based, adapt to your style).
  # This grep targets a literal array: export const ENROLLMENT_VALID_STATUSES = ['enrolled', 'cancelled', ...]
  ts_values=$(grep -h --include='*.ts' -roE "$const\s*=\s*\[[^\]]+\]" lib/ src/ 2>/dev/null \
    | grep -oE "'[^']+'" | tr -d "'" | sort -u)

  if [[ -z "$ts_values" ]]; then
    echo "✗ Could not locate TypeScript constant $const — check your sources path"
    DRIFT=1
    continue
  fi

  # Diff the two sets
  only_db=$(comm -23 <(echo "$db_values") <(echo "$ts_values") || true)
  only_ts=$(comm -13 <(echo "$db_values") <(echo "$ts_values") || true)

  if [[ -z "$only_db" && -z "$only_ts" ]]; then
    echo "✓ $table.$col matches $const"
  else
    echo "✗ DRIFT on $table.$col vs $const"
    [[ -n "$only_db" ]] && echo "    only in DB: $(echo $only_db | tr '\n' ' ')"
    [[ -n "$only_ts" ]] && echo "    only in TS: $(echo $only_ts | tr '\n' ' ')"
    DRIFT=1
  fi
done

if [[ $DRIFT -eq 1 ]]; then
  echo ""
  echo "Drift detected — sync your TS constant or add a migration."
  exit 1
fi

echo ""
echo "All enums in sync."
exit 0
