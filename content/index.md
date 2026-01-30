---
title: Poly SSG - One Contract, Many Paradigms
description: Polyglot static site generator framework where each engine embodies its language's philosophy
---

# Poly SSG

_One contract. Many paradigms. Every paradigm teaches._

A polyglot static site generator framework where each engine embodies its language's philosophy—from dependently-typed correctness to stack-based minimalism—unified through a common MCP interface.

## Who Is This For?

- **Paradigm explorers** — See the same problem solved through functional, logic, parallel, and stack-based lenses
- **Language enthusiasts** — Each engine is idiomatic, not a transliteration
- **MCP practitioners** — Switch between engines without changing your tooling
- **Educators** — Demonstrate that there's no "one true way" to generate sites

## Why poly-ssg?

### Paradigm Purity

Each engine embraces its language's strengths. Haskell stays pure. Prolog stays declarative. Forth stays stack-oriented. No lowest-common-denominator compromises.

### One Contract, Many Implementations

The MCP contract defines _what_ an SSG does. Each engine decides _how_. Your AI assistant, build scripts, and workflows remain unchanged when you switch paradigms.

### Production-Ready Satellites

Each engine is a standalone project. **Use Casket (Haskell) in production** while exploring Ddraig (Idris 2) for provable correctness. They share a contract, not a codebase.

## Engines

| Engine | Language | Paradigmatic Strength | Status |
|--------|----------|----------------------|--------|
| **Casket** | Haskell | Pure functional, a2ml + k9-svc verification | ✅ **Production (v1.0)** |
| **Ddraig** | Idris 2 | Dependently-typed, compile-time proofs | 🔧 In Development |
| **Estate** | Forth | Stack-based, minimal dependencies | 🔧 In Development |
| **Parallax** | Chapel | Data-parallel, massive scale | 🔧 In Development |
| **Prodigy** | Prolog | Logic-based, declarative rules | 🔧 In Development |
| **Rescribe** | ReScript | Type-safe JS compilation | 🔧 In Development |
| **Zigzag** | Zig | Zero-overhead, explicit control | 🔧 In Development |

## Casket SSG - First Production Engine

**casket-ssg v1.0** is **production-ready** and powers this site!

### Features

- ✅ Markdown & a2ml content formats
- ✅ YAML frontmatter
- ✅ External template system
- ✅ Asset pipeline (CSS, images auto-copy)
- ✅ Site configuration (config.yaml)
- ✅ **a2ml integration** (typed, verifiable markup)
- ✅ **k9-svc validation** (self-validating components)

**Unique:** First SSG with **formal verification** built-in.

### Quick Start

```bash
# Clone casket-ssg
git clone https://github.com/hyperpolymath/casket-ssg
cd casket-ssg

# Build
stack build

# Build your site
casket-ssg build content _site
```

## Quick Links

- [casket-ssg Repository](https://github.com/hyperpolymath/casket-ssg)
- [poly-ssg-mcp (MCP Interface)](https://github.com/hyperpolymath/poly-ssg-mcp)
- [Example Site: axel-protocol.org](https://axel-protocol.org) (Built with casket-ssg)
- [Contributing](https://github.com/hyperpolymath/poly-ssg/blob/main/CONTRIBUTING.adoc)

## License

MPL-2.0-or-later | Philosophy: [Palimpsest](https://github.com/hyperpolymath/palimpsest-license)

---

_This site is built with **casket-ssg** v1.0 (Haskell engine)_
