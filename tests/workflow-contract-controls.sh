#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/.github/workflows"
cd "$tmp"
fixture=.github/workflows/fixture.yml
cat > "$fixture" <<'YAML'
# SPDX-License-Identifier: MPL-2.0-or-later
name: fixture
on: push
permissions:
  contents: read
jobs:
  fixture:
    runs-on: ubuntu-24.04
    steps:
      # uses: fabricated/comment@main
      - run: |
          echo 'uses: string/not-an-action@main'
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - uses: ./local-action
YAML
bash "$root/scripts/lint-workflow-contracts.sh" > "$tmp/good"
grep -Fq 'Parsed 1 workflows' "$tmp/good"
cp "$fixture" "$tmp/original"
reject() {
  local actual=0
  bash "$root/scripts/lint-workflow-contracts.sh" > "$tmp/result" 2>&1 || actual=$?
  [[ "$actual" == 1 ]] && grep -Fq 'Unpinned action' "$tmp/result" || { cat "$tmp/result" >&2; exit 1; }
  cp "$tmp/original" "$fixture"
}
sed -i 's/@3d3c42e5aac5ba805825da76410c181273ba90b1/@main/' "$fixture"
reject
sed -i 's/@3d3c42e5aac5ba805825da76410c181273ba90b1/@3d3c42e5aac5ba805825da76410c181273ba90b1extra/' "$fixture"
reject
sed -i 's|actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1|actions/github-script@main|' "$fixture"
reject
cat >> "$fixture" <<'YAML'
  reusable:
    uses: example/source/.github/workflows/check.yml@main
YAML
reject
echo 'Workflow parser controls passed: actual unpinned refs rejected; comments and run strings are not action refs.'
