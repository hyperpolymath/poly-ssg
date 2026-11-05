#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0-or-later
# Keep complete SARIF. Classify findings; never rewrite or suppress a result.
set -euo pipefail
if (( $# != 3 && $# != 5 )); then
  echo 'usage: review-preservation-sarif.sh reporter input.sarif output-prefix [import-commit expected-tree]' >&2
  exit 2
fi
reporter=$1; input=$2; output=$3; shift 3
case "$reporter" in codeql|semgrep|scorecard) ;; *) echo 'Unknown reporter' >&2; exit 2 ;; esac
analysis_scope=checked-out-subject
if [[ "$reporter" == scorecard ]]; then
  case "${SCORECARD_ANALYSIS_SCOPE:-}" in
    checked-out-subject|remote-default-branch) analysis_scope=$SCORECARD_ANALYSIS_SCOPE ;;
    *) echo 'Scorecard analysis scope must be declared from the workflow event' >&2; exit 2 ;;
  esac
fi
command -v jq >/dev/null || { echo 'jq is required' >&2; exit 2; }
checker_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$checker_dir/preservation-scope.sh"
preservation_scope_init "$@" || exit 2
[[ -f "$input" && ! -L "$input" && -s "$input" ]] || { echo 'Missing or unsafe SARIF input' >&2; exit 2; }
if ! jq -se --arg reporter "$reporter" '
  length == 1 and (.[0] |
    .version == "2.1.0" and (.runs | type == "array" and length > 0) and
    (.inlineExternalProperties == null or .inlineExternalProperties == []) and
    all(.runs[];
      (.tool.driver.name | type == "string" and length > 0) and
      (if $reporter == "codeql" then .tool.driver.name == "CodeQL"
       elif $reporter == "scorecard" then .tool.driver.name == "Scorecard"
       else (.tool.driver.name | ascii_downcase | startswith("semgrep")) end) and
      (.results | type == "array") and
      (.externalPropertyFileReferences == null or .externalPropertyFileReferences == {}) and
      all(.invocations[]?; .executionSuccessful == true and
        all(.toolExecutionNotifications[]?; .level != "error")) and
      all(.results[];
        (.ruleId | type == "string" and length > 0) and
        (.message | type == "object") and
        ((.message.text // .message.markdown) | type == "string") and
        (.level == null or (.level as $l | ["error","warning","note","none"] | index($l) != null)) and
        (.locations == null or (.locations | type == "array")))))
' "$input" >/dev/null; then
  echo 'Malformed, failed or mismatched SARIF analysis; no passing result can be inferred' >&2
  exit 2
fi
mkdir -p -- "$(dirname -- "$output")"
rows=$(mktemp); results=$(mktemp)
trap 'rm -f -- "$rows" "$results"' EXIT
jq -c '.runs[] | .results[]' "$input" > "$results"
total=0; historical=0; advisory=0; actionable=0
while IFS= read -r result; do
  total=$((total + 1))
  rule=$(jq -r '.ruleId' <<< "$result")
  disposition=actionable
  reason='Current, changed, unlocated or unqualified source requires review.'
  if ! locations=$(jq -c -f "$checker_dir/preservation-sarif-locations.jq" <<< "$result"); then
    echo 'Cannot evaluate complete SARIF location evidence' >&2; exit 2
  fi
  location_count=$(jq '.artifact_locations | length' <<< "$locations")
  if [[ $(jq -r '.complete' <<< "$locations") != true ]]; then
    reason="Unqualified location evidence: $(jq -r '.reason' <<< "$locations")"
  fi
  # Only this observed repository-level condition has a staging disposition.
  # Missing security policy and every other Scorecard rule remain actionable.
  if [[ "$reporter" == scorecard && "$rule" == FuzzingID ]] &&
    jq -e '(.message.text | startswith("score is 0: project is not fuzzed:")) and
      (.locations | type == "array" and length > 0)' <<< "$result" >/dev/null &&
    jq -e '.complete and (.artifact_locations | length > 0 and all(.[]; .uri == "no file associated with this alert"))' <<< "$locations" >/dev/null; then
    disposition=preservation-advisory
    reason='No supported executable release is provided by this preservation repository; no fuzzing qualification is claimed. A selected runtime successor must qualify its own fuzzing.'
    advisory=$((advisory + 1))
  elif [[ "$analysis_scope" == checked-out-subject ]] && (( location_count > 0 )); then
    all_preserved=true
    for (( index=0; index<location_count; index++ )); do
      if ! path=$(jq -er --argjson i "$index" '.artifact_locations[$i].uri' <<< "$locations"); then
        all_preserved=false; break
      fi
      path=${path#./}
      if ! preserved_source_matches "$path"; then all_preserved=false; break; fi
    done
    if [[ "$all_preserved" == true ]]; then
      disposition=retained-historical-source
      reason='Every reported location is an enumerated unsupported source area with exactly the imported Git path, blob and file mode. The finding is retained, not fixed or declared false.'
      historical=$((historical + 1))
    fi
  fi
  [[ "$disposition" != actionable ]] || actionable=$((actionable + 1))
  jq -cn --arg reporter "$reporter" --arg disposition "$disposition" --arg reason "$reason" \
    --argjson locations "$locations" --argjson result "$result" \
    '{reporter:$reporter,disposition:$disposition,reason:$reason,location_evidence:$locations,result:$result}' >> "$rows"
done < "$results"
jq -s --arg reporter "$reporter" --arg subject "$SUBJECT_SHA" --arg import "$PRESERVED_IMPORT" \
  --arg analysis_scope "$analysis_scope" \
  --arg input_sha256 "$(sha256sum "$input" | cut -d ' ' -f 1)" \
  --argjson total "$total" --argjson historical "$historical" --argjson advisory "$advisory" --argjson actionable "$actionable" \
  '{schema_version:1,reporter:$reporter,checked_out_subject_sha:$subject,import_sha:$import,
    analysis_scope:$analysis_scope,analysis_subject_sha:(if $analysis_scope == "checked-out-subject" then $subject else null end),
    raw_sarif_sha256:$input_sha256,hosted_upload:"unavailable-private-repository",
    security_clean_claim:false,counts:{total:$total,retained_historical:$historical,preservation_advisory:$advisory,actionable:$actionable},findings:.}' \
  "$rows" > "$output.json"
{
  printf '### %s analysis disposition\n\n' "$reporter"
  printf 'Checkout: `%s`. Analysis scope: `%s`. Raw SARIF is retained unchanged in the workflow artifact.\n\n' "$SUBJECT_SHA" "$analysis_scope"
  if [[ "$analysis_scope" == remote-default-branch ]]; then
    printf 'Scorecard queried the remote default branch; its precise analyzed commit is not supplied by this action. Checkout identity is not asserted as analysis identity, and source findings cannot receive the historical-file disposition.\n\n'
  fi
  printf '| Total | Exact retained source | Preservation advisory | Current or unqualified |\n| ---: | ---: | ---: | ---: |\n| %s | %s | %s | %s |\n\n' "$total" "$historical" "$advisory" "$actionable"
  printf 'Hosted code-scanning upload is unavailable for this private repository. This is a preservation disposition, not a clean-security or supported-runtime attestation.\n'
} > "$output.md"
cat "$output.md"
[[ -z ${GITHUB_STEP_SUMMARY:-} ]] || cat "$output.md" >> "$GITHUB_STEP_SUMMARY"
(( actionable == 0 )) || { echo "::error::$reporter has $actionable current or unqualified finding(s); inspect the complete SARIF and disposition artifact" >&2; exit 1; }
