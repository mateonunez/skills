---
name: website
description: Knowledge pack for mateonunez.co — Next.js 16 + React 19 personal website with MDX blog, Spotify/GitHub integrations, and comprehensive SEO.
metadata:
  author: mateonunez
  version: 1.7.0
  source: https://mateonunez.co
  stack: Next.js 16, React 19, Tailwind CSS v4, MDX, SWR, Framer Motion
---

# website

Personal website and blog built with Next.js 16 (App Router), React 19 with React Compiler, Tailwind CSS v4, and MDX for content.

## Preferences

- **Package manager**: pnpm (corepack required)
- **Linter/formatter**: Biome 2.x — 2-space indent, single quotes JS, double quotes JSX, semicolons, 120-char width
- **Styling**: Tailwind CSS v4 + `clsx` + `tailwind-merge` + `class-variance-authority`
- **Data fetching**: SWR (client), React `cache()` (server)
- **Commits**: Conventional Commits with scopes: `a11y`, `seo`, `spotify`, `blog`, `ui`, `dependencies`, `agents`
- **No tests** — linting only via `pnpm lint` / `pnpm lint:fix`
- **Path aliases**: `@/` → project root

## References

| Category | Reference | Description |
|----------|-----------|-------------|
| Core | [core-architecture](references/core-architecture.md) | App Router structure, path aliases, next.config |
| Core | [core-mdx-system](references/core-mdx-system.md) | MDX articles, frontmatter schema, remark/rehype plugins |
| Features | [features-spotify](references/features-spotify.md) | OAuth refresh flow, SWR polling, in-memory cache |
| Features | [features-github](references/features-github.md) | GraphQL integration, activity feed, contribution data |
| Features | [features-seo](references/features-seo.md) | JSON-LD, sitemap, OG images, security headers |
| Best Practices | [best-practices-a11y](references/best-practices-a11y.md) | WCAG 2.1 AA, skip nav, aria-live, reduced motion |
| Best Practices | [best-practices-perf](references/best-practices-perf.md) | React Compiler, dynamic imports, cache profiles |
| Best Practices | [best-practices-error](references/best-practices-error.md) | Error boundaries, loading states, SWR error handling |

## Quick Reference

```bash
# Development
pnpm dev          # Start dev server (webpack mode)
pnpm build        # Production build (standalone output)
pnpm lint         # Biome lint + format + check
pnpm lint:fix     # Auto-fix with --write --unsafe

# Key env vars
NEXT_PUBLIC_BASE_URL=https://mateonunez.co
SPOTIFY_CLIENT_ID=...
SPOTIFY_CLIENT_SECRET=...
SPOTIFY_REFRESH_TOKEN=...
GITHUB_TOKEN=...
NEXT_PUBLIC_GTM_ID=...
```

```typescript
// Import pattern
import { cn } from '@/lib/utils';
import { config } from '@/lib/config/personal';

// Component with CVA
import { cva } from 'class-variance-authority';
const buttonVariants = cva('base-classes', {
  variants: { size: { sm: '...', md: '...' } },
});
```
