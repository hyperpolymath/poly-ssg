;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; AGENTIC.scm — poly-ssg agentic AI integration

(define-module (poly-ssg agentic)
  #:export (agent-capabilities tool-definitions workflows constraints))

;;; ============================================================
;;; AGENT CAPABILITIES - What agents can do
;;; ============================================================

(define agent-capabilities
  '((code-generation
     (languages . ("Ada" "Chapel" "Forth" "Haskell" "Idris" "OCaml"
                   "Prolog" "ReScript" "Zig" "Python" "TypeScript"))
     (tasks . ("implement-engine" "write-adapter" "add-tests" "fix-bugs"))
     (constraints . ("follow-coding-standards" "add-spdx-headers" "pin-actions")))

    (code-review
     (scope . ("security" "style" "correctness" "performance"))
     (outputs . ("inline-comments" "summary-report" "suggested-fixes")))

    (documentation
     (types . ("api-docs" "user-guides" "adoc-formatting" "changelog"))
     (formats . ("asciidoc" "markdown" "scheme-comments")))

    (testing
     (types . ("unit" "integration" "e2e" "security"))
     (frameworks . ("dune-test" "pytest" "jest" "custom-harness")))

    (devops
     (tasks . ("ci-workflows" "dependency-updates" "security-scans"))
     (tools . ("github-actions" "dependabot" "codeql" "semgrep")))))

;;; ============================================================
;;; TOOL DEFINITIONS - MCP tools for agents
;;; ============================================================

(define tool-definitions
  '((build-engine
     (description . "Build a specific SSG engine")
     (parameters . ((engine . "string") (verbose . "boolean")))
     (returns . "Build result with logs"))

    (test-engine
     (description . "Run tests for a specific engine")
     (parameters . ((engine . "string") (category . "string")))
     (returns . "Test results with pass/fail counts"))

    (validate-contract
     (description . "Check if engine implements SSG contract")
     (parameters . ((engine . "string")))
     (returns . "Contract compliance report"))

    (sync-satellite
     (description . "Synchronize with a satellite repository")
     (parameters . ((satellite . "string")))
     (returns . "Sync status and changes"))

    (security-scan
     (description . "Run security scans on codebase")
     (parameters . ((scope . "string") (fix . "boolean")))
     (returns . "Security report with findings"))

    (generate-adapter
     (description . "Generate MCP adapter for new satellite")
     (parameters . ((language . "string") (satellite-name . "string")))
     (returns . "Generated adapter code"))))

;;; ============================================================
;;; WORKFLOWS - Agent orchestration patterns
;;; ============================================================

(define workflows
  '((implement-new-engine
     (description . "Guide agent through implementing a new SSG engine")
     (steps
      (("analyze-language" . "Understand language paradigm and idioms")
       ("scaffold-project" . "Create directory structure and manifest")
       ("implement-parser" . "Frontmatter and markdown parsing")
       ("implement-templating" . "Template loading and variable substitution")
       ("implement-generator" . "HTML output generation")
       ("add-tests" . "Unit tests against test-corpus")
       ("add-ci" . "GitHub Actions workflow with pinned actions")
       ("document" . "README, usage examples, API docs")))
     (agent-type . "code-generation"))

    (security-hardening
     (description . "Automated security enhancement workflow")
     (steps
      (("audit-dependencies" . "Check for vulnerable packages")
       ("pin-actions" . "Convert tag refs to SHA pins")
       ("add-permissions" . "Apply least-privilege permissions")
       ("add-sast" . "Ensure CodeQL and Semgrep configured")
       ("verify-spdx" . "Check all files have SPDX headers")
       ("update-security-md" . "Document security practices")))
     (agent-type . "devops"))

    (satellite-integration
     (description . "Integrate new satellite into hub")
     (steps
      (("clone-satellite" . "Fetch satellite repository")
       ("validate-manifest" . "Check manifest.json/ncl")
       ("generate-adapter" . "Create ReScript MCP adapter")
       ("test-communication" . "Verify MCP protocol works")
       ("update-registry" . "Add to SATELLITES.scm")
       ("update-ecosystem" . "Update ECOSYSTEM.scm counts")))
     (agent-type . "integration"))))

;;; ============================================================
;;; CONSTRAINTS - Safety boundaries for agents
;;; ============================================================

(define constraints
  '((code-generation
     (must . ("include-spdx-header" "follow-language-idioms" "add-tests"))
     (must-not . ("use-unsafe-patterns" "hardcode-secrets" "skip-validation")))

    (security
     (must . ("pin-actions-to-sha" "use-least-privilege" "validate-input"))
     (must-not . ("disable-security-checks" "expose-credentials" "bypass-hooks")))

    (git-operations
     (must . ("use-conventional-commits" "run-tests-before-push"))
     (must-not . ("force-push-to-main" "skip-ci" "amend-others-commits")))

    (documentation
     (must . ("be-accurate" "include-examples" "use-asciidoc-for-docs"))
     (must-not . ("duplicate-content" "include-stale-info")))))
