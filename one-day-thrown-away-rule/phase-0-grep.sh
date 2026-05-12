#!/usr/bin/env bash
# ===========================================================================
#  phase-0-grep.sh — enumerate existing code in a domain before letting an
#  AI agent write a new component for it.
# ===========================================================================
#  Usage: ./phase-0-grep.sh <domain-keyword>
#  Cost:  ~2 minutes (mostly to skim the output, not to run the commands)
# ===========================================================================

set -euo pipefail

DOMAIN="${1:?usage: $0 <domain-keyword>   e.g. invoices, emargement, exports}"

OUTPUT_VERBS=(Render Export Pdf Generate Build Compose Format)

echo "─── Phase 0 grep for domain: $DOMAIN ──────────────────────"
echo

# 1. Files in the domain directory
echo "Files in app/$DOMAIN/ and lib/$DOMAIN/:"
find "app/$DOMAIN/" "lib/$DOMAIN/" 2>/dev/null \
  -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.sql" \) \
  | head -30 | sed 's/^/  /'

echo

# 2. Existing output-producing patterns across the codebase
echo "Existing output-producing components matching $DOMAIN:"
for verb in "${OUTPUT_VERBS[@]}"; do
  grep -rl "$verb" "app/" "lib/" 2>/dev/null \
    | grep -i "$DOMAIN" \
    | sed "s/^/  [$verb] /"
done

echo

# 3. Existing API routes for the domain
echo "API routes mentioning $DOMAIN:"
find "app/api/" 2>/dev/null \
  -type d -iname "*$DOMAIN*" \
  | sed 's/^/  /'

echo

# 4. SQL migrations touching the domain
echo "Migrations mentioning $DOMAIN:"
grep -lE "$DOMAIN" supabase/migrations/*.sql 2>/dev/null \
  | head -10 | sed 's/^/  /'

echo
echo "─── End of Phase 0 inventory ──────────────────────────────"
echo
echo "Before asking your agent to write a new $DOMAIN component:"
echo "  1. Open every file listed under 'output-producing components'"
echo "  2. Verbalize what each one does in one sentence"
echo "  3. Decide: extend, refactor, or write new (with justification)"
