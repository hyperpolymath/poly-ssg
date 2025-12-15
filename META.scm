;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;;; META.scm — poly-ssg

(define-module (poly-ssg meta)
  #:export (architecture-decisions development-practices design-rationale))

(define architecture-decisions
  '((adr-001
     (title . "RSR Compliance")
     (status . "accepted")
     (date . "2025-12-15")
     (context . "A polyglot static site generator framework with MCP integration. Each engine implements the same SSG contract in a different programming language, bringing unique paradigmatic strengths.")
     (decision . "Follow Rhodium Standard Repository guidelines")
     (consequences . ("RSR Gold target" "SHA-pinned actions" "SPDX headers" "Multi-platform CI")))))

(define development-practices
  '((code-style (languages . ("Ada" "Chapel" "Dune" "Forth" "HTML" "Haskell" "Idris" "Just" "Nickel" "OCaml" "Prolog" "Python" "ReScript" "Scheme" "Shell" "TypeScript" "Zig")) (formatter . "gnatpp") (linter . "gnatcheck"))
    (security (sast . "CodeQL") (credentials . "env vars only"))
    (testing (coverage-minimum . 70))
    (versioning (scheme . "SemVer 2.0.0"))))

(define design-rationale
  '((why-rsr "RSR ensures consistency, security, and maintainability.")))
