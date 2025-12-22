;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; META.scm — poly-ssg

(define-module (poly-ssg meta)
  #:export (architecture-decisions development-practices design-rationale component-status))

;;; ============================================================
;;; ARCHITECTURE DECISIONS
;;; ============================================================

(define architecture-decisions
  '((adr-001
     (title . "RSR Compliance")
     (status . "accepted")
     (date . "2025-12-15")
     (context . "A polyglot static site generator framework with MCP integration. Each engine implements the same SSG contract in a different programming language, bringing unique paradigmatic strengths.")
     (decision . "Follow Rhodium Standard Repository guidelines")
     (consequences . ("RSR Gold target" "SHA-pinned actions" "SPDX headers" "Multi-platform CI")))

    (adr-002
     (title . "Satellite Architecture")
     (status . "accepted")
     (date . "2025-12-20")
     (context . "Need to coordinate 33 language-specific SSGs")
     (decision . "Hub-satellite model with MCP adapters")
     (consequences . ("Central hub coordinates" "Satellites are autonomous" "MCP for communication")))

    (adr-003
     (title . "Security-First CI/CD")
     (status . "accepted")
     (date . "2025-12-22")
     (context . "Supply chain security is critical")
     (decision . "SHA-pinned actions, least-privilege permissions, automated scanning")
     (consequences . ("All actions pinned" "CodeQL + Semgrep daily" "SECURITY.md policy")))))

;;; ============================================================
;;; DEVELOPMENT PRACTICES
;;; ============================================================

(define development-practices
  '((code-style
     (languages . ("Ada" "Chapel" "Dune" "Forth" "HTML" "Haskell" "Idris"
                   "Just" "Nickel" "OCaml" "Prolog" "Python" "ReScript"
                   "Scheme" "Shell" "TypeScript" "Zig"))
     (formatter . "language-specific")
     (linter . "language-specific + CodeQL"))

    (security
     (sast . ("CodeQL" "Semgrep"))
     (ocaml-audit . ("no-obj-magic" "no-marshal" "no-shell-exec"))
     (action-pinning . "SHA-only")
     (credentials . "env vars only"))

    (testing
     (coverage-minimum . 70)
     (test-corpus . 6)  ; categories
     (test-files . 20)) ; total test files

    (versioning
     (scheme . "SemVer 2.0.0"))

    (documentation
     (formats . ("asciidoc" "markdown" "scheme-comments"))
     (required . ("README" "SECURITY" "cookbook")))))

;;; ============================================================
;;; DESIGN RATIONALE
;;; ============================================================

(define design-rationale
  '((why-rsr . "RSR ensures consistency, security, and maintainability.")
    (why-polyglot . "Each language brings unique paradigmatic strengths.")
    (why-mcp . "Standard protocol for satellite coordination.")
    (why-nickel . "Type-safe configuration with ultracombinatoric power.")
    (why-scheme . "S-expressions for machine-readable project metadata.")))

;;; ============================================================
;;; 44-COMPONENT STATUS (poly-ssg adaptation)
;;; ============================================================

(define component-status
  '((components-total . 44)
    (components-complete . 38)

    (core-engine (4 4)
     ("Satellite hub" . "complete")
     ("MCP adapters" . "complete")
     ("Engine contract" . "complete")
     ("Variable store" . "complete"))

    (build-system (4 4)
     ("Justfile commands" . "complete")
     ("Mustfile invariants" . "complete")
     ("asdf tooling" . "complete")
     ("Nickel config" . "complete"))

    (site-generation (4 4)
     ("Content processing" . "complete")
     ("Template engine" . "per-satellite")
     ("Output generation" . "per-satellite")
     ("Content schema" . "complete"))

    (adapters (3 3)
     ("MCP server" . "complete")
     ("ReScript adapters" . "complete")
     ("Deno runtime" . "optional"))

    (testing (4 4)
     ("Test harness" . "complete")
     ("Unit tests" . "54 passing")
     ("E2E tests" . "framework ready")
     ("CI pipeline" . "complete"))

    (documentation (8 8)
     ("README" . "complete")
     ("SECURITY.md" . "complete")
     ("cookbook.adoc" . "complete")
     ("SCM files" . "complete")
     ("ENGINE-CONTRACT" . "complete")
     ("Module docs" . "per-engine")
     ("User guide" . "pending")
     ("API docs" . "auto-generated"))

    (configuration (3 3)
     ("Site config schema" . "config.ncl")
     ("Example config" . "complete")
     ("Environment handling" . "complete"))

    (security (6 6)
     ("CodeQL" . "active")
     ("Semgrep" . "active")
     ("OCaml audit" . "active")
     ("Action pinning" . "all SHA")
     ("Dependabot" . "active")
     ("SECURITY.md" . "complete"))

    (scm-files (7 7)
     ("META.scm" . "complete")
     ("ECOSYSTEM.scm" . "complete")
     ("STATE.scm" . "complete")
     ("SATELLITES.scm" . "complete")
     ("PLAYBOOK.scm" . "complete")
     ("AGENTIC.scm" . "complete")
     ("NEUROSYM.scm" . "complete"))))
