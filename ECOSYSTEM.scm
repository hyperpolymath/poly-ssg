;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — poly-ssg

(ecosystem
  (version "1.1.0")
  (name "poly-ssg")
  (type "hub")
  (updated "2025-12-22")
  (purpose "A polyglot static site generator hub coordinating 33 language-specific satellites via MCP. Each satellite IS the definitive SSG for its language.")

  (position-in-ecosystem
    "Central hub of the poly-ssg satellite network.
     Part of hyperpolymath ecosystem. Follows RSR guidelines.
     Security-hardened with SHA-pinned actions and automated scanning.")

  (satellites
    ;; See SATELLITES.scm for full registry
    (implemented 12)  ; Updated: includes webforge-ssg
    (todo 21)
    (total 33)
    (languages
     "Ada" "Haskell" "Idris 2" "Forth" "Chapel" "Prolog"
     "ReScript" "Zig" "Game of Life" "COW" "Logo" "WAT"))

  (infrastructure
    (build-system . ("Justfile" "Mustfile" "Nickel" "asdf"))
    (ci-cd . ("GitHub Actions" "CodeQL" "Semgrep" "Dependabot"))
    (security . ("SHA-pinned-actions" "least-privilege" "SECURITY.md"))
    (scm-files . ("META" "ECOSYSTEM" "STATE" "SATELLITES" "PLAYBOOK" "AGENTIC" "NEUROSYM"))
    (documentation . ("cookbook.adoc" "README.md" "SECURITY.md")))

  (related-projects
    (project (name "casket-ssg")
             (url "https://github.com/hyperpolymath/casket-ssg")
             (relationship "satellite")
             (language "Haskell"))
    (project (name "ddraig-ssg")
             (url "https://github.com/hyperpolymath/ddraig-ssg")
             (relationship "satellite")
             (language "Idris 2"))
    (project (name "estate-ssg")
             (url "https://github.com/hyperpolymath/estate-ssg")
             (relationship "satellite")
             (language "Forth"))
    (project (name "parallax-ssg")
             (url "https://github.com/hyperpolymath/parallax-ssg")
             (relationship "satellite")
             (language "Chapel"))
    (project (name "prodigy-ssg")
             (url "https://github.com/hyperpolymath/prodigy-ssg")
             (relationship "satellite")
             (language "Prolog"))
    (project (name "rescribe-ssg")
             (url "https://github.com/hyperpolymath/rescribe-ssg")
             (relationship "satellite")
             (language "ReScript"))
    (project (name "zigzag-ssg")
             (url "https://github.com/hyperpolymath/zigzag-ssg")
             (relationship "satellite")
             (language "Zig"))
    (project (name "hackenbush-ssg")
             (url "https://github.com/hyperpolymath/hackenbush-ssg")
             (relationship "satellite")
             (language "Conway's Game of Life")
             (status "needs-rewrite"))
    (project (name "milk-ssg")
             (url "https://github.com/hyperpolymath/milk-ssg")
             (relationship "satellite")
             (language "COW"))
    (project (name "terrapin-ssg")
             (url "https://github.com/hyperpolymath/terrapin-ssg")
             (relationship "satellite")
             (language "Logo"))
    (project (name "wagasm-ssg")
             (url "https://github.com/hyperpolymath/wagasm-ssg")
             (relationship "satellite")
             (language "WebAssembly Text (WAT)")
             (status "experimental"))
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "Central hub for polyglot SSG satellite network. Coordinates 33 language-specific SSGs via MCP adapters.")
  (what-this-is-not "- NOT a monolithic multi-language repo\n- NOT exempt from RSR compliance\n- Does NOT contain SSG implementations (those are in satellites)"))
