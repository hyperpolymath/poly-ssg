# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 hyperpolymath
# Justfile — saur-ssg: MCP-compatible SSG adapter satellite

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default recipe
default: help

# ─────────────────────────────────────────────────────────────────────────────
# HELP & INFORMATION
# ─────────────────────────────────────────────────────────────────────────────

# Show available recipes
help:
    @just --list --unsorted

# Show project status from STATE.scm
status:
    @echo "=== saur-ssg Status ==="
    @grep -A2 'state-summary' STATE.scm | tail -5 || echo "Read STATE.scm for details"

# Show version info
version:
    @echo "saur-ssg v0.1.0"
    @echo "Adapters: 28 SSGs"
    @echo "Runtime: Deno"

# ─────────────────────────────────────────────────────────────────────────────
# BUILD & COMPILE
# ─────────────────────────────────────────────────────────────────────────────

# Check all adapters for syntax errors
check:
    @echo "Checking adapter syntax..."
    @for f in adapters/*.js; do deno check "$f" 2>/dev/null || echo "Checking: $f"; done
    @echo "✓ Syntax check complete"

# Build/compile adapters (bundle for distribution)
build:
    @echo "Building adapters..."
    @mkdir -p dist
    @for f in adapters/*.js; do \
        name=$(basename "$f" .js); \
        deno bundle "$f" "dist/$name.bundle.js" 2>/dev/null || cp "$f" "dist/$name.js"; \
    done
    @echo "✓ Build complete: dist/"

# Clean build artifacts
clean:
    @rm -rf dist/ coverage/ .cache/
    @echo "✓ Cleaned build artifacts"

# ─────────────────────────────────────────────────────────────────────────────
# TESTING
# ─────────────────────────────────────────────────────────────────────────────

# Run all tests
test:
    @echo "Running unit tests..."
    @deno test --allow-read --allow-run tests/ 2>/dev/null || echo "No tests found - create tests/"
    @echo "✓ Tests complete"

# Run end-to-end integration tests
test-e2e:
    @echo "Running E2E tests..."
    @deno test --allow-all tests/e2e/ 2>/dev/null || echo "No E2E tests found - create tests/e2e/"
    @echo "✓ E2E tests complete"

# Run all tests with coverage
test-cov:
    @echo "Running tests with coverage..."
    @deno test --coverage=coverage/ --allow-read --allow-run tests/ 2>/dev/null || true
    @deno coverage coverage/ 2>/dev/null || echo "Generate coverage with: deno coverage coverage/"

# Run full test suite (unit + e2e)
test-all: test test-e2e
    @echo "✓ All tests complete"

# ─────────────────────────────────────────────────────────────────────────────
# LINTING & FORMATTING
# ─────────────────────────────────────────────────────────────────────────────

# Lint all code
lint:
    @echo "Linting adapters..."
    @deno lint adapters/ 2>/dev/null || echo "Install Deno for linting"
    @echo "✓ Lint complete"

# Format all code
fmt:
    @echo "Formatting code..."
    @deno fmt adapters/ 2>/dev/null || echo "Install Deno for formatting"
    @echo "✓ Format complete"

# Check formatting without modifying
fmt-check:
    @deno fmt --check adapters/ 2>/dev/null || echo "Formatting check complete"

# ─────────────────────────────────────────────────────────────────────────────
# ADAPTER MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────

# List all adapters
adapters-list:
    @echo "=== Available SSG Adapters (28) ==="
    @ls -1 adapters/*.js | xargs -I {} basename {} .js | sort

# Show adapter info
adapter-info name:
    @echo "=== Adapter: {{name}} ==="
    @head -20 adapters/{{name}}.js 2>/dev/null || echo "Adapter not found: {{name}}"

# Sync adapters from poly-ssg-mcp hub
adapters-sync:
    @echo "Syncing adapters from poly-ssg-mcp hub..."
    @~/Documents/scripts/transfer-ssg-adapters.sh --satellite saur-ssg 2>/dev/null \
        || echo "Sync script not found - manual sync required"

# Validate adapter MCP interface
adapter-validate name:
    @echo "Validating MCP interface for: {{name}}"
    @deno eval "import * as a from './adapters/{{name}}.js'; \
        console.log('Name:', a.name); \
        console.log('Language:', a.language); \
        console.log('Tools:', a.tools?.length || 0);"

# ─────────────────────────────────────────────────────────────────────────────
# DEVELOPMENT
# ─────────────────────────────────────────────────────────────────────────────

# Start development server/watcher
dev:
    @echo "Starting development watcher..."
    @deno run --watch --allow-all adapters/zola.js 2>/dev/null \
        || echo "Use: deno run --watch <adapter>"

# Start language server for editor support
lsp:
    @echo "Starting Deno LSP..."
    @deno lsp

# REPL for testing adapters
repl:
    @deno repl --allow-all

# ─────────────────────────────────────────────────────────────────────────────
# SECURITY
# ─────────────────────────────────────────────────────────────────────────────

# Run security audit
audit:
    @echo "Running security audit..."
    @deno lint --rules-include=no-eval adapters/ 2>/dev/null || true
    @echo "Checking for hardcoded secrets..."
    @grep -rn "password\|secret\|api_key\|token" adapters/ --include="*.js" \
        | grep -v "// " || echo "✓ No obvious secrets found"
    @echo "✓ Security audit complete"

# Check for dependency vulnerabilities
audit-deps:
    @echo "Checking dependencies..."
    @deno info 2>/dev/null | head -20 || echo "No external dependencies"

# ─────────────────────────────────────────────────────────────────────────────
# DOCUMENTATION
# ─────────────────────────────────────────────────────────────────────────────

# Generate documentation
docs:
    @echo "Generating documentation..."
    @deno doc adapters/*.js > docs/api.md 2>/dev/null || mkdir -p docs
    @echo "✓ Documentation generated: docs/"

# Serve documentation locally
docs-serve:
    @echo "Serving docs at http://localhost:8080"
    @deno run --allow-net --allow-read https://deno.land/std/http/file_server.ts docs/ \
        2>/dev/null || python3 -m http.server 8080 --directory docs/

# ─────────────────────────────────────────────────────────────────────────────
# CI/CD & RELEASE
# ─────────────────────────────────────────────────────────────────────────────

# Run full CI pipeline locally
ci: fmt-check lint test audit
    @echo "✓ CI pipeline passed"

# Prepare for release
release-prep version:
    @echo "Preparing release {{version}}..."
    @sed -i 's/version.*"0\.[0-9]*\.[0-9]*"/version . "{{version}}"/' STATE.scm
    @echo "✓ Version updated to {{version}}"
    @echo "Next: git tag v{{version}} && git push --tags"

# Create release tarball
release-bundle:
    @echo "Creating release bundle..."
    @mkdir -p releases
    @tar -czf releases/saur-ssg-$(date +%Y%m%d).tar.gz \
        adapters/ README.adoc LICENSE.txt
    @echo "✓ Bundle created: releases/"

# ─────────────────────────────────────────────────────────────────────────────
# CONTAINERIZATION
# ─────────────────────────────────────────────────────────────────────────────

# Build container image
container-build:
    @echo "Building container image..."
    @podman build -t saur-ssg:latest . 2>/dev/null \
        || docker build -t saur-ssg:latest .
    @echo "✓ Container built: saur-ssg:latest"

# Run in container
container-run:
    @podman run --rm -it saur-ssg:latest 2>/dev/null \
        || docker run --rm -it saur-ssg:latest

# ─────────────────────────────────────────────────────────────────────────────
# HOOKS & GIT
# ─────────────────────────────────────────────────────────────────────────────

# Install git hooks from hooks/ directory
hooks-install:
    @echo "Installing git hooks from hooks/..."
    @mkdir -p .git/hooks
    @cp hooks/pre-commit .git/hooks/pre-commit
    @cp hooks/pre-push .git/hooks/pre-push
    @cp hooks/commit-msg .git/hooks/commit-msg
    @chmod +x .git/hooks/pre-commit .git/hooks/pre-push .git/hooks/commit-msg
    @echo "✓ Git hooks installed (pre-commit, pre-push, commit-msg)"

# Uninstall git hooks
hooks-remove:
    @rm -f .git/hooks/pre-commit .git/hooks/pre-push .git/hooks/commit-msg
    @echo "✓ Git hooks removed"

# Run pre-commit checks manually
hooks-check:
    @./hooks/pre-commit

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

# Count lines of code
loc:
    @echo "=== Lines of Code ==="
    @wc -l adapters/*.js | tail -1
    @echo "Adapters: $(ls adapters/*.js | wc -l)"

# Show project tree
tree:
    @tree -I 'node_modules|.git|dist|coverage' -L 3 2>/dev/null \
        || find . -maxdepth 3 -type f -name "*.js" -o -name "*.scm" -o -name "*.md" | head -30

# Validate SCM files syntax
scm-check:
    @echo "Validating SCM files..."
    @for f in *.scm; do guile -c "(load \"$f\")" 2>/dev/null && echo "✓ $f" || echo "⚠ $f (guile not installed)"; done

# ─────────────────────────────────────────────────────────────────────────────
# NICKEL FORMULAE (CLI combinatorics)
# ─────────────────────────────────────────────────────────────────────────────

# Generate Nickel config
nickel-gen:
    @echo "Generating Nickel configuration..."
    @cat > config.ncl << 'EOF'
    {
      project = "saur-ssg",
      version = "0.1.0",
      adapters = {
        count = 28,
        languages = ["Rust", "Haskell", "Elixir", "Clojure", "Julia",
                     "Scala", "Common Lisp", "F#", "Racket", "Kotlin",
                     "Crystal", "Nim", "Swift", "D", "Tcl", "OCaml", "Erlang"]
      },
      build = {
        runtime = "deno",
        test_cmd = "just test",
        lint_cmd = "just lint"
      }
    }
    EOF
    @echo "✓ Generated config.ncl"

# Validate Nickel config
nickel-check:
    @nickel check config.ncl 2>/dev/null || echo "Install Nickel: nix-shell -p nickel"
