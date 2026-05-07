---
summary: Data persistence adapters — PersistenceInFile and PersistenceInMemory implementations.
read_when: Configuring data persistence, implementing custom persistence, or debugging restore/save.
---

# Persistence

## Overview

The plugin supports optional persistence through adapter classes. If no persistence is configured, the database is ephemeral (lost on restart).

## PersistenceInFile

Saves/restores the Orama database to/from a file on disk.

```javascript
// lib/persistence/in-file.js
const { restoreFromFile, persistToFile } = require('@orama/plugin-data-persistence/server');

class PersistenceInFile {
  constructor(options = {}) {
    this.filePath = options.filePath || './orama.msp';
    this.format = options.format || 'binary';
    this.mustExistOnStart = options.mustExistOnStart || false;
  }

  async restore() {
    try {
      return await restoreFromFile(this.format, this.filePath);
    } catch (err) {
      if (this.mustExistOnStart) throw err;
      return null; // File doesn't exist yet — create fresh DB
    }
  }

  async persist(db) {
    return persistToFile(db, this.format, this.filePath);
  }
}
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `filePath` | `'./orama.msp'` | Path to the persistence file |
| `format` | `'binary'` | Serialization format (`'binary'` or `'json'`) |
| `mustExistOnStart` | `false` | Throw if file doesn't exist on restore |

### Usage

```javascript
const { fastifyOrama, PersistenceInFile } = require('fastify-orama');

await fastify.register(fastifyOrama, {
  schema: { title: 'string', body: 'string' },
  persistence: new PersistenceInFile({
    filePath: './data/search-index.msp',
    format: 'binary',
  }),
});

// Later: save to disk
await fastify.orama.persist();
```

## PersistenceInMemory

Saves/restores from an in-memory JSON string. Useful for testing or passing serialized data.

```javascript
// lib/persistence/in-memory.js
const { restore, persist } = require('@orama/plugin-data-persistence');

class PersistenceInMemory {
  constructor(options = {}) {
    this.jsonIndex = options.jsonIndex || null;
  }

  async restore() {
    if (!this.jsonIndex) return null;
    return restore('json', this.jsonIndex);
  }

  async persist(db) {
    this.jsonIndex = await persist(db, 'json');
    return this.jsonIndex;
  }
}
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `jsonIndex` | `null` | Stringified JSON of a previously persisted database |

### Usage

```javascript
const { fastifyOrama, PersistenceInMemory } = require('fastify-orama');

// Restore from a previously saved JSON string
const persistence = new PersistenceInMemory({
  jsonIndex: savedJsonString,
});

await fastify.register(fastifyOrama, {
  schema: { title: 'string' },
  persistence,
});

// Save current state
const json = await fastify.orama.persist();
// json is a string you can store anywhere (Redis, DB, etc.)
```

## Custom Persistence

Any object implementing `restore()` and `persist()` can be used:

```javascript
const customPersistence = {
  async restore() {
    // Return an Orama DB instance or null
    const data = await redis.get('orama-index');
    if (!data) return null;
    return restore('json', data);
  },

  async persist(db) {
    const json = await persist(db, 'json');
    await redis.set('orama-index', json);
    return json;
  },
};

await fastify.register(fastifyOrama, {
  schema: { title: 'string' },
  persistence: customPersistence,
});
```
