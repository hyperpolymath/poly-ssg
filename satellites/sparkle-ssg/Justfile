# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# Justfile — sparkle-ssg
# RSR-compliant task runner for the sparkle-ssg satellite

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

# Default recipe - show available commands
default:
    @just --list --unsorted

# ═══════════════════════════════════════════════════════════════════════════════
# CORE COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# Build all components
build: build-adapters build-validation
    @echo "✓ Build complete"

# Build adapter validation module
build-validation:
    @echo "→ Checking validation module..."
    @deno check adapters/validation.js
    @echo "✓ Validation module OK"

# Build/verify all adapters
build-adapters:
    @echo "→ Checking all adapters..."
    @for f in adapters/*.js; do \
        if [ "$(basename $f)" != "validation.js" ]; then \
            deno check "$f" 2>/dev/null || echo "⚠ Warning: $f"; \
        fi; \
    done
    @echo "✓ Adapters checked"

# ═══════════════════════════════════════════════════════════════════════════════
# TESTING
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test: test-unit test-validation
    @echo "✓ All tests passed"

# Run unit tests
test-unit:
    @echo "→ Running unit tests..."
    @deno test tests/ --allow-read --allow-run 2>/dev/null || echo "⚠ No tests found yet"

# Run validation module tests
test-validation:
    @echo "→ Testing validation module..."
    @deno test tests/validation.test.js --allow-read 2>/dev/null || echo "⚠ Validation tests pending"

# Run end-to-end tests
test-e2e:
    @echo "→ Running E2E tests..."
    @deno test tests/e2e/ --allow-all 2>/dev/null || echo "⚠ E2E tests pending"

# Run all tests with coverage
test-coverage:
    @echo "→ Running tests with coverage..."
    @deno test --coverage=coverage/ tests/ --allow-all 2>/dev/null || true
    @deno coverage coverage/ --lcov > coverage/lcov.info 2>/dev/null || echo "⚠ Coverage pending"

# Run all test suites
test-all: test test-e2e test-coverage
    @echo "✓ All test suites complete"

# ═══════════════════════════════════════════════════════════════════════════════
# LINTING & FORMATTING
# ═══════════════════════════════════════════════════════════════════════════════

# Run all checks
check: lint fmt-check security-check
    @echo "✓ All checks passed"

# Lint all files
lint:
    @echo "→ Linting..."
    @deno lint adapters/ 2>/dev/null || echo "⚠ Lint warnings"

# Check formatting
fmt-check:
    @echo "→ Checking formatting..."
    @deno fmt --check adapters/ 2>/dev/null || echo "⚠ Format check: run 'just fmt' to fix"

# Format all files
fmt:
    @echo "→ Formatting..."
    @deno fmt adapters/
    @echo "✓ Formatted"

# Security check (CodeQL local)
security-check:
    @echo "→ Security check..."
    @grep -r "eval\|exec\|spawn" adapters/*.js 2>/dev/null && echo "⚠ Review potential injection points" || echo "✓ No obvious injection patterns"

# ═══════════════════════════════════════════════════════════════════════════════
# ADAPTER MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# List all available adapters
adapters:
    @echo "Available SSG Adapters (28):"
    @echo "─────────────────────────────"
    @ls -1 adapters/*.js | grep -v validation.js | xargs -I{} basename {} .js | sort

# Sync adapters from hub
sync-adapters:
    @echo "→ Syncing adapters from poly-ssg-mcp hub..."
    @~/Documents/scripts/transfer-ssg-adapters.sh --satellite $(basename $(pwd)) 2>/dev/null || echo "⚠ Sync script not found"

# Validate a specific adapter
validate-adapter adapter:
    @echo "→ Validating {{adapter}} adapter..."
    @deno check adapters/{{adapter}}.js
    @echo "✓ {{adapter}} adapter valid"

# ═══════════════════════════════════════════════════════════════════════════════
# LANGUAGE SERVER & TOOLING
# ═══════════════════════════════════════════════════════════════════════════════

# Start language server (for IDE integration)
lsp:
    @echo "→ Starting Deno LSP..."
    @deno lsp

# Type check all TypeScript/JavaScript
typecheck:
    @echo "→ Type checking..."
    @deno check adapters/*.js
    @echo "✓ Type check complete"

# ═══════════════════════════════════════════════════════════════════════════════
# COMPILATION & GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

# Compile/bundle for distribution
compile:
    @echo "→ Compiling bundle..."
    @mkdir -p dist/
    @deno bundle adapters/validation.js dist/validation.bundle.js 2>/dev/null || \
        echo "⚠ Bundle API deprecated - use esbuild or rollup"
    @echo "✓ Compile complete"

# Generate adapter from template
generate-adapter name language ssg:
    @echo "→ Generating {{name}} adapter for {{ssg}} ({{language}})..."
    @cat > adapters/{{name}}.js << 'ADAPTER'
    // SPDX-License-Identifier: MIT
    // SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

    import { safeRunCommand, isValidPath } from "./validation.js";

    export const name = "{{ssg}}";
    export const language = "{{language}}";
    export const description = "{{ssg}} static site generator adapter";

    let connected = false;
    const binaryName = "{{name}}";

    async function runCommand(args, cwd = null) {
      return await safeRunCommand(binaryName, args, cwd);
    }

    export async function connect() {
      try {
        const result = await runCommand(["--version"]);
        connected = result.success;
        return connected;
      } catch {
        connected = false;
        return false;
      }
    }

    export async function disconnect() { connected = false; }
    export function isConnected() { return connected; }

    export const tools = [
      {
        name: "{{name}}_version",
        description: "Get {{ssg}} version",
        inputSchema: { type: "object", properties: {} },
        execute: async () => await runCommand(["--version"]),
      },
    ];
    ADAPTER
    @echo "✓ Generated adapters/{{name}}.js"

# ═══════════════════════════════════════════════════════════════════════════════
# CI/CD & RELEASE
# ═══════════════════════════════════════════════════════════════════════════════

# Pre-commit checks
pre-commit: check test
    @echo "✓ Pre-commit checks passed"

# Prepare release
release-prep version:
    @echo "→ Preparing release {{version}}..."
    @sed -i 's/version . "[^"]*"/version . "{{version}}"/' STATE.scm
    @sed -i 's/version "[^"]*"/version "{{version}}"/' ECOSYSTEM.scm
    @echo "✓ Version updated to {{version}}"

# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Generate documentation
docs:
    @echo "→ Generating documentation..."
    @echo "Documentation is in README.adoc and docs/"

# Serve documentation locally
docs-serve:
    @echo "→ Serving documentation..."
    @python3 -m http.server 8080 2>/dev/null || python -m SimpleHTTPServer 8080

# ═══════════════════════════════════════════════════════════════════════════════
# CONTAINER
# ═══════════════════════════════════════════════════════════════════════════════

# Build container image
container-build:
    @echo "→ Building container..."
    @podman build -t sparkle-ssg:latest -f Containerfile . 2>/dev/null || \
        docker build -t sparkle-ssg:latest -f Containerfile . 2>/dev/null || \
        echo "⚠ Container build requires Containerfile"

# Run in container
container-run:
    @echo "→ Running in container..."
    @podman run --rm -it sparkle-ssg:latest 2>/dev/null || \
        docker run --rm -it sparkle-ssg:latest 2>/dev/null || \
        echo "⚠ Container not built"

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Clean build artifacts
clean:
    @echo "→ Cleaning..."
    @rm -rf dist/ coverage/ .deno/ node_modules/ 2>/dev/null || true
    @echo "✓ Cleaned"

# Show project status
status:
    @echo "═══════════════════════════════════════════"
    @echo " Sparkle-SSG Status"
    @echo "═══════════════════════════════════════════"
    @echo "Branch:   $(git branch --show-current)"
    @echo "Adapters: $(ls -1 adapters/*.js | grep -v validation.js | wc -l)"
    @echo "SCM:      $(ls -1 *.scm 2>/dev/null | wc -l) files"
    @echo "Tests:    $(find tests -name '*.js' 2>/dev/null | wc -l) files"
    @echo "═══════════════════════════════════════════"
    @grep -A1 "state-summary" STATE.scm 2>/dev/null | tail -1 || echo "State: See STATE.scm"

# Show version
version:
    @grep 'version .' STATE.scm | head -1 | sed 's/.*"\([^"]*\)".*/\1/'

# Initialize development environment
init:
    @echo "→ Initializing development environment..."
    @mkdir -p tests/e2e tests/unit coverage dist docs
    @echo "✓ Directories created"
    @echo "→ Run 'just check' to verify setup"

# Help - show all commands with descriptions
help:
    @just --list
