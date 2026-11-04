#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
command -v yq >/dev/null || { echo 'yq is required to parse actual workflow keys' >&2; exit 2; }
shopt -s nullglob
files=(.github/workflows/*.yml .github/workflows/*.yaml)
(( ${#files[@]} > 0 )) || { echo 'No workflow population' >&2; exit 2; }
failed=0
refs=$(mktemp)
trap 'rm -f -- "$refs"' EXIT
for file in "${files[@]}"; do
  IFS= read -r first < "$file"
  [[ "$first" == '# SPDX-License-Identifier:'* ]] || { echo "Missing SPDX header: $file" >&2; failed=1; }
  if ! yq -e 'has("permissions") and (.jobs | tag == "!!map")' "$file" >/dev/null; then
    echo "Malformed workflow or missing permission declaration: $file" >&2; failed=1; continue
  fi
  if ! yq -r '([.jobs[] | select(has("uses")) | .uses] + [.jobs[].steps[]? | select(has("uses")) | .uses]) | .[]' "$file" > "$refs"; then
    echo "Cannot enumerate workflow uses: $file" >&2; failed=1; continue
  fi
  while IFS= read -r ref; do
    if [[ "$ref" == ./* ]]; then
      case "/${ref#./}/" in */../*|*/./*|*//*) echo "Invalid local action path: $file" >&2; failed=1 ;; esac
    elif [[ "$ref" == docker://* ]]; then
      [[ "$ref" =~ ^docker://[^[:space:]@]+@sha256:[0-9a-f]{64}$ ]] || { echo "Unpinned container action: $file" >&2; failed=1; }
    elif [[ ! "$ref" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/[A-Za-z0-9_./-]+)?@[0-9a-f]{40}$ ]]; then
      printf 'Unpinned action or reusable workflow in %s: %s\n' "$file" "$ref" >&2; failed=1
    fi
  done < "$refs"
done
if [[ -f .github/workflows/codeql.yml && -f .github/workflows/codeql-analysis.yml ]]; then
  echo 'Duplicate CodeQL entry points require review' >&2; failed=1
fi
(( failed == 0 )) || exit 1
printf 'Parsed %s workflows: SPDX, explicit permissions and complete action pins passed.\n' "${#files[@]}"
