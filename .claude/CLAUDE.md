# Claude Code Instructions for poly-ssg

## Project Context

poly-ssg is a polyglot static site generator framework. The `engines/` directory contains SSG implementations in 12 different languages, all implementing the same contract.

### Engine Registry (12 engines)

| Engine | Language | Lines | Status |
|--------|----------|-------|--------|
| forth-estate | Gforth | 925 | Has code, needs tests |
| parallel-press | Chapel | 695 | Has code, needs tests |
| terrapin-ssg | Python/Logo | 512 | Has code, needs tests |
| milk-ssg | Python/COW | 424 | Has code, needs tests |
| wagasm-ssg | AssemblyScript | 347 | Has code, needs tests |
| yocaml-ssg | OCaml | 326 | Has code, needs tests |
| zigzag-ssg | Zig | 324 | Has code, needs tests |
| rescribe-ssg | ReScript | 312 | Has code, needs tests |
| casket-ssg | Haskell | 307 | Has code, needs tests |
| ddraig-ssg | Idris 2 | 282 | Has code, needs tests |
| webforge-ssg | Ada | 255 | Has code, needs tests |
| prodigy-ssg | Prolog | 168 | Has code, needs tests |

### Companion Projects

- **rescript-wasm**: ReScript to WASM-GC compiler backend (OCaml, complete)

## Code Quality Rules

### Always

1. Use descriptive variable names across all files
2. Add type annotations to OCaml `.mli` interface files
3. Include stack comments `( -- )` in Forth code
4. Run `dune test` before suggesting OCaml changes are complete
5. Validate generated WAT mentally follows WASM-GC spec

### Never

1. Use `Obj.magic` in OCaml (breaks type safety)
2. Use `Marshal` for untrusted data (code execution risk)
3. Execute shell commands with unvalidated input
4. Suppress warnings without documented justification
5. Use catch-all `_` patterns without explicit intent

## Security Scanning

The project uses:
- **CodeQL**: JavaScript security analysis
- **Custom OCaml checks**: Scans for unsafe patterns (Obj.magic, Marshal, shell exec)
- **Dependabot**: Dependency updates

When reviewing code, check for:
- Array bounds violations
- Integer overflow in WASM i31 operations
- Unhandled pattern match cases
- Resource leaks (file handles, etc.)

## WASM-GC Type Mapping

| ReScript | WASM-GC | Notes |
|----------|---------|-------|
| int | (ref i31) | 31-bit signed, requires wrap/unwrap |
| float | f64 | Unboxed 64-bit float |
| bool | (ref i31) | 0=false, 1=true |
| string | (ref (array i32)) | UTF-8 bytes |
| unit | (ref $unit) | Empty struct |

## Testing Requirements

### Test Infrastructure

- Master test harness: `scripts/test-harness.sh`
- Output validator: `scripts/validate-output.sh`
- Test corpus: `test-corpus/` (20 files across 6 categories)

### Test Corpus Categories

| Category | Files | Purpose |
|----------|-------|---------|
| valid | 2 | Simple and complex valid inputs |
| edge-cases | 6 | Empty, whitespace, nesting, duplicates |
| malformed | 4 | Unclosed frontmatter, invalid YAML, binary |
| unicode | 2 | Multilingual, emoji, surrogate pairs |
| injection | 3 | XSS, path traversal, command injection |
| stress | 3 | Large files, long lines, many markers |

### Engine Test Scripts

Each engine should have `scripts/test-all.sh` with:
- Warnings as errors enabled
- All test corpus categories
- Output validation
- Performance checks

### ReScript-WASM Tests

- Tests in `engines/rescript-wasm/test/test_compile.ml`
- Use existing test helpers: `test`, `assert_eq`, `assert_contains`
- Expected WAT outputs go in `test/fixtures/`

## Build Commands

```bash
# ReScript-WASM
cd engines/rescript-wasm
dune build        # Build
dune test         # Test (54 tests - Phases 1-7 complete)
dune exec rescript_wasm -- add           # Generate WAT
dune exec rescript_wasm -- -b -o out.wasm add  # Binary WASM
dune exec rescript_wasm -- -O2 combined  # Optimized output
dune exec rescript_wasm -- --sourcemap add  # With source map

# Validate WAT (if wasm-tools installed)
wasm-tools validate --features gc output.wat
```

## Current Implementation Status

### ReScript-WASM Backend (All Phases Complete)

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Core compilation (constants, vars, functions, arithmetic) | ✅ Complete |
| 2 | Records, tuples, arrays (struct/array types) | ✅ Complete |
| 3 | Closures (captured variables, closure structs) | ✅ Complete |
| 4 | Variants (tagged unions, pattern matching, switch) | ✅ Complete |
| 5 | JS interop (imports, exports, external calls) | ✅ Complete |
| 6 | Binary emission, optimization, source maps | ✅ Complete |
| 7 | CLI integration, examples | ✅ Complete |

### CLI Options

- `-b, --binary` - Output binary WASM instead of WAT
- `-o, --output FILE` - Write to file
- `-O0/-O1/-O2` - Optimization levels
- `--sourcemap` - Generate source map
- `--list` - List available examples
- `--test` - Run built-in tests

## Commit Convention

```
feat: new features
fix: bug fixes
chore: maintenance/deps
docs: documentation
test: test changes
refactor: code restructuring
```
