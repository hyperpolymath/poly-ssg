#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
# Verify retained source identity and ancestry. This is not runtime qualification.
set -euo pipefail

if (( $# > 2 )); then
  echo 'usage: verify-preservation.sh [import-commit expected-tree]' >&2
  exit 2
fi
import_commit="${1:-9302dfcc3aedb7c52edf2867a2fcbf2c735878b4}"
expected_tree="${2:-6a8aa93222c8261c3e81b37acd7d1bd59f42bdc4}"
if [[ ! "$import_commit" =~ ^[0-9a-f]{40}$ || ! "$expected_tree" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'FAIL: preservation requires immutable full Git object IDs' >&2
  exit 1
fi
if ! actual_tree=$(git rev-parse --verify "$import_commit^{tree}"); then
  echo 'FAIL: preserved import is absent; fetch full repository history' >&2
  exit 1
fi
if [[ "$actual_tree" != "$expected_tree" ]]; then
  echo 'FAIL: imported tree differs from the recorded source tree' >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$import_commit" HEAD; then
  echo 'FAIL: current branch does not retain the preserved import in its ancestry' >&2
  exit 1
fi
git fsck --connectivity-only --no-dangling --no-reflogs "$import_commit"
printf 'PASS: retained import %s has source tree %s and is an ancestor of %s\n' \
  "$import_commit" "$actual_tree" "$(git rev-parse HEAD)"

