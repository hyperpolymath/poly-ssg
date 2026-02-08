;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SPDX-FileCopyrightText: 2025 hyperpolymath
;;
;; Guix package definition for poly-ssg-mcp
;; Build: guix build -f guix.scm
;; Shell: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system trivial)
             (guix licenses)
             (gnu packages node)
             (gnu packages web))

(define-public poly-ssg-mcp
  (package
    (name "poly-ssg-mcp")
    (version "1.1.0")
    (source
     (local-file "." "poly-ssg-mcp-checkout"
                 #:recursive? #t
                 #:select? (git-predicate ".")))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (source (assoc-ref %build-inputs "source"))
                (deno (assoc-ref %build-inputs "deno"))
                (node (assoc-ref %build-inputs "node"))
                (lib (string-append out "/lib/poly-ssg-mcp"))
                (bin (string-append out "/bin")))
           ;; Copy source
           (mkdir-p lib)
           (copy-recursively source lib)

           ;; Create wrapper script
           (mkdir-p bin)
           (call-with-output-file (string-append bin "/poly-ssg-mcp")
             (lambda (port)
               (format port "#!~a/bin/sh~%" (assoc-ref %build-inputs "bash"))
               (format port "exec ~a/bin/deno run \\\n" deno)
               (format port "  --allow-run --allow-read --allow-write --allow-env --allow-net \\\n")
               (format port "  --config=~a/deno.json \\\n" lib)
               (format port "  ~a/main.js \"$@\"\n" lib)))
           (chmod (string-append bin "/poly-ssg-mcp") #o755)
           #t))))
    (native-inputs
     (list node-lts))
    (inputs
     (list deno))
    (synopsis "MCP server for 29 static site generators")
    (description
     "Polyglot SSG MCP is a Model Context Protocol (MCP) server that provides
unified access to 29 static site generators across 20 programming languages.
It focuses on functional programming languages, systems languages, and
academic tools rather than mainstream JavaScript/Python/Ruby SSGs.

Supported languages include: Rust (Zola, Cobalt, mdBook), Elixir (Serum),
Haskell (Hakyll), OCaml (YOCaml), F# (Fornax), Common Lisp (Coleslaw),
Julia (Franklin.jl), Clojure (Cryogen), Scala (Laika), and more.")
    (home-page "https://github.com/hyperpolymath/poly-ssg-mcp")
    (license expat)))

;; HTTP server variant
(define-public poly-ssg-mcp-http
  (package
    (inherit poly-ssg-mcp)
    (name "poly-ssg-mcp-http")
    (arguments
     (substitute-keyword-arguments (package-arguments poly-ssg-mcp)
       ((#:builder builder)
        `(begin
           (use-modules (guix build utils))
           (let* ((out (assoc-ref %outputs "out"))
                  (source (assoc-ref %build-inputs "source"))
                  (deno (assoc-ref %build-inputs "deno"))
                  (lib (string-append out "/lib/poly-ssg-mcp"))
                  (bin (string-append out "/bin")))
             (mkdir-p lib)
             (copy-recursively source lib)
             (mkdir-p bin)
             (call-with-output-file (string-append bin "/poly-ssg-mcp-http")
               (lambda (port)
                 (format port "#!~a/bin/sh~%" (assoc-ref %build-inputs "bash"))
                 (format port "export MCP_HTTP_MODE=true~%")
                 (format port "exec ~a/bin/deno run \\\n" deno)
                 (format port "  --allow-run --allow-read --allow-write --allow-env --allow-net \\\n")
                 (format port "  --config=~a/deno.json \\\n" lib)
                 (format port "  ~a/main.js \"$@\"\n" lib)))
             (chmod (string-append bin "/poly-ssg-mcp-http") #o755)
             #t)))))
    (synopsis "HTTP variant of Polyglot SSG MCP server")))

poly-ssg-mcp
