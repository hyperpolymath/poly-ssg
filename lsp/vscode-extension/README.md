# PolySSG VSCode Extension

Language Server Protocol extension for 60+ static site generators.

## Features

- **Auto-detection**: Automatically detects SSG type from project files
- **Build commands**: Run build, serve, clean from command palette
- **Diagnostics**: Real-time build error reporting
- **Auto-completion**: Template syntax and frontmatter (coming soon)
- **Hover docs**: SSG-specific documentation (coming soon)

## Supported SSGs

- Zola (Rust)
- Hugo (Go)
- Jekyll (Ruby)
- mdBook (Rust)
- Hakyll (Haskell)
- Franklin.jl (Julia)
- ...and 54 more

## Requirements

- Elixir 1.17+ and Erlang/OTP 26+
- poly-ssg-lsp server installed

## Installation

### From VSIX

1. Download latest `.vsix` from releases
2. Run: `code --install-extension poly-ssg-0.1.0.vsix`

### From Source

```bash
cd vscode-extension
npm install
npm run compile
npm run package  # Creates poly-ssg-0.1.0.vsix
code --install-extension poly-ssg-0.1.0.vsix
```

## Configuration

```json
{
  "poly-ssg.lsp.path": "/path/to/poly-ssg-lsp",
  "poly-ssg.diagnostics.onSave": true,
  "poly-ssg.trace.server": "off"
}
```

## Commands

- `PolySSG: Build Site` - Build the static site
- `PolySSG: Start Dev Server` - Start development server
- `PolySSG: Clean Build Artifacts` - Clean output directory
- `PolySSG: Restart LSP Server` - Restart the language server

## License

PMPL-1.0-or-later
