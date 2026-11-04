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
retained_path=engines/example/archive.py
active_path=scripts/active.sh
printf '%s\n' '# retained source fixture' > "$retained_path"
printf '%s\n' '# active automation fixture' > "$active_path"
git add .; git commit -qm import
base=$(git rev-parse HEAD); tree=$(git rev-parse HEAD^{tree})
object_violation='VIOLATION: prohibited source object differs in path, blob, mode or retained area'
current_finding='current or unqualified finding(s)'
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
printf '%s\n' '# changed historical source' >> "$retained_path"
git add .; git commit -qm changed
expect 1 "$object_violation" "${policy[@]}"
git reset --hard -q "$base"
cp "$retained_path" engines/example/new.py
git add .; git commit -qm copied
expect 1 "$object_violation" "${policy[@]}"
git reset --hard -q "$base"
chmod +x "$retained_path"
git add .; git commit -qm mode
expect 1 "$object_violation" "${policy[@]}"
git reset --hard -q "$base"
git mv "$retained_path" scripts/relocated.py
git commit -qm moved
expect 1 "$object_violation" "${policy[@]}"
git reset --hard -q "$base"
expect 2 'imported tree differs' bash "$root/scripts/check-preserved-language-policy.sh" "$base" "0000000000000000000000000000000000000000"
# Record the actual limit: an allowed wrapper does not alter a retained source
# object. This gate must not claim it proved the wrapper cannot execute it.
printf '%s\n' '#!/usr/bin/env bash' 'python engines/example/archive.py' > scripts/wrapper.sh
git add .; git commit -qm wrapper
expect 0 'Execution references and activation are not analyzed' "${policy[@]}"
grep -Fq 'historical=1 violations=0' "$tmp/output"
git reset --hard -q "$base"

sarif="$tmp/result.sarif"
make_result() {
  local tool=$1 rule=$2 uri=$3 message=${4:-fixture finding}
  jq -n --arg tool "$tool" --arg rule "$rule" --arg uri "$uri" --arg message "$message" \
    '{version:"2.1.0",runs:[{tool:{driver:{name:$tool}},results:[{ruleId:$rule,level:"warning",message:{text:$message},locations:[{physicalLocation:{artifactLocation:{uri:$uri}}}]}]}]}' > "$sarif"
}
review=(bash "$root/scripts/review-preservation-sarif.sh")
export SCORECARD_ANALYSIS_SCOPE=checked-out-subject
make_result CodeQL fixture "$retained_path"
original=$(sha256sum "$sarif")
expect 0 'Exact retained source' "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
[[ $(sha256sum "$sarif") == "$original" ]]
jq -e '.counts.total == 1 and .counts.retained_historical == 1 and .security_clean_claim == false' "$tmp/receipt.json" >/dev/null
make_result CodeQL fixture "$active_path"
expect 1 "$current_finding" "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
make_result CodeQL fixture ../engines/example/archive.py
expect 1 "$current_finding" "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
make_result CodeQL fixture "$retained_path"
printf '%s\n' '# current mutation' >> "$retained_path"
git add .; git commit -qm current
expect 1 "$current_finding" "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
git reset --hard -q "$base"
make_result Scorecard FuzzingID 'no file associated with this alert' 'score is 0: project is not fuzzed: fixture'
expect 0 'Preservation advisory' "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
jq -e '.counts.preservation_advisory == 1 and .counts.actionable == 0' "$tmp/receipt.json" >/dev/null
make_result Scorecard SecurityPolicyID 'no file associated with this alert'
expect 1 "$current_finding" "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
make_result Scorecard FuzzingID 'no file associated with this alert' 'a different failure'
expect 1 "$current_finding" "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
make_result Scorecard fixture "$retained_path"
SCORECARD_ANALYSIS_SCOPE=remote-default-branch expect 1 "$current_finding" "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
jq -e '.analysis_subject_sha == null and .analysis_scope == "remote-default-branch"' "$tmp/receipt.json" >/dev/null

extend_result() {
  local expression=$1 uri=${2:-$active_path}
  jq --arg uri "$uri" 'def loc: {physicalLocation:{artifactLocation:{uri:$uri}}};
    .runs[0].results[0] |= ('"$expression"')' "$sarif" > "$tmp/extended.sarif"
  mv "$tmp/extended.sarif" "$sarif"
}
review_source_fixture() {
  local status=$1 marker=$2
  local before
  before=$(sha256sum "$sarif")
  expect "$status" "$marker" "${review[@]}" codeql "$sarif" "$tmp/receipt" "$base" "$tree"
  [[ $(sha256sum "$sarif") == "$before" ]]
  jq -e --slurpfile raw "$sarif" \
    '[.findings[].result] == [$raw[0].runs[].results[]]' "$tmp/receipt.json" >/dev/null
}

# Every supported source-bearing shape gets both a retained-source positive
# and a mixed current/historical negative. Primary locations alone are not enough.
while IFS= read -r expression; do
  printf 'location control: %s\n' "$expression"
  make_result CodeQL fixture "$retained_path"
  extend_result "$expression" "$retained_path"
  review_source_fixture 0 'Exact retained source'
  jq -e '.findings[0].location_evidence.complete and (.findings[0].location_evidence.artifact_locations | length > 1)' "$tmp/receipt.json" >/dev/null
  make_result CodeQL fixture "$retained_path"
  extend_result "$expression" "$active_path"
  review_source_fixture 1 "$current_finding"
done <<'JQ'
.relatedLocations=[loc]
.analysisTarget={uri:$uri}
.codeFlows=[{threadFlows:[{locations:[{location:loc}]}]}]
.codeFlows=[{threadFlows:[{locations:[{location:.locations[0],stack:{frames:[{location:loc}]}}]}]}]
.stacks=[{frames:[{location:loc}]}]
.graphs=[{nodes:[{id:"parent",children:[{id:"child",location:loc}]}]}]
.fixes=[{artifactChanges:[{artifactLocation:{uri:$uri},replacements:[]}]}]
.attachments=[{artifactLocation:{uri:$uri}}]
.suppressions=[{kind:"inSource",location:loc}]
.provenance={conversionSources:[loc.physicalLocation]}
JQ

# An unsupported/missing secondary reference must not disappear from traversal.
while IFS= read -r expression; do
  printf 'unresolved location control: %s\n' "$expression"
  make_result CodeQL fixture "$retained_path"
  extend_result "$expression"
  review_source_fixture 1 "$current_finding"
  jq -e '.findings[0].location_evidence.complete == false' "$tmp/receipt.json" >/dev/null
done <<'JQ'
.relatedLocations=[{}]
.relatedLocations=[{logicalLocations:[{name:"unknown"}]}]
.relatedLocations=[{physicalLocation:{artifactLocation:{index:0}}}]
.relatedLocations=[{physicalLocation:{artifactLocation:{uri:$uri,uriBaseId:"UNKNOWN"}}}]
.relatedLocations=null
.locations[0].physicalLocation.artifactLocation.index=0
.locations[0].physicalLocation.address={index:0}
.locations[0].relationships=[{target:9}]
.codeFlows=[{threadFlows:[{locations:[{index:0}]}]}]
.codeFlows=[{threadFlows:[]}]
.stacks=[{frames:[{}]}]
.fixes=[{artifactChanges:[{}]}]
.attachments=[{}]
.graphs=[{nodes:[{id:"unknown"}]}]
.graphTraversals=[{runGraphIndex:0}]
.properties={sourceLocation:loc}
.customLocation=loc
.relatedLocations=[{physicalLocation:{artifactLocation:{uri:"engines/example/archive.py\nother"}}}]
JQ

make_result Scorecard FuzzingID 'no file associated with this alert' 'score is 0: project is not fuzzed: fixture'
extend_result '.relatedLocations=[loc]'
expect 1 "$current_finding" "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
make_result Scorecard FuzzingID 'no file associated with this alert' 'score is 0: project is not fuzzed: fixture'
extend_result '.locations=[]'
expect 1 "$current_finding" "${review[@]}" scorecard "$sarif" "$tmp/receipt" "$base" "$tree"
make_result CodeQL fixture "$retained_path"
jq '.runs[0].invocations=[{executionSuccessful:false}]' "$sarif" > "$tmp/bad.sarif"
expect 2 'Malformed, failed or mismatched' "${review[@]}" codeql "$tmp/bad.sarif" "$tmp/receipt" "$base" "$tree"
expect 2 'Malformed, failed or mismatched' "${review[@]}" semgrep "$sarif" "$tmp/receipt" "$base" "$tree"
jq '.runs[0].externalPropertyFileReferences={results:[{location:{uri:"external.sarif"}}]}' "$sarif" > "$tmp/bad.sarif"
expect 2 'Malformed, failed or mismatched' "${review[@]}" codeql "$tmp/bad.sarif" "$tmp/receipt" "$base" "$tree"
printf '{' > "$tmp/bad.sarif"
expect 2 'Malformed, failed or mismatched' "${review[@]}" codeql "$tmp/bad.sarif" "$tmp/receipt" "$base" "$tree"
expect 2 'Missing or unsafe SARIF input' "${review[@]}" codeql "$tmp/absent.sarif" "$tmp/receipt" "$base" "$tree"
echo 'Preservation policy and SARIF controls passed; synthetic fixtures do not qualify actual repository analysis.'
