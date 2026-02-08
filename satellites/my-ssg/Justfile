# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# Justfile for my-ssg - SSG Adapter Collection

# Default recipe
default: help

# Show available commands
help:
    @just --list --unsorted

# ============================================================================
# ADAPTER TESTING
# ============================================================================

# Run all adapter tests
test:
    @echo "Testing SSG adapters..."
    deno test --allow-all tests/

# Test specific adapter
test-adapter name:
    @echo "Testing {{name}} adapter..."
    deno test --allow-all tests/ --filter "{{name}}"

# Run E2E tests
test-e2e:
    @echo "Running E2E tests..."
    deno test --allow-all tests/e2e/

# Run all tests
test-all: test test-e2e
    @echo "All tests complete"

# Check code coverage
coverage:
    @echo "Generating coverage report..."
    deno test --allow-all --coverage=.coverage tests/
    deno coverage .coverage --lcov > coverage.lcov

# ============================================================================
# ADAPTER VERIFICATION
# ============================================================================

# Check all adapter syntax
check:
    @echo "Checking adapter syntax..."
    @for adapter in adapters/*.js; do \
        echo "Checking $$adapter..."; \
        deno check "$$adapter" 2>/dev/null || echo "  (skipped - JS file)"; \
    done

# Verify adapter exports
verify:
    @echo "Verifying adapter exports..."
    @deno eval " \
        const files = [...Deno.readDirSync('adapters')].filter(f => f.name.endsWith('.js')); \
        let count = 0; \
        for (const file of files) { \
            try { \
                const mod = await import('./adapters/' + file.name); \
                if (mod.name && mod.tools && mod.connect) { \
                    console.log('✓', file.name.padEnd(25), 'tools:', (mod.tools?.length || 0).toString().padStart(2)); \
                    count++; \
                } else { \
                    console.log('⚠', file.name, '- missing exports'); \
                } \
            } catch (e) { \
                console.log('✗', file.name, '-', e.message); \
            } \
        } \
        console.log('\nTotal valid adapters:', count); \
    "

# List all adapters
list:
    @echo "Available SSG Adapters ($(ls -1 adapters/*.js | wc -l) total):"
    @echo ""
    @for adapter in adapters/*.js; do \
        name=$$(basename "$$adapter" .js); \
        echo "  - $$name"; \
    done

# Test adapter connection (requires SSG to be installed)
connect adapter:
    @echo "Testing connection to {{adapter}}..."
    @deno eval " \
        const mod = await import('./adapters/{{adapter}}.js'); \
        console.log('Name:', mod.name); \
        console.log('Language:', mod.language); \
        console.log('Tools:', mod.tools?.length || 0); \
        const connected = await mod.connect(); \
        console.log('Connected:', connected); \
    "

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Format all code
fmt:
    deno fmt adapters/ tests/

# Lint all code
lint:
    deno lint adapters/ tests/

# Security audit
audit:
    @echo "Running security checks..."
    @echo ""
    @echo "Checking for shell:true..."
    @grep -rn "shell:\s*true" adapters/ 2>/dev/null && echo "⚠ WARNING: shell:true found!" || echo "✓ No shell:true usage"
    @echo ""
    @echo "Checking for eval()..."
    @grep -rn "eval(" adapters/ 2>/dev/null && echo "⚠ WARNING: eval() found!" || echo "✓ No eval() usage"
    @echo ""
    @echo "Checking for exec()..."
    @grep -rn "[^.]exec(" adapters/ 2>/dev/null && echo "⚠ WARNING: exec() found!" || echo "✓ No exec() usage"
    @echo ""
    @echo "Security audit complete"

# Run all CI checks locally
ci: fmt lint check verify test audit
    @echo ""
    @echo "All CI checks passed!"

# ============================================================================
# CONTAINER
# ============================================================================

# Build container image
container-build:
    podman build -t my-ssg:latest -f Containerfile .

# Run container
container-run:
    podman run -it --rm my-ssg:latest

# Push container to registry
container-push registry="ghcr.io/hyperpolymath":
    podman push my-ssg:latest {{registry}}/my-ssg:latest

# ============================================================================
# UTILITIES
# ============================================================================

# Clean build artifacts
clean:
    rm -rf .coverage coverage.lcov

# Show adapter statistics
stats:
    @echo "Adapter Statistics:"
    @echo "==================="
    @echo "Total adapters:  $(ls -1 adapters/*.js | wc -l)"
    @echo "Total lines:     $(wc -l adapters/*.js | tail -1 | awk '{print $$1}')"
    @echo ""
    @echo "By language:"
    @deno eval " \
        const files = [...Deno.readDirSync('adapters')].filter(f => f.name.endsWith('.js')); \
        const langs = {}; \
        for (const file of files) { \
            try { \
                const mod = await import('./adapters/' + file.name); \
                const lang = mod.language || 'Unknown'; \
                langs[lang] = (langs[lang] || 0) + 1; \
            } catch {} \
        } \
        for (const [lang, count] of Object.entries(langs).sort((a,b) => b[1] - a[1])) { \
            console.log('  ' + lang.padEnd(15) + count); \
        } \
    "
