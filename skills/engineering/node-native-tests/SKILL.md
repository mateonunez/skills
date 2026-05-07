---
name: node-native-tests
description: I use node:test + borp + c8, not Jest or Vitest. The runtime ships a test runner — I use it. Use when adding tests, when an agent reaches for Jest/Vitest, when configuring coverage, or when user says "add a test", "test runner", or "borp".
---

# Node-native tests

The Node.js runtime ships a test runner. I use it. No `jest`, no `vitest`, no `@types/jest`. The runner is `borp` (TAP reporter, parallel by default), coverage is `c8`.

This is a [`single-tool-per-job`](../single-tool-per-job/SKILL.md) choice: the standard library covers it, so no third-party test framework earns its place in `package.json`. The full `ait` testing setup — Docker test services, c8 invocation, package-mirroring `test/` directory — is documented at [`personal/ait/references/best-practices-testing.md`](../../personal/ait/references/best-practices-testing.md).

## When this skill is active

You are about to:

- Add a test file
- Configure a test runner or coverage tool
- Migrate from another test framework (only if I asked for it)
- Reach for `jest.mock`, `vi.mock`, or `@types/jest`

## The setup

```jsonc
// package.json
{
  "scripts": {
    "test": "borp",
    "test:coverage": "c8 borp -T --reporter spec"
  },
  "devDependencies": {
    "borp": "^0.x",
    "c8": "^10.x"
  }
}
```

In monorepos with Docker-backed test infra (PostgreSQL, Qdrant, Redis), pre/post hooks bring services up and down:

```jsonc
{
  "scripts": {
    "test":     "pnpm run:recursive test",
    "pretest":  "pnpm start:services:test",
    "posttest": "pnpm stop:services:test"
  }
}
```

```typescript
// src/foo.spec.ts
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { foo } from './foo.ts';

describe('foo', () => {
  it('returns ok for valid input', () => {
    const r = foo('valid');
    assert.equal(r.ok, true);
  });

  it('returns err with __type for invalid input', () => {
    const r = foo('');
    assert.equal(r.ok, false);
    if (!r.ok) assert.equal(r.error.__type, 'empty-input');
  });
});
```

File suffix is `.spec.ts` (or `.spec.js`). `borp` picks them up by default.

## Mocking

`node:test` ships `mock` from `node:test`:

```typescript
import { describe, it, mock } from 'node:test';

const fn = mock.fn(() => 42);
fn();
assert.equal(fn.mock.callCount(), 1);
```

For module-level mocks, prefer dependency injection over runtime patching. If you really need module mocking, `mock.module` is in Node 22+.

## Anti-patterns

- **Reaching for Jest or Vitest.** Don't. The runtime has a runner. If something is missing, name what — usually it isn't.
- **`@types/jest` in `devDependencies`.** That's the migration tell. Remove it.
- **`vi.mock`, `jest.mock`, `jest.fn()`** in new code. Use `mock.fn` from `node:test`.
- **`*.test.ts` instead of `*.spec.ts`.** Pick one. I use `.spec.ts`. Keep the codebase consistent.
- **Adding `tsx` or `ts-node` as a test dependency** when `node --experimental-strip-types` (Node 22.6+) or native TS support (Node 23.6+) handles it.
- **Test files importing from `./dist/`.** Test the source, not the build.

## When the codebase already has Jest or Vitest

Stop. Don't migrate unprompted. If there are 50 Jest tests, a silent rewrite is hostile. Note the existing setup, propose a migration as a separate task, and write new tests in the existing style for now. If I confirm the migration, do it in one commit with no other changes.

The exception: brand-new packages added to an existing monorepo can use `node:test` even if other packages use Jest. Each package owns its own test setup.
