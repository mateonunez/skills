---
summary: TypeScript generics, module augmentation, and the withOrama<T>() pattern.
read_when: Using fastify-orama with TypeScript, extending types, or understanding the type system.
---

# TypeScript Best Practices

## Module Augmentation

The plugin augments Fastify's types via declaration merging:

```typescript
// index.d.ts
import type { Orama, create, SearchParams, Results, Schema, PartialSchemaDeep, TypedDocument } from '@orama/orama';

export interface OramaApi<T> {
  insert: (document: PartialSchemaDeep<TypedDocument<Orama<T>>>) => Promise<string>;
  search: (params: SearchParams<Orama<Schema<T>>, T>) => Promise<Results<Schema<T>>>;
  remove: (id: string) => Promise<boolean>;
  update: (id: string, document: PartialSchemaDeep<TypedDocument<Orama<T>>>) => Promise<string>;
  count: () => Promise<number>;
  persist?: () => Promise<any>;
}

declare module 'fastify' {
  interface FastifyInstance {
    orama: OramaApi<any>;  // Default: untyped
    withOrama<T>(): this & { orama: OramaApi<T> };  // Generic: typed
  }
}
```

## withOrama<T>() Pattern

The `withOrama<T>()` method provides type-safe access to the Orama API:

```typescript
import Fastify from 'fastify';
import { fastifyOrama } from 'fastify-orama';

// Define your schema type
type MySchema = {
  title: 'string';
  body: 'string';
  tag: 'enum';
};

const app = Fastify();

await app.register(fastifyOrama, {
  schema: { title: 'string', body: 'string', tag: 'enum' },
});

// Without withOrama — orama is OramaApi<any>
app.orama.insert({ title: 'Hello' }); // No type checking on document shape

// With withOrama<T> — fully typed
const typed = app.withOrama<MySchema>();
typed.orama.insert({ title: 'Hello', body: 'World', tag: 'news' }); // Type-checked
typed.orama.search({ term: 'hello' }); // Results are typed
```

## Persistence Types

```typescript
interface FastifyOramaPersistence<T = any, O = any> {
  restore: () => Promise<Orama<T> | null>;
  persist: (data: Orama<T>) => Promise<O>;
}

declare class PersistenceInMemory<T, O = string | Buffer> {
  constructor(options?: { jsonIndex?: string });
  restore(): Promise<Orama<T> | null>;
  persist(db: Orama<T>): Promise<O>;
}

declare class PersistenceInFile<T, O = string> {
  constructor(options?: {
    filePath?: string;
    format?: 'binary' | 'json';
    mustExistOnStart?: boolean;
  });
  restore(): Promise<Orama<T> | null>;
  persist(db: Orama<T>): Promise<O>;
}
```

## Plugin Options Type

```typescript
type FastifyOramaPluginOptions = {
  persistence?: FastifyOramaPersistence;
} & Partial<Parameters<typeof create>[0]>;
```

This combines the optional persistence adapter with all Orama `create()` options.

## Type Testing

Type correctness is verified using `tstyche`:

```bash
npm run typescript  # Runs tstyche --config tstyche.config.json
```

Type tests live in `test/types/` and verify that the module augmentation and generics work correctly at compile time.
