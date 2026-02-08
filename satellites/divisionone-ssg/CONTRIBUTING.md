# Contributing to Division One SSG

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to Division One SSG.

## Table of Contents

- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Pull Request Process](#pull-request-process)

---

## Getting Started

### Prerequisites

- [Deno](https://deno.land/) runtime (for running adapters)
- Git for version control
- Familiarity with JavaScript/TypeScript

### Setup

```bash
# Clone the repository
git clone https://github.com/hyperpolymath/divisionone-ssg.git
cd divisionone-ssg

# Verify Deno is installed
deno --version

# Run adapter tests (when available)
deno test
```

### Repository Structure

```
divisionone-ssg/
├── adapters/            # 28 SSG adapter implementations
│   ├── zola.js          # Rust - Zola adapter
│   ├── hakyll.js        # Haskell - Hakyll adapter
│   └── ...              # Other SSG adapters
├── .github/             # GitHub config (Perimeter 1)
│   ├── ISSUE_TEMPLATE/  # Issue templates
│   ├── workflows/       # CI/CD workflows
│   └── dependabot.yml   # Dependency updates
├── CODE_OF_CONDUCT.md   # Community guidelines
├── CONTRIBUTING.md      # This file
├── ECOSYSTEM.scm        # Ecosystem positioning
├── LICENSE.txt          # Dual MIT/AGPL-3.0 license
├── META.scm             # Architecture decisions
├── README.adoc          # Main documentation
├── SECURITY.md          # Security policy
└── STATE.scm            # Project state tracking
```

---

## How to Contribute

### Reporting Bugs

**Before reporting**:
1. Search existing issues
2. Check if it's already fixed in `main`
3. Identify which adapter is affected

**When reporting**:

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Clear, descriptive title
- Which adapter/SSG is affected
- Environment details (OS, Deno version, SSG version)
- Steps to reproduce
- Expected vs actual behaviour
- Logs or error messages

### Suggesting Features

**Before suggesting**:
1. Search existing issues and discussions
2. Consider if it fits the project scope

**When suggesting**:

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- Problem statement (what pain point does this solve?)
- Proposed solution
- Alternatives considered
- Which adapter(s) would be affected

### Your First Contribution

Look for issues labelled:

- [`good first issue`](https://github.com/hyperpolymath/divisionone-ssg/labels/good%20first%20issue) — Simple tasks for newcomers
- [`help wanted`](https://github.com/hyperpolymath/divisionone-ssg/labels/help%20wanted) — Community help needed
- [`documentation`](https://github.com/hyperpolymath/divisionone-ssg/labels/documentation) — Docs improvements

---

## Development Workflow

### Branch Naming

```
docs/short-description       # Documentation
test/what-added              # Test additions
feat/short-description       # New features
fix/issue-number-description # Bug fixes
refactor/what-changed        # Code improvements
security/what-fixed          # Security fixes
```

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks
- `security`: Security fixes

**Examples**:
```
feat(zola): add support for drafts flag
fix(hakyll): correct port argument handling
docs: update adapter installation guide
security(deps): update vulnerable dependency
```

### Testing

Before submitting:

```bash
# Format code
deno fmt

# Lint code
deno lint

# Run tests (when available)
deno test
```

---

## Code Standards

### Adapter Structure

Each adapter should follow this pattern:

```javascript
// SPDX-License-Identifier: MPL-2.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

/**
 * [SSG Name] adapter - [Brief description]
 * [Official URL]
 */

export const name = "SSG Name";
export const language = "Language";
export const description = "Description of the SSG";

// Connection state
let connected = false;

// Command runner using Deno.Command (secure against injection)
async function runCommand(args, cwd = null) {
  const cmd = new Deno.Command(binaryPath, {
    args,  // Always pass args as array, never interpolate strings
    cwd: cwd || Deno.cwd(),
    stdout: "piped",
    stderr: "piped",
  });
  // ...
}

export async function connect() { /* ... */ }
export async function disconnect() { /* ... */ }
export function isConnected() { /* ... */ }

export const tools = [
  // Tool definitions with inputSchema
];
```

### Security Requirements

- **Command Execution**: Always use `Deno.Command` with array-based args (never shell interpolation)
- **Path Handling**: Validate and sanitize file paths
- **No Secrets**: Never commit credentials, API keys, or secrets
- **SPDX Headers**: Include license headers in all source files

### Style Guidelines

- Use `deno fmt` for formatting
- Use `deno lint` for linting
- Prefer `const` over `let` where possible
- Use meaningful variable and function names
- Add JSDoc comments for exported functions

---

## Pull Request Process

### Before Submitting

1. **Update from main**: `git pull origin main`
2. **Run checks**: `deno fmt && deno lint`
3. **Test changes**: Verify your adapter works with the target SSG
4. **Update docs**: If adding features, update relevant documentation

### PR Requirements

- [ ] Code follows project style guidelines
- [ ] Changes are tested
- [ ] Commits follow conventional commits format
- [ ] PR description explains the changes
- [ ] No unrelated changes included

### Review Process

1. Submit your PR against `main`
2. Automated checks will run (CodeQL, linting)
3. A maintainer will review your changes
4. Address any feedback
5. Once approved, a maintainer will merge

### After Merge

- Delete your feature branch
- Update your local main: `git pull origin main`

---

## Adapter Synchronization

This repository is a **satellite** of the [poly-ssg-mcp hub](https://github.com/hyperpolymath/poly-ssg-mcp). Adapters are synchronized from the hub.

For significant adapter changes, consider contributing to the hub repository instead, so changes propagate to all satellite repositories.

---

## Questions?

- Open a [Discussion](https://github.com/hyperpolymath/divisionone-ssg/discussions)
- Check existing issues and documentation
- Contact maintainers for guidance

---

## License

By contributing, you agree that your contributions will be dual-licensed under MIT OR AGPL-3.0-or-later.

---

*Thank you for contributing to Division One SSG!*
