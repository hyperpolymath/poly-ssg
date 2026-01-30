---
title: poly-ssg - Polyglot Static Site Generator Metaframework
description: MCP-native metaframework for building and managing polyglot static site generators with formal verification
date: 2026-01-30
license: PMPL-1.0-or-later
---

# poly-ssg

**Polyglot Static Site Generator Metaframework**

![License: PMPL-1.0](https://img.shields.io/badge/License-PMPL--1.0-indigo.svg)
![Status: Active Development](https://img.shields.io/badge/Status-Active-green.svg)

A metaframework for building and managing polyglot static site generators with MCP (Model Context Protocol) integration and formal verification capabilities.

## Philosophy

**poly-ssg** embraces the palimpsest nature of knowledge systems. Like manuscript layers building upon each other, static site generators should compose, interoperate, and preserve lineage across language boundaries.

Traditional SSG ecosystems are siloed by language. poly-ssg breaks these barriers by:

- **Language-agnostic orchestration** - Coordinate generators written in any language
- **Formal verification hooks** - Integrate proof systems (a2ml, k9-svc) at build time
- **MCP-native design** - First-class Model Context Protocol support
- **Provenance preservation** - Track content lineage across transformations

## Current Engines

### Casket-SSG (Reference Implementation) ✓

**Language:** Haskell
**Status:** Production Ready (v2.0.0)
**Repository:** [hyperpolymath/casket-ssg](https://github.com/hyperpolymath/casket-ssg)

First SSG with formal verification integration. Features:

- Markdown, AsciiDoc, RST, Org-mode support (via Pandoc)
- a2ml integration (typed, verifiable markup)
- k9-svc validation (self-validating components)
- Spell checking (hunspell/aspell)
- i18n support (en, es, fr, de)
- Gnosis metadata integration

**Deployed sites:**
- [axel-protocol.org](https://axel-protocol.org)
- [stamp-protocol.org](https://stamp-protocol.org)
- [asdf-plugins registry](https://hyperpolymath.github.io/asdf-plugins/)

### Planned Engines

- **hackenbush-ssg** (ReScript) - Fast, type-safe with JSX templating
- **bunsenite-ssg** (Nickel) - Configuration-as-code with type inference
- **cobalt-ssg** (Rust) - Low-latency with incremental builds

## MCP Integration

poly-ssg provides a unified MCP server interface:

```javascript
// Query any engine through MCP
const result = await mcp.call("poly-ssg/build", {
  engine: "casket-ssg",
  input: "content/",
  output: "_site/"
});
```

Engines register capabilities (Markdown, AsciiDoc, i18n, etc.) and poly-ssg routes requests to the appropriate implementation.

## Formal Verification

poly-ssg engines can integrate verification systems:

- **a2ml** - Attested Markup Language with type-level content guarantees
- **k9-svc** - Self-Validating Components with runtime proofs
- **Idris2** - Dependent types for provable correctness

Example from Casket-SSG:

```haskell
-- Verify content compiles with a2ml type checker
verifyContent :: A2MLDoc -> Either TypeError HTML
```

## Use Cases

- **Multi-engine sites** - Use Casket for formal content, hackenbush for blogs
- **Proof-carrying content** - Mathematical papers with verified theorems
- **Compliance documentation** - Generate sites with provable properties
- **Research artifacts** - Preserve lineage and attribution chains

## License

**PMPL-1.0-or-later** (Palimpsest-MPL License)

Like a palimpsest manuscript, poly-ssg recognizes that static site generators carry layers of meaning - from original content to transformation logic to final presentation. This license protects both technical attribution and cultural context.

See the [Palimpsest License](https://github.com/hyperpolymath/palimpsest-license) for full details.

### Why PMPL for poly-ssg?

- **Emotional lineage** - Content transformations preserve author intent
- **Quantum-safe provenance** - Long-term attribution for generated sites
- **Ethical use framework** - Respect cultural and narrative context
- **AI training permitted** - With clear attribution obligations

## Getting Started

### Using Casket-SSG (Available Now)

```bash
# Clone the reference implementation
git clone https://github.com/hyperpolymath/casket-ssg
cd casket-ssg

# Build
cabal build

# Generate a site
cabal run casket-ssg build content/ _site/
```

### Contributing an Engine

See [ENGINE-SPEC.adoc](https://github.com/hyperpolymath/poly-ssg/blob/main/ENGINE-SPEC.adoc) for requirements.

## Resources

- **Repository:** [github.com/hyperpolymath/poly-ssg](https://github.com/hyperpolymath/poly-ssg)
- **Casket-SSG:** [github.com/hyperpolymath/casket-ssg](https://github.com/hyperpolymath/casket-ssg)
- **License:** [github.com/hyperpolymath/palimpsest-license](https://github.com/hyperpolymath/palimpsest-license)
- **Maintainer:** Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

---

Built with 🔮 by [Jonathan D.A. Jewell](https://github.com/hyperpolymath) | Licensed under [PMPL-1.0-or-later](https://github.com/hyperpolymath/palimpsest-license)
