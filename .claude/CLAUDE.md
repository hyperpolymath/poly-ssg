# Claude Code Instructions for poly-ssg

## Project Context

poly-ssg is a polyglot static site generator framework. The `engines/` directory contains SSG implementations in different languages, all implementing the same contract.

### Active Engines

- **rescript-wasm**: ReScript to WASM-GC compiler backend (OCaml)
- **forth-estate**: Forth-based SSG (Gforth)

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

- New features require tests in `test/test_compile.ml`
- Use existing test helpers: `test`, `assert_eq`, `assert_contains`
- Expected WAT outputs go in `test/fixtures/`

## Build Commands

```bash
# ReScript-WASM
cd engines/rescript-wasm
dune build        # Build
dune test         # Test (21 tests)
dune exec rescript_wasm -- add  # Generate WAT

# Validate WAT (if wasm-tools installed)
wasm-tools validate --features gc output.wat
```

## Commit Convention

```
feat: new features
fix: bug fixes
chore: maintenance/deps
docs: documentation
test: test changes
refactor: code restructuring
```
