---
summary: Error handling patterns — error boundaries per route segment, global error handler, SWR error handling, and loading states.
read_when: Implementing error handling, loading states, or debugging error boundaries.
---

# Error Handling Best Practices

## Route-Level Error Boundaries

Every route segment has its own `error.tsx` (client component) and `loading.tsx` (server component):

```
app/
├── error.tsx           # Root error boundary
├── loading.tsx         # Root loading skeleton
├── blog/
│   ├── error.tsx       # Blog-specific errors
│   └── loading.tsx     # Blog loading skeleton
├── spotify/
│   ├── error.tsx       # Spotify-specific errors
│   └── loading.tsx
└── open-source/
    ├── error.tsx
    └── loading.tsx
```

## Error Boundary Pattern

```tsx
// app/blog/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center min-h-[50vh] gap-4">
      <h2 className="text-2xl font-bold">Something went wrong</h2>
      <p className="text-muted-foreground">
        {error.digest && <code className="text-sm">Error ID: {error.digest}</code>}
      </p>
      <button
        onClick={reset}
        className="px-4 py-2 bg-amber-600 text-white rounded hover:bg-amber-700"
      >
        Try again
      </button>
    </div>
  );
}
```

**Key points**:
- Must be a client component (`'use client'`)
- Receives `error` (with optional `digest` for server errors) and `reset` function
- `reset()` re-renders the route segment
- Shows `error.digest` to help with debugging

## Global Error Handler

```tsx
// app/global-error.tsx
'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        {/* Inline styles only — no external CSS/JS guaranteed to load */}
        <div style={{ padding: '2rem', textAlign: 'center' }}>
          <h2>Something went wrong</h2>
          <button onClick={reset}>Try again</button>
        </div>
      </body>
    </html>
  );
}
```

**Critical**: `global-error.tsx` renders its own `<html>` and `<body>` because it replaces the root layout. Uses **inline styles only** — external CSS may not have loaded.

## Custom 404

```tsx
// app/not-found.tsx
export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[50vh]">
      <h1 className="text-4xl font-bold">404</h1>
      <p className="text-muted-foreground">Page not found</p>
    </div>
  );
}
```

## SWR Error Handling

Fetchers throw on non-ok responses:

```typescript
const fetcher = async (url: string) => {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to fetch: ${res.status}`);
  return res.json();
};

// In components — SWR provides error state
const { data, error, isLoading } = useSWR('/api/spotify/now-playing', fetcher);

if (error) return <ErrorFallback />;
if (isLoading) return <Skeleton />;
return <NowPlaying data={data} />;
```

## Loading State Pattern

```tsx
// app/blog/loading.tsx (Server Component — no 'use client')
export default function Loading() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 5 }, (_, i) => (
        <div key={i} className="animate-pulse space-y-2">
          <div className="h-6 bg-muted rounded w-3/4" />
          <div className="h-4 bg-muted rounded w-1/2" />
        </div>
      ))}
    </div>
  );
}
```

## Error Hierarchy

1. **Route `error.tsx`** — catches errors in that route segment
2. **Parent `error.tsx`** — catches errors from child segments (bubbles up)
3. **Root `error.tsx`** — catches all uncaught errors in the app
4. **`global-error.tsx`** — last resort, replaces entire HTML document
