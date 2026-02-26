---
name: biome
description: Shared Biome formatter and linter conventions for TypeScript/JavaScript projects. Covers configuration patterns, editor integration, CI setup, and rule management. Use when setting up or configuring Biome in any project.
---

# biome

Code quality conventions using Biome as a unified formatter + linter. Replaces ESLint + Prettier with a single, fast tool.

## Preferences

- **Indent**: 2 spaces
- **Quote style**: Single quotes for JS/TS, double quotes for JSX attributes
- **Semicolons**: Always
- **Line width**: 120 characters
- **Organize imports**: Enabled
- **Trailing commas**: All

## References

| Category | Reference | Description |
|----------|-----------|-------------|
| Core | [core-config](references/core-config.md) | biome.json patterns, VCS integration, editor setup |
| Best Practices | [best-practices-rules](references/best-practices-rules.md) | Rule management, biome-ignore patterns, overrides |

## Quick Reference

```bash
# Lint only
biome lint .

# Format only
biome format .

# Full check (lint + format + organize imports)
biome check .

# Auto-fix everything
biome check --write .

# Aggressive fix (includes unsafe transforms)
biome check --write --unsafe .

# CI — optimized output for CI environments
biome ci .

# Check only staged files (for pre-commit hooks)
biome check --staged
```

```json
// Minimal biome.json
{
  "$schema": "https://biomejs.dev/schemas/2.4.4/schema.json",
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 120
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "jsxQuoteStyle": "double",
      "semicolons": "always",
      "trailingCommas": "all"
    }
  },
  "organizeImports": { "enabled": true },
  "linter": { "enabled": true }
}
```
