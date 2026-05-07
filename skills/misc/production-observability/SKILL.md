---
name: production-observability
description: Include error telemetry, request context, and queue visibility in production code. Use when writing error handlers, queue processors, async jobs, or boundary code that talks to external systems.
---

# Production Observability

> "If you can't see what's failing, you can't fix it."

## Philosophy

Code fails in production in ways it never fails in your editor. Silent failures are worse than loud failures. Every error, retry, and state transition should leave a trace.

## The Minimal Stack

**Error context** — when an error happens, log the context that led to it:

```typescript
// ✗ Silent failure
const result = await fetchUser(userId);
if (!result.ok) return null; // Where? Why? What ID?

// ✓ With context
const result = await fetchUser(userId);
if (!result.ok) {
  logger.error('fetch-user-failed', {
    userId,
    error: result.error.code,
    attempt: retryCount,
    elapsed: Date.now() - startTime,
  });
  return null;
}
```

**Request tracing** — every log entry tied to the request that caused it:

```typescript
// Fastify plugin: attach traceId to every log
app.addHook('onRequest', (request, reply, done) => {
  request.traceId = crypto.randomUUID();
  done();
});

// Later, in your logger:
logger.info('action', { traceId: request.traceId, ...data });
```

Later in a dashboard, you can follow one request through 10 different services.

**Queue visibility** — jobs that have retried 3x should alarm. Jobs stuck for 24h should alarm. Use BullMQ (or equivalent) metrics:

```typescript
// Expose these to your monitoring system:
const queue = new Queue('order-processing');

// These should feed dashboards:
queue.count(); // Total pending
queue.getDelayedCount(); // Retrying
queue.getFailedCount(); // Dead-lettered
queue.getActiveCount(); // Currently processing
```

## Structured Logging

Log as structured JSON, not prose. Grepability matters less than machine parsing:

```typescript
// ✗ Prose (hard to alert on)
logger.error(`Failed to process order ${orderId}: ${error}`);

// ✓ Structured
logger.error('order-process-failed', {
  orderId,
  errorCode: error.code,
  errorMessage: error.message,
  retryCount,
  elapsed,
  service: 'order-processor',
});
```

## When to Log

- **Every error**, with the error code and relevant context
- **Every external IO** (database, API, queue) that could fail — log both success and failure
- **State transitions** — job moved to retry, order status changed, user signed in
- **Performance milestones** — "query took 850ms" if it's a slow path
- **Security events** — failed auth, suspicious rate, permission denied

Do NOT log every line of business logic. Do NOT log for debugging during dev — that's what the debugger is for.

## Anti-Patterns

- **Silent failures.** Code that catches and swallows an error without logging. I've debugged production for hours because of this.
- **Logs without context.** "Error occurred" tells me nothing. Always include: what failed, why it might fail, and relevant IDs.
- **Structured logging without timestamps/traceIds.** Logs are worthless if you can't correlate them across services.
- **Alerts that never fire.** If you set up a threshold but never get paged, the threshold is wrong. Calibrate until the signal-to-noise ratio is useful.
- **Logging secrets.** Never log API keys, tokens, or user passwords, even in error messages. Sanitize or exclude.

## Phases

1. **Error boundaries** — every fallible operation (DB, HTTP, auth) must log on failure with error code + context
2. **Request tracing** — attach a traceId to every request so you can follow it through the system
3. **State transitions** — log when important things change (job queued, order shipped, retry triggered)
4. **Queue metrics** — expose queue depth, retry count, failure rate to your monitoring system
5. **Alarms** — set thresholds that page you when things are clearly wrong (error rate > 5%, queue depth growing unbounded, jobs stuck)

## Examples from ait

The `ait` reference implementation uses:
- **Error codes** in Result<T, E extends Error> — log `error.code` to correlate failure modes
- **BullMQ metrics** — dashboard shows pending/retrying/failed job counts, job-specific latency
- **Request correlation** — traceId flows from HTTP handler → queue job → external API calls
- **Qdrant observability** — collection health metrics, embedding latency tracked
