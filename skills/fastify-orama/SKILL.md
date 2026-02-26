---
name: fastify-orama
description: Knowledge pack for fastify-orama — a Fastify plugin that integrates Orama full-text search with persistence support.
metadata:
  author: mateonunez
  version: 4.0.0
  source: https://github.com/mateonunez/fastify-orama
  stack: Fastify 5, Orama 3, fastify-plugin, JavaScript + TypeScript declarations
---

# fastify-orama

Fastify plugin for Orama search engine. Provides a proxy API over all Orama functions via `fastify.orama`, with optional data persistence (in-memory or file-based) and TypeScript generics via `withOrama<T>()`.

## Preferences

- **Language**: JavaScript (CommonJS) with TypeScript declaration files
- **Linter**: StandardJS (not Biome/ESLint)
- **Testing**: `borp` (TAP protocol) + `c8` coverage + `tstyche` for type tests
- **Plugin pattern**: `fastify-plugin` wrapper with `{ fastify: '5.x', name: 'fastify-orama' }`
- **Compatibility**: Plugin v4 → Fastify 5 + Orama 3

## References

| Category | Reference | Description |
|----------|-----------|-------------|
| Core | [core-plugin-api](references/core-plugin-api.md) | Plugin registration, decorator, Orama proxy pattern |
| Features | [features-persistence](references/features-persistence.md) | PersistenceInFile and PersistenceInMemory adapters |
| Best Practices | [best-practices-types](references/best-practices-types.md) | TypeScript generics, module augmentation, `withOrama<T>()` |

## Quick Reference

```bash
# Development
npm test          # lint + unit tests + type tests
npm run unit      # borp -T --reporter spec (with c8 coverage)
npm run typescript # tstyche type checking
npm run lint      # standard | snazzy
```

```javascript
// Basic usage
const fastify = require('fastify')();
const { fastifyOrama } = require('fastify-orama');

await fastify.register(fastifyOrama, {
  schema: { title: 'string', body: 'string', tag: 'enum' },
});

await fastify.orama.insert({ title: 'Hello', body: 'World', tag: 'news' });
const results = await fastify.orama.search({ term: 'hello' });
```

```typescript
// TypeScript with generics
const app = fastify().withOrama<{ title: 'string'; body: 'string' }>();
// app.orama is now typed with OramaApi<{ title: 'string'; body: 'string' }>
```
