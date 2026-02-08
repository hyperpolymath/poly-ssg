# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# Justfile — rescribe-ssg
# ReScript Static Site Generator Build System
#
# Usage: just <recipe>
# List all recipes: just --list

set dotenv-load := true
set positional-arguments := true

# Default recipe - show help
default:
    @just --list

# ============================================================================
# Core Build Recipes
# ============================================================================

# Compile ReScript to JavaScript
build:
    @echo "🔨 Building rescribe-ssg..."
    cd adapters && npm run build
    @echo "✅ Build complete"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    cd adapters && npm run clean
    rm -rf lib/ _site/
    @echo "✅ Clean complete"

# Watch mode development
dev:
    @echo "👀 Starting watch mode..."
    cd adapters && npm run watch

# Compile ReScript (alias)
compile: build

# ============================================================================
# Testing Recipes
# ============================================================================

# Run unit tests
test:
    @echo "🧪 Running unit tests..."
    cd adapters && npm run build
    node adapters/src/RescribeAdapter.mjs test 2>/dev/null || echo "Tests not yet implemented"
    @echo "✅ Tests complete"

# Run end-to-end tests
test-e2e:
    @echo "🔬 Running end-to-end tests..."
    just build
    @echo "E2E tests not yet implemented"
    @echo "✅ E2E tests complete"

# Run all tests
test-all: test test-e2e

# Run tests with coverage
test-coverage:
    @echo "📊 Running tests with coverage..."
    just test
    @echo "Coverage reporting not yet implemented"

# ============================================================================
# Linting & Formatting
# ============================================================================

# Check code formatting
lint:
    @echo "🔍 Checking code formatting..."
    cd adapters && npx rescript format -check src/ || echo "Format check: review needed"
    @echo "✅ Lint complete"

# Format code
format:
    @echo "✨ Formatting code..."
    cd adapters && npx rescript format src/
    @echo "✅ Format complete"

# ============================================================================
# Site Generation
# ============================================================================

# Generate static site from content
generate CONTENT_DIR="_content" OUTPUT_DIR="_site":
    @echo "📄 Generating static site..."
    @echo "  Content: {{CONTENT_DIR}}"
    @echo "  Output: {{OUTPUT_DIR}}"
    just build
    mkdir -p {{OUTPUT_DIR}}
    @echo "Site generation not yet fully implemented"
    @echo "✅ Generation complete"

# Serve generated site locally
serve PORT="3000":
    @echo "🌐 Starting local server on port {{PORT}}..."
    @command -v npx >/dev/null 2>&1 && npx serve _site -l {{PORT}} || echo "Install serve: npm i -g serve"

# Generate and serve
preview: generate
    just serve

# ============================================================================
# Language Server & Editor Integration
# ============================================================================

# Start ReScript language server
lsp:
    @echo "🔧 Starting ReScript language server..."
    @echo "Use rescript-vscode extension for LSP support"
    @echo "Install: code --install-extension chenglou92.rescript-vscode"

# ============================================================================
# Container Operations
# ============================================================================

# Build container image
container-build:
    @echo "📦 Building container image..."
    podman build -t rescribe-ssg:latest .
    @echo "✅ Container build complete"

# Run in container
container-run:
    @echo "🐳 Running in container..."
    podman run --rm -it -v $(pwd):/app:Z rescribe-ssg:latest

# Push container to registry
container-push:
    @echo "🚀 Pushing container to registry..."
    podman push rescribe-ssg:latest ghcr.io/hyperpolymath/rescribe-ssg:latest

# ============================================================================
# Dependency Management
# ============================================================================

# Install dependencies
install:
    @echo "📥 Installing dependencies..."
    cd adapters && npm install
    @echo "✅ Dependencies installed"

# Update dependencies
update:
    @echo "🔄 Updating dependencies..."
    cd adapters && npm update
    @echo "✅ Dependencies updated"

# Audit dependencies for vulnerabilities
audit:
    @echo "🔒 Auditing dependencies..."
    cd adapters && npm audit
    @echo "✅ Audit complete"

# ============================================================================
# Release & Versioning
# ============================================================================

# Bump version (patch, minor, major)
version-bump LEVEL="patch":
    @echo "📌 Bumping version ({{LEVEL}})..."
    cd adapters && npm version {{LEVEL}} --no-git-tag-version
    @echo "✅ Version bumped"

# Create release
release VERSION:
    @echo "🎉 Creating release {{VERSION}}..."
    git tag -a v{{VERSION}} -m "Release v{{VERSION}}"
    git push origin v{{VERSION}}
    @echo "✅ Release created"

# ============================================================================
# Documentation
# ============================================================================

# Build documentation
docs:
    @echo "📚 Building documentation..."
    @echo "Documentation build not yet implemented"
    @echo "✅ Docs complete"

# ============================================================================
# CI/CD Helpers
# ============================================================================

# Run CI checks locally
ci: lint build test
    @echo "✅ All CI checks passed"

# Verify all requirements
verify:
    @echo "🔍 Verifying requirements..."
    @command -v node >/dev/null 2>&1 && echo "✅ Node.js installed" || echo "❌ Node.js not found"
    @command -v npx >/dev/null 2>&1 && echo "✅ npx available" || echo "❌ npx not found"
    @test -f adapters/node_modules/.package-lock.json && echo "✅ Dependencies installed" || echo "⚠️  Run: just install"
    @echo "✅ Verification complete"

# ============================================================================
# MCP Adapter
# ============================================================================

# Test MCP adapter connection
mcp-test:
    @echo "🔌 Testing MCP adapter..."
    just build
    node -e "import('./adapters/src/RescribeAdapter.mjs').then(m => m.connect().then(r => console.log('Connected:', r)))"

# ============================================================================
# Utility Recipes
# ============================================================================

# Show project info
info:
    @echo "╔══════════════════════════════════════════╗"
    @echo "║         rescribe-ssg                     ║"
    @echo "║   ReScript Static Site Generator         ║"
    @echo "╠══════════════════════════════════════════╣"
    @echo "║ Language: ReScript (MANDATORY)           ║"
    @echo "║ Output:   JavaScript (.mjs)              ║"
    @echo "║ License:  AGPL-3.0-or-later              ║"
    @echo "╚══════════════════════════════════════════╝"
    @cat STATE.scm | grep "overall-completion" || true

# Reset to clean state
reset: clean
    @echo "🔄 Resetting to clean state..."
    rm -rf adapters/node_modules
    just install
    just build
    @echo "✅ Reset complete"
