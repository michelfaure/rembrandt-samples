#!/bin/bash
# Ratio glue code vs business logic dans lib/
# Usage :
#   ./glue-ratio.sh           — sortie humaine complete
#   ./glue-ratio.sh --metric  — emet juste le pourcentage hors-types (pour CI)
#
# Glue     = integration externe (API clients, auth, config, utils, plumbing)
# Business = logique metier (pipelines, permissions, templates, domaine)
#
# Cible : < 25%. Seuil d'alerte : 30%. Plafond bloquant : 40%.
#
# Remplir les deux listes ci-dessous avec les fichiers de ton projet.
# Toute nouvelle addition doit etre classee consciemment dans l'une ou l'autre.

GLUE_FILES=(
  # Adapters vers services tiers — remplir avec tes propres chemins
  "lib/supabase.ts"
  "lib/gmail.ts"
  "lib/brevo.ts"
  "lib/slack.ts"
  "lib/stripe.ts"
  "lib/rate-limit.ts"
  "lib/webhook-idempotency.ts"
  "lib/utils.ts"
  "lib/database.types.ts"  # auto-genere — exclu du denominateur hors-types
)

BUSINESS_FILES=(
  # Logique metier — remplir avec tes propres chemins
  "lib/lead-pipeline.ts"
  "lib/email-outbox.ts"
  "lib/email-templates.ts"
  "lib/permissions.ts"
  "lib/contacts.ts"
)

# Nom du fichier auto-genere a exclure du denominateur hors-types.
# Mettre a vide si tu n'as pas de fichier auto-genere.
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
  echo "Aucun fichier trouve — verifie les chemins dans GLUE_FILES / BUSINESS_FILES" >&2
  exit 1
fi

glue_pct=$((glue_lines * 100 / total))
business_pct=$((business_lines * 100 / total))

# Calcul du ratio hors-types (metrique de reference)
types_lines=0
if [ -n "$TYPES_FILE" ] && [ -f "$TYPES_FILE" ]; then
  types_lines=$(wc -l < "$TYPES_FILE")
fi
real_glue=$((glue_lines - types_lines))
real_total=$((total - types_lines))
real_pct=$((real_glue * 100 / real_total))

# Mode --metric : sortir juste le ratio hors-types (pour CI diff)
if [ "${1:-}" = "--metric" ]; then
  echo "$real_pct"
  exit 0
fi

echo ""
echo "Ratio glue/business — lib/"
echo "=========================="
echo "  Glue:     ${glue_lines} lignes (${glue_pct}%)"
echo "  Business: ${business_lines} lignes (${business_pct}%)"
echo "  Total:    ${total} lignes"
echo ""

if [ "$types_lines" -gt 0 ]; then
  echo "  (hors ${TYPES_FILE} : ${real_glue} glue / ${real_total} total = ${real_pct}%)"
  echo ""
fi

if [ "$real_pct" -gt 40 ]; then
  echo "  PLAFOND: glue hors-types > 40% — refactoring urgent"
elif [ "$real_pct" -gt 30 ]; then
  echo "  ALERTE: glue hors-types > 30% — cible 25%"
else
  echo "  OK: glue hors-types sous le seuil d'alerte 30% (cible 25%)"
fi

echo ""
echo "$(date +%Y-%m-%d) | glue=${glue_lines} (${glue_pct}%) | hors-types=${real_pct}% | business=${business_lines} (${business_pct}%) | total=${total}"
