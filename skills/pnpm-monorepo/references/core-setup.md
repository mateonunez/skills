---
summary: pnpm workspace setup — corepack activation, workspace.yaml, protocol, and package filtering.
read_when: Setting up a new monorepo, adding packages, or understanding workspace configuration.
---

# pnpm Workspace Setup

## Corepack Activation

```bash
# Enable corepack (ships with Node.js 16+)
corepack enable

# Pin pnpm version (creates packageManager field in package.json)
corepack prepare pnpm@latest --activate
```

This ensures all developers use the same pnpm version. The `packageManager` field in `package.json` locks the version:

```json
{
  "packageManager": "pnpm@10.x.x"
}
```

## Workspace Configuration

```yaml
# pnpm-workspace.yaml
packages:
  - packages/*
  - apps/*
```

Adjust globs to match your directory structure. Common patterns:

```yaml
# Flat
packages:
  - packages/*

# Nested by domain
packages:
  - packages/core/*
  - packages/infrastructure/*
  - packages/apps/*

# Apps + packages
packages:
  - apps/*
  - packages/*
  - tooling/*
```

### Excluding Packages

Use `!` prefix to exclude specific packages from workspace operations:

```yaml
packages:
  - packages/*
  - '!packages/legacy-module'  # Exclude from workspace operations
```

## Workspace Protocol

Internal dependencies use `workspace:*` to reference other packages in the monorepo:

```json
{
  "dependencies": {
    "@scope/core": "workspace:*",
    "@scope/shared": "workspace:*"
  }
}
```

At publish time, `workspace:*` is replaced with the actual version number.

## Package Filtering

```bash
# Run command in specific package
pnpm --filter @scope/core build
pnpm --filter @scope/api dev

# Run in all packages matching pattern
pnpm --filter "@scope/*" build

# Run in package and its dependencies
pnpm --filter @scope/api... build

# Run in dependents of a package
pnpm --filter ...@scope/core build

# Run only in changed packages (since main)
pnpm --filter "...[main]" build
```

## Root package.json

```json
{
  "name": "@scope/monorepo",
  "private": true,
  "scripts": {
    "dev": "pnpm run:recursive --parallel dev",
    "build": "pnpm run:recursive build",
    "test": "pnpm run:recursive test",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "run:recursive": "pnpm -r --workspace-concurrency=1 --if-present"
  }
}
```

### Key Flags

| Flag | Purpose |
|------|---------|
| `-r` | Run recursively across all packages |
| `--workspace-concurrency=1` | Sequential execution (respects build order) |
| `--if-present` | Skip packages that don't have the script |
| `--parallel` | Run in parallel (for dev servers) |

## Adding Dependencies

```bash
# Add to specific package
pnpm --filter @scope/core add zod

# Add as dev dependency
pnpm --filter @scope/core add -D typescript

# Add workspace dependency
pnpm --filter @scope/api add @scope/core@workspace:*

# Add to root (shared dev tools)
pnpm add -Dw biome typescript
```

## Package Naming

Choose a scope that reflects your project or organization:

```
@scope/core          # Foundation types and utilities
@scope/shared        # Shared code across packages
@scope/api           # HTTP API / server
@scope/web           # Frontend application
@scope/db            # Database layer
@scope/config        # Shared configuration
```
