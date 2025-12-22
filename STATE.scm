;;; STATE.scm — poly-ssg
;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

(define-module (poly-ssg state)
  #:export (metadata current-position blockers-and-issues
            critical-next-actions session-history state-summary))

;;; ============================================================
;;; METADATA
;;; ============================================================

(define metadata
  '((version . "0.2.0")
    (updated . "2025-12-22")
    (project . "poly-ssg")
    (status . "active")))

;;; ============================================================
;;; CURRENT POSITION
;;; ============================================================

(define current-position
  '((phase . "v0.2 - Security Hardening & SCM Complete")
    (overall-completion . 86)  ; 38/44 components

    (components
     ((core-engine
       (status . "complete")
       (completion . 100)
       (items . ("hub" "adapters" "contract" "store")))

      (build-system
       (status . "complete")
       (completion . 100)
       (items . ("Justfile" "Mustfile" "asdf" "Nickel")))

      (security
       (status . "complete")
       (completion . 100)
       (items . ("CodeQL" "Semgrep" "OCaml-audit" "SHA-pins" "SECURITY.md")))

      (scm-files
       (status . "complete")
       (completion . 100)
       (items . ("META" "ECOSYSTEM" "STATE" "SATELLITES" "PLAYBOOK" "AGENTIC" "NEUROSYM")))

      (documentation
       (status . "mostly-complete")
       (completion . 87)
       (items . ("README" "SECURITY" "cookbook" "ENGINE-CONTRACT")))

      (testing
       (status . "mostly-complete")
       (completion . 75)
       (items . ("harness" "unit-tests" "corpus" "e2e-pending")))

      (engines
       (status . "in-progress")
       (completion . 50)
       (items . ("12 engines need tests")))))))

;;; ============================================================
;;; BLOCKERS AND ISSUES
;;; ============================================================

(define blockers-and-issues
  '((critical ())
    (high-priority ())
    (medium-priority
     (("Engine test suites" . "Each engine needs test scripts")
      ("E2E test implementation" . "Framework ready, tests needed")))
    (low-priority
     (("User guide" . "Nice to have")
      ("Additional satellites" . "22 more to implement")))))

;;; ============================================================
;;; CRITICAL NEXT ACTIONS
;;; ============================================================

(define critical-next-actions
  '((immediate
     (("Commit security changes" . "high")
      ("Push to branch" . "high")))

    (this-week
     (("Implement engine test scripts" . "medium")
      ("E2E test suite" . "medium")))

    (this-month
     (("Additional satellite implementations" . "low")
      ("User guide documentation" . "low")))))

;;; ============================================================
;;; SESSION HISTORY
;;; ============================================================

(define session-history
  '((snapshots
     ((date . "2025-12-15")
      (session . "initial")
      (notes . "SCM files added, RSR compliance"))

     ((date . "2025-12-22")
      (session . "security-hardening")
      (notes . "SHA-pinned all actions, added SECURITY.md, PLAYBOOK/AGENTIC/NEUROSYM.scm")
      (changes . ("12 engine CI workflows hardened"
                  "Justfile with 50+ recipes"
                  "Mustfile invariants"
                  "cookbook.adoc with hyperlinks"
                  "Full SCM file suite"))))))

;;; ============================================================
;;; STATE SUMMARY
;;; ============================================================

(define state-summary
  '((project . "poly-ssg")
    (completion . 86)
    (components-complete . "38/44")
    (blockers . 0)
    (updated . "2025-12-22")
    (next-milestone . "Engine test suites")))
