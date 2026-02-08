;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

;; AI.scm — AI Assistant Instructions
;; polyglot-ssg-mcp

(define-module (polyglot-ssg-mcp ai)
  #:export (ai-instructions))

(define ai-instructions
  '((project-context
     (name . "polyglot-ssg-mcp")
     (purpose . "Unified MCP server for 28 static site generators")
     (scope . "FP/systems/academic languages only - no mainstream JS/Python/Ruby"))

    (key-facts
     (ssgs . 28)
     (languages . 19)
     (runtime . "Deno")
     (core . "ReScript")
     (license . "MIT"))

    (language-families
     (ml-family . ("Haskell" "OCaml" "F#"))
     (lisp-family . ("Clojure" "Common Lisp" "Racket"))
     (beam . ("Elixir" "Erlang"))
     (systems . ("Rust" "D" "Nim" "Crystal"))
     (scientific . ("Julia" "Scala"))
     (other . ("Swift" "Kotlin" "Tcl")))

    (instructions
     (adding-adapters . "Follow existing adapter patterns in adapters/")
     (code-style . "SPDX headers, Deno fmt, ReScript for core")
     (testing . "Manual testing with installed SSGs")
     (documentation . "AsciiDoc format"))

    (feedback
     (issues . "https://github.com/hyperpolymath/polyglot-ssg-mcp/issues")
     (discussions . "https://github.com/hyperpolymath/polyglot-ssg-mcp/discussions"))))
