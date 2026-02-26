---
summary: AIt layered architecture — data flow, package structure, and infrastructure services.
read_when: Understanding AIt system design, adding new packages, or modifying data flow.
---

# Core Architecture

## System Overview

```
OAuth → Connector → PostgreSQL → Scheduler/ETL → Embeddings → Qdrant → RAG → AI Response
```

### Three Main Flows

1. **Authentication**: User → OAuth → Encrypted credentials → PostgreSQL
2. **Data Sync**: Scheduler → Connector → Raw data → ETL (retove) → Embeddings → Qdrant
3. **Query (RAG)**: User question → Embeddings → Qdrant search → Context → LLM → Streamed response

## Package Structure

All packages scoped `@ait/*`:

```
packages/
├── core/                   # @ait/core — Foundation types, errors, utilities
│   └── src/
│       ├── constants/      # Shared constants
│       ├── entities/       # Base entity definitions
│       ├── errors/         # AItError, RateLimitError
│       ├── http/           # HTTP client wrapper
│       ├── logging/        # Structured logging
│       ├── openapi/        # OpenAPI spec helpers
│       ├── types/          # Result<T,E>, EntityType, integrations/*
│       ├── utils/          # string, encryption, hash, array, async, format
│       └── validation/     # Input validation
│
├── connectors/             # @ait/connectors — External service integrations
│   └── src/
│       ├── domain/         # Entities + mappers (normalize vendor → internal)
│       ├── infrastructure/ # Vendor API clients
│       ├── services/       # High-level service layer
│       ├── shared/         # Auth utilities, constants
│       └── types/          # Connector-specific types
│
├── infrastructure/
│   ├── ai-sdk/             # @ait/ai-sdk — AI/ML pipeline
│   │   └── src/
│   │       ├── config/     # Model specs, collection config
│   │       ├── generation/ # stream.ts, text.ts, object.ts, tool-loop-controller.ts
│   │       ├── rag/        # retrieve.ts, rerank.ts
│   │       ├── services/   # embeddings/, generation/, tokenizer/
│   │       ├── telemetry/  # Langfuse integration
│   │       └── tools/      # MCP tools
│   ├── postgres/           # @ait/postgres — Drizzle ORM schemas + migrations
│   ├── qdrant/             # @ait/qdrant — Vector store client
│   ├── redis/              # @ait/redis — Cache + pub/sub
│   ├── scheduler/          # @ait/scheduler — BullMQ job scheduling
│   ├── storage/            # @ait/storage — S3/MinIO object storage
│   ├── store/              # Application data store
│   ├── ollama/             # Ollama model management
│   └── open-webui/         # Open WebUI integration
│
├── transformers/
│   └── retove/             # @ait/retove — ETL pipeline
│
├── gateway/                # @ait/gateway — Fastify HTTP API
│   └── src/
│       ├── config/         # Server configuration
│       ├── gateway.server.ts
│       ├── routes/         # auth/, chat/, data/
│       └── services/       # analytics/, cache/, insights/
│
└── apps/
    ├── chat/               # Landing page (React + Vite + Tailwind)
    └── uit/                # Main UI (React + Vite)
```

## Infrastructure Ports

| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Relational data + encrypted credentials |
| Qdrant | 6333 | Vector store (embeddings) |
| Redis | 6379 | Cache, BullMQ queues, pub/sub |
| Ollama | 11434 | Local LLM inference |
| MinIO | 9090 | Object storage (S3-compatible) |
| Langfuse | 3333 | LLM observability/telemetry |
| Gateway | 3000 | HTTP API |
| UIt | 5173 | Frontend UI |

## Database Schema (PostgreSQL + Drizzle)

Key tables:
- `users` — User accounts
- `connector_configs` — OAuth credentials (AES encrypted)
- `sync_jobs` — Data sync history
- `entities` — Normalized external data
- `conversations` — Chat history
- `messages` — Individual messages

## Vector Store (Qdrant)

- **Vector size**: 1024 for all collections (mxbai-embed-large)
- **Collections**: One per entity type category (spotify, github, linear, etc.)
- **Search**: Hybrid (dense + sparse BM25) with Reciprocal Rank Fusion

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `ConnectorService` |
| Interfaces | `I` prefix PascalCase | `IConnectorService` |
| Methods/vars | camelCase | `getTopTracks` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Files | kebab-case | `connector.service.ts` |
| Type files | `.types.ts` | `spotify.types.ts` |
| Spec files | `.spec.ts` | `connector.spec.ts` |
