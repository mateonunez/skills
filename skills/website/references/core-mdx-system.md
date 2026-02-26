---
summary: MDX article system — file location, frontmatter schema, remark/rehype plugins, and server-side compilation.
read_when: Working on blog articles, MDX components, or content rendering.
---

# MDX System

## Article Location

Articles live in `./articles/*.mdx` at the project root — **not inside `app/`**. This separation keeps content independent from routing.

## Frontmatter Schema

```yaml
---
title: "Article Title"
description: "Brief description for SEO and previews"
date: "2025-01-15"
tags: ["nextjs", "react", "typescript"]
categories: ["engineering"]
image: "/images/articles/article-slug.webp"  # Optional
author: "Mateo Nunez"                         # Optional, defaults to config
translated: false                              # Optional
---
```

**Required fields**: `title`, `description`, `date`, `tags`
**Auto-computed**: `readingTime` (via `reading-time` library), `slug` (from filename), `permalink` (from `config.baseUrl + /articles/:slug`)

## Compilation Pipeline

```typescript
// lib/articles/parser.ts
import { compileMDX } from 'next-mdx-remote/rsc';
import remarkGfm from 'remark-gfm';
import rehypeSlug from 'rehype-slug';

// Server-side RSC compilation — no client bundle impact
const { content, frontmatter } = await compileMDX({
  source: rawMdx,
  options: {
    parseFrontmatter: true,
    mdxOptions: {
      remarkPlugins: [remarkGfm],     // GitHub Flavored Markdown
      rehypePlugins: [rehypeSlug],     // Auto-generate heading IDs
    },
  },
  components: mdxComponents, // Custom component registry
});
```

## Caching Strategy

All article functions are wrapped in React's `cache()` for request-level deduplication:

```typescript
import { cache } from 'react';

export const getArticles = cache(async () => {
  // Parse all .mdx files from ./articles/
  // Returns sorted by date (newest first)
});

export const getArticleBySlug = cache(async (slug: string) => {
  // Parse single article, compute reading time
});
```

This ensures each article is parsed at most once per request, even if multiple components call the same function.

## MDX Component Registry

Custom components are registered in `components/mdx/` and passed to `compileMDX`. This allows MDX articles to use project-specific UI components:

```tsx
// components/mdx/index.ts
const mdxComponents = {
  // Override default HTML elements
  h1: (props) => <h1 className="text-3xl font-bold" {...props} />,
  a: (props) => <Link className="text-amber-600 hover:underline" {...props} />,
  code: (props) => <Code {...props} />,
  // Custom components available in MDX
  Callout,
  CodeBlock,
};
```

## Reading Time

Computed automatically using the `reading-time` library at parse time:

```typescript
import readingTime from 'reading-time';

const stats = readingTime(rawContent);
// stats.text → "5 min read"
// stats.minutes → 5
```

## URL Pattern

- Listing: `/blog`
- Single article: `/blog/[slug]` where slug = MDX filename without extension
- Permalink: `https://mateonunez.co/articles/{slug}`
