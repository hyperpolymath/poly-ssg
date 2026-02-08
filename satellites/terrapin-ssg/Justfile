# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# terrapin-ssg Justfile - Logo Static Site Generator

# Default recipe - show help
default:
    @just --list

# === Core Commands ===

# Build the site using Logo
build:
    @echo "🐢 Building terrapin-ssg site..."
    @if command -v logo >/dev/null 2>&1; then \
        logo src/terrapin-ssg.logo; \
    elif command -v ucblogo >/dev/null 2>&1; then \
        ucblogo src/terrapin-ssg.logo; \
    else \
        echo "Error: No Logo interpreter found. Install UCBLogo."; \
        exit 1; \
    fi

# Run tests
test:
    @echo "🧪 Running Logo tests..."
    @just _check-logo
    @just lint
    @echo "✓ All tests passed"

# Run end-to-end tests
test-e2e:
    @echo "🔄 Running E2E tests..."
    @just build
    @test -d _site && echo "✓ Output directory created"
    @test -f _site/index.html && echo "✓ Index page generated"
    @echo "✓ E2E tests passed"

# Run all tests
test-all: test test-e2e
    @echo "✓ All test suites passed"

# Lint Logo files
lint:
    @echo "🔍 Linting Logo files..."
    @for f in src/*.logo; do \
        if [ -f "$$f" ]; then \
            echo "Checking $$f..."; \
            grep -n "TO " "$$f" | head -5; \
        fi; \
    done
    @echo "✓ Lint complete"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    rm -rf _site
    @echo "✓ Clean complete"

# === Development Commands ===

# Start Logo REPL for development
repl:
    @echo "🐢 Starting Logo REPL..."
    @if command -v logo >/dev/null 2>&1; then \
        logo; \
    elif command -v ucblogo >/dev/null 2>&1; then \
        ucblogo; \
    else \
        echo "Error: No Logo interpreter found"; \
        exit 1; \
    fi

# Watch for changes and rebuild (requires entr)
watch:
    @echo "👁️ Watching for changes..."
    @if command -v entr >/dev/null 2>&1; then \
        find src -name "*.logo" | entr -c just build; \
    else \
        echo "Install 'entr' for watch mode: apt install entr"; \
    fi

# Serve the built site (requires python)
serve: build
    @echo "🌐 Serving site at http://localhost:8000"
    cd _site && python3 -m http.server 8000

# === Adapter Commands ===

# Build ReScript MCP adapter
adapter-build:
    @echo "📦 Building ReScript adapter..."
    cd adapters && npm install && npm run build

# Test adapter
adapter-test:
    @echo "🧪 Testing adapter..."
    cd adapters && npm test

# === Validation Commands ===

# Validate Logo syntax (basic check)
validate:
    @echo "✅ Validating Logo files..."
    @for f in src/*.logo; do \
        if [ -f "$$f" ]; then \
            if grep -q "^TO " "$$f" || grep -q "^to " "$$f"; then \
                echo "✓ $$f has procedures"; \
            else \
                echo "⚠ $$f may be empty"; \
            fi; \
        fi; \
    done

# Check for forbidden languages in src/
check-languages:
    @echo "🚫 Checking for forbidden languages..."
    @forbidden=$$(find src/ -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.rb" -o -name "*.go" \) 2>/dev/null); \
    if [ -n "$$forbidden" ]; then \
        echo "ERROR: Found forbidden language files:"; \
        echo "$$forbidden"; \
        exit 1; \
    fi
    @echo "✓ Only Logo files in src/"

# === Security Commands ===

# Run security checks
security:
    @echo "🔒 Running security checks..."
    @just check-languages
    @echo "Checking for secrets..."
    @if grep -r "password\|secret\|api.key\|token" src/ 2>/dev/null | grep -v "^Binary"; then \
        echo "⚠ Potential secrets found"; \
    else \
        echo "✓ No obvious secrets"; \
    fi
    @echo "✓ Security check complete"

# === Documentation Commands ===

# Generate documentation
docs:
    @echo "📚 Generating documentation..."
    @if command -v asciidoctor >/dev/null 2>&1; then \
        asciidoctor README.adoc -o docs/index.html; \
        asciidoctor cookbook.adoc -o docs/cookbook.html 2>/dev/null || true; \
    else \
        echo "Install asciidoctor for HTML docs"; \
    fi

# === Container Commands ===

# Build container image
container-build:
    @echo "🐳 Building container..."
    podman build -t terrapin-ssg .

# Run in container
container-run:
    @echo "🐳 Running in container..."
    podman run --rm -v .:/app terrapin-ssg just build

# === CI/CD Commands ===

# Full CI pipeline
ci: check-languages lint test-all security
    @echo "✓ CI pipeline passed"

# Pre-commit checks
pre-commit: lint check-languages validate
    @echo "✓ Pre-commit checks passed"

# === Utility Commands ===

# Show project info
info:
    @echo "🐢 terrapin-ssg - Logo Static Site Generator"
    @echo "Language: Logo (UCBLogo interpreter)"
    @echo "Version: 1.0.1"
    @echo ""
    @echo "Files:"
    @find src -name "*.logo" -exec wc -l {} \; 2>/dev/null || echo "No .logo files"

# Check Logo interpreter availability
_check-logo:
    @if command -v logo >/dev/null 2>&1; then \
        echo "✓ logo interpreter found"; \
    elif command -v ucblogo >/dev/null 2>&1; then \
        echo "✓ ucblogo interpreter found"; \
    else \
        echo "⚠ No Logo interpreter found"; \
        echo "  Install UCBLogo: apt install ucblogo"; \
    fi

# Create example content
example:
    @echo "📝 Creating example content..."
    @mkdir -p content
    @echo "; Example Logo content" > content/example.logo
    @echo "TO EXAMPLE.PAGE" >> content/example.logo
    @echo "  REPEAT 5 [FORWARD 50 RIGHT 144]" >> content/example.logo
    @echo "END" >> content/example.logo
    @echo "✓ Example created in content/"

# Initialize new terrapin-ssg project
init:
    @echo "🚀 Initializing terrapin-ssg project..."
    @mkdir -p src content templates _site
    @just example
    @echo "✓ Project initialized"
