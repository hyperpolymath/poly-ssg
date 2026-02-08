# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>

# List available recipes
default:
    @just --list

# Install dependencies
deps:
    mix deps.get

# Compile the project
build:
    mix compile

# Run tests
test:
    mix test

# Run tests with coverage
test-coverage:
    mix coveralls.html

# Format code
fmt:
    mix format

# Check code formatting
fmt-check:
    mix format --check-formatted

# Run linter
lint:
    mix credo --strict

# Run type checker
dialyzer:
    mix dialyzer

# Run all quality checks
quality: fmt-check lint dialyzer

# Generate documentation
docs:
    mix docs

# Clean build artifacts
clean:
    mix clean
    rm -rf _build deps doc

# Start the LSP server (stdio mode)
start:
    mix run --no-halt

# Start IEx REPL with project loaded
repl:
    iex -S mix

# Run a specific adapter test
test-adapter adapter:
    mix test test/adapters/{{adapter}}_test.exs

# Check for outdated dependencies
deps-outdated:
    mix hex.outdated

# Update dependencies
deps-update:
    mix deps.update --all

# Create a release build
release:
    MIX_ENV=prod mix release

# Run CI checks locally
ci: quality test

# Setup project from scratch
setup: deps build test
    @echo "✓ Project setup complete"
