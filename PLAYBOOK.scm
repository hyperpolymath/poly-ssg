;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; PLAYBOOK.scm — poly-ssg operational procedures

(define-module (poly-ssg playbook)
  #:export (workflows runbooks troubleshooting recipes))

;;; ============================================================
;;; WORKFLOWS - Standard operational procedures
;;; ============================================================

(define workflows
  '((build-workflow
     (name . "Standard Build")
     (steps . (("lint" . "just lint")
               ("test" . "just test")
               ("build" . "just build")
               ("validate" . "just validate")))
     (on-failure . "See troubleshooting/build-failures"))

    (release-workflow
     (name . "Release Process")
     (steps . (("version-bump" . "just version patch|minor|major")
               ("changelog" . "just changelog")
               ("tag" . "just tag")
               ("publish" . "just publish")))
     (requires . ("all tests passing" "clean git state")))

    (satellite-sync
     (name . "Satellite Synchronization")
     (steps . (("fetch-satellites" . "just satellite fetch-all")
               ("validate-contracts" . "just satellite validate")
               ("update-registry" . "just satellite update-registry")
               ("test-integration" . "just test-e2e")))
     (frequency . "weekly"))

    (security-audit
     (name . "Security Audit")
     (steps . (("scan-deps" . "just security scan")
               ("check-pins" . "just security check-pins")
               ("verify-spdx" . "just security verify-spdx")
               ("audit-ocaml" . "just security audit-ocaml")))
     (frequency . "daily via CI"))))

;;; ============================================================
;;; RUNBOOKS - Detailed operational procedures
;;; ============================================================

(define runbooks
  '((add-new-satellite
     (title . "Adding a New SSG Satellite")
     (steps
      ((step 1 "Create satellite repository from template"
              "gh repo create hyperpolymath/<lang>-ssg --template hyperpolymath/ssg-satellite-template")
       (step 2 "Implement SSG contract"
              "Follow ENGINE-CONTRACT.md for required interfaces")
       (step 3 "Create MCP adapter"
              "Add adapters/src/<Lang>Adapter.res with standard protocol")
       (step 4 "Register in SATELLITES.scm"
              "Add entry to implemented or todo section")
       (step 5 "Update ECOSYSTEM.scm"
              "Increment satellite counts")
       (step 6 "Add CI workflow"
              "Copy and customize .github/workflows/ci.yml")
       (step 7 "Test integration"
              "Run just test-e2e to verify MCP communication"))))

    (engine-implementation
     (title . "Implementing an Engine")
     (steps
      ((step 1 "Scaffold engine directory"
              "mkdir -p engines/<engine>-ssg/{src,tests,docs}")
       (step 2 "Create manifest files"
              "manifest.json and manifest.ncl with engine metadata")
       (step 3 "Implement core functions"
              "parse-frontmatter, render-markdown, apply-template, write-output")
       (step 4 "Add test suite"
              "Tests against test-corpus categories")
       (step 5 "Create CI workflow"
              "With SHA-pinned actions and permissions")
       (step 6 "Document in ENGINE.md"
              "Usage, features, language-specific notes"))))

    (security-incident
     (title . "Security Incident Response")
     (steps
      ((step 1 "Identify scope"
              "Determine affected components and data")
       (step 2 "Contain threat"
              "Disable affected workflows, rotate secrets if needed")
       (step 3 "Patch vulnerability"
              "Apply fix, update dependencies, re-pin actions")
       (step 4 "Verify fix"
              "Run full security audit")
       (step 5 "Document incident"
              "Add to SECURITY.md and update STATE.scm")
       (step 6 "Notify stakeholders"
              "If applicable per security policy"))))))

;;; ============================================================
;;; TROUBLESHOOTING - Common issues and solutions
;;; ============================================================

(define troubleshooting
  '((build-failures
     (issue . "Build fails with missing dependency")
     (solutions
      (("Check .tool-versions" . "asdf install")
       ("Reinstall deps" . "just deps")
       ("Clear cache" . "just clean && just build"))))

    (ci-failures
     (issue . "CI workflow fails")
     (solutions
      (("Check action pinning" . "Verify SHA hashes are correct")
       ("Check permissions" . "Ensure least-privilege permissions")
       ("Check secrets" . "Verify secrets are configured in repo settings"))))

    (satellite-connection
     (issue . "Cannot connect to satellite")
     (solutions
      (("Check adapter" . "Verify adapter implements MCP protocol")
       ("Check network" . "Ensure satellite repo is accessible")
       ("Check manifest" . "Verify manifest.json is valid JSON"))))

    (test-corpus-failures
     (issue . "Engine fails test corpus")
     (solutions
      (("Check encoding" . "Ensure UTF-8 handling for unicode tests")
       ("Check sanitization" . "Verify XSS/injection protections")
       ("Check edge cases" . "Handle empty/malformed inputs"))))))

;;; ============================================================
;;; RECIPES - Quick command reference
;;; ============================================================

(define recipes
  '((daily-workflow . ("just lint" "just test" "just build"))
    (full-validation . ("just test-all" "just security scan" "just validate"))
    (release-prep . ("just changelog" "just version" "just tag"))
    (debug-engine . ("just test-engine <name> --verbose"))
    (satellite-ops . ("just satellite list" "just satellite sync" "just satellite validate"))))
