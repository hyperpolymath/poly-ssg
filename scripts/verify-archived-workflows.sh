#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
# Original Git blob IDs preserve exact bytes; they are object identity, not
# cryptographic security attestations. Parent commits are recorded in the ledger.
set -euo pipefail
(( $# == 0 )) || { echo 'usage: verify-archived-workflows.sh' >&2; exit 2; }
command -v git >/dev/null || { echo 'git is required for archive object identity' >&2; exit 2; }
failed=0
count=0
while read -r expected path; do
  count=$((count + 1))
  if [[ ! -f "$path" || -L "$path" ]]; then
    echo "Archived workflow is missing or not a regular file: $path" >&2
    failed=1; continue
  fi
  actual=$(git hash-object --no-filters -- "$path") || exit 2
  if [[ "$actual" != "$expected" ]]; then
    echo "Archived workflow bytes differ from the original Git blob: $path" >&2
    failed=1
  fi
done <<'BLOBS'
10835026204a248fd671748b2215b1bccc38a771 docs/legacy-workflows/ci.yml.txt
a865df41062cb761bbeb7a7f04b9e7e91e75deb5 docs/legacy-workflows/deploy-casket.yml.txt
8d4ed07ca40fb96dd5be39622a9614256d9b42a1 docs/legacy-workflows/deploy-ddraig.yml.txt
3c784538bf4c1b434ec913874ba4b45e7f91b185 docs/legacy-workflows/instant-sync.yml.txt
a7b1547af5637dacea5690deb0c1d492d7b56370 docs/legacy-workflows/mirror.yml.txt
BLOBS
(( failed == 0 )) || exit 1
printf 'Verified %s archived workflows against their exact original Git blobs.\n' "$count"
