# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
# polyglot-ssg-mcp justfile

# Default recipe
default:
    @just --list

# Start the MCP server
start:
    deno task start

# Development mode with watch
dev:
    deno task dev

# Build ReScript
build:
    deno task res:build

# Clean ReScript build
clean:
    deno task res:clean

# Lint JavaScript
lint:
    deno lint --ignore=node_modules,lib

# Format code
fmt:
    deno fmt --ignore=node_modules,lib

# Check Deno types
check:
    deno check index.js

# Run RSR compliance check
rsr-check:
    @echo "=== RSR Compliance Check ==="
    @echo "Checking SPDX headers..."
    @find . -name "*.js" -not -path "./node_modules/*" -exec grep -L "SPDX-License-Identifier" {} \; | head -5
    @echo "Checking required files..."
    @for f in README.adoc LICENSE.txt CLAUDE.md STATE.scm META.scm; do \
        if [ -f "$$f" ]; then echo "OK: $$f"; else echo "MISSING: $$f"; fi; \
    done
    @echo "Counting adapters..."
    @ls adapters/*.js | wc -l
    @echo "=== Check Complete ==="

# Build container (Wolfi)
container-build:
    podman build -t polyglot-ssg-mcp:latest -f Containerfile .

# Build Alpine container
container-build-alpine:
    podman build -t polyglot-ssg-mcp:alpine -f Containerfile.alpine .

# Run container
container-run:
    podman run -it --rm polyglot-ssg-mcp:latest

# Install npm dependencies (for ReScript)
deps:
    npm install

# Count SSGs
count:
    @echo "SSG Adapters: $(ls adapters/*.js | wc -l)"
    @echo "Languages: 19"
