---
summary: Performance patterns — React Compiler, dynamic imports, cacheLife profiles, and bundle optimization.
read_when: Optimizing website performance, bundle size, or caching strategy.
---

# Performance Best Practices

## React Compiler

Enabled with `compilationMode: 'infer'` — the compiler automatically memoizes components and hooks:

```typescript
// next.config.ts
reactCompiler: { compilationMode: 'infer' }
```

**Impact**: No need for manual `useMemo`, `useCallback`, or `React.memo` in most cases. The compiler handles it.

**When to still use manual memoization**: Complex derived computations that the compiler can't infer (rare).

## Package Optimization

```typescript
// next.config.ts
experimental: {
  optimizePackageImports: ['lucide-react', 'date-fns', 'framer-motion'],
}
```

These packages use barrel exports. Next.js automatically tree-shakes them so only used components/functions are bundled.

## Dynamic Imports

For heavy components not needed on initial load:

```typescript
import dynamic from 'next/dynamic';

const SpotifyPlayer = dynamic(() => import('@/components/mate/spotify-player'), {
  loading: () => <div className="animate-pulse h-20 bg-muted rounded" />,
  ssr: false, // Client-only component
});
```

## Cache Life Profiles

Three cache profiles defined in `next.config.ts`:

| Profile | Stale | Revalidate | Expire | Use Case |
|---------|-------|------------|--------|----------|
| `default` | 60s | 300s (5min) | 3600s (1hr) | Most pages |
| `articles` | 300s (5min) | 900s (15min) | 86400s (24hr) | Blog content |
| `dynamic` | 0s | 60s (1min) | 300s (5min) | Spotify, GitHub activity |

Usage in server components:

```typescript
import { unstable_cacheLife as cacheLife } from 'next/cache';

export default async function SpotifyPage() {
  'use cache';
  cacheLife('dynamic');
  // ...
}
```

## Image Optimization

```typescript
// next.config.ts
images: {
  formats: ['image/avif', 'image/webp'], // AVIF first (smaller), WebP fallback
  minimumCacheTTL: 86400,                 // 24-hour cache
}
```

Always use `next/image` with explicit `width` and `height` to prevent CLS:

```tsx
import Image from 'next/image';
<Image src={src} alt={alt} width={400} height={300} />
```

## CSS Optimization

```typescript
// next.config.ts
experimental: {
  inlineCss: true, // Inline critical CSS, reduce render-blocking
}
```

Tailwind v4 with `clsx` + `tailwind-merge` for class composition:

```typescript
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## Standalone Output

```typescript
output: 'standalone' // Minimal production build for Docker
```

Produces a self-contained build without `node_modules`. Ideal for containerized deployments.

## Loading States

Every route segment has a `loading.tsx` with skeleton UI:

```tsx
// app/blog/loading.tsx
export default function Loading() {
  return (
    <div className="space-y-4">
      {[1, 2, 3].map((i) => (
        <div key={i} className="animate-pulse h-24 bg-muted rounded" />
      ))}
    </div>
  );
}
```

## Core Web Vitals Targets

| Metric | Target |
|--------|--------|
| LCP (Largest Contentful Paint) | < 2.5s |
| FID (First Input Delay) | < 100ms |
| CLS (Cumulative Layout Shift) | < 0.1 |
| INP (Interaction to Next Paint) | < 200ms |
