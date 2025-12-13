;;; STATE.scm — poly-ssg Project State Checkpoint
;;; Format: https://github.com/hyperpolymath/state.scm
;;;
;;; Download this file at end of each session!
;;; At start of next conversation, upload it.

(define state
  '((metadata
     (version . "0.2.0")
     (created . "2025-12-13")
     (updated . "2025-12-13")
     (generator . "claude-opus-4.5"))

    (user
     (name . "hyperpolymath")
     (roles . (maintainer architect))
     (languages . (ocaml forth rescript scheme nickel zig ada haskell idris prolog chapel))
     (tools . (dune just wasm-tools wasmtime gh toolbox))
     (values . (type-safety polyglot offline-first harsh-testing)))

    (session
     (conversation-id . "poly-ssg/harsh-testing-infrastructure")
     (messages . "session-active")
     (token-limit . 200000)
     (tokens-remaining . "~150000"))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; CURRENT POSITION
    ;; ═══════════════════════════════════════════════════════════════════

    (focus
     (project . "poly-ssg")
     (phase . "test-infrastructure")
     (milestone . "Creating harsh test suites for all 12 engines")
     (blocking . ()))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; ACTIVE TASK QUEUE
    ;; ═══════════════════════════════════════════════════════════════════

    (task-queue
     ((task . "test-infrastructure")
      (status . complete)
      (notes . "Test corpus created with edge cases, malformed, unicode, injection, stress tests"))

     ((task . "forth-estate-tests")
      (status . pending)
      (notes . "Gforth test suite with -Wall equivalent"))

     ((task . "zigzag-tests")
      (status . pending)
      (notes . "Zig test suite with -Werror"))

     ((task . "yocaml-tests")
      (status . pending)
      (notes . "OCaml test suite with -strict-sequence -safe-string"))

     ((task . "prodigy-tests")
      (status . pending)
      (notes . "Prolog test suite"))

     ((task . "casket-tests")
      (status . pending)
      (notes . "Haskell test suite with -Wall -Werror"))

     ((task . "ddraig-tests")
      (status . pending)
      (notes . "Idris 2 test suite"))

     ((task . "webforge-tests")
      (status . pending)
      (notes . "Ada test suite with -gnatwe"))

     ((task . "rescribe-tests")
      (status . pending)
      (notes . "ReScript test suite"))

     ((task . "wagasm-tests")
      (status . pending)
      (notes . "AssemblyScript test suite"))

     ((task . "parallel-press-tests")
      (status . pending)
      (notes . "Chapel test suite"))

     ((task . "terrapin-tests")
      (status . pending)
      (notes . "Logo/Python test suite"))

     ((task . "milk-tests")
      (status . pending)
      (notes . "COW/Python test suite")))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; ENGINE CATALOG
    ;; ═══════════════════════════════════════════════════════════════════

    (engines
     ((id . "forth-estate")
      (name . "Forth Estate")
      (language . "Gforth")
      (status . has-code)
      (lines . 925)
      (tests . none)
      (notes . "Stack-based SSG, markdown/frontmatter/template support"))

     ((id . "zigzag-ssg")
      (name . "ZigZag")
      (language . "Zig")
      (status . has-code)
      (lines . 324)
      (tests . none)
      (notes . "Memory-safe SSG with compile-time features"))

     ((id . "yocaml-ssg")
      (name . "YOCaml Lite")
      (language . "OCaml")
      (status . has-code)
      (lines . 326)
      (tests . none)
      (notes . "Functional SSG with type safety"))

     ((id . "prodigy-ssg")
      (name . "Prodigy")
      (language . "Prolog")
      (status . has-code)
      (lines . 168)
      (tests . none)
      (notes . "Logic programming SSG"))

     ((id . "casket-ssg")
      (name . "Casket")
      (language . "Haskell")
      (status . has-code)
      (lines . 307)
      (tests . none)
      (notes . "Pure functional SSG"))

     ((id . "ddraig-ssg")
      (name . "Ddraig")
      (language . "Idris 2")
      (status . has-code)
      (lines . 282)
      (tests . none)
      (notes . "Dependently-typed SSG (Welsh: dragon)"))

     ((id . "webforge-ssg")
      (name . "WebForge")
      (language . "Ada")
      (status . has-code)
      (lines . 255)
      (tests . none)
      (notes . "Safety-critical SSG"))

     ((id . "rescribe-ssg")
      (name . "Rescribe")
      (language . "ReScript")
      (status . has-code)
      (lines . 312)
      (tests . none)
      (notes . "ReScript SSG with JS interop"))

     ((id . "wagasm-ssg")
      (name . "Wagasm")
      (language . "AssemblyScript")
      (status . has-code)
      (lines . 347)
      (tests . none)
      (notes . "WebAssembly SSG"))

     ((id . "parallel-press-ssg")
      (name . "Parallel Press")
      (language . "Chapel")
      (status . has-code)
      (lines . 695)
      (tests . none)
      (notes . "Parallel computing SSG"))

     ((id . "terrapin-ssg")
      (name . "Terrapin")
      (language . "Python/Logo")
      (status . has-code)
      (lines . 512)
      (tests . none)
      (notes . "Logo interpreter SSG"))

     ((id . "milk-ssg")
      (name . "Milk")
      (language . "Python/COW")
      (status . has-code)
      (lines . 424)
      (tests . none)
      (notes . "COW esoteric language SSG")))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; TEST CORPUS
    ;; ═══════════════════════════════════════════════════════════════════

    (test-corpus
     (location . "test-corpus/")
     (categories
      ((valid . 2)
       (edge-cases . 6)
       (malformed . 4)
       (unicode . 2)
       (injection . 3)
       (stress . 3)))
     (tests-include
      ("simple markdown parsing"
       "complex nested structures"
       "empty files"
       "frontmatter edge cases"
       "whitespace torture"
       "deep nesting"
       "multilingual unicode"
       "surrogate pairs and emoji"
       "unclosed frontmatter"
       "invalid YAML"
       "unclosed formatting"
       "binary content"
       "HTML/XSS injection"
       "path traversal attempts"
       "command injection attempts"
       "large file (8000+ lines)"
       "long lines (8KB+)"
       "many formatting markers")))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; INFRASTRUCTURE STATUS
    ;; ═══════════════════════════════════════════════════════════════════

    (infrastructure
     ((feature . "github-mirrors")
      (status . complete)
      (notes . "Hub-spoke: GitHub -> GitLab, Bitbucket on all 159 repos"))

     ((feature . "dependabot")
      (status . complete)
      (notes . "Vulnerability alerts enabled on all repos"))

     ((feature . "codeql")
      (status . complete)
      (notes . "Security scanning workflows on all repos"))

     ((feature . "repo-watcher")
      (status . complete)
      (notes . "Auto-config workflow in rhodium-standard-repositories"))

     ((feature . "template-repo")
      (status . complete)
      (notes . "rsr-template-repo with standard workflows")))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; FILES CREATED THIS SESSION
    ;; ═══════════════════════════════════════════════════════════════════

    (files-created-this-session
     ("test-corpus/valid/simple.md"
      "test-corpus/valid/complex.md"
      "test-corpus/edge-cases/empty.md"
      "test-corpus/edge-cases/frontmatter-only.md"
      "test-corpus/edge-cases/no-frontmatter.md"
      "test-corpus/edge-cases/whitespace-hell.md"
      "test-corpus/edge-cases/deeply-nested.md"
      "test-corpus/edge-cases/duplicate-ids.md"
      "test-corpus/unicode/multilingual.md"
      "test-corpus/unicode/surrogate-pairs.md"
      "test-corpus/malformed/unclosed-frontmatter.md"
      "test-corpus/malformed/invalid-yaml.md"
      "test-corpus/malformed/unclosed-formatting.md"
      "test-corpus/malformed/binary-garbage.md"
      "test-corpus/injection/html-injection.md"
      "test-corpus/injection/path-traversal.md"
      "test-corpus/injection/command-injection.md"
      "test-corpus/stress/huge-file.md"
      "test-corpus/stress/long-lines.md"
      "scripts/test-harness.sh"
      "scripts/validate-output.sh"))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; CONTEXT NOTES
    ;; ═══════════════════════════════════════════════════════════════════

    (context-notes
     "Building harsh test infrastructure for all 12 poly-ssg engines.
      Test corpus includes edge cases, malformed inputs, unicode, injection attempts.
      All engines have source code but no test scripts yet.
      Creating test-all.sh for each engine with warnings-as-errors.
      Master test harness orchestrates all engine tests.
      All 159 GitHub repos have security features enabled.
      Hub-spoke mirroring configured for GitLab and Bitbucket.")))

;;; End of STATE.scm
