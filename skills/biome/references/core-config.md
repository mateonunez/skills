---
summary: Biome configuration patterns — biome.json setup, VCS integration, editor config, and CI hooks.
read_when: Setting up Biome in a new project or updating shared formatting rules.
---

# Biome Configuration

## Base Config

Recommended starting point for TypeScript projects:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.4.4/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 120,
    "lineEnding": "lf"
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "jsxQuoteStyle": "double",
      "semicolons": "always",
      "trailingCommas": "all",
      "arrowParentheses": "always"
    }
  },
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  }
}
```

## Version

Target **Biome 2.x** (latest stable). Update the schema URL when upgrading:

```
"$schema": "https://biomejs.dev/schemas/2.4.4/schema.json"
```

Key additions in Biome 2.x:
- CSS linting and formatting support
- HTML/Astro/Svelte/Vue parser improvements
- Expanded rule set (nursery to stable promotions each release)
- `biome ci` command optimized for CI environments

## package.json Scripts

```json
{
  "lint": "biome check .",
  "lint:fix": "biome check --write ."
}
```

## VCS Integration

```json
{
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  }
}
```

Tells Biome to respect `.gitignore` patterns, so `node_modules/`, `dist/`, etc. are automatically excluded.

## File Patterns

Additional ignore patterns beyond `.gitignore`:

```json
{
  "files": {
    "ignore": [
      "*.min.js",
      "*.d.ts",
      "coverage/**",
      ".next/**",
      "dist/**"
    ]
  }
}
```

## Editor Integration

### VS Code

Use the official Biome extension and set as default formatter:

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "[javascript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescriptreact]": { "editor.defaultFormatter": "biomejs.biome" }
}
```

### Neovim

Biome provides LSP support. Configure via your LSP client (mason, nvim-lspconfig, or equivalent).

## Pre-commit Hooks

With Husky or similar:

```bash
# .husky/pre-commit
biome check --staged
```

This checks only staged files, keeping commits fast.
