# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# Justfile — eclipse-ssg build automation
#
# Usage: just <recipe>
# List recipes: just --list

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default recipe
default: check

# ============================================================
# CORE COMMANDS
# ============================================================

# Build the SSG engine and all adapters
build:
    @echo "Building eclipse-ssg..."
    deno task build
    @echo "Build complete."

# Run unit tests
test:
    @echo "Running unit tests..."
    deno test --allow-read --allow-write tests/

# Run end-to-end integration tests
test-e2e:
    @echo "Running e2e tests..."
    deno test --allow-all tests/e2e/

# Run all tests (unit + e2e + verification)
test-all: test test-e2e test-verify
    @echo "All tests passed."

# Run Bernoulli verification tests
test-verify:
    @echo "Running verification tests..."
    deno test --allow-read tests/verify/

# Start the NoteG language server
lsp:
    @echo "Starting NoteG LSP..."
    deno run --allow-all noteg-lang/src/lsp/server.ts

# Compile a .noteg file
compile file:
    @echo "Compiling {{file}}..."
    deno run --allow-read --allow-write noteg-lang/src/compiler.ts {{file}}

# ============================================================
# CODE QUALITY
# ============================================================

# Format all source files
fmt:
    deno fmt
    @echo "Formatting complete."

# Check formatting without modifying
fmt-check:
    deno fmt --check

# Lint all source files
lint:
    deno lint

# Type check
typecheck:
    deno check **/*.ts

# Run all checks (fmt + lint + typecheck)
check: fmt-check lint typecheck
    @echo "All checks passed."

# ============================================================
# DEVELOPMENT
# ============================================================

# Start development server with hot reload
serve port="8080":
    @echo "Starting dev server on port {{port}}..."
    deno run --allow-all --watch ssg/src/serve.ts --port {{port}}

# Watch for changes and rebuild
watch:
    deno task build --watch

# Clean build artifacts
clean:
    rm -rf dist/ .cache/ coverage/
    @echo "Cleaned."

# Install/update dependencies
deps:
    deno cache --reload deps.ts
    @echo "Dependencies updated."

# ============================================================
# ADAPTERS
# ============================================================

# List available SSG adapters
adapter-list:
    @echo "Available adapters:"
    @ls -1 adapters/*.js | xargs -n1 basename | sed 's/.js$//'

# Check adapter connection status
adapter-check adapter:
    deno run --allow-run adapters/{{adapter}}.js --check

# Build with specific adapter
build-adapter adapter *args:
    deno run --allow-all adapters/{{adapter}}.js build {{args}}

# Sync adapters from poly-ssg-mcp hub
adapter-sync:
    @echo "Syncing adapters from hub..."
    @if [ -f ~/Documents/scripts/transfer-ssg-adapters.sh ]; then \
        ~/Documents/scripts/transfer-ssg-adapters.sh --satellite eclipse-ssg; \
    else \
        echo "Sync script not found. Manual sync required."; \
    fi

# Run adapter in parallel (comma-separated list)
adapter-parallel adapters cmd:
    @echo "Running {{cmd}} on adapters: {{adapters}}"
    echo "{{adapters}}" | tr ',' '\n' | parallel -j4 just build-adapter {} {{cmd}}

# ============================================================
# NOTEG LANGUAGE
# ============================================================

# Parse NoteG file (AST output)
noteg-parse file:
    deno run --allow-read noteg-lang/src/parser.ts {{file}}

# Interpret NoteG file
noteg-interpret file:
    deno run --allow-read noteg-lang/src/interpreter.ts {{file}}

# Validate NoteG syntax
noteg-validate file:
    deno run --allow-read noteg-lang/src/lexer.ts {{file}}

# ============================================================
# ACCESSIBILITY
# ============================================================

# Validate accessibility metadata
a11y-check:
    deno run --allow-read a11y/validate.ts

# Generate accessibility report
a11y-report output="a11y-report.html":
    deno run --allow-all a11y/report.ts --output {{output}}

# ============================================================
# CI/CD
# ============================================================

# Run CI pipeline locally
ci: deps check test-all build
    @echo "CI pipeline complete."

# Generate coverage report
coverage:
    deno test --coverage=coverage/ tests/
    deno coverage coverage/ --lcov > coverage/lcov.info

# Security scan with CodeQL (local)
security-scan:
    @echo "Running security scans..."
    deno lint --rules=no-eval,no-unsafe-finally

# ============================================================
# RELEASE
# ============================================================

# Prepare release
release-prepare version:
    @echo "Preparing release {{version}}..."
    just check
    just test-all
    @echo "Release {{version}} ready."

# Publish to deno.land
publish-deno:
    @echo "Publishing to deno.land..."
    deno publish

# ============================================================
# NICKEL INTEGRATION
# ============================================================

# Evaluate Nickel build configuration
nickel-build:
    nickel eval .nickel/build.ncl

# Export Nickel config as JSON
nickel-config:
    nickel export .nickel/config.ncl --format json

# Typecheck all Nickel files
nickel-check:
    find .nickel -name "*.ncl" -exec nickel typecheck {} \;

# ============================================================
# PODMAN/CONTAINER
# ============================================================

# Build container image
container-build tag="eclipse-ssg:latest":
    podman build -t {{tag}} .

# Run container
container-run tag="eclipse-ssg:latest" *args:
    podman run --rm -it {{tag}} {{args}}

# ============================================================
# DOCUMENTATION
# ============================================================

# Generate API documentation
docs:
    deno doc --html ssg/src/ --output=docs/api/

# Serve documentation locally
docs-serve:
    python3 -m http.server 8000 --directory docs/

# ============================================================
# HOOKS
# ============================================================

# Install git hooks
hooks-install:
    @echo "Installing git hooks..."
    @mkdir -p .git/hooks
    @echo '#!/bin/sh\njust fmt-check && just lint' > .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo '#!/bin/sh\njust test' > .git/hooks/pre-push
    @chmod +x .git/hooks/pre-push
    @echo "Hooks installed."

# Run pre-commit checks
hooks-pre-commit:
    just fmt-check
    just lint
    just typecheck

# Run pre-push checks
hooks-pre-push:
    just test
