#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/docs"
cp -R "$root/docs/legacy-workflows" "$tmp/docs/"
cd "$tmp"
verifier=(bash "$root/scripts/verify-archived-workflows.sh")
"${verifier[@]}" > result
grep -Fq 'Verified 5 archived workflows' result
reject() {
  local marker=$1 status=0
  "${verifier[@]}" > result 2>&1 || status=$?
  if (( status != 1 )) || ! grep -Fq "$marker" result; then
    cat result >&2; echo 'Expected archive identity rejection was absent' >&2; exit 1
  fi
  printf 'rejected: %s\n' "$marker"
}
for path in docs/legacy-workflows/*.yml.txt; do
  printf '\n' >> "$path"
  reject "Archived workflow bytes differ from the original Git blob: $path"
  cp "$root/$path" "$path"
done
path=docs/legacy-workflows/ci.yml.txt
rm "$path"
reject "Archived workflow is missing or not a regular file: $path"
ln -s "$root/$path" "$path"
reject "Archived workflow is missing or not a regular file: $path"
echo 'Archive controls passed: original bytes accepted; appended bytes, missing files and symlinks rejected.'
