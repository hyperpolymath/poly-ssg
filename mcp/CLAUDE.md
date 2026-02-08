# CLAUDE.md — AI Assistant Instructions

## Project Overview

**polyglot-ssg-mcp** is a unified MCP server for 29 static site generators across 20 programming languages. No mainstream JS/Python/Ruby - this focuses on functional programming, systems languages, and academic tools.

## Quick Reference

```bash
# Start the server
deno task start

# Development with watch
deno task dev

# Build ReScript
deno task res:build
```

## Supported Languages

| Language | SSGs |
|----------|------|
| Rust | Zola, Cobalt, mdBook |
| Elixir | Serum, NimblePublisher, Tableau |
| Haskell | Hakyll, Ema |
| OCaml | YOCaml |
| F# | Fornax |
| Swift | Publish |
| Common Lisp | Coleslaw |
| Kotlin | Orchid |
| Julia | Franklin.jl, StaticWebPages.jl, Documenter.jl |
| Clojure | Cryogen, Perun, Babashka |
| Scala | Laika, ScalaTex |
| Erlang | Zotonic |
| Racket | Pollen, Frog |
| D | Reggae |
| Tcl | Wub |
| Crystal | Marmot |
| Nim | Nimrod |
| Pony | Corral |

## Architecture

```
main.js           — Entry shim (imports ReScript modules for Deno)
lib/es6/src/      — Compiled ReScript output
src/              — ReScript source
  ├── adapters/       — 29 SSG-specific adapters (.res)
  ├── transport/      — HTTP transport implementation
  ├── bindings/       — Deno/MCP API bindings
  ├── Executor.res    — Type-safe command execution
  ├── Adapter.res     — Adapter interface types
  ├── Server.res      — MCP server logic
  └── Main.res        — ReScript entry point
```

## Adding a New SSG Adapter

1. Create `src/adapters/YourSSG.res`
2. Export: `name`, `language`, `description`, `connect`, `disconnect`, `isConnected`, `tools`
3. Follow existing adapter patterns (see `src/adapters/Zola.res`)
4. Add SPDX header: `// SPDX-License-Identifier: MIT`
5. Add import to `main.js`
6. Run `deno task res:build`

## Code Standards

- **License**: MIT with SPDX headers
- **Primary Language**: ReScript (compiled to ES6)
- **No TypeScript**: Use ReScript instead
- **No JavaScript adapters**: All adapters must be ReScript
- **main.js exception**: Entry shim only (imports ReScript modules)

## RSR Enforcement

Pre-commit hook enforces:
- No new TypeScript files
- No new JavaScript files (except main.js shim)
- All adapters must be in ReScript

## Security

- Commands executed via `Deno.Command` (not shell)
- Whitelist approach for subcommands
- Argument sanitization

## Related Projects

- [polyglot-db-mcp](https://github.com/hyperpolymath/polyglot-db-mcp)
- [polyglot-container-mcp](https://github.com/hyperpolymath/polyglot-container-mcp)
