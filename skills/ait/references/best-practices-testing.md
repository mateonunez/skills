---
summary: Testing patterns — Node.js native test runner, Docker test services, borp runner, and c8 coverage.
read_when: Writing tests, configuring test infrastructure, or debugging test failures.
---

# Testing Best Practices

## Stack

| Tool | Purpose |
|------|---------|
| `node:test` | Native Node.js test runner (describe/it) |
| `borp` | Test runner with TAP output |
| `c8` | Code coverage (V8-based) |
| Docker Compose | Test infrastructure (PostgreSQL, Qdrant, Redis) |

## Test Structure

Mirror `src/` directory in `test/`:

```
packages/core/
├── src/
│   ├── types/
│   │   └── result.ts
│   └── utils/
│       └── string.ts
└── test/
    ├── types/
    │   └── result.spec.ts
    └── utils/
        └── string.spec.ts
```

## Writing Tests

```typescript
// test/types/result.spec.ts
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { ok, err, type Result } from '../../src/types/result.ts';

describe('Result', () => {
  describe('ok()', () => {
    it('should create an Ok result', () => {
      const result = ok(42);
      assert.equal(result.ok, true);
      assert.equal(result.value, 42);
    });
  });

  describe('err()', () => {
    it('should create an Err result', () => {
      const error = new Error('test');
      const result = err(error);
      assert.equal(result.ok, false);
      assert.equal(result.error, error);
    });
  });
});
```

## Running Tests

```bash
# All tests (auto-starts Docker services)
pnpm test
# → runs: pnpm start:services:test && pnpm -r test && pnpm stop:services:test

# Single package
pnpm --filter @ait/core test

# With coverage
c8 borp -T --reporter spec
```

## Docker Test Services

```bash
# Start test infrastructure
pnpm start:services:test
# → docker compose -f docker-compose.test.yml up -d

# Stop test infrastructure
pnpm stop:services:test
# → docker compose -f docker-compose.test.yml down
```

Test services use different ports or databases to avoid conflicts with development.

## Pre-test Hook

```json
// Root package.json
{
  "pretest": "pnpm start:services:test && pnpm run --filter @ait/postgres db:migrate:test",
  "posttest": "pnpm stop:services:test"
}
```

Migrations run against the test database before tests execute.

## Test Patterns

### Service Tests (with DB)

```typescript
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';

describe('ConnectorService', () => {
  let service: ConnectorService;

  before(async () => {
    // Setup: connect to test DB, seed data
    service = new ConnectorService(testDb);
  });

  after(async () => {
    // Cleanup: remove test data, close connections
    await testDb.cleanup();
  });

  it('should sync spotify tracks', async () => {
    const result = await service.syncByType('spotify_track', testUserId, testConfigId);
    assert.equal(result.ok, true);
    assert.ok(result.value.count > 0);
  });
});
```

### Unit Tests (pure functions)

```typescript
describe('encryption', () => {
  it('should encrypt and decrypt roundtrip', () => {
    const original = 'sensitive-data';
    const encrypted = encrypt(original);
    const decrypted = decrypt(encrypted);
    assert.equal(decrypted, original);
    assert.notEqual(encrypted, original);
  });
});
```

## Coverage

c8 provides V8-based coverage without instrumenting source code:

```bash
c8 --reporter=text --reporter=html borp -T --reporter spec
```

## Guidelines

- Use `node:assert/strict` (not `assert` without strict)
- Always clean up test data in `after()` hooks
- Mock external APIs — never call real Spotify/GitHub in tests
- Test Result paths: both `ok` and `err` branches
- Name test files `*.spec.ts`
