---
summary: RAG pipeline — Qdrant vector search, hybrid retrieval, reranking, context injection, and streaming responses.
read_when: Working on AI responses, vector search, embedding generation, or context retrieval.
---

# RAG Pipeline

## Architecture

```
User Query
  ↓
Generate Query Embedding (mxbai-embed-large via Ollama)
  ↓
Hybrid Search (Dense + Sparse BM25) across Qdrant collections
  ↓
Reciprocal Rank Fusion (RRF) to merge results
  ↓
Deduplication + Collection-weight boosting + Rank limiting
  ↓
Build System Prompt with retrieved context
  ↓
Stream Response via Vercel AI SDK (streamText)
```

## Retrieval

```typescript
// packages/infrastructure/ai-sdk/src/rag/retrieve.ts

interface RetrieveOptions {
  query: string;
  collections?: string[];      // Specific collections (default: all)
  types?: EntityType[];         // Filter by entity types
  limit?: number;               // Max results (default: 20)
  scoreThreshold?: number;      // Minimum score (default: 0.4)
  enableCache?: boolean;        // Cache results (default: true)
  filter?: {
    fromDate?: Date;
    toDate?: Date;
  };
  collectionWeights?: Record<string, number>; // Boost specific collections
  allowedVendors?: string[];    // Filter by vendor
}
```

### Hybrid Search

1. **Dense vector search**: Query embedding → cosine similarity in Qdrant
2. **Sparse vector search**: BM25 keyword matching in Qdrant
3. **Fusion**: Reciprocal Rank Fusion (RRF) merges both result sets

Falls back to simple dense vector search if hybrid fails.

### Parallel Collection Search

Searches run in parallel across all relevant Qdrant collections:

```typescript
const results = await Promise.all(
  collections.map(collection =>
    qdrantClient.search(collection, {
      vector: queryEmbedding,
      limit: options.limit,
      score_threshold: options.scoreThreshold,
      filter: buildFilter(options),
    })
  )
);
```

### Post-Processing

1. **Deduplication**: Remove duplicate entities across collections
2. **Collection weighting**: Apply `collectionWeights` to boost/demote sources
3. **Rank limiting**: Return top N after re-scoring

## Embedding Generation

```typescript
// packages/infrastructure/ai-sdk/src/services/embeddings/
const embedding = await ollama.embeddings({
  model: EMBEDDINGS_MODEL, // 'mxbai-embed-large'
  prompt: text,
});
// Returns 1024-dimensional vector
```

**Model**: `mxbai-embed-large` via Ollama (1024 dimensions)
**All collections** use the same vector size (1024).

## Stream Generation

```typescript
// packages/infrastructure/ai-sdk/src/generation/stream.ts
import { streamText } from 'ai'; // Vercel AI SDK

const stream = await streamText({
  model: getModelSpec(GENERATION_MODEL),
  system: buildSystemPrompt(retrievedContext),
  messages: conversationHistory,
  tools: availableTools,
  maxSteps: 5, // Tool loop controller
  temperature: modelSpec.temperature,
  topP: modelSpec.topP,
});
```

### System Prompt Construction

RAG context is injected into the system prompt:

```typescript
function buildSystemPrompt(context: RetrievedDocument[]): string {
  const contextBlock = context
    .map(doc => `[${doc.__type}] ${doc.title}: ${doc.description}`)
    .join('\n');

  return `You are AIt, a personal AI assistant.

Use the following context to answer the user's question:
<context>
${contextBlock}
</context>

Answer based on the context. If the context doesn't contain relevant information, say so.`;
}
```

### Tool Loop Controller

Multi-step tool use with configurable max rounds (default: 5):

```typescript
// Prevents infinite tool loops
// After maxRounds, forces a text response
// Injects fallback message if tool loop produces no final text
```

## Caching

Retrieved results can be cached via `ICacheProvider` (Redis):

```typescript
interface ICacheProvider {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttl?: number): Promise<void>;
  delete(key: string): Promise<void>;
}
```

Cache key: hash of `query + collections + types + filter`.

## Qdrant Collection Layout

| Collection | Entity Types | Vector Size |
|------------|-------------|-------------|
| spotify | spotify_* | 1024 |
| github | github_* | 1024 |
| linear | linear_* | 1024 |
| notion | notion_* | 1024 |
| slack | slack_* | 1024 |
| google | google_*, gmail_* | 1024 |

## Telemetry

LLM calls are traced via Langfuse (port 3333):

```typescript
// Automatic span creation for each generation
const span = langfuse.span({
  name: 'rag-generation',
  input: { query, contextCount: context.length },
});
```
