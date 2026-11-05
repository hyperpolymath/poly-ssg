#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
# Shared source-identity checks. Source this file; it never executes retained code.

preservation_scope_init() {
  local checker_dir entry metadata path
  checker_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  PRESERVED_IMPORT=${1:-9302dfcc3aedb7c52edf2867a2fcbf2c735878b4}
  PRESERVED_TREE=${2:-6a8aa93222c8261c3e81b37acd7d1bd59f42bdc4}
  bash "$checker_dir/verify-preservation.sh" "$PRESERVED_IMPORT" "$PRESERVED_TREE" || return 2
  SUBJECT_SHA=$(git rev-parse --verify HEAD) || return 2
  declare -gA PRESERVED_OBJECTS=() SUBJECT_OBJECTS=()
  local inventory
  inventory=$(mktemp) || return 2
  if ! git ls-tree -rz --full-tree "$PRESERVED_IMPORT" > "$inventory"; then
    rm -f -- "$inventory"; return 2
  fi
  while IFS= read -r -d '' entry; do
    metadata=${entry%%$'\t'*}; path=${entry#*$'\t'}
    PRESERVED_OBJECTS["$path"]=$metadata
  done < "$inventory"
  if ! git ls-tree -rz --full-tree "$SUBJECT_SHA" > "$inventory"; then
    rm -f -- "$inventory"; return 2
  fi
  while IFS= read -r -d '' entry; do
    metadata=${entry%%$'\t'*}; path=${entry#*$'\t'}
    SUBJECT_OBJECTS["$path"]=$metadata
  done < "$inventory"
  rm -f -- "$inventory"
  (( ${#PRESERVED_OBJECTS[@]} > 0 && ${#SUBJECT_OBJECTS[@]} > 0 ))
}

preserved_source_area() {
  # Explicit unsupported source areas from docs/RETENTION-PLAN.adoc.
  # Current automation, scripts, policy, documentation and configuration do
  # not acquire an exemption merely because an old copy exists in the import.
  case "$1" in
    engines/*|satellites/*|casket-ssg/*|src/*|lib/*|public/*|content/*|mcp/*|lsp/*|test-corpus/*|sites-build/*) return 0 ;;
    *) return 1 ;;
  esac
}

preserved_source_matches() {
  local path=$1 old current
  [[ -n "$path" && "$path" != /* && "$path" != *$'\n'* && "$path" != *$'\r'* ]] || return 1
  case "/$path/" in
    */../*|*/./*|*//*|*%*|*\\*) return 1 ;;
    *) ;; # A canonical relative path proceeds to exact object comparison.
  esac
  preserved_source_area "$path" || return 1
  old=${PRESERVED_OBJECTS["$path"]-}; current=${SUBJECT_OBJECTS["$path"]-}
  [[ -n "$old" && "$old" == "$current" && "$old" =~ ^100(644|755)\ blob\ [0-9a-f]{40}$ ]]
}
