---
summary: SEO implementation — JSON-LD structured data, dynamic sitemap, OG image generation, and security headers.
read_when: Working on SEO, metadata, structured data, social sharing, or security headers.
---

# SEO Implementation

## JSON-LD Structured Data

Schema.org structured data for rich search results:

```typescript
// components/seo/json-ld.tsx
import type { WithContext, Person, WebSite, BlogPosting } from 'schema-dts';

// Person schema on home page
const personSchema: WithContext<Person> = {
  '@context': 'https://schema.org',
  '@type': 'Person',
  name: config.name,
  url: config.website,
  jobTitle: config.role,
  sameAs: [
    `https://github.com/${config.github}`,
    `https://twitter.com/${config.twitter}`,
  ],
};

// BlogPosting schema on article pages
const articleSchema: WithContext<BlogPosting> = {
  '@context': 'https://schema.org',
  '@type': 'BlogPosting',
  headline: article.title,
  datePublished: article.date,
  author: { '@type': 'Person', name: config.name },
  description: article.description,
};
```

## Dynamic Sitemap

```typescript
// app/sitemap.ts
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const articles = await getArticles();
  const articleUrls = articles.map((a) => ({
    url: `${config.baseUrl}/blog/${a.slug}`,
    lastModified: new Date(a.date),
    changeFrequency: 'monthly' as const,
    priority: 0.7,
  }));

  return [
    { url: config.baseUrl, changeFrequency: 'weekly', priority: 1.0 },
    { url: `${config.baseUrl}/blog`, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${config.baseUrl}/open-source`, changeFrequency: 'weekly', priority: 0.8 },
    { url: `${config.baseUrl}/spotify`, changeFrequency: 'daily', priority: 0.6 },
    ...articleUrls,
  ];
}
```

## Dynamic OG Image

```typescript
// app/opengraph-image.tsx
import { ImageResponse } from 'next/og';

export default async function Image() {
  return new ImageResponse(
    // JSX rendered as image — uses site branding, title, description
    // Renders at 1200x630 for social sharing
  );
}

export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';
```

## Metadata Pattern

```typescript
// app/layout.tsx or page-level
export const metadata: Metadata = {
  title: { template: '%s | Mateo Nunez', default: 'Mateo Nunez' },
  description: '...',
  metadataBase: new URL(config.baseUrl),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    siteName: 'Mateo Nunez',
  },
  twitter: {
    card: 'summary_large_image',
    creator: `@${config.twitter}`,
  },
  robots: { index: true, follow: true },
};
```

## Robots.txt

```typescript
// app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: `${config.baseUrl}/sitemap.xml`,
  };
}
```

## RSS Feed

Available at `/api/rss` — generates XML feed of all blog articles.

## Security Headers

All applied in `next.config.ts` `headers()` function:

| Header | Value |
|--------|-------|
| Content-Security-Policy | Strict CSP with nonce-based scripts |
| Strict-Transport-Security | `max-age=63072000; includeSubDomains; preload` |
| X-Frame-Options | `DENY` |
| X-Content-Type-Options | `nosniff` |
| Referrer-Policy | `same-origin` |
| X-XSS-Protection | `1; mode=block` |

## Static Asset Caching

```typescript
// 1-year immutable cache for static assets
{
  source: '/(images|fonts|_next/static)/(.*)',
  headers: [
    { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
  ],
}
```

## Trailing Slashes

No trailing slashes. Next.js default behavior (no `trailingSlash: true` in config).
