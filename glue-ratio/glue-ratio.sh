#!/bin/bash
# Glue code vs business logic ratio in lib/
# Usage:
#   ./glue-ratio.sh           — full human-readable output
#   ./glue-ratio.sh --metric  — emits just the types-excluded percentage (for CI)
#
# Glue     = external integration (API clients, auth, config, utils, plumbing)
# Business = business logic (pipelines, permissions, templates, domain)
#
# Target: < 25%. Alert threshold: 30%. Blocking ceiling: 40%.
#
# Fill in the two lists below with your project's files.
# Every new addition must be consciously classified into one or the other.

GLUE_FILES=(
  # Adapters to third-party services — fill with your own paths
  "lib/supabase.ts"
  "lib/gmail.ts"
  "lib/brevo.ts"
  "lib/slack.ts"
  "lib/stripe.ts"
  "lib/rate-limit.ts"
  "lib/webhook-idempotency.ts"
  "lib/utils.ts"
  "lib/database.types.ts"  # auto-generated — excluded from the types-excluded denominator
)

BUSINESS_FILES=(
  # Business logic — fill with your own paths
  "lib/lead-pipeline.ts"
  "lib/email-outbox.ts"
  "lib/email-templates.ts"
  "lib/permissions.ts"
  "lib/contacts.ts"
)

# Name of the auto-generated file to exclude from the types-excluded denominator.
# Leave empty if you don't have an auto-generated file.
TYPES_FILE="lib/database.types.ts"

cd "$(dirname "$0")/.." || exit 1

glue_lines=0
business_lines=0

for f in "${GLUE_FILES[@]}"; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    glue_lines=$((glue_lines + lines))
  fi
done

for f in "${BUSINESS_FILES[@]}"; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    business_lines=$((business_lines + lines))
  fi
done

total=$((glue_lines + business_lines))

if [ "$total" -eq 0 ]; then
  echo "No file found — check the paths in GLUE_FILES / BUSINESS_FILES" >&2
  exit 1
fi

glue_pct=$((glue_lines * 100 / total))
business_pct=$((business_lines * 100 / total))

# Compute the types-excluded ratio (reference metric)
types_lines=0
if [ -n "$TYPES_FILE" ] && [ -f "$TYPES_FILE" ]; then
  types_lines=$(wc -l < "$TYPES_FILE")
fi
real_glue=$((glue_lines - types_lines))
real_total=$((total - types_lines))
real_pct=$((real_glue * 100 / real_total))

# --metric mode: emit just the types-excluded ratio (for CI diff)
if [ "${1:-}" = "--metric" ]; then
  echo "$real_pct"
  exit 0
fi

echo ""
echo "Glue/business ratio — lib/"
echo "=========================="
echo "  Glue:     ${glue_lines} lines (${glue_pct}%)"
echo "  Business: ${business_lines} lines (${business_pct}%)"
echo "  Total:    ${total} lines"
echo ""

if [ "$types_lines" -gt 0 ]; then
  echo "  (excluding ${TYPES_FILE}: ${real_glue} glue / ${real_total} total = ${real_pct}%)"
  echo ""
fi

if [ "$real_pct" -gt 40 ]; then
  echo "  CEILING: types-excluded glue > 40% — refactoring urgent"
elif [ "$real_pct" -gt 30 ]; then
  echo "  ALERT: types-excluded glue > 30% — target 25%"
else
  echo "  OK: types-excluded glue under the 30% alert threshold (target 25%)"
fi

echo ""
echo "$(date +%Y-%m-%d) | glue=${glue_lines} (${glue_pct}%) | types-excluded=${real_pct}% | business=${business_lines} (${business_pct}%) | total=${total}"
