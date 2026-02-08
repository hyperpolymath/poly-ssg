# Casket SSG

[![CI](https://github.com/hyperpolymath/casket-ssg/actions/workflows/ci.yml/badge.svg)](https://github.com/hyperpolymath/casket-ssg/actions/workflows/ci.yml)
image:https://img.shields.io/badge/License-MPL_2.0-blue.svg[MPL-2.0-or-later,link="https://opensource.org/licenses/MPL-2.0"]
[![Language: Haskell](https://img.shields.io/badge/Language-Haskell-purple.svg)](https://www.haskell.org/)

> Functional static site generator in Haskell

**Casket** brings pure functional elegance to static site generation. Immutable data, composable functions, lazy evaluation.

## Features

- λ Pure functional design
- 📝 Markdown parser with pattern matching
- 📋 YAML frontmatter extraction
- 🎨 Template substitution engine
- 🔄 Lazy evaluation for efficiency
- 🔒 Strong static typing

## Installation

```bash
# Install GHC
# Ubuntu/Debian
sudo apt-get install ghc

# Compile
ghc -o casket Casket.hs
```

## Usage

```bash
./casket test-markdown
./casket test-frontmatter
./casket test-full
```

## Why Haskell?

- **Purity**: No side effects, predictable behavior
- **Type inference**: Strong types without verbosity
- **Pattern matching**: Elegant parsing code
- **Lazy evaluation**: Process only what you need

## Part of poly-ssg

This is one of 12 polyglot static site generators. See [poly-ssg](https://github.com/hyperpolymath/poly-ssg) for the full collection.

## License

MIT © [hyperpolymath](https://github.com/hyperpolymath)

## Topics

`static-site-generator` `ssg` `haskell` `functional` `pure-functional` `lazy-evaluation` `type-safe` `polyglot`
