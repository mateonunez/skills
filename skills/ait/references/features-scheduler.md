---
summary: BullMQ scheduler — priority queues, repeatable jobs, task registry, and worker configuration.
read_when: Working on background jobs, data sync scheduling, or queue management.
---

# Scheduler (BullMQ)

## Architecture

```
Scheduler Service
├── BullMQ Queue (Redis-backed)
├── Worker (concurrent job processor)
├── QueueEvents (job lifecycle monitoring)
└── Task Registry (validated task definitions)
```

## Configuration

```typescript
// packages/infrastructure/scheduler/src/scheduler.service.ts

// Default worker settings
const workerOptions = {
  concurrency: 2,
  connection: redisConnection,
};

// Default job options
const defaultJobOptions = {
  attempts: 3,
  backoff: { type: 'exponential', delay: 2000 },
  removeOnComplete: { age: 3600, count: 100 },
  removeOnFail: { age: 86400 },
};

// Rate limiter
const rateLimiter = {
  max: 10,
  duration: 60_000, // 10 jobs per 60 seconds
};
```

## Task Registry

All tasks must be registered before scheduling. The registry validates task names at runtime:

```typescript
// packages/infrastructure/scheduler/src/registry/
const schedulerRegistry = new Map<string, TaskDefinition>();

// Registration
schedulerRegistry.set('sync:spotify', {
  handler: syncSpotifyHandler,
  priority: 2,
  cron: '*/30 * * * *', // Every 30 minutes
});

// Validation before scheduling
if (!schedulerRegistry.has(taskName)) {
  throw new AItError('INVALID_TASK', `Unknown task: ${taskName}`);
}
```

## Priority Levels

| Priority | Value | Use Case |
|----------|-------|----------|
| High | 1 | User-initiated actions, auth refresh |
| Normal | 2 | Regular data sync (default) |
| Low | 3 | Background maintenance, cleanup |

## Repeatable Jobs

Scheduled via cron patterns:

```typescript
await queue.add('sync:spotify', { userId, configId }, {
  ...defaultJobOptions,
  repeat: { pattern: '*/30 * * * *' }, // Every 30 minutes
  priority: 2,
});

await queue.add('sync:github', { userId, configId }, {
  ...defaultJobOptions,
  repeat: { pattern: '0 */2 * * *' }, // Every 2 hours
  priority: 2,
});

await queue.add('cleanup:expired-tokens', {}, {
  ...defaultJobOptions,
  repeat: { pattern: '0 0 * * *' }, // Daily at midnight
  priority: 3,
});
```

## Job Lifecycle

```
Added → Waiting → Active → Completed/Failed
                    ↓
              (on failure)
                    ↓
            Waiting (retry with exponential backoff)
                    ↓
           (after 3 attempts)
                    ↓
               Failed (kept for 24h)
```

## Entrypoint

```typescript
// packages/infrastructure/scheduler/src/scheduler.entrypoint.ts
// Standalone process — runs outside the gateway
// Connects to Redis, registers all tasks, starts worker
```

The scheduler runs as a **separate process** from the gateway. Start independently.

## Task Manager

```typescript
// packages/infrastructure/scheduler/src/task-manager/
// High-level API for managing scheduled tasks:
// - addTask(name, data, options)
// - removeTask(jobId)
// - pauseTask(jobId)
// - getTaskStatus(jobId)
// - listTasks(filter)
```

## Note on Workspace Exclusion

The scheduler package is excluded from default workspace concurrency in `pnpm-workspace.yaml` because it uses TypeScript decorators which require specific build ordering:

```yaml
packages:
  - packages/*
  - packages/infrastructure/*
  - '!packages/infrastructure/scheduler'  # Excluded
```
