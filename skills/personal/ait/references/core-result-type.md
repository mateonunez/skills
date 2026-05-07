---
summary: Result<T,E> pattern — ok() and err() constructors, usage in business logic, and error propagation.
read_when: Writing business logic that can fail, handling errors, or understanding the error model.
---

# Result Type Pattern

## Definition

```typescript
// packages/core/src/types/result.ts
export type Ok<T> = { ok: true; value: T };
export type Err<E extends Error = Error> = { ok: false; error: E };
export type Result<T, E extends Error = Error> = Ok<T> | Err<E>;

export const ok = <T>(value: T): Ok<T> => ({ ok: true, value });
export const err = <E extends Error>(error: E): Err<E> => ({ ok: false, error });
```

## Usage Pattern

**Never throw in business logic.** Use `Result<T, E>` instead:

```typescript
import { Result, ok, err } from '@ait/core';

async function fetchUserData(userId: string): Promise<Result<UserData, AItError>> {
  try {
    const user = await db.users.findById(userId);
    if (!user) {
      return err(new AItError('USER_NOT_FOUND', `User ${userId} not found`));
    }
    return ok(user);
  } catch (e) {
    return err(new AItError('DB_ERROR', 'Failed to fetch user', {}, e));
  }
}
```

## Consuming Results

```typescript
const result = await fetchUserData('123');

if (result.ok) {
  // TypeScript narrows to Ok<UserData>
  console.log(result.value.name);
} else {
  // TypeScript narrows to Err<AItError>
  console.error(result.error.code, result.error.message);
}
```

## AItError Class

```typescript
// packages/core/src/errors/ait-error.ts
export class AItError extends Error {
  readonly code: string;
  readonly meta?: Record<string, unknown>;

  constructor(
    code: string,
    message: string,
    meta?: Record<string, unknown>,
    cause?: unknown,
  ) {
    super(message, { cause });
    this.code = code;
    this.meta = meta;
    this.name = 'AItError';
  }
}
```

## Common Error Codes

| Code | Context |
|------|---------|
| `USER_NOT_FOUND` | User lookup failures |
| `DB_ERROR` | Database operation failures |
| `AUTH_ERROR` | Authentication/authorization failures |
| `CONNECTOR_ERROR` | External API call failures |
| `RATE_LIMIT` | Rate limiting hit |
| `VALIDATION_ERROR` | Input validation failures |
| `EMBEDDING_ERROR` | Embedding generation failures |
| `RETRIEVAL_ERROR` | Qdrant search failures |

## Chaining Results

```typescript
async function processUser(userId: string): Promise<Result<ProcessedData>> {
  const userResult = await fetchUserData(userId);
  if (!userResult.ok) return userResult; // Propagate error

  const configResult = await getConnectorConfig(userResult.value.configId);
  if (!configResult.ok) return configResult; // Propagate error

  return ok(transform(userResult.value, configResult.value));
}
```

## When to Throw

Exceptions (throw) are only used for:
- Programming errors (bugs that should crash)
- Framework boundaries (Fastify route handlers catch and format)
- Infrastructure failures that can't be recovered

All business logic uses `Result<T, E>`.
