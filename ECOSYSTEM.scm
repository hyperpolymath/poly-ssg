;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — poly-ssg

(ecosystem
  (version "1.0.0")
  (name "poly-ssg")
  (type "project")
  (purpose "A polyglot static site generator framework with MCP integration. Each engine implements the same SSG contract in a different programming language, bringing unique paradigmatic strengths.")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "A polyglot static site generator framework with MCP integration. Each engine implements the same SSG contract in a different programming language, bringing unique paradigmatic strengths.")
  (what-this-is-not "- NOT exempt from RSR compliance"))
