# SPDX-License-Identifier: MPL-2.0-or-later
# SARIF 2.1.0 result source locations, including secondary evidence.
# Unsupported references remain actionable; this does not resolve cached,
# external, logical-only or extension-defined locations by guessing a file.

def object_value:
  if type == "object" then . else error("location object is missing or malformed") end;

def entries($key):
  if has($key) then
    .[$key] | if type == "array" then .[] else error($key + " is not an array") end
  else empty end;

def required_entries($key):
  if has($key) and (.[$key] | type == "array" and length > 0)
  then .[$key][] else error($key + " has no explicit entries") end;

def optional($key; parser):
  if has($key) then .[$key] | parser else empty end;

def no_cached_index:
  if has("index") and .index != -1 then error("cached location index is unresolved") else . end;

def artifact:
  object_value | no_cached_index |
  if (.uri | type == "string" and length > 0 and (test("[\u0000-\u001f\u007f]") | not)) and
     ((has("uriBaseId") | not) or .uriBaseId == "%SRCROOT%")
  then . else error("artifact URI or source base is missing or unsupported") end;

def physical:
  object_value |
  if has("address") then error("address-based source evidence is unsupported")
  else .artifactLocation | artifact end;

def location:
  object_value |
  # A logical name cannot qualify a physical file. Cached logical references
  # are also not silently resolved against a potentially different run.
  if any(entries("logicalLocations"); type != "object" or
      (has("index") and .index != -1) or (has("parentIndex") and .parentIndex != -1))
  then error("logical location reference is unresolved")
  elif has("relationships") and (.relationships | type != "array" or length > 0)
  then error("location relationship references are unresolved")
  else .physicalLocation | physical end;

def stack:
  object_value | required_entries("frames") | object_value | .location | location;

def flow_location:
  object_value | no_cached_index |
  (.location | location), optional("stack"; stack);

def code_flow:
  object_value | required_entries("threadFlows") | object_value |
  required_entries("locations") | flow_location;

def node:
  object_value |
  if has("location") or (.children | type == "array" and length > 0) then
    optional("location"; location), (entries("children") | node)
  else error("graph node has no explicit source location") end;

def graph:
  object_value | required_entries("nodes") | node;

def fix:
  object_value | required_entries("artifactChanges") | object_value | .artifactLocation | artifact;

def provenance:
  object_value | entries("conversionSources") | physical;

def extension_boundary:
  # Standard property-bag tags carry no location. Other opaque extensions,
  # runtime request/response evidence and graph-index traversals need review.
  if any(.. | objects;
    (has("properties") and
      (.properties | type != "object" or ((keys - ["tags"]) | length > 0) or
        (has("tags") and (.tags | type != "array" or any(.[]; type != "string"))))) or
    has("webRequest") or has("webResponse"))
  then error("opaque extension or runtime location evidence is unsupported")
  elif has("graphTraversals") and (.graphTraversals | type != "array" or length > 0)
  then error("graph traversal references are unresolved")
  else . end;

def result_locations:
  object_value | extension_boundary |
  # Unknown result fields are not assumed to be location-free extensions.
  if (keys - ["ruleId","ruleIndex","rule","kind","level","message","analysisTarget",
    "locations","guid","correlationGuid","occurrenceCount","partialFingerprints",
    "fingerprints","stacks","codeFlows","graphs","graphTraversals","relatedLocations",
    "suppressions","baselineState","rank","attachments","hostedViewerUri","workItemUris",
    "provenance","fixes","taxa","webRequest","webResponse","properties"] | length > 0)
  then error("unknown result field requires location review") else . end |
  (entries("locations") | location),
  (entries("relatedLocations") | location),
  optional("analysisTarget"; artifact),
  (entries("codeFlows") | code_flow),
  (entries("stacks") | stack),
  (entries("graphs") | graph),
  (entries("fixes") | fix),
  (entries("attachments") | object_value | .artifactLocation | artifact),
  (entries("suppressions") | object_value | optional("location"; location)),
  optional("provenance"; provenance);

try ([result_locations] |
  if length == 0 then error("result has no explicit source locations")
  else {complete:true, artifact_locations:., reason:null} end)
catch {complete:false, artifact_locations:[], reason:.}
