;;; ECOSYSTEM.scm — poly-ssg Ecosystem Map
;;; Defines relationships between engines, languages, and toolchains

(define ecosystem
  '((name . "poly-ssg")
    (description . "Polyglot Static Site Generator Framework")
    (tagline . "One contract, twelve languages, zero compromises")

    ;; ═══════════════════════════════════════════════════════════════════
    ;; LANGUAGE FAMILIES
    ;; ═══════════════════════════════════════════════════════════════════

    (language-families
     ((family . "ml")
      (languages . (ocaml rescript haskell))
      (engines . (yocaml-ssg rescribe-ssg casket-ssg))
      (traits . (type-safe functional immutable)))

     ((family . "systems")
      (languages . (zig ada))
      (engines . (zigzag-ssg webforge-ssg))
      (traits . (memory-safe low-level embedded-friendly)))

     ((family . "stack")
      (languages . (forth))
      (engines . (forth-estate))
      (traits . (concatenative minimal postfix)))

     ((family . "logic")
      (languages . (prolog idris))
      (engines . (prodigy-ssg ddraig-ssg))
      (traits . (declarative logic-programming dependent-types)))

     ((family . "parallel")
      (languages . (chapel))
      (engines . (parallel-press-ssg))
      (traits . (parallel distributed scientific)))

     ((family . "wasm")
      (languages . (assemblyscript))
      (engines . (wagasm-ssg))
      (traits . (browser portable sandboxed)))

     ((family . "esoteric")
      (languages . (logo cow))
      (engines . (terrapin-ssg milk-ssg))
      (traits . (educational artistic minimalist))))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; TOOLCHAINS
    ;; ═══════════════════════════════════════════════════════════════════

    (toolchains
     ((engine . "forth-estate")
      (compiler . "gforth")
      (package-manager . #f)
      (build-system . "direct")
      (test-command . "gforth forth-estate.fs -e 'test-all bye'")
      (warning-flags . ("-silent" "-depth0")))

     ((engine . "zigzag-ssg")
      (compiler . "zig")
      (package-manager . "zig-build")
      (build-system . "zig")
      (test-command . "zig build test")
      (warning-flags . ("-Werror" "--warn-unused-result")))

     ((engine . "yocaml-ssg")
      (compiler . "ocamlopt")
      (package-manager . "opam")
      (build-system . "dune")
      (test-command . "dune test")
      (warning-flags . ("-strict-sequence" "-safe-string" "-w" "+a-4-40-42-44")))

     ((engine . "prodigy-ssg")
      (compiler . "swipl")
      (package-manager . #f)
      (build-system . "direct")
      (test-command . "swipl -g run_tests -t halt prodigy.pl")
      (warning-flags . ("-W" "all")))

     ((engine . "casket-ssg")
      (compiler . "ghc")
      (package-manager . "cabal")
      (build-system . "cabal")
      (test-command . "cabal test")
      (warning-flags . ("-Wall" "-Werror" "-Wcompat" "-Wincomplete-patterns")))

     ((engine . "ddraig-ssg")
      (compiler . "idris2")
      (package-manager . "pack")
      (build-system . "idris2")
      (test-command . "idris2 --check Ddraig.idr")
      (warning-flags . ("--warnpartial" "--warnreach")))

     ((engine . "webforge-ssg")
      (compiler . "gnat")
      (package-manager . "alire")
      (build-system . "gprbuild")
      (test-command . "gprbuild -P webforge.gpr && ./webforge_test")
      (warning-flags . ("-gnatwe" "-gnatwj" "-gnatwa")))

     ((engine . "rescribe-ssg")
      (compiler . "rescript")
      (package-manager . "npm")
      (build-system . "rescript")
      (test-command . "npm test")
      (warning-flags . ("-w")))

     ((engine . "wagasm-ssg")
      (compiler . "asc")
      (package-manager . "npm")
      (build-system . "npm")
      (test-command . "npm test")
      (warning-flags . ("--pedantic")))

     ((engine . "parallel-press-ssg")
      (compiler . "chpl")
      (package-manager . "mason")
      (build-system . "mason")
      (test-command . "mason test")
      (warning-flags . ("--warnings" "--warn-unstable")))

     ((engine . "terrapin-ssg")
      (compiler . "python3")
      (package-manager . "pip")
      (build-system . "direct")
      (test-command . "python3 -m pytest")
      (warning-flags . ("-W" "error" "-Werror")))

     ((engine . "milk-ssg")
      (compiler . "python3")
      (package-manager . "pip")
      (build-system . "direct")
      (test-command . "python3 -m pytest")
      (warning-flags . ("-W" "error" "-Werror"))))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; SSG CONTRACT
    ;; ═══════════════════════════════════════════════════════════════════

    (contract
     (name . "SSG Interface Contract")
     (version . "1.0.0")
     (operations
      ((name . "parse-frontmatter")
       (input . "markdown-with-yaml")
       (output . "(frontmatter-map . content)")
       (required . #t))

      ((name . "parse-markdown")
       (input . "markdown-string")
       (output . "html-string")
       (required . #t))

      ((name . "apply-template")
       (input . "(template-string . variables-map)")
       (output . "html-string")
       (required . #t))

      ((name . "build")
       (input . "(source-dir . output-dir)")
       (output . "file-count")
       (required . #t))

      ((name . "watch")
       (input . "(source-dir . callback)")
       (output . "watcher-handle")
       (required . #f))

      ((name . "serve")
       (input . "(output-dir . port)")
       (output . "server-handle")
       (required . #f))))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; QUALITY GATES
    ;; ═══════════════════════════════════════════════════════════════════

    (quality-gates
     ((gate . "compile")
      (description . "Must compile with all warnings as errors")
      (required . #t))

     ((gate . "test-valid")
      (description . "Must pass all valid input tests")
      (required . #t))

     ((gate . "test-edge-cases")
      (description . "Must handle edge cases gracefully")
      (required . #t))

     ((gate . "test-malformed")
      (description . "Must not crash on malformed input")
      (required . #t))

     ((gate . "test-unicode")
      (description . "Must handle unicode correctly")
      (required . #t))

     ((gate . "test-security")
      (description . "Must sanitize injection attempts")
      (required . #t))

     ((gate . "test-stress")
      (description . "Must handle large files without timeout")
      (required . #f)))))

;;; End of ECOSYSTEM.scm
