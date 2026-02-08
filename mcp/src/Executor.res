// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Type-safe command execution for SSG CLIs

type ssg =
  // Rust
  | Zola
  | Cobalt
  | MdBook
  // Elixir
  | Serum
  | NimblePublisher
  | Tableau
  // Haskell
  | Hakyll
  | Ema
  // OCaml
  | YOCaml
  // F#
  | Fornax
  // Swift
  | Publish
  // Common Lisp
  | Coleslaw
  // Kotlin
  | Orchid
  // Julia
  | Franklin
  | StaticWebPages
  | Documenter
  // Clojure
  | Cryogen
  | Perun
  | Babashka
  // Scala
  | Laika
  | ScalaTex
  // Erlang
  | Zotonic
  // Racket
  | Pollen
  | Frog
  // D
  | Reggae
  // Tcl
  | Wub
  // Crystal
  | Marmot
  // Nim
  | Nimrod
  // Pony
  | Corral

type commandResult = {
  success: bool,
  stdout: string,
  stderr: string,
  code: int,
}

// Allowed subcommands for SSG operations
let allowedCommands = [
  "init",
  "new",
  "create",
  "build",
  "serve",
  "watch",
  "deploy",
  "check",
  "clean",
  "version",
  "help",
  "generate",
  "preview",
  "publish",
  "render",
]

// Sanitize arguments to prevent shell injection
let sanitizeArg = arg =>
  arg->String.replaceRegExp(%re("/[;&|`$(){}\\[\\]<>]/g"), "")

// Get the binary name for each SSG
let getBinary = ssg =>
  switch ssg {
  | Zola => "zola"
  | Cobalt => "cobalt"
  | MdBook => "mdbook"
  | Serum => "mix"
  | NimblePublisher => "mix"
  | Tableau => "mix"
  | Hakyll => "stack"
  | Ema => "ema"
  | YOCaml => "yocaml"
  | Fornax => "fornax"
  | Publish => "publish"
  | Coleslaw => "coleslaw"
  | Orchid => "orchid"
  | Franklin => "julia"
  | StaticWebPages => "julia"
  | Documenter => "julia"
  | Cryogen => "lein"
  | Perun => "boot"
  | Babashka => "bb"
  | Laika => "laika"
  | ScalaTex => "mill"
  | Zotonic => "zotonic"
  | Pollen => "raco"
  | Frog => "raco"
  | Reggae => "reggae"
  | Wub => "wub"
  | Marmot => "marmot"
  | Nimrod => "nimrod"
  | Corral => "corral"
  }

// Get language for display
let getLanguage = ssg =>
  switch ssg {
  | Zola | Cobalt | MdBook => "Rust"
  | Serum | NimblePublisher | Tableau => "Elixir"
  | Hakyll | Ema => "Haskell"
  | YOCaml => "OCaml"
  | Fornax => "F#"
  | Publish => "Swift"
  | Coleslaw => "Common Lisp"
  | Orchid => "Kotlin"
  | Franklin | StaticWebPages | Documenter => "Julia"
  | Cryogen | Perun | Babashka => "Clojure"
  | Laika | ScalaTex => "Scala"
  | Zotonic => "Erlang"
  | Pollen | Frog => "Racket"
  | Reggae => "D"
  | Wub => "Tcl"
  | Marmot => "Crystal"
  | Nimrod => "Nim"
  | Corral => "Pony"
  }
