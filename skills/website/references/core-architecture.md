---
summary: Next.js 16 App Router directory structure, path aliases, and next.config.ts setup.
read_when: Working on the website project structure, routing, or build configuration.
---

# Core Architecture

## Framework

- **Next.js 16.1.6** with App Router (no Pages Router)
- **React 19.2.4** with React Compiler (`compilationMode: 'infer'`)
- **TypeScript 5.9+** in strict mode
- **Output**: `standalone` (optimized Docker deployments)

## Directory Structure

```
website/
├── app/                    # App Router — routes + layouts
│   ├── layout.tsx          # Root layout (providers, fonts, skip-nav)
│   ├── page.tsx            # Home page
│   ├── error.tsx           # Root error boundary
│   ├── global-error.tsx    # Global error (inline styles only)
│   ├── loading.tsx         # Root loading skeleton
│   ├── not-found.tsx       # Custom 404
│   ├── robots.ts           # Dynamic robots.txt
│   ├── sitemap.ts          # Dynamic sitemap.xml
│   ├── opengraph-image.tsx # Dynamic OG image generation
│   ├── manifest.json       # PWA manifest (generated via prebuild)
│   ├── api/
│   │   ├── open-source/    # GitHub data API route
│   │   ├── rss/            # RSS feed endpoint
│   │   ├── spotify/        # Spotify proxy API route
│   │   └── webhook/        # Webhook handler
│   ├── blog/               # Blog listing + [slug] pages
│   ├── open-source/        # Open source portfolio page
│   └── spotify/            # Spotify integration page
├── articles/               # MDX content (NOT inside app/)
├── components/
│   ├── mate/               # Site-specific components
│   ├── mdx/                # MDX component registry
│   ├── providers/          # React context providers
│   ├── seo/                # SEO components (JSON-LD, etc.)
│   └── ui/                 # Generic reusable (shadcn/ui style)
├── hooks/                  # Custom React hooks
├── lib/
│   ├── analytics/          # GTM / Vercel analytics
│   ├── articles/           # parser.ts, fetcher.ts
│   ├── cache.ts            # Cache utilities
│   ├── config/             # personal.ts, social, metadata
│   ├── github.ts           # GitHubClient class
│   ├── helpers/            # Utility helpers
│   ├── seo/                # SEO utilities
│   ├── spotify.ts          # SpotifyClient class
│   └── utils.ts            # cn() helper (clsx + twMerge)
├── public/                 # Static assets
├── scripts/                # Build scripts (webmanifest generator)
├── styles/                 # Global CSS
└── types/                  # Shared TypeScript types
```

## Path Aliases

```json
// tsconfig.json
{ "compilerOptions": { "paths": { "@/*": ["./*"] } } }
```

All imports use `@/` prefix: `import { cn } from '@/lib/utils'`.

## next.config.ts Key Settings

```typescript
const nextConfig: NextConfig = {
  output: 'standalone',
  reactCompiler: { compilationMode: 'infer' },
  transpilePackages: ['next-mdx-remote'],
  pageExtensions: ['ts', 'tsx', 'js', 'jsx', 'md', 'mdx'],

  experimental: {
    inlineCss: true,
    optimizePackageImports: ['lucide-react', 'date-fns', 'framer-motion'],
    cacheLife: {
      default: { stale: 60, revalidate: 300, expire: 3600 },
      articles: { stale: 300, revalidate: 900, expire: 86400 },
      dynamic: { stale: 0, revalidate: 60, expire: 300 },
    },
  },

  images: {
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 86400,
    remotePatterns: [
      // Spotify CDN, GitHub avatars/assets, Spotify images
    ],
  },
};
```

## Security Headers

Applied via `headers()` in next.config.ts:

- **CSP**: Strict Content-Security-Policy with nonce-based scripts
- **HSTS**: `max-age=63072000; includeSubDomains; preload`
- **X-Frame-Options**: `DENY`
- **X-Content-Type-Options**: `nosniff`
- **Referrer-Policy**: `same-origin`
- **X-XSS-Protection**: `1; mode=block`
- **Static assets**: 1-year immutable cache for `/images/`, `/fonts/`, `/_next/static/`

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| next | 16.1.6 | Framework |
| react | 19.2.4 | UI library |
| tailwindcss | ^4.2.0 | Styling |
| next-mdx-remote | ^6.0.0 | MDX rendering (RSC) |
| swr | ^2.4.0 | Client-side data fetching |
| framer-motion | ^12.34.2 | Animations |
| @octokit/graphql | — | GitHub API |
| class-variance-authority | — | Component variants |
| zod | ^4.3.6 | Schema validation |
| lucide-react | — | Icons |
| date-fns | — | Date formatting |
| @radix-ui/* | — | Accessible primitives |
