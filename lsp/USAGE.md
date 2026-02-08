# Usage Guide

> Comprehensive guide for using poly-ssg-lsp across VSCode, Neovim, and Emacs

## Table of Contents

- [VSCode Setup](#vscode-setup)
- [Neovim Setup](#neovim-setup)
- [Emacs Setup](#emacs-setup)
- [Configuration](#configuration)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)
- [Adapter-Specific Notes](#adapter-specific-notes)

## VSCode Setup

### Installation

1. **Install the LSP Server:**
   ```bash
   git clone https://github.com/hyperpolymath/poly-ssg-lsp.git
   cd poly-ssg-lsp
   ./install.sh
   ```

2. **Install VSCode Extension:**
   ```bash
   cd vscode-extension
   npm install
   npm run compile
   code --install-extension *.vsix
   ```

### Features

The VSCode extension provides:

- **Auto-detection**: Automatically detects SSG type from project files (config.toml, _config.yml, etc.)
- **Completions**: Template syntax, frontmatter fields, shortcodes
- **Diagnostics**: Build errors, configuration issues, missing dependencies
- **Hover Documentation**: SSG-specific docs and configuration help
- **Code Actions**: Quick fixes for common issues
- **Commands**: Build, serve, clean directly from Command Palette

### Available Commands

Access via Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`):

- **SSG: Build Site** - Build the static site
- **SSG: Serve Site** - Start development server
- **SSG: Clean Build** - Remove generated files
- **SSG: Detect Generator** - Manually trigger SSG detection
- **SSG: Show Status** - Display current SSG configuration

### Settings

Add to your workspace or user `settings.json`:

```json
{
  "lsp.serverPath": "/path/to/poly-ssg-lsp",
  "lsp.trace.server": "verbose",
  "lsp.ssg.autoDetect": true,
  "lsp.ssg.buildOnSave": false,
  "lsp.ssg.serverPort": 1313
}
```

## Neovim Setup

### Using nvim-lspconfig

Add to your Neovim configuration:

```lua
local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

-- Register poly-ssg-lsp if not already defined
if not configs.poly_ssg_lsp then
  configs.poly_ssg_lsp = {
    default_config = {
      cmd = {'/path/to/poly-ssg-lsp/_build/prod/rel/poly_ssg_lsp/bin/poly_ssg_lsp'},
      filetypes = {'markdown', 'html', 'toml', 'yaml', 'liquid'},
      root_dir = lspconfig.util.root_pattern(
        'config.toml',     -- Hugo, Zola
        '_config.yml',     -- Jekyll
        'mkdocs.yml',      -- MkDocs
        'book.toml',       -- mdBook
        'config.yaml',     -- Hugo
        'hakyll.hs',       -- Hakyll
        '__site.jl'        -- Franklin
      ),
      settings = {
        ssg = {
          autoDetect = true,
          buildOnSave = false
        }
      }
    }
  }
end

-- Setup the LSP
lspconfig.poly_ssg_lsp.setup({
  on_attach = function(client, bufnr)
    -- Enable completion
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Key mappings
    local opts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

    -- Custom commands
    vim.api.nvim_buf_create_user_command(bufnr, 'SSGBuild', function()
      vim.lsp.buf.execute_command({command = 'ssg.build'})
    end, {})

    vim.api.nvim_buf_create_user_command(bufnr, 'SSGServe', function()
      vim.lsp.buf.execute_command({command = 'ssg.serve'})
    end, {})
  end,
  capabilities = require('cmp_nvim_lsp').default_capabilities()
})
```

### Using coc.nvim

Add to `:CocConfig`:

```json
{
  "languageserver": {
    "poly-ssg-lsp": {
      "command": "/path/to/poly-ssg-lsp/_build/prod/rel/poly_ssg_lsp/bin/poly_ssg_lsp",
      "filetypes": ["markdown", "html", "toml", "yaml", "liquid"],
      "rootPatterns": ["config.toml", "_config.yml", "mkdocs.yml", "book.toml"],
      "settings": {
        "ssg": {
          "autoDetect": true
        }
      }
    }
  }
}
```

## Emacs Setup

### Using lsp-mode

Add to your Emacs configuration:

```elisp
(use-package lsp-mode
  :hook ((markdown-mode html-mode yaml-mode) . lsp)
  :config
  (add-to-list 'lsp-language-id-configuration '(markdown-mode . "markdown"))

  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection
                     '("/path/to/poly-ssg-lsp/_build/prod/rel/poly_ssg_lsp/bin/poly_ssg_lsp"))
    :major-modes '(markdown-mode html-mode yaml-mode)
    :server-id 'poly-ssg-lsp
    :priority 1
    :activation-fn (lsp-activate-on "markdown" "html" "yaml")
    :initialization-options (lambda ()
                             '(:autoDetect t
                               :buildOnSave nil)))))

;; Custom commands
(defun ssg-build ()
  "Build the static site."
  (interactive)
  (lsp-execute-command "ssg.build"))

(defun ssg-serve ()
  "Start the development server."
  (interactive)
  (lsp-execute-command "ssg.serve"))

(define-key lsp-mode-map (kbd "C-c s b") 'ssg-build)
(define-key lsp-mode-map (kbd "C-c s s") 'ssg-serve)
```

### Using eglot

```elisp
(use-package eglot
  :hook ((markdown-mode html-mode yaml-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((markdown-mode html-mode yaml-mode)
                 . ("/path/to/poly-ssg-lsp/_build/prod/rel/poly_ssg_lsp/bin/poly_ssg_lsp"))))

;; Custom commands
(defun ssg-build ()
  "Build the static site."
  (interactive)
  (eglot-execute-command (eglot--current-server-or-lose) "ssg.build" nil))

(defun ssg-serve ()
  "Start the development server."
  (interactive)
  (eglot-execute-command (eglot--current-server-or-lose) "ssg.serve" nil))
```

## Configuration

### Server Configuration

Create `.poly-ssg-lsp.json` in your project root:

```json
{
  "ssg": {
    "type": "auto",
    "buildCommand": "hugo",
    "serveCommand": "hugo server",
    "cleanCommand": "rm -rf public",
    "outputDir": "public",
    "contentDir": "content",
    "templateDirs": ["layouts", "themes"]
  },
  "completion": {
    "enableShortcodes": true,
    "enableFrontmatter": true,
    "enableTemplateSyntax": true
  },
  "diagnostics": {
    "enableBuildErrors": true,
    "enableConfigWarnings": true,
    "checkDependencies": true
  }
}
```

### Environment Variables

```bash
# Server configuration
export POLY_SSG_LSP_LOG_LEVEL=info     # debug, info, warn, error
export POLY_SSG_LSP_PORT=9999          # LSP stdio port (if not stdio)
export POLY_SSG_LSP_CACHE_DIR=~/.cache/poly-ssg-lsp

# SSG-specific paths
export HUGO_ROOT=/usr/local/bin/hugo
export JEKYLL_ROOT=/usr/bin/jekyll
export ZOLA_ROOT=/usr/bin/zola
```

### Adapter-Specific Configuration

Each adapter can be configured individually:

```json
{
  "adapters": {
    "hugo": {
      "binaryPath": "/usr/local/bin/hugo",
      "defaultTheme": "theme-name",
      "enableLiveReload": true
    },
    "jekyll": {
      "binaryPath": "/usr/bin/jekyll",
      "enableIncrementalBuild": true,
      "port": 4000
    },
    "zola": {
      "binaryPath": "/usr/bin/zola",
      "port": 1111
    },
    "mdbook": {
      "binaryPath": "/usr/bin/mdbook",
      "preprocessors": ["links", "toc"]
    }
  }
}
```

## Commands

### LSP Commands

All commands available via `workspace/executeCommand`:

#### ssg.build
Build the static site.

**Parameters:** None

**Returns:** Build status and output

**Example (Neovim):**
```lua
vim.lsp.buf.execute_command({command = 'ssg.build'})
```

#### ssg.serve
Start the development server.

**Parameters:**
- `port` (optional): Server port (default: SSG default)

**Returns:** Server URL and PID

**Example (VSCode):**
Command Palette → "SSG: Serve Site"

#### ssg.clean
Remove generated files.

**Parameters:** None

**Returns:** Cleaned directories list

#### ssg.detect
Detect SSG type from project files.

**Parameters:** None

**Returns:** Detected SSG type and confidence score

#### ssg.status
Get current SSG configuration and status.

**Parameters:** None

**Returns:** Configuration object

### Keyboard Shortcuts

**VSCode:**
- Build: No default (assign in Keyboard Shortcuts)
- Serve: No default
- Clean: No default

**Neovim (suggested):**
```lua
vim.keymap.set('n', '<leader>sb', function()
  vim.lsp.buf.execute_command({command = 'ssg.build'})
end, {desc = 'SSG: Build'})

vim.keymap.set('n', '<leader>ss', function()
  vim.lsp.buf.execute_command({command = 'ssg.serve'})
end, {desc = 'SSG: Serve'})

vim.keymap.set('n', '<leader>sc', function()
  vim.lsp.buf.execute_command({command = 'ssg.clean'})
end, {desc = 'SSG: Clean'})
```

**Emacs:**
```elisp
(define-key lsp-mode-map (kbd "C-c s b") 'ssg-build)
(define-key lsp-mode-map (kbd "C-c s s") 'ssg-serve)
(define-key lsp-mode-map (kbd "C-c s c") 'ssg-clean)
```

## Troubleshooting

### LSP Server Not Starting

**Symptoms:** No completions, diagnostics, or hover information.

**Solutions:**

1. **Check server binary:**
   ```bash
   ls -la /path/to/poly-ssg-lsp/_build/prod/rel/poly_ssg_lsp/bin/poly_ssg_lsp
   ```

2. **Verify Elixir installation:**
   ```bash
   elixir --version  # Should be 1.17+
   erl --version     # Should be OTP 27+
   ```

3. **Test server manually:**
   ```bash
   cd /path/to/poly-ssg-lsp
   mix test
   ```

4. **Check logs:**
   - VSCode: Output panel → Select "poly-ssg-lsp"
   - Neovim: `:LspLog`
   - Emacs: `*lsp-log*` buffer

### Completions Not Working

**Symptoms:** No autocomplete suggestions appearing.

**Solutions:**

1. **Verify SSG detection:**
   ```bash
   # In project root
   mix run -e 'IO.inspect(PolySSGLsp.Adapters.detect())'
   ```

2. **Check file type:**
   - Ensure file extension is supported (.md, .html, .toml, .yaml, .liquid)
   - VSCode: Check status bar for file type
   - Neovim: `:set filetype?`
   - Emacs: `M-x describe-mode`

3. **Enable verbose logging:**
   ```json
   {"lsp.trace.server": "verbose"}
   ```

### Build Command Failing

**Symptoms:** `ssg.build` command returns error.

**Solutions:**

1. **Verify SSG binary path:**
   ```bash
   which hugo  # or jekyll, zola, etc.
   ```

2. **Check project structure:**
   - Hugo: Requires `config.toml` or `config.yaml`
   - Jekyll: Requires `_config.yml`
   - Zola: Requires `config.toml`
   - mdBook: Requires `book.toml`

3. **Test build manually:**
   ```bash
   hugo build  # or jekyll build, zola build, etc.
   ```

4. **Check adapter logs:**
   ```bash
   tail -f ~/.cache/poly-ssg-lsp/adapter.log
   ```

### High CPU Usage

**Symptoms:** Editor becomes slow, high CPU usage.

**Solutions:**

1. **Disable build-on-save:**
   ```json
   {"lsp.ssg.buildOnSave": false}
   ```

2. **Increase debounce delay:**
   ```json
   {"lsp.ssg.debounceMs": 1000}
   ```

3. **Exclude large directories:**
   ```json
   {
     "lsp.ssg.excludeDirs": ["public", "node_modules", ".git"]
   }
   ```

### Adapter Crashes

**Symptoms:** LSP stops responding for specific SSG.

**Solutions:**

1. **Check crash dump:**
   ```bash
   ls -la /path/to/poly-ssg-lsp/erl_crash.dump
   cat erl_crash.dump
   ```

2. **Restart adapter:**
   ```bash
   # LSP automatically restarts crashed adapters
   # Or restart LSP server manually
   ```

3. **Report issue:**
   - Include crash dump
   - Provide SSG version: `hugo version`, `jekyll --version`, etc.
   - Share project configuration (sanitized)

## Adapter-Specific Notes

### Hugo

**Detection:** `config.toml`, `config.yaml`, or `config.json` in root

**Features:**
- Shortcode completion (all built-in + custom)
- Frontmatter validation (required fields: `title`, `date`)
- Template function hover docs
- Taxonomy suggestions (tags, categories)

**Configuration:**
```json
{
  "adapters": {
    "hugo": {
      "binaryPath": "/usr/local/bin/hugo",
      "version": "0.133.0+",
      "enableShortcodeCompletion": true,
      "enableTaxonomyCompletion": true
    }
  }
}
```

**Known Issues:**
- Nested shortcodes require manual triggering (Ctrl+Space)
- Custom shortcode docs require local `/layouts/shortcodes/*.html` parsing

### Jekyll

**Detection:** `_config.yml` in root

**Features:**
- Liquid template completion
- Front Matter YAML validation
- Include/layout suggestions
- Plugin detection

**Configuration:**
```json
{
  "adapters": {
    "jekyll": {
      "binaryPath": "/usr/bin/jekyll",
      "version": "4.0+",
      "enableLiquidCompletion": true,
      "pluginDirs": ["_plugins"]
    }
  }
}
```

**Known Issues:**
- Custom Liquid filters require manual definition in config
- Incremental build not supported in LSP (use `jekyll serve` directly)

### Zola

**Detection:** `config.toml` with `[build]` section in root

**Features:**
- Tera template syntax completion
- Section/page frontmatter validation
- Shortcode completion
- Taxonomy support

**Configuration:**
```json
{
  "adapters": {
    "zola": {
      "binaryPath": "/usr/bin/zola",
      "version": "0.19.0+",
      "enableTeraCompletion": true
    }
  }
}
```

### mdBook

**Detection:** `book.toml` in root

**Features:**
- SUMMARY.md validation
- Preprocessor completion
- Theme customization hints

**Configuration:**
```json
{
  "adapters": {
    "mdbook": {
      "binaryPath": "/usr/bin/mdbook",
      "preprocessors": ["links", "toc", "mermaid"]
    }
  }
}
```

### Franklin

**Detection:** `__site.jl` in root

**Features:**
- Julia code block validation
- Franklin command completion
- Page variable suggestions

**Configuration:**
```json
{
  "adapters": {
    "franklin": {
      "juliaPath": "/usr/bin/julia",
      "enableJuliaValidation": true
    }
  }
}
```

**Known Issues:**
- Julia compilation errors not captured (Julia runtime required)

### Hakyll

**Detection:** `hakyll.hs` or `site.hs` in root

**Features:**
- Pandoc template completion
- Haskell route validation
- Template context suggestions

**Configuration:**
```json
{
  "adapters": {
    "hakyll": {
      "stackPath": "/usr/bin/stack",
      "enableHaskellValidation": false
    }
  }
}
```

**Known Issues:**
- Requires compiled Hakyll binary (not auto-built by LSP)

### Other Supported SSGs

The LSP supports 60+ SSGs through a pluggable adapter system. For SSGs not listed above:

1. Check adapter implementation: `lib/adapters/`
2. Refer to adapter behaviour: `lib/adapters/behaviour.ex`
3. Common patterns apply (frontmatter, templates, build commands)

**Full list:** Hugo, Jekyll, Zola, Gatsby, Next.js, Astro, Eleventy, Pelican, Hexo, VuePress, Docusaurus, MkDocs, mdBook, Sphinx, Franklin, Hakyll, Bridgetown, Lume, SvelteKit, Remix, Nuxt, Middleman, Nanoc, Wintersmith, Metalsmith, Assemble, Harp, Brunch, Phenomic, Charge, Cactus, and 30+ more.

## Additional Resources

- **GitHub Repository:** https://github.com/hyperpolymath/poly-ssg-lsp
- **Issue Tracker:** https://github.com/hyperpolymath/poly-ssg-lsp/issues
- **Examples:** See `examples/` directory for sample configurations
- **API Documentation:** Run `mix docs` to generate API docs

## License

PMPL-1.0-or-later
