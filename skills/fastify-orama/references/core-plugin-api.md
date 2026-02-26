---
summary: Plugin registration, Fastify decorator, and Orama proxy pattern.
read_when: Understanding how the plugin works, modifying the API surface, or debugging registration.
---

# Plugin API

## Registration

The plugin uses `fastify-plugin` to ensure it registers at the correct encapsulation level:

```javascript
'use strict';
const fp = require('fastify-plugin');
const Orama = require('@orama/orama');

const SKIP_METHODS = ['create']; // Don't proxy 'create' — handled internally

async function fastifyOrama(fastify, options) {
  const { persistence, ...oramaOptions } = options;
  let db;
  const oramaApi = { persist: undefined };

  // Proxy all Orama functions (except SKIP_METHODS) with db as first argument
  const oramaProxyKeys = Object.keys(Orama)
    .filter((key) => typeof Orama[key] === 'function' && !SKIP_METHODS.includes(key));

  for (const key of oramaProxyKeys) {
    oramaApi[key] = (...args) => Orama[key](db, ...args);
  }

  // Persistence: try to restore existing DB
  if (persistence) {
    db = await persistence.restore();
    oramaApi.persist = () => persistence.persist(db);
  }

  // If no DB restored, create new one (requires schema)
  if (!db) {
    if (!oramaOptions.schema) {
      throw new Error('You must provide a schema to create a new Orama database');
    }
    db = Orama.create(oramaOptions);
  }

  // Decorate Fastify instance
  fastify.decorate('orama', oramaApi);
  fastify.decorate('withOrama', function withOrama() { return this; });
}

module.exports = fp(fastifyOrama, {
  fastify: '5.x',
  name: 'fastify-orama',
});
```

## Decorator: `fastify.orama`

The `orama` decorator proxies all Orama functions, automatically passing the database instance as the first argument:

```javascript
// Without the plugin (raw Orama):
await Orama.insert(db, { title: 'Hello' });
await Orama.search(db, { term: 'hello' });

// With the plugin (proxied):
await fastify.orama.insert({ title: 'Hello' });
await fastify.orama.search({ term: 'hello' });
```

### Available Methods

All Orama public functions except `create` are proxied:

- `insert(document)` — Insert a document
- `search(params)` — Full-text search
- `remove(id)` — Remove a document
- `update(id, document)` — Update a document
- `count()` — Count documents
- `persist()` — Save to persistence (only if persistence configured)
- Plus any other Orama functions added in future versions

## Decorator: `fastify.withOrama()`

A no-op function that returns `this` — used purely for TypeScript type narrowing:

```javascript
fastify.decorate('withOrama', function withOrama() { return this; });
```

See [best-practices-types](best-practices-types.md) for TypeScript usage.

## Plugin Options

```typescript
interface FastifyOramaPluginOptions {
  // Orama schema (required if no persistence or persistence returns null)
  schema?: Record<string, string>;

  // Optional persistence adapter
  persistence?: {
    restore: () => Promise<OramaDB | null>;
    persist: (db: OramaDB) => Promise<any>;
  };

  // Any other Orama.create() options
  [key: string]: any;
}
```

## Exports

```javascript
module.exports = fp(fastifyOrama, { fastify: '5.x', name: 'fastify-orama' });
module.exports.fastifyOrama = fastifyOrama;       // Named export
module.exports.PersistenceInMemory = PersistenceInMemory;
module.exports.PersistenceInFile = PersistenceInFile;
module.exports.oramaInternals = Orama.internals;  // Expose Orama internals
```
