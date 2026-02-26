---
name: pnpm-monorepo
description: Patterns and conventions for managing monorepos with pnpm workspaces. Covers corepack setup, workspace protocol, package filtering, and shared scripts. Use when setting up or working within a pnpm monorepo.
---

# pnpm-monorepo

Patterns for managing monorepos with pnpm workspaces. Applicable to any multi-package TypeScript project.

## Preferences

- **Package manager**: pnpm via corepack (`corepack enable && corepack prepare pnpm@latest --activate`)
- **Workspace protocol**: `workspace:*` for internal dependencies
- **Node.js**: 22+ (LTS)
- **Concurrency**: Sequential by default (`--workspace-concurrency=1`) for build ordering

## References

| Category | Reference | Description |
|----------|-----------|-------------|
| Core | [core-setup](references/core-setup.md) | Corepack, workspace.yaml, protocol, filtering |
| Best Practices | [best-practices-scripts](references/best-practices-scripts.md) | Common scripts, service management, recursive runs |

## Quick Reference

```bash
# Setup
corepack enable
corepack prepare pnpm@latest --activate

# Install
pnpm install

# Run in specific package
pnpm --filter @scope/core build
pnpm --filter @scope/api dev

# Run across all packages
pnpm -r build
pnpm -r --workspace-concurrency=1 --if-present dev

# Add dependency to a package
pnpm --filter @scope/core add zod
pnpm --filter @scope/core add -D typescript

# Add workspace dependency
pnpm --filter @scope/api add @scope/core@workspace:*
```

```yaml
# pnpm-workspace.yaml
packages:
  - packages/*
  - apps/*
```
