---
name: vertical-slices
description: I organise code by feature, not by layer. In monorepos, every feature is a workspace package; new files live with the feature they belong to, not in a shared utils/ pile. Use when adding a new feature, deciding where a file goes, proposing package structure, or when user says "vertical slice", "package by feature", or "where should this go".
---

# Vertical slices

Layered organisation (`controllers/`, `services/`, `repositories/`) makes every change a horizontal cut across the whole codebase. One feature edit touches five folders. Tests in one place, code in another, types in a third. Then six months in, every PR is a tour through the entire repo.

I organise by feature instead. A feature owns its handlers, its services, its types, its tests, its migrations, its fixtures. The seam between features is a package boundary, not a layer convention.

The canonical example is [`ait`](../../personal/ait/SKILL.md) — see the package layout in [`personal/ait/references/core-architecture.md`](../../personal/ait/references/core-architecture.md): `@ait/core`, `@ait/connectors`, `@ait/postgres`, `@ait/qdrant`, `@ait/scheduler`, `@ait/gateway`. Each one owns its slice end to end.

## When this skill is active

You are about to:

- Create a new file or directory and have to decide where it goes
- Add a new feature or domain concept
- Propose monorepo package structure
- Refactor code that has accumulated into a shared `utils/` or `lib/` pile

## The decision tree

When deciding where a new file lives, ask in order:

1. **Does it belong to one feature?** → put it inside that feature's package, next to the code that uses it.
2. **Is it shared by 2+ features in the same domain?** → put it in a domain package (e.g. `@scope/auth`, `@scope/billing`).
3. **Is it shared across the whole product, with no domain coupling?** → consider a `@scope/shared` package, but **only if the abstraction is real**. Three callers is the bar. Two is duplication; one is premature.
4. **None of the above?** → you don't know yet. Inline it. Wait for the third caller before extracting.

## Workspace shape

In pnpm monorepos, the slice boundary is enforced by package boundaries:

```
packages/
  feature-a/
    src/
    test/
    package.json    # name: @scope/feature-a
  feature-b/
    src/
    package.json    # depends on "@scope/feature-a": "workspace:*"
apps/
  api/
  web/
```

Internal deps use `workspace:*`. Scoped names (`@scope/feature`) make the boundary visible at every import site.

## Anti-patterns

- **Shared `utils/` mega-package.** Becomes a junk drawer with no cohesion. Every feature ends up depending on it; nothing depends on a clear contract. Split or delete.
- **Splitting a feature across packages by tier** — e.g. `@scope/auth-controllers`, `@scope/auth-services`, `@scope/auth-repositories`. Re-creates layered organisation at the package level. Collapse to `@scope/auth`.
- **Inventing a feature for a one-off file.** If the file has one caller, it's not a feature, it's an implementation detail. Inline it.
- **Cross-feature imports that bypass the public API.** If `@scope/billing` imports from `@scope/auth/src/internals/`, the boundary is fake. Re-export through the package's `index.ts` or push the shared concept down to a third package.
- **Putting types in a separate `@scope/types` package** when the types belong to one feature. Types live with their owner.

## Useful pnpm scripts for the slice shape

```jsonc
// package.json (root)
{
  "scripts": {
    "dev":   "pnpm run:recursive --parallel dev",
    "build": "pnpm run:recursive build",
    "test":  "pnpm run:recursive test",
    "lint":  "biome check .",
    "run:recursive": "pnpm -r --workspace-concurrency=1 --if-present"
  }
}
```

`run:recursive` is a reusable base — `-r` traverses workspaces, `--workspace-concurrency=1` respects build order, `--if-present` skips packages that don't define the script. Override with `--parallel` for dev servers.

## When refactoring an existing horizontal layout

Don't rewrite the world. Pick one feature, slice it vertically into its own package, prove the pattern, then iterate. A half-finished refactor is worse than no refactor.

If the existing codebase is small (<10 files), just leave it. Premature monorepo-isation is a real failure mode.
