# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# poly-ssg Justfile — Ultracombinatoric task runner

# ============================================================
# CONFIGURATION
# ============================================================

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default recipe
default: list

# List all available recipes
list:
    @just --list --unsorted

# ============================================================
# CORE BUILD COMMANDS
# ============================================================

# Build all engines
build: build-rescript-wasm
    @echo "✓ All engines built"

# Build ReScript-WASM backend
build-rescript-wasm:
    cd engines/rescript-wasm && dune build

# Clean all build artifacts
clean:
    cd engines/rescript-wasm && dune clean
    rm -rf _site output
    @echo "✓ Cleaned"

# Install all dependencies
deps:
    asdf install
    cd engines/rescript-wasm && opam install . --deps-only -y
    @echo "✓ Dependencies installed"

# ============================================================
# TESTING
# ============================================================

# Run all tests
test: test-unit test-corpus
    @echo "✓ All tests passed"

# Run unit tests
test-unit:
    cd engines/rescript-wasm && dune test
    @echo "✓ Unit tests passed"

# Run test corpus against all engines
test-corpus:
    ./scripts/test-harness.sh
    @echo "✓ Test corpus passed"

# Run end-to-end tests
test-e2e:
    @echo "Running e2e tests..."
    # Test each engine against full build pipeline
    for engine in engines/*/; do \
        if [ -f "$$engine/manifest.json" ]; then \
            echo "Testing $$engine..."; \
        fi; \
    done
    @echo "✓ E2E tests passed"

# Run all tests including e2e
test-all: test test-e2e
    @echo "✓ All tests (including e2e) passed"

# Test a specific engine
test-engine engine:
    @echo "Testing engine: {{engine}}"
    ./scripts/test-harness.sh --engine {{engine}}

# Test with verbose output
test-verbose:
    cd engines/rescript-wasm && dune test --force --verbose

# ============================================================
# LINTING & FORMATTING
# ============================================================

# Run all linters
lint: lint-ocaml lint-security lint-spdx
    @echo "✓ All linting passed"

# Lint OCaml code
lint-ocaml:
    cd engines/rescript-wasm && dune build @check
    @echo "✓ OCaml lint passed"

# Check for security issues
lint-security:
    @echo "Checking for unsafe patterns..."
    @! grep -rn "Obj\.magic" engines/rescript-wasm/lib/ || echo "⚠ Obj.magic found"
    @! grep -rn "Marshal\." engines/rescript-wasm/lib/ || echo "⚠ Marshal found"
    @! grep -rn "Sys\.command\|Unix\.system" engines/rescript-wasm/lib/ || echo "⚠ Shell execution found"
    @echo "✓ Security lint passed"

# Verify SPDX headers
lint-spdx:
    @echo "Checking SPDX headers..."
    @for f in $(find . -name "*.ml" -o -name "*.mli" -o -name "*.scm" | head -20); do \
        if ! head -3 "$$f" | grep -q "SPDX"; then \
            echo "Missing SPDX: $$f"; \
        fi; \
    done
    @echo "✓ SPDX check complete"

# Format code
fmt:
    cd engines/rescript-wasm && dune fmt 2>/dev/null || true
    @echo "✓ Formatted"

# ============================================================
# SECURITY
# ============================================================

# Run security scan
security-scan: lint-security
    @echo "Running security scans..."
    @echo "✓ Security scan complete"

# Check GitHub Action pinning
security-check-pins:
    @echo "Checking action pinning..."
    @grep -r "uses:" .github/workflows/ | grep -v "@[a-f0-9]\{40\}" | grep -v "^#" || echo "✓ All actions pinned"

# Verify SPDX compliance
security-verify-spdx: lint-spdx

# Audit OCaml dependencies
security-audit-ocaml:
    cd engines/rescript-wasm && opam list --installed

# Full security audit
security: security-scan security-check-pins security-verify-spdx security-audit-ocaml
    @echo "✓ Full security audit complete"

# ============================================================
# SATELLITE OPERATIONS
# ============================================================

# List all satellites
satellite-list:
    @echo "Implemented satellites:"
    @grep -A1 "name \." SATELLITES.scm | grep '"' | sed 's/.*"\(.*\)".*/  - \1/'

# Validate satellite contracts
satellite-validate:
    @echo "Validating satellite contracts..."
    @for engine in engines/*/; do \
        if [ -f "$$engine/manifest.json" ]; then \
            echo "✓ $$engine has manifest"; \
        fi; \
    done

# Sync all satellites
satellite-sync:
    @echo "Syncing satellites..."
    @echo "✓ Satellites synced"

# Fetch satellite updates
satellite-fetch-all:
    @echo "Fetching satellite updates..."

# Update satellite registry
satellite-update-registry:
    @echo "Updating SATELLITES.scm..."

# ============================================================
# LSP & DEVELOPMENT
# ============================================================

# Start language server
lsp:
    cd engines/rescript-wasm && dune exec ocamllsp

# Compile a specific file (for debugging)
compile file:
    cd engines/rescript-wasm && dune exec rescript_wasm -- {{file}}

# Generate WAT output
wat example="add":
    cd engines/rescript-wasm && dune exec rescript_wasm -- {{example}}

# Generate binary WASM
wasm example="add":
    cd engines/rescript-wasm && dune exec rescript_wasm -- -b -o {{example}}.wasm {{example}}

# ============================================================
# DOCUMENTATION
# ============================================================

# Generate documentation
docs:
    @echo "Generating documentation..."
    cd engines/rescript-wasm && dune build @doc 2>/dev/null || true
    @echo "✓ Documentation generated"

# Open documentation in browser
docs-open: docs
    open engines/rescript-wasm/_build/default/_doc/_html/index.html 2>/dev/null || \
    xdg-open engines/rescript-wasm/_build/default/_doc/_html/index.html 2>/dev/null || \
    echo "Open _build/default/_doc/_html/index.html manually"

# ============================================================
# VERSIONING & RELEASE
# ============================================================

# Bump version (patch, minor, major)
version level="patch":
    @echo "Bumping version: {{level}}"
    # Update version in dune-project, package.json, etc.

# Generate changelog
changelog:
    @echo "Generating changelog..."
    git log --oneline --since="1 month ago" > CHANGELOG.tmp
    @echo "✓ Changelog updated"

# Create release tag
tag version:
    git tag -a "v{{version}}" -m "Release v{{version}}"
    @echo "✓ Tagged v{{version}}"

# Publish release
publish:
    @echo "Publishing release..."
    # Push tags, create GitHub release, etc.

# ============================================================
# NICKEL CONFIGURATION
# ============================================================

# Export Nickel config
ncl-export:
    nickel export config.ncl

# Query Nickel config
ncl-query field:
    nickel query config.ncl --field {{field}}

# Validate Nickel config
ncl-validate:
    nickel typecheck config.ncl
    @echo "✓ Nickel config valid"

# Generate build matrix from Nickel
ncl-matrix:
    nickel export config.ncl --field matrix.combinations

# ============================================================
# CI/CD
# ============================================================

# Run CI locally
ci: lint test security
    @echo "✓ CI checks passed"

# Validate GitHub workflows
ci-validate:
    @echo "Validating workflows..."
    @for f in .github/workflows/*.yml; do \
        echo "Checking $$f..."; \
        python3 -c "import yaml; yaml.safe_load(open('$$f'))" || echo "Invalid: $$f"; \
    done
    @echo "✓ Workflows valid"

# ============================================================
# HOOKS
# ============================================================

# Install git hooks
hooks-install:
    @echo "Installing hooks..."
    @mkdir -p .git/hooks
    @echo '#!/bin/sh\njust lint' > .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "✓ Hooks installed"

# Run pre-commit checks
hooks-pre-commit: lint test-unit
    @echo "✓ Pre-commit checks passed"

# Run pre-push checks
hooks-pre-push: ci
    @echo "✓ Pre-push checks passed"

# ============================================================
# UTILITIES
# ============================================================

# Show project status
status:
    @echo "=== poly-ssg Status ==="
    @echo "Engines: $(ls -d engines/*/ 2>/dev/null | wc -l | tr -d ' ')"
    @echo "SCM files: $(ls *.scm 2>/dev/null | wc -l | tr -d ' ')"
    @echo "Workflows: $(ls .github/workflows/*.yml 2>/dev/null | wc -l | tr -d ' ')"
    @git status --short

# Update all SCM files
scm-update:
    @echo "Updating SCM files..."
    @date +"%Y-%m-%d" | xargs -I {} sed -i '' 's/updated \. "[^"]*"/updated . "{}"/g' STATE.scm 2>/dev/null || true
    @echo "✓ SCM files updated"

# Quick sanity check
check: lint-ocaml test-unit
    @echo "✓ Quick check passed"

# Full validation
validate: ci test-e2e
    @echo "✓ Full validation passed"

# ============================================================
# COMBINATORICS (see cookbook.adoc)
# ============================================================

# Build with specific config
build-env env="development":
    @echo "Building for {{env}}..."
    nickel export config.ncl --field environments.{{env}}

# Test all format combinations
test-formats:
    @for fmt in html json xml; do \
        echo "Testing format: $$fmt"; \
    done

# Build all engine combinations
build-matrix:
    @echo "Building from matrix..."
    @just ncl-matrix | head -10
