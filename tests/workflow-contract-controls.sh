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
      # image: fabricated/container:latest
      - run: |
          echo 'uses: string/not-an-action@main'
          echo 'container: string/not-an-image:latest'
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - uses: ./local-action
YAML
bash "$root/scripts/lint-workflow-contracts.sh" > "$tmp/good"
grep -Fq 'Parsed 1 workflows' "$tmp/good"
cp "$fixture" "$tmp/original"
reject() {
  local marker=${1:-Unpinned action}
  local actual=0
  bash "$root/scripts/lint-workflow-contracts.sh" > "$tmp/result" 2>&1 || actual=$?
  [[ "$actual" == 1 ]] && grep -Fq "$marker" "$tmp/result" || { cat "$tmp/result" >&2; exit 1; }
  printf 'rejected: %s\n' "$marker"
  cp "$tmp/original" "$fixture"
}
accept() {
  bash "$root/scripts/lint-workflow-contracts.sh" > "$tmp/result" 2>&1 || { cat "$tmp/result" >&2; exit 1; }
  grep -Fq 'container image digests passed' "$tmp/result"
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

# The literals are fixtures for pin syntax, not claims about real image content.
export WORKFLOW_TEST_IMAGE='example/tool:V1@sha256:1111111111111111111111111111111111111111111111111111111111111111'
yq -i '.jobs.fixture.container = strenv(WORKFLOW_TEST_IMAGE)' "$fixture"
accept
yq -i '.jobs.fixture.container = {"image":strenv(WORKFLOW_TEST_IMAGE)}' "$fixture"
accept
yq -i '.jobs.fixture.services = {"db":{"image":strenv(WORKFLOW_TEST_IMAGE)}}' "$fixture"
accept
yq -i '.jobs.fixture.services = {}' "$fixture"
accept
for expression in \
  '.jobs.fixture.container = "example/tool:latest"' \
  '.jobs.fixture.container = {"image":"example/tool:v1"}' \
  '.jobs.fixture.services = {"db":{"image":"example/db:latest"}}' \
  '.jobs.fixture.container = "${{ matrix.image }}"' \
  '.jobs.fixture.container = "__container_population_complete__"' \
  '.jobs.fixture.container = "example/tool@sha256:abcd"'; do
  yq -i "$expression" "$fixture"
  reject 'Unpinned job or service container image'
done
for expression in \
  '.jobs.fixture.container = null' \
  '.jobs.fixture.container = {}' \
  '.jobs.fixture.container = {"image":[]}' \
  '.jobs.fixture.services = null' \
  '.jobs.fixture.services = {"db":{}}' \
  '.jobs.fixture.services = {"db":strenv(WORKFLOW_TEST_IMAGE)}' \
  '.jobs.fixture.container = strenv(WORKFLOW_TEST_IMAGE) + "\n" + strenv(WORKFLOW_TEST_IMAGE)'; do
  yq -i "$expression" "$fixture"
  reject 'Malformed job or service container'
done
yq -i '.jobs.fixture.steps += [{"uses":"docker://example/tool:latest"}]' "$fixture"
reject 'Unpinned container action'
yq -i '.jobs.fixture.steps += [{"uses":"docker://" + strenv(WORKFLOW_TEST_IMAGE)}]' "$fixture"
accept
yq -i '.jobs.fixture.steps += [{"uses":"./a/../b"}]' "$fixture"
reject 'Invalid local action path'
echo 'Workflow parser controls passed: action refs and job/service image pins checked; comments and run strings remain inert.'
