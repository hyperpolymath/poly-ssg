#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
# Preserve exact historical objects; reject newly introduced prohibited source.
set -euo pipefail
(( $# == 0 || $# == 2 )) || { echo 'usage: check-preserved-language-policy.sh [import-commit expected-tree]' >&2; exit 2; }
source "$(dirname -- "${BASH_SOURCE[0]}")/preservation-scope.sh"
preservation_scope_init "$@" || exit 2
historical=0
violations=0
for path in "${!SUBJECT_OBJECTS[@]}"; do
  case "$path" in
    *.d.ts) continue ;;
    *.ts|*.tsx|*.go|*.py|*.java|*.kt|*.kts|*.swift|*.dart|package-lock.json|*/package-lock.json|yarn.lock|*/yarn.lock|pnpm-lock.yaml|*/pnpm-lock.yaml|tsconfig.json|*/tsconfig.json) ;;
    *) continue ;;
  esac
  if preserved_source_matches "$path"; then
    printf 'HISTORICAL unsupported source: %s [%s]\n' "$path" "${SUBJECT_OBJECTS["$path"]}"
    historical=$((historical + 1))
  else
    printf 'VIOLATION: new, changed, relocated or active prohibited source: %s\n' "$path" >&2
    violations=$((violations + 1))
  fi
done
printf 'Language preservation check: subject=%s historical=%s violations=%s\n' "$SUBJECT_SHA" "$historical" "$violations"
echo 'Historical means exact retained source, not current language approval or runtime/security qualification.'
if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
  printf '### Language preservation scope\n\nSubject: `%s`\n\nRetained prohibited-language objects: **%s**. New/changed violations: **%s**. Historical objects remain unsupported.\n' \
    "$SUBJECT_SHA" "$historical" "$violations" >> "$GITHUB_STEP_SUMMARY"
fi
(( violations == 0 ))
