#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
git -C "$scratch" init -q
git -C "$scratch" config user.name 'Preservation regression fixture'
git -C "$scratch" config user.email 'fixture@example.invalid'
git -C "$scratch" config commit.gpgsign false
printf 'retained source\n' > "$scratch/source.txt"
git -C "$scratch" add source.txt
git -C "$scratch" commit -qm 'fixture import'
import_commit=$(git -C "$scratch" rev-parse HEAD)
tree=$(git -C "$scratch" rev-parse 'HEAD^{tree}')
printf 'new documentation\n' > "$scratch/README"
git -C "$scratch" add README
git -C "$scratch" commit -qm 'fixture successor'
(cd "$scratch" && bash "$root/scripts/verify-preservation.sh" "$import_commit" "$tree")
reject() {
  local label=$1 expected=$2
  shift 2
  local rc=0
  (cd "$scratch" && bash "$root/scripts/verify-preservation.sh" "$@") >"$scratch/result" 2>&1 || rc=$?
  if (( rc != 1 )) || ! grep -Fq "$expected" "$scratch/result"; then
    printf 'FAIL: %s did not produce the expected rejection\n' "$label" >&2
    cat "$scratch/result" >&2
    exit 1
  fi
  printf 'PASS: rejected %s\n' "$label"
}
reject 'mutable import ref' 'immutable full Git object IDs' main "$tree"
reject 'missing import' 'preserved import is absent' 0000000000000000000000000000000000000000 "$tree"
reject 'wrong source tree' 'imported tree differs' "$import_commit" 0000000000000000000000000000000000000000
git -C "$scratch" checkout --orphan unrelated -q
git -C "$scratch" rm -rfq .
printf 'unrelated\n' > "$scratch/other"
git -C "$scratch" add other
git -C "$scratch" commit -qm 'unrelated history'
reject 'unrelated history' 'does not retain the preserved import' "$import_commit" "$tree"

