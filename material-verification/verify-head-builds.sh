#!/usr/bin/env bash
# verify-head-builds.sh
#
# Verify that the git HEAD compiles cleanly — without working copy
# contamination. Run BEFORE any `git push origin main` to catch
# inconsistent commits (consumers up to date but exports missing in
# non-staged files).
#
# Source article: Why "green build" without the raw output has zero
# evidentiary value (DEV.to / @michelfaure)
#
# Why this exists
# ---------------
# A typecheck on the working copy passes when local files contain
# exports that aren't yet committed. The pushed HEAD is missing those
# exports, builds break, CI is red. This script does the typecheck on
# HEAD only by stashing local changes first, then restoring them.
#
# A subtle bug in earlier versions: `git stash pop -q 2>/dev/null` in
# the trap was masking pop failures, leaving the working tree silently
# wiped. Fixed by removing 2>/dev/null, adding --index to preserve the
# staging area, and exiting 2 with explicit recovery instructions if
# pop fails.
#
# Usage
#   bash scripts/verify-head-builds.sh
#
# Exit codes
#   0 — HEAD compiles cleanly, safe to push
#   1 — HEAD does not compile, inconsistent commit, FIX before push
#   2 — infrastructure error (stash/pop failed, see recovery hints)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null \
  || { echo "Not a git repo"; exit 2; })"
cd "$REPO_ROOT"

echo "→ HEAD: $(git rev-parse --short HEAD) — $(git log -1 --format='%s' | cut -c1-60)"

# Detect local changes (staged, unstaged, untracked)
HAS_LOCAL_CHANGES=0
if ! git diff --quiet HEAD 2>/dev/null \
   || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  HAS_LOCAL_CHANGES=1
fi

# Stash if needed
if [[ $HAS_LOCAL_CHANGES -eq 1 ]]; then
  echo "→ Working copy has local changes — temporary stash"
  git stash push -u -q --message "verify-head-builds-autostash-$$" || {
    echo "✗ Stash failed — abort"
    exit 2
  }
fi

# Cleanup trap: always restore the stash on exit
cleanup() {
  local ec=$?
  if [[ $HAS_LOCAL_CHANGES -eq 1 ]]; then
    if ! git stash pop --index -q; then
      echo "✗ git stash pop FAILED — stash KEPT in stash@{0}"
      echo ""
      echo "  Recovery:"
      echo "    git stash list                      # confirm presence"
      echo "    git stash show -p stash@{0} --stat  # view contents"
      echo "    git stash apply --index stash@{0}   # retry (may show conflict)"
      echo "    git checkout stash@{0} -- <file>    # targeted file recovery"
      echo "    git stash drop stash@{0}            # cleanup once recovered"
      echo ""
      echo "  If stash lost (subsequent crash):"
      echo "    git fsck --no-reflogs --lost-found | grep 'dangling commit'"
      echo "    then filter by message 'verify-head-builds-autostash'"
      echo "    then git checkout <SHA> -- <file>"
      ec=2
    fi
  fi
  exit $ec
}
trap cleanup EXIT INT TERM

# Typecheck on pure HEAD (fast: ~10-30s, no full bundle build needed)
echo "→ Typecheck of HEAD (tsc --noEmit)…"
if npx tsc --noEmit 2>&1; then
  echo "✓ HEAD compiles cleanly — safe to push"
  HAS_LOCAL_CHANGES=$HAS_LOCAL_CHANGES  # forced for trap
  exit 0
else
  echo ""
  echo "✗ HEAD does NOT compile cleanly"
  echo ""
  echo "  Likely cause: staged files consume symbols exported by"
  echo "  NON-staged files (working copy contaminated)."
  echo ""
  echo "  Diagnosis:"
  echo "    1. List modified non-staged files: git status --short"
  echo "    2. Stage them if they belong to the commit, or amend the"
  echo "       previous commit to remove their consumers."
  exit 1
fi
