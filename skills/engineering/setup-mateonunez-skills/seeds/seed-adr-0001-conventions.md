# ADR 0001 — Conventions

**Status**: Accepted
**Date**: <!-- YYYY-MM-DD -->

## Context

This repo follows the conventions encoded in [`mateonunez-skills`](https://github.com/mateonunez/agentfiles). Recording the decision here so the next contributor (human or agent) knows the choice was deliberate.

## Decision

- **Package manager**: pnpm via corepack. `packageManager` field pinned in `package.json`.
- **Lint + format**: Biome only. No ESLint, no Prettier.
- **Tests**: `node:test` + `borp` runner + `c8` coverage. No Jest, no Vitest.
- **Error handling in business logic**: `Result<T, E>` (see `result-not-throw` skill). Throws reserved for boundary code.
- **Module organisation**: vertical slices (package by feature) in monorepos. Workspace protocol (`workspace:*`) for internal deps.
- **Commits**: Conventional Commits with scopes.

## Consequences

- New tooling must clear the `single-tool-per-job` bar before being added.
- Migrations away from any of these defaults require a follow-up ADR.
