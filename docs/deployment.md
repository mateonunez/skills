---
summary: Deployment patterns for Vercel (frontend) and Docker (backend/fullstack).
read_when: Deploying to production, configuring CI/CD, or optimizing build output.
---

# Deployment

## Frontend → Vercel

### Configuration

Deploy Next.js applications to Vercel with standalone output:

```typescript
// next.config.ts
const nextConfig: NextConfig = {
  output: 'standalone',
};
```

### Environment Variables

Manage in Vercel dashboard. Never commit secrets. Use `.env.example` to document required variables.

### Build Command

```bash
pnpm build
# Output: .next/standalone/ (self-contained)
```

### Preview Deployments

Every PR gets a preview deployment automatically. Preview URLs are posted as PR comments.

## Backend → Docker

### Multi-stage Dockerfile

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
RUN corepack enable
WORKDIR /app
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY packages/ ./packages/
RUN pnpm install --frozen-lockfile
RUN pnpm -r build

# Stage 2: Production
FROM node:22-alpine AS runner
RUN corepack enable
WORKDIR /app
COPY --from=builder /app/package.json /app/pnpm-workspace.yaml /app/pnpm-lock.yaml ./
COPY --from=builder /app/packages/ ./packages/
RUN pnpm install --frozen-lockfile --prod
CMD ["node", "packages/api/dist/server.js"]
```

### Docker Compose

```yaml
services:
  api:
    build: .
    ports:
      - "3000:3000"
    env_file: .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  postgres:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s

volumes:
  pgdata:
```

### Standalone Next.js in Docker

For containerized frontend deployment (alternative to Vercel):

```dockerfile
FROM node:22-alpine AS runner
WORKDIR /app
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
CMD ["node", "server.js"]
```

## Build Optimization Tips

- Use `--frozen-lockfile` in CI to prevent lock file changes
- Multi-stage builds minimize production image size
- Add `.dockerignore` to exclude `node_modules`, `.git`, `.next`
- Use health checks for dependent service startup ordering
- Cache pnpm store in CI: `pnpm store path` → cache key
