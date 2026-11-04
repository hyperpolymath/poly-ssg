#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Fixture GIT_COMMITTER_NAME=Fixture
export GIT_AUTHOR_EMAIL=fixture@example.invalid GIT_COMMITTER_EMAIL=fixture@example.invalid
git init -q "$tmp/repo"
cd "$tmp/repo"
mkdir -p engines/example scripts
printf '%s\n' '# retained source fixture' > engines/example/archive.py
printf '%s\n' '# active automation fixture' > scripts/active.sh
git add .; git commit -qm import
base=$(git rev-parse HEAD); tree=$(git rev-parse HEAD^{tree})
expect() {
  local wanted=$1 marker=$2; shift 2
  local actual=0
  "$@" > "$tmp/output" 2>&1 || actual=$?
  if [[ "$actual" != "$wanted" ]] || ! grep -Fq -- "$marker" "$tmp/output"; then
    cat "$tmp/output" >&2; printf 'Expected status %s and marker %s, got %s\n' "$wanted" "$marker" "$actual" >&2; exit 1
  fi
  printf 'ok: %s\n' "$marker"
}
policy=(bash "$root/scripts/check-preserved-language-policy.sh" "$base" "$tree")
expect 0 'historical=1 violations=0' "${policy[@]}"
printf '%s\n' '# changed historical source' >> engines/example/archive.py
git add .; git commit -qm changed
expect 1 'VIOLATION: new, changed, relocated or active prohibited source' "${policy[@]}"
git reset --hard -q "$base"
cp engines/example/archive.py engines/example/new.py
git add .; git commit -qm copied
expect 1 'VIOLATION: new, changed, relocated or active prohibited source' "${policy[@]}"
git reset --hard -q "$base"
chmod +x engines/example/archive.py
git add .; git commit -qm mode
expect 1 'VIOLATION: new, changed, relocated or active prohibited source' "${policy[@]}"
git reset --hard -q "$base"
git mv engines/example/archive.py scripts/relocated.py
git commit -qm moved
expect 1 'VIOLATION: new, changed, relocated or active prohibited source' "${policy[@]}"
git reset --hard -q "$base"
expect 2 'imported tree differs' bash "$root/scripts/check-preserved-language-policy.sh" "$base" "0000000000000000000000000000000000000000"

sarif="$tmp/result.sarif"
make_result() {
  jq -n --arg tool "$1" --arg rule "$2" --arg uri "$3" --arg message "${4:-fixture finding}" \
    '{version:"2.1.0",runs:[{tool:{driver:{name:$tool}},results:[{ruleId:$rule,level:"warning",message:{text:$message},locations:[{physicalLocation:{artifactLocation:{uri:$uri}}}]}]}]}' > "$sarif"
}
review=(bash "$root/scripts/review-preservation-sarif.sh")
export SCORECARD_ANALYSIS_SCOPE=checked-out-subject
make_result CodeQL fixture engines/example/archive.py
original=$(sha256sum "$sarif")
expect 0 'Exact retained source' "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
[[ $(sha256sum "$sarif") == "$original" ]]
jq -e '.counts.total == 1 and .counts.retained_historical == 1 and .security_clean_claim == false' "$tmp/receipt.json" >/dev/null
make_result CodeQL fixture scripts/active.sh
expect 1 'current or unqualified finding(s)' "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
make_result CodeQL fixture ../engines/example/archive.py
expect 1 'current or unqualified finding(s)' "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
make_result CodeQL fixture engines/example/archive.py
printf '%s\n' '# current mutation' >> engines/example/archive.py
git add .; git commit -qm current
expect 1 'current or unqualified finding(s)' "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
git reset --hard -q "$base"
make_result Scorecard FuzzingID 'no file associated with this alert' 'score is 0: project is not fuzzed: fixture'
expect 0 'Preservation advisory' "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
jq -e '.counts.preservation_advisory == 1 and .counts.actionable == 0' "$tmp/receipt.json" >/dev/null
make_result Scorecard SecurityPolicyID 'no file associated with this alert'
expect 1 'current or unqualified finding(s)' "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
make_result Scorecard FuzzingID 'no file associated with this alert' 'a different failure'
expect 1 'current or unqualified finding(s)' "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
make_result Scorecard fixture engines/example/archive.py
SCORECARD_ANALYSIS_SCOPE=remote-default-branch expect 1 'current or unqualified finding(s)' "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
jq -e '.analysis_subject_sha == null and .analysis_scope == "remote-default-branch"' "$tmp/receipt.json" >/dev/null
make_result CodeQL fixture engines/example/archive.py
jq '.runs[0].invocations=[{executionSuccessful:false}]' "$sarif" > "$tmp/bad.sarif"
expect 2 'Malformed, failed or mismatched' "${review[@]}" codeql "$tmp/bad.sarif" "$tmp/receipt" "$base" "$tree"
expect 2 'Malformed, failed or mismatched' "${review[@]}" semgrep "$sarif" "$tmp/receipt" "$base" "$tree"
printf '{' > "$tmp/bad.sarif"
expect 2 'Malformed, failed or mismatched' "${review[@]}" codeql "$tmp/bad.sarif" "$tmp/receipt" "$base" "$tree"
expect 2 'Missing or unsafe SARIF input' "${review[@]}" codeql "$tmp/absent.sarif" "$tmp/receipt" "$base" "$tree"
echo 'Preservation policy and SARIF controls passed; synthetic fixtures do not qualify actual repository analysis.'
