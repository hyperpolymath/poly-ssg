<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
# Security policy

## Supported scope

This repository is private source-preservation staging for historical Poly SSG
experiments. It offers no supported executable release, hosted service or
production deployment. The retained source has known, unqualified security
findings. A passing preservation check establishes only the claim named by
that check; it does not establish that an engine is safe to run.

Current preservation scripts, workflow definitions and documentation are
maintained within the qualification work tracked in issue #2. An implementation
selected for a maintained successor needs its own security and runtime review.

## Reporting a vulnerability

Contact the repository owner at **jonathan.jewell@open.ac.uk**, the reporting
address already published in this repository's `.well-known/security.txt`.
Identify the repository, exact commit, affected path, impact and a small
reproduction where possible. Do not include live credentials or disclose private
source in a public issue or public pull request. No response-time or remediation
SLA is promised by this preservation project.

Reports about current automation and exposed credentials require review even
when the associated source is historical. Preserved-source findings remain
recorded in complete scanner artifacts and are not described as fixed or false
positives solely because the source is unsupported.

## Analysis records

GitHub hosted code scanning was unavailable for this private repository when
the workflow repair was prepared. CodeQL, Semgrep and Scorecard retain complete
SARIF artifacts and explicit disposition reports. Missing or failed analysis
cannot become a passing finding gate. Artifact retention is finite; qualification
issue #2 must retain the accepted evidence needed for final closure.

## Acknowledgments

Reporter attribution will be agreed with the reporter before publication.
