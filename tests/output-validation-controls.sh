#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
check() {
  local expected=$1 target=$2 rc=0
  bash "$root/scripts/validate-output.sh" "$target" >"$scratch/result" 2>&1 || rc=$?
  if (( rc != expected )); then
    printf 'FAIL: %s returned %s, expected %s\n' "$target" "$rc" "$expected" >&2
    cat "$scratch/result" >&2
    exit 1
  fi
}
printf '<!DOCTYPE html><html><head><title>Control</title></head><body><p>Safe &amp; plain.</p></body></html>\n' > "$scratch/safe.html"
check 0 "$scratch/safe.html"
printf 'plain text without counted tags\n' > "$scratch/plain.html"
check 0 "$scratch/plain.html"
printf '<p><script>alert(1)</script></p>\n' > "$scratch/script.html"
check 1 "$scratch/script.html"
printf '<p><img src="x" onerror="alert(1)" alt="x"></p>\n' > "$scratch/event.html"
check 1 "$scratch/event.html"
printf '<p><img src="x" onerror = "alert(1)" alt="x"></p>\n' > "$scratch/event-spaced.html"
check 1 "$scratch/event-spaced.html"
printf '<p><a href="javascript:alert(1)">link</a></p>\n' > "$scratch/url.html"
check 1 "$scratch/url.html"
{ printf '<p><script>alert(1)</script>'; head -c 262144 /dev/zero | tr '\000' x; printf '</p>\n'; } > "$scratch/large.html"
check 1 "$scratch/large.html"
printf '<p>nul\000byte</p>\n' > "$scratch/nul.html"
check 1 "$scratch/nul.html"
printf '<p>invalid\377</p>\n' > "$scratch/encoding.html"
check 1 "$scratch/encoding.html"
: > "$scratch/empty.html"
check 1 "$scratch/empty.html"
check 1 "$scratch/absent.html"
mkdir "$scratch/empty-directory"
check 1 "$scratch/empty-directory"
mkdir "$scratch/mixed-directory"
cp "$scratch/safe.html" "$scratch/mixed-directory/first safe.html"
cp "$scratch/script.html" "$scratch/mixed-directory/second unsafe.html"
check 1 "$scratch/mixed-directory"
grep -Fq '1 errors' "$scratch/result"
printf 'PASS: safe output accepted; empty, missing, injection, NUL, UTF-8 and directory controls rejected\n'
