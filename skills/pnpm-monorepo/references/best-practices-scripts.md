---
summary: Common monorepo scripts, Docker service management, and recursive run patterns.
read_when: Adding scripts, managing Docker services, or optimizing monorepo workflows.
---

# Monorepo Scripts Best Practices

## Root-Level Scripts

```json
{
  "scripts": {
    "dev": "pnpm run:recursive --parallel dev",
    "build": "pnpm run:recursive build",
    "test": "pnpm run:recursive test",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",

    "pretest": "pnpm start:services:test",
    "posttest": "pnpm stop:services:test",

    "start:services": "docker compose up -d",
    "stop:services": "docker compose down",
    "start:services:test": "docker compose -f docker-compose.test.yml up -d",
    "stop:services:test": "docker compose -f docker-compose.test.yml down",

    "run:recursive": "pnpm -r --workspace-concurrency=1 --if-present"
  }
}
```

## The `run:recursive` Helper

```json
"run:recursive": "pnpm -r --workspace-concurrency=1 --if-present"
```

A reusable base command for recursive operations:
- `-r`: Traverse all workspace packages
- `--workspace-concurrency=1`: Run one at a time (respects dependency order)
- `--if-present`: Skip packages that don't define the script

Usage: `pnpm run:recursive build` runs `build` in each package sequentially.

For dev servers, override with `--parallel`: `pnpm run:recursive --parallel dev`.

## Docker Service Management

```bash
# Development
pnpm start:services     # Start all infrastructure services
pnpm stop:services      # Stop all

# Testing (separate ports/DBs to avoid conflicts)
pnpm start:services:test
pnpm stop:services:test
```

### Pre/Post Test Hooks

```json
{
  "pretest": "pnpm start:services:test && pnpm --filter @scope/db migrate:test",
  "posttest": "pnpm stop:services:test"
}
```

The `pretest` script starts test infrastructure and runs migrations. The `posttest` script tears it down.

## Per-Package Scripts

### Library Package

```json
{
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "test": "borp -T --reporter spec",
    "lint": "biome check src/"
  }
}
```

### API Server (Fastify / Express)

```json
{
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc -p tsconfig.build.json",
    "start": "node dist/server.js"
  }
}
```

### Web App (Vite / Next.js)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  }
}
```

## Guidelines

1. **Root scripts orchestrate** — individual packages define their own `dev`/`build`/`test`
2. **Use `--filter` for targeted runs** — avoid running everything when working on one package
3. **Sequential builds, parallel dev** — builds need dependency ordering, dev servers don't
4. **Docker services are idempotent** — `docker compose up -d` is safe to run multiple times
5. **Test services are isolated** — different ports and databases prevent conflicts with dev
