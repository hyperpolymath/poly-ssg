# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| develop | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in poly-ssg, please report it responsibly:

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email the maintainers directly or use GitHub's private vulnerability reporting feature
3. Include a detailed description of the vulnerability
4. Provide steps to reproduce if possible
5. Allow reasonable time for a fix before public disclosure

## Security Measures

### Supply Chain Security

- All GitHub Actions are pinned to full SHA commit hashes to prevent supply chain attacks
- Dependabot monitors dependencies for known vulnerabilities
- CodeQL and Semgrep provide automated security scanning

### Code Security

The project enforces strict security practices:

#### OCaml/ReScript-WASM Backend
- No `Obj.magic` (type safety bypass)
- No `Marshal` on untrusted data (code execution risk)
- No shell command execution in library code
- No dynamic code loading (`Dynlink`, `Toploop`)

#### All Engines
- Input validation on all file operations
- XSS prevention in HTML output
- Path traversal protection
- No hardcoded secrets

### CI/CD Security

- Workflows use least-privilege permissions
- Security scans run daily (CodeQL, Semgrep)
- All PRs require passing security checks
- Secrets are managed through GitHub Secrets

## Security Scanning

The following automated security tools are active:

| Tool | Purpose | Frequency |
|------|---------|-----------|
| CodeQL | Static analysis for JavaScript/Actions | Daily + PR |
| Semgrep | SAST for multiple languages | Daily + PR |
| OCaml Security Audit | Unsafe pattern detection | Every PR |
| Dependabot | Dependency vulnerability scanning | Weekly |

## Best Practices for Contributors

1. Never commit secrets, API keys, or credentials
2. Use SHA-pinned GitHub Actions
3. Validate all external input
4. Follow the principle of least privilege
5. Review security scan results before merging

## Test Corpus Security

The test corpus includes security-focused test cases:

- `test-corpus/injection/` - XSS, path traversal, command injection tests
- All engines must pass injection tests to be considered secure

## Acknowledgments

We appreciate responsible security researchers who help improve poly-ssg security.
