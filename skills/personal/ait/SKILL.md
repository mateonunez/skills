---
name: ait
description: Architectural invariants for ait — my personal AI platform. pnpm monorepo, Fastify gateway, Drizzle ORM, Qdrant vectors, Ollama generation, BullMQ scheduling, OAuth connectors (GitHub/Spotify/Linear/Notion/Slack/Google). Use when working in the ait repo, when proposing changes to connectors / RAG / scheduler, or when user mentions "ait", a connector name, or RAG.
---

# ait

Personal AI platform. Private repo. Public skills (`result-not-throw`, `vertical-slices`, `node-native-tests`, `single-tool-per-job`) all apply here — this is where they originated. This skill records ait-specific invariants.

## Stack invariants

- **Monorepo**: pnpm + workspace protocol. Packages scoped `@ait/*`.
- **Gateway**: Fastify 5. ORM: Drizzle (PostgreSQL).
- **Vectors**: Qdrant. Generation: Ollama (local). Telemetry: Langfuse. Queue: BullMQ (Redis).
- **Storage**: MinIO. UI: React + Vite (`UIt`).
- **Linter**: Biome **1.9** (legacy). Don't migrate to 2.x without asking — config differences would noise the diff.

## Conventions specific to this repo

- **Error handling**: `Result<T, E>` everywhere in business logic. Throws only at boundaries (Fastify handlers, CLI). See the public `result-not-throw` skill — this repo is the canonical example.
- **Naming**: PascalCase classes, `I`-prefix interfaces, camelCase methods, SCREAMING_SNAKE constants, kebab-case files. Type files: `*.types.ts`. Test files: `*.spec.ts`.
- **Entity types**: every domain entity has a `__type` discriminator string. Used by the ETL pipeline to route normalisation.
- **Connectors**: factory pattern. `connectorServiceFactory.getServiceByConfig(configId, userId)` is the entry point. Don't import connectors directly.
- **OAuth credentials**: encrypted at rest. The factory handles refresh — don't roll your own token logic.
- **Tests**: `node:test` + `borp` + `c8`. Docker services start automatically via `pnpm test`.

## Anti-patterns specific to this repo

- **Throwing in a service method.** Use `Result<T, E>`. The codebase will read inconsistent if you don't.
- **Importing a specific connector module** (e.g. `from '@ait/connector-spotify/internals'`) instead of going through the factory.
- **Adding a new connector without registering it in the factory** — it'll work in tests and silently miss in prod.
- **Migrating Biome 1.9 → 2.x as a side-effect** of another change.
- **Adding Jest, Vitest, ESLint, or Prettier.** All four are explicitly excluded by the public skills. ait predates them.
- **Storing Spotify/GitHub/etc. tokens unencrypted.** Always go through the credential layer.

## References

- [core-architecture](references/core-architecture.md) — layered architecture, data flow, package structure
- [core-entity-types](references/core-entity-types.md) — normalised `__type` discriminator entities
- [core-result-type](references/core-result-type.md) — `Result<T,E>`, `ok()`, `err()` usage
- [features-oauth](references/features-oauth.md) — encrypted credentials, factory pattern, refresh
- [features-rag](references/features-rag.md) — Qdrant, multi-query retrieval, reranking, streaming
- [features-scheduler](references/features-scheduler.md) — BullMQ, priority queues, repeatables
- [features-connectors](references/features-connectors.md) — connector catalogue + factory
- [best-practices-testing](references/best-practices-testing.md) — node:test, Docker services, c8

## Ports + env

```
PostgreSQL: 5432 | Qdrant: 6333 | Redis: 6379
Ollama: 11434    | MinIO: 9090  | Langfuse: 3333
Gateway: 3000    | UIt: 5173

GENERATION_MODEL=gemma3:latest
EMBEDDINGS_MODEL=mxbai-embed-large:latest
```
