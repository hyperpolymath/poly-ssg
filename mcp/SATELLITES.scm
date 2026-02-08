;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; SATELLITES.scm - Hub-Satellite Registry for poly-ssg-mcp
;;
;; This file defines all satellite repositories that orbit the poly-ssg-mcp hub.
;; Satellites are SSG project implementations that use the unified MCP adapter interface.
;;
;; Last updated: 2025-01-18 (v1.0.0 implementation session)

(satellites
  (version "2.0.0")
  (hub
    (name "poly-ssg-mcp")
    (url "https://github.com/hyperpolymath/poly-ssg-mcp")
    (description "Unified MCP server for static site generators across multiple languages")
    (adapters 28))

  ;; ============================================================================
  ;; IMPLEMENTED ENGINES (with source code)
  ;; ============================================================================
  (implemented
    ;; Completed language paradigm engines
    (satellite
      (name "zigzag-ssg")
      (url "https://github.com/hyperpolymath/zigzag-ssg")
      (language "Zig")
      (status "implemented")
      (features "comptime templates, zero-allocation parsing, SIMD markdown"))

    (satellite
      (name "casket-ssg")
      (url "https://github.com/hyperpolymath/casket-ssg")
      (language "Haskell")
      (status "implemented")
      (features "pure functional, monadic pipelines, type-safe templates"))

    (satellite
      (name "prodigy-ssg")
      (url "https://github.com/hyperpolymath/prodigy-ssg")
      (language "Prolog")
      (status "implemented")
      (features "DCG parsing, logic programming, backtracking search"))

    (satellite
      (name "sparkle-ssg")
      (url "https://github.com/hyperpolymath/sparkle-ssg")
      (language "Gleam")
      (status "implemented")
      (features "BEAM concurrency, type-safe, fault-tolerant actors"))

    (satellite
      (name "macrauchenia-ssg")
      (url "https://github.com/hyperpolymath/macrauchenia-ssg")
      (language "OCaml")
      (status "implemented")
      (features "pattern matching, ADTs, cmdliner CLI"))

    (satellite
      (name "eclipse-ssg")
      (url "https://github.com/hyperpolymath/eclipse-ssg")
      (language "Pony")
      (status "implemented")
      (features "actor model, reference capabilities, lock-free concurrency"))

    (satellite
      (name "chicxulub-ssg")
      (url "https://github.com/hyperpolymath/chicxulub-ssg")
      (language "Bash")
      (status "implemented")
      (features "shell pipeline, POSIX compatible, portable"))

    (satellite
      (name "anvil-ssg")
      (url "https://github.com/hyperpolymath/anvil-ssg")
      (language "Ada/SPARK")
      (status "implemented")
      (features "formal verification, contracts, SPARK proofs")
      (note "Merged with noteg-ssg for dual-mode architecture"))

    (satellite
      (name "divisionone-ssg")
      (url "https://github.com/hyperpolymath/divisionone-ssg")
      (language "COBOL")
      (status "implemented")
      (features "IDENTIFICATION/DATA/PROCEDURE divisions, GnuCOBOL, enterprise-style"))

    (satellite
      (name "labnote-ssg")
      (url "https://github.com/hyperpolymath/labnote-ssg")
      (language "SciLab")
      (status "implemented")
      (features "embedded code execution, matrix computation, scientific publishing"))

    (satellite
      (name "milk-ssg")
      (url "https://github.com/hyperpolymath/milk-ssg")
      (language "COW")
      (status "implemented")
      (features "esoteric Brainfuck variant, MoO/MOo/Moo commands, HTML generation")))

  ;; ============================================================================
  ;; THEME/INTEGRATION SATELLITES
  ;; ============================================================================
  (themes-and-integrations
    (satellite
      (name "hackenbush-ssg")
      (url "https://github.com/hyperpolymath/hackenbush-ssg")
      (role "template")
      (status "active")
      (description "Canonical RSR template for SSG projects"))

    (satellite
      (name "poly-ssg")
      (url "https://github.com/hyperpolymath/poly-ssg")
      (role "meta")
      (status "active")
      (description "Polyglot SSG framework documentation hub"))

    (satellite
      (name "dei-ssg")
      (url "https://github.com/hyperpolymath/dei-ssg")
      (role "plugin-provider")
      (status "active")
      (description "Consent plugin provider for poly-ssg family")
      (plugins ("consent"))))

  ;; ============================================================================
  ;; ADDITIONAL IMPLEMENTED ENGINES (Session 2025-01-18)
  ;; ============================================================================
  (implemented-v2
    (satellite
      (name "baremetal-ssg")
      (url "https://github.com/hyperpolymath/baremetal-ssg")
      (language "x86-64 Assembly")
      (status "implemented")
      (features "direct syscalls, zero dependencies, minimal binary"))

    (satellite
      (name "befunge-ssg")
      (url "https://github.com/hyperpolymath/befunge-ssg")
      (language "Befunge-93")
      (status "implemented")
      (features "2D esoteric language, program counter navigation"))

    (satellite
      (name "ddraig-ssg")
      (url "https://github.com/hyperpolymath/ddraig-ssg")
      (language "Idris 2")
      (status "implemented")
      (features "dependent types, proofs, total functions"))

    (satellite
      (name "doit-ssg")
      (url "https://github.com/hyperpolymath/doit-ssg")
      (language "Io")
      (status "implemented")
      (features "prototype-based OOP, message passing, concurrency"))

    (satellite
      (name "estate-ssg")
      (url "https://github.com/hyperpolymath/estate-ssg")
      (language "Eiffel")
      (status "implemented")
      (features "design by contract, preconditions, postconditions"))

    (satellite
      (name "gungir-ssg")
      (url "https://github.com/hyperpolymath/gungir-ssg")
      (language "ReScript")
      (status "implemented")
      (features "type-safe, Deno runtime, functional style"))

    (satellite
      (name "iota-ssg")
      (url "https://github.com/hyperpolymath/iota-ssg")
      (language "APL")
      (status "implemented")
      (features "array-oriented, symbolic operators, vectorized"))

    (satellite
      (name "my-ssg")
      (url "https://github.com/hyperpolymath/my-ssg")
      (language "Janet")
      (status "implemented")
      (features "Lisp-like, PEG parsing, embeddable"))

    (satellite
      (name "obli-ssg")
      (url "https://github.com/hyperpolymath/obli-ssg")
      (language "Oberon")
      (status "implemented")
      (features "modular programming, Wirth-style, OBNC compiler"))

    (satellite
      (name "odd-ssg")
      (url "https://github.com/hyperpolymath/odd-ssg")
      (language "Forth")
      (status "implemented")
      (features "stack-based, concatenative, Gforth"))

    (satellite
      (name "orbital-ssg")
      (url "https://github.com/hyperpolymath/orbital-ssg")
      (language "Grain")
      (status "implemented")
      (features "functional, WebAssembly, pattern matching"))

    (satellite
      (name "parallax-ssg")
      (url "https://github.com/hyperpolymath/parallax-ssg")
      (language "Chapel")
      (status "implemented")
      (features "parallel computing, domains, locales"))

    (satellite
      (name "pharos-ssg")
      (url "https://github.com/hyperpolymath/pharos-ssg")
      (language "Pharo Smalltalk")
      (status "implemented")
      (features "live image, message passing, object-oriented"))

    (satellite
      (name "qed-ssg")
      (url "https://github.com/hyperpolymath/qed-ssg")
      (language "Lean 4")
      (status "implemented")
      (features "theorem prover, dependent types, tactics"))

    (satellite
      (name "rats-ssg")
      (url "https://github.com/hyperpolymath/rats-ssg")
      (language "Ratfor")
      (status "implemented")
      (features "C-like Fortran preprocessor, structured programming"))

    (satellite
      (name "rescribe-ssg")
      (url "https://github.com/hyperpolymath/rescribe-ssg")
      (language "ReScript")
      (status "implemented")
      (features "type-safe JS output, pattern matching, immutable"))

    (satellite
      (name "saur-ssg")
      (url "https://github.com/hyperpolymath/saur-ssg")
      (language "Squirrel")
      (status "implemented")
      (features "lightweight scripting, game heritage, dynamic typing"))

    (satellite
      (name "shift-ssg")
      (url "https://github.com/hyperpolymath/shift-ssg")
      (language "Wren")
      (status "implemented")
      (features "class-based, fiber concurrency, embeddable"))

    (satellite
      (name "terrapin-ssg")
      (url "https://github.com/hyperpolymath/terrapin-ssg")
      (language "Logo")
      (status "implemented")
      (features "turtle graphics heritage, educational, UCBLogo"))

    (satellite
      (name "wagasm-ssg")
      (url "https://github.com/hyperpolymath/wagasm-ssg")
      (language "WebAssembly Text")
      (status "implemented")
      (features "pure WAT, memory operations, host imports")))

  ;; ============================================================================
  ;; EXPERIMENTAL (novel approaches requiring research)
  ;; ============================================================================
  (experimental
    (satellite
      (name "noteg-ssg")
      (url "https://github.com/hyperpolymath/noteg-ssg")
      (status "experimental")
      (note "Dual-mode architecture with anvil-ssg"))

    (satellite
      (name "60-ssg")
      (url "https://github.com/hyperpolymath/60-ssg")
      (status "experimental")
      (features "time-constrained builds, deadline-aware rendering"))

    (satellite
      (name "consensus-ssg")
      (url "https://github.com/hyperpolymath/consensus-ssg")
      (status "experimental")
      (features "distributed consensus, multi-node validation"))

    (satellite
      (name "cpt-ssg")
      (url "https://github.com/hyperpolymath/cpt-ssg")
      (status "experimental")
      (features "neural template generation, ML-assisted layouts"))

    (satellite
      (name "easel-ssg")
      (url "https://github.com/hyperpolymath/easel-ssg")
      (status "experimental")
      (features "visual canvas editing, drag-drop composition"))

    (satellite
      (name "liminal-ssg")
      (url "https://github.com/hyperpolymath/liminal-ssg")
      (status "experimental")
      (features "transitional states, metamorphic templates"))

    (satellite
      (name "region-ssg")
      (url "https://github.com/hyperpolymath/region-ssg")
      (status "experimental")
      (features "geographic content adaptation, locale-aware builds"))

    (satellite
      (name "undo-ssg")
      (url "https://github.com/hyperpolymath/undo-ssg")
      (status "experimental")
      (features "version-aware builds, temporal navigation")))

  ;; ============================================================================
  ;; STATISTICS (Updated 2025-01-18)
  ;; ============================================================================
  (statistics
    (implemented-count 31)  ;; 11 original + 20 new
    (theme-integration-count 3)
    (experimental-count 8)  ;; Novel approaches requiring research
    (pending-count 0)
    (total-satellites 42)
    (languages-represented 31))

  ;; ============================================================================
  ;; AVAILABLE ADAPTERS (from hub)
  ;; ============================================================================
  (available-adapters
    (adapter (name "babashka") (language "Clojure"))
    (adapter (name "cobalt") (language "Rust"))
    (adapter (name "coleslaw") (language "Common Lisp"))
    (adapter (name "cryogen") (language "Clojure"))
    (adapter (name "documenter") (language "Julia"))
    (adapter (name "ema") (language "Haskell"))
    (adapter (name "fornax") (language "F#"))
    (adapter (name "franklin") (language "Julia"))
    (adapter (name "frog") (language "Racket"))
    (adapter (name "hakyll") (language "Haskell"))
    (adapter (name "laika") (language "Scala"))
    (adapter (name "marmot") (language "Crystal"))
    (adapter (name "mdbook") (language "Rust"))
    (adapter (name "nimble-publisher") (language "Elixir"))
    (adapter (name "nimrod") (language "Nim"))
    (adapter (name "orchid") (language "Kotlin"))
    (adapter (name "perun") (language "Clojure"))
    (adapter (name "pollen") (language "Racket"))
    (adapter (name "publish") (language "Swift"))
    (adapter (name "reggae") (language "D"))
    (adapter (name "scalatex") (language "Scala"))
    (adapter (name "serum") (language "Elixir"))
    (adapter (name "staticwebpages") (language "Julia"))
    (adapter (name "tableau") (language "Elixir"))
    (adapter (name "wub") (language "Tcl"))
    (adapter (name "yocaml") (language "OCaml"))
    (adapter (name "zola") (language "Rust"))
    (adapter (name "zotonic") (language "Erlang"))))

;;; End of SATELLITES.scm
