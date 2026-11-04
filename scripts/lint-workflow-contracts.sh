#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
command -v yq >/dev/null || { echo 'yq is required to parse actual workflow keys' >&2; exit 2; }
command -v jq >/dev/null || { echo 'jq is required to inspect parsed container definitions' >&2; exit 2; }
shopt -s nullglob
files=(.github/workflows/*.yml .github/workflows/*.yaml)
(( ${#files[@]} > 0 )) || { echo 'No workflow population' >&2; exit 2; }
failed=0
refs=$(mktemp)
parsed=$(mktemp)
images=$(mktemp)
trap 'rm -f -- "$refs" "$parsed" "$images"' EXIT
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
      case "/${ref#./}/" in
        */../*|*/./*|*//*) echo "Invalid local action path: $file" >&2; failed=1 ;;
        *) ;; # A canonical local path requires no remote version pin.
      esac
    elif [[ "$ref" == docker://* ]]; then
      [[ "$ref" =~ ^docker://[^[:space:]@]+@sha256:[0-9a-f]{64}$ ]] || { echo "Unpinned container action: $file" >&2; failed=1; }
    elif [[ ! "$ref" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/[A-Za-z0-9_./-]+)?@[0-9a-f]{40}$ ]]; then
      printf 'Unpinned action or reusable workflow in %s: %s\n' "$file" "$ref" >&2; failed=1
    fi
  done < "$refs"
  if ! yq -o=json '.' "$file" > "$parsed" ||
    ! jq -r '
      def image:
        if type == "string" and length > 0 and (test("[\u0000-\u001f\u007f]") | not) then .
        else error("container image is missing or malformed") end;
      def service_image:
        if type == "object" then .image | image
        else error("service container is not an object") end;
      [.jobs[] |
        (if has("container") then .container |
          if type == "string" then image else service_image end
         else empty end),
        (if has("services") then .services |
          if type == "object" then .[] | service_image
          else error("services is not a map") end
         else empty end)] | .[]
    ' "$parsed" > "$images"; then
    echo "Malformed job or service container: $file" >&2; failed=1; continue
  fi
  while IFS= read -r image; do
    if [[ ! "$image" =~ ^[A-Za-z0-9][A-Za-z0-9._:/-]*@sha256:[0-9a-f]{64}$ ]]; then
      echo "Unpinned job or service container image: $file" >&2; failed=1
    fi
  done < "$images"
done
if [[ -f .github/workflows/codeql.yml && -f .github/workflows/codeql-analysis.yml ]]; then
  echo 'Duplicate CodeQL entry points require review' >&2; failed=1
fi
(( failed == 0 )) || exit 1
printf 'Parsed %s workflows: SPDX, explicit permissions, action pins and container image digests passed.\n' "${#files[@]}"
