#!/bin/bash
# Compare le ratio glue (hors-types) entre HEAD et une ref de base.
# Fail si la PR fait regresser le ratio de plus de TOLERANCE points.
#
# Usage : ./glue-ratio-check.sh
# Env optionnelle : TOLERANCE (defaut 0), BASE_REF (defaut origin/main)
#
# Place ce script et glue-ratio.sh dans scripts/ de ton projet,
# et appelle-le depuis ta CI (voir ci-workflow.yml).

set -euo pipefail

TOLERANCE="${TOLERANCE:-0}"
BASE_REF="${BASE_REF:-origin/main}"

cd "$(dirname "$0")/.."

# Ratio courant (HEAD)
current=$(bash scripts/glue-ratio.sh --metric)

# Ratio sur la base de comparaison — on extrait uniquement lib/ de la base
# puis on mesure avec le script de HEAD (qui sait gerer --metric).
# Cela evite les faux positifs si le script a evolue.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/scripts"
cp scripts/glue-ratio.sh "$tmp/scripts/"
git archive "$BASE_REF" lib/ | tar -x -C "$tmp"

base=$(cd "$tmp" && bash scripts/glue-ratio.sh --metric)

delta=$((current - base))

echo "Glue ratio (hors types)"
echo "  Base ($BASE_REF): ${base}%"
echo "  HEAD:             ${current}%"
echo "  Delta:            $([ "$delta" -ge 0 ] && echo "+")${delta} pts"
echo "  Tolerance:        +${TOLERANCE} pts"

if [ "$delta" -gt "$TOLERANCE" ]; then
  echo ""
  echo "ECHEC: le ratio glue a augmente de ${delta} pts (tolerance +${TOLERANCE})."
  echo "Verifier si :"
  echo "  - du glue peut etre extrait dans lib/mappings/ ou lib/adapters/"
  echo "  - un nouveau fichier est mal categorise dans scripts/glue-ratio.sh"
  echo "  - de la logique metier est ajoutee en face pour equilibrer"
  exit 1
fi

if [ "$delta" -lt 0 ]; then
  echo ""
  echo "OK: ratio en baisse, glue extrait ou business etoffe."
else
  echo ""
  echo "OK: ratio stable."
fi
