;;; META.scm — poly-ssg Project Metadata
;;; Machine-readable project information for automation and discovery

(define meta
  '((project
     (name . "poly-ssg")
     (full-name . "Polyglot Static Site Generator")
     (version . "0.2.0")
     (license . "MIT")
     (homepage . "https://github.com/hyperpolymath/poly-ssg")
     (repository . "https://github.com/hyperpolymath/poly-ssg")
     (issue-tracker . "https://github.com/hyperpolymath/poly-ssg/issues")
     (documentation . "https://github.com/hyperpolymath/poly-ssg#readme"))

    (maintainers
     ((name . "hyperpolymath")
      (role . "lead")
      (email . #f)
      (github . "hyperpolymath")
      (gitlab . "hyperpolymath")
      (bitbucket . "hyperpolymath")))

    (keywords
     ("static-site-generator"
      "polyglot"
      "multi-language"
      "ocaml"
      "forth"
      "zig"
      "haskell"
      "prolog"
      "idris"
      "ada"
      "chapel"
      "rescript"
      "assemblyscript"
      "wasm"
      "markdown"
      "html"))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; MIRRORS
    ;; ═══════════════════════════════════════════════════════════════════

    (mirrors
     ((platform . "github")
      (url . "https://github.com/hyperpolymath/poly-ssg")
      (role . "hub")
      (primary . #t))

     ((platform . "gitlab")
      (url . "https://gitlab.com/hyperpolymath/poly-ssg")
      (role . "spoke")
      (sync . "push-mirror"))

     ((platform . "bitbucket")
      (url . "https://bitbucket.org/hyperpolymath/poly-ssg")
      (role . "spoke")
      (sync . "push-mirror")))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; ENGINE REGISTRY
    ;; ═══════════════════════════════════════════════════════════════════

    (engine-registry
     ((id . "forth-estate")
      (path . "engines/forth-estate")
      (standalone . "https://github.com/hyperpolymath/forth-estate-ssg")
      (language . "gforth")
      (min-version . "0.7.3"))

     ((id . "zigzag-ssg")
      (path . "engines/zigzag-ssg")
      (standalone . "https://github.com/hyperpolymath/zigzag-ssg")
      (language . "zig")
      (min-version . "0.11.0"))

     ((id . "yocaml-ssg")
      (path . "engines/yocaml-ssg")
      (standalone . "https://github.com/hyperpolymath/yocaml-ssg")
      (language . "ocaml")
      (min-version . "4.14.0"))

     ((id . "prodigy-ssg")
      (path . "engines/prodigy-ssg")
      (standalone . "https://github.com/hyperpolymath/prodigy-ssg")
      (language . "swipl")
      (min-version . "8.0.0"))

     ((id . "casket-ssg")
      (path . "engines/casket-ssg")
      (standalone . "https://github.com/hyperpolymath/casket-ssg")
      (language . "ghc")
      (min-version . "9.2.0"))

     ((id . "ddraig-ssg")
      (path . "engines/ddraig-ssg")
      (standalone . "https://github.com/hyperpolymath/ddraig-ssg")
      (language . "idris2")
      (min-version . "0.6.0"))

     ((id . "webforge-ssg")
      (path . "engines/webforge-ssg")
      (standalone . "https://github.com/hyperpolymath/webforge-ssg")
      (language . "gnat")
      (min-version . "12.0.0"))

     ((id . "rescribe-ssg")
      (path . "engines/rescribe-ssg")
      (standalone . "https://github.com/hyperpolymath/rescribe-ssg")
      (language . "rescript")
      (min-version . "10.0.0"))

     ((id . "wagasm-ssg")
      (path . "engines/wagasm-ssg")
      (standalone . "https://github.com/hyperpolymath/wagasm-ssg")
      (language . "assemblyscript")
      (min-version . "0.27.0"))

     ((id . "parallel-press-ssg")
      (path . "engines/parallel-press-ssg")
      (standalone . "https://github.com/hyperpolymath/parallel-press-ssg")
      (language . "chapel")
      (min-version . "1.30.0"))

     ((id . "terrapin-ssg")
      (path . "engines/terrapin-ssg")
      (standalone . "https://github.com/hyperpolymath/terrapin-ssg")
      (language . "python3")
      (min-version . "3.9.0"))

     ((id . "milk-ssg")
      (path . "engines/milk-ssg")
      (standalone . "https://github.com/hyperpolymath/milk-ssg")
      (language . "python3")
      (min-version . "3.9.0")))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; CI/CD
    ;; ═══════════════════════════════════════════════════════════════════

    (ci-cd
     ((workflow . "mirror.yml")
      (purpose . "Hub-spoke mirroring to GitLab and Bitbucket")
      (triggers . (push workflow_dispatch)))

     ((workflow . "codeql-analysis.yml")
      (purpose . "Security scanning")
      (triggers . (push pull_request schedule)))

     ((workflow . "test.yml")
      (purpose . "Run engine test suites")
      (triggers . (push pull_request))
      (status . planned)))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; STATISTICS
    ;; ═══════════════════════════════════════════════════════════════════

    (statistics
     (engines . 12)
     (languages . 12)
     (total-lines . 4857)
     (test-corpus-files . 20)
     (mirrors . 3)
     (last-updated . "2025-12-13"))

    ;; ═══════════════════════════════════════════════════════════════════
    ;; ROADMAP
    ;; ═══════════════════════════════════════════════════════════════════

    (roadmap
     ((milestone . "v0.2.0")
      (status . in-progress)
      (goals . ("Harsh test suites for all engines"
                "Warnings as errors enforcement"
                "Security injection tests"
                "Unicode compliance")))

     ((milestone . "v0.3.0")
      (status . planned)
      (goals . ("Performance benchmarks"
                "Cross-engine output comparison"
                "Documentation generation")))

     ((milestone . "v1.0.0")
      (status . planned)
      (goals . ("All engines passing all tests"
                "CLI unification"
                "Package publishing"
                "User documentation"))))))

;;; End of META.scm
