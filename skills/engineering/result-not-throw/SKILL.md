---
name: result-not-throw
description: I return Result<T, E extends Error> from business logic — never throw. Errors are typed Error subclasses with a code field (AItError pattern). Throws are reserved for boundary code (Fastify handlers, CLI entry, framework adapters). Use when writing TypeScript service/domain functions, when reviewing code that throws inside happy paths, when the codebase already exposes ok()/err() helpers, or when user says "Result type", "don't throw", or "no exceptions".
---

# Result, not throw

> If it doesn't hold up in production, it doesn't make the cut.

Throwing in business logic hides control flow. Failures become invisible until they propagate to a `try/catch` three layers up — by which point the type system has nothing useful to say and the caller has no idea what failure modes exist.

In my code, business logic returns `Result<T, E>`. Throws are reserved for boundaries (Fastify handlers, CLI entry points, framework adapters) where there's no caller to `ok`/`err` against.

This is the [`ait`](../../personal/ait/SKILL.md) pattern, lifted into a public skill. The canonical implementation lives at [`@ait/core/types/result.ts`](../../personal/ait/references/core-result-type.md).

## When this skill is active

You are writing or editing one of:

- A service-layer method (`*Service`, `*Repository`, `*UseCase`)
- A domain function in `packages/*/src/` that is not a handler
- A pure utility that can fail meaningfully (parsing, validation, IO)

If it's a Fastify handler, a CLI command, top-level `main()`, or a test, this skill **does not apply** — those are boundaries.

## The contract

```typescript
// packages/core/src/types/result.ts
export type Ok<T> = { ok: true; value: T };
export type Err<E extends Error = Error> = { ok: false; error: E };
export type Result<T, E extends Error = Error> = Ok<T> | Err<E>;

export const ok = <T>(value: T): Ok<T> => ({ ok: true, value });
export const err = <E extends Error>(error: E): Err<E> => ({ ok: false, error });
```

`E extends Error` — the error channel carries a real `Error` (or subclass), not a plain object. Stack traces still work, `cause` chaining still works, structured loggers still serialise.

If the codebase already has these helpers, **use them**:

```bash
grep -rE "export (const|function) (ok|err)\b" packages/ src/
```

In `ait` they live at `@ait/core` — same elsewhere.

## Phase 1 — Detect

- [ ] Is this boundary code? If yes, throw is fine. Stop.
- [ ] Does the codebase already export `Result<T, E>`, `ok`, `err`? Use them.
- [ ] Is there a typed `Error` subclass for this domain (e.g. `AItError`)? Use it.
- [ ] What are the failure modes? Pick a `code` string for each — `USER_NOT_FOUND`, `DB_ERROR`, `RATE_LIMIT`, `VALIDATION_ERROR`.

## Phase 2 — Type the errors

Errors are `Error` subclasses with a `code` field. Not plain objects, not discriminated unions of primitives. The `Error` base means stack traces, `cause` chaining, and serialisers all keep working; the `code` field gives you the discriminator the caller switches on.

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

Common codes I reuse: `USER_NOT_FOUND`, `DB_ERROR`, `AUTH_ERROR`, `CONNECTOR_ERROR`, `RATE_LIMIT`, `VALIDATION_ERROR`, `EMBEDDING_ERROR`, `RETRIEVAL_ERROR`. Pick from the existing catalogue before inventing one.

```typescript
async function fetchUserData(userId: string): Promise<Result<UserData, AItError>> {
  try {
    const user = await db.users.findById(userId);
    if (!user) return err(new AItError('USER_NOT_FOUND', `User ${userId} not found`));
    return ok(user);
  } catch (e) {
    return err(new AItError('DB_ERROR', 'Failed to fetch user', { userId }, e));
  }
}
```

The outer `try/catch` here is at the IO seam — that's the right place to convert thrown DB errors into `Result`. Inside business logic, no try/catch.

## Phase 3 — Chain results, propagate early

```typescript
async function processUser(userId: string): Promise<Result<ProcessedData, AItError>> {
  const userResult = await fetchUserData(userId);
  if (!userResult.ok) return userResult;             // propagate

  const configResult = await getConnectorConfig(userResult.value.configId);
  if (!configResult.ok) return configResult;          // propagate

  return ok(transform(userResult.value, configResult.value));
}
```

No `if/else` ladders, no nested try/catch — early-return on error, narrow on `ok`.

## Phase 4 — Consume at the boundary

```typescript
// gateway/src/routes/users.ts
fastify.get('/users/:id', async (request, reply) => {
  const r = await fetchUserData(request.params.id);
  if (!r.ok) {
    switch (r.error.code) {
      case 'USER_NOT_FOUND': return reply.code(404).send({ error: r.error.code });
      case 'DB_ERROR':       return reply.code(503).send({ error: r.error.code });
      default:               return reply.code(500).send({ error: r.error.code });
    }
  }
  return reply.send(r.value);
});
```

The boundary is where `Result` becomes HTTP / process exit / log + crash. Inner code never does that translation.

## Anti-patterns

- **`Result<T, string>` or `Result<T, { code: string }>`** — break the `E extends Error` constraint. Use a real `Error` subclass.
- **`result.value!`** — non-null assertion on a `Result` is a bug. Narrow with `if (r.ok)`.
- **Wrapping every IO call in `try { return ok(await fn()) } catch (e) { return err(e) }`** — write one `safe(fn)` helper and reuse it.
- **Throwing inside a function that returns `Result`** — the signature lies. Caller has no `try`.
- **Inventing a new error class per failure mode** — `UserNotFoundError`, `DbDownError`, `RateLimitedError` … one `AItError` (or domain equivalent) with a `code` string covers it. The `code` is the discriminant.
- **Mixed styles in one module** — if `userService.ts` returns `Result`, every exported function in it does. No half-measures.
- **`Result` at the boundary just for symmetry** — handlers throw or send HTTP; they don't return `Result` to the framework.

## When you encounter throws in existing code

Don't migrate unprompted. Note it, propose a follow-up, keep the surrounding style consistent. Mixed-style commits are noise. If I ask for the migration, do it as its own commit with no other changes.

## Cross-references

- Canonical implementation: [`personal/ait/references/core-result-type.md`](../../personal/ait/references/core-result-type.md)
- Domain glossary: [`CONTEXT.md`](../../../CONTEXT.md)
