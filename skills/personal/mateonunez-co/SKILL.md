---
name: mateonunez-co
description: Architectural invariants for mateonunez.co — Next.js 16 App Router, React 19 + React Compiler, Tailwind v4, MDX articles, Spotify/GitHub integrations, WCAG 2.1 AA, SEO-first. Use when working in the mateonunez.co repo, when proposing changes to my personal site, or when user mentions Spotify/GitHub integration, MDX articles, or the blog.
---

# mateonunez.co

My personal site. Public, SEO-driven, accessibility-first. Public skills (`result-not-throw`, `vertical-slices`, `node-native-tests`, `single-tool-per-job`) apply here too — this skill records what's site-specific.

## Stack invariants

- **Next.js 16** App Router. No pages router.
- **React 19** with React Compiler enabled. No manual `useMemo`/`useCallback` unless profiling demands it.
- **Tailwind CSS v4**. `clsx` + `tailwind-merge` via a `cn()` helper. CVA for component variants.
- **MDX** for articles. Frontmatter is the source of truth for SEO metadata.
- **No test suite.** Linting is the gate. `pnpm lint` must pass.
- **Biome 2.x** with the standard config (single quotes JS, double quotes JSX, 2-space, 120 width, semicolons, trailing commas all).
- **Path alias**: `@/` → project root.

## Conventions specific to this repo

- **Conventional Commit scopes**: `a11y`, `seo`, `spotify`, `blog`, `ui`, `dependencies`, `agents`. Use one of those — don't invent new scopes here.
- **Server data**: React `cache()`. **Client data**: SWR. Don't mix.
- **Spotify**: OAuth refresh flow with in-memory cache. Don't add a database — the in-memory cache is intentional.
- **Images**: WebP/AVIF via `next/image`. Decorative `alt=""`, content `alt="…"`.

## Anti-patterns specific to this repo

- **Adding a test runner.** I don't test this site. The bar is "lint passes + manual smoke". Don't propose Jest, Vitest, or Playwright unprompted.
- **Adding a CMS.** MDX in-repo is the CMS. No Contentful, no Sanity.
- **Persisting Spotify tokens to a database.** In-memory only. The refresh flow is built around that.
- **Bypassing the `cn()` helper** for class composition. Use `cn`, not raw template strings or `clsx` directly.
- **`outline: none` without a replacement.** WCAG 2.1 AA bar applies — see the `a11y-default-review` skill.
- **JSON-LD changes without updating the corresponding test fixture** in `references/features-seo.md` if one exists.

## References

- [core-architecture](references/core-architecture.md) — App Router structure, path aliases, next.config
- [core-mdx-system](references/core-mdx-system.md) — MDX pipeline, frontmatter, remark/rehype
- [features-spotify](references/features-spotify.md) — OAuth refresh, SWR polling, cache shape
- [features-github](references/features-github.md) — GraphQL integration, activity feed
- [features-seo](references/features-seo.md) — JSON-LD, sitemap, OG images, security headers
- [best-practices-a11y](references/best-practices-a11y.md) — WCAG 2.1 AA specifics
- [best-practices-perf](references/best-practices-perf.md) — React Compiler, dynamic imports, cache profiles
- [best-practices-error](references/best-practices-error.md) — Error boundaries, loading states

## Env vars

```
NEXT_PUBLIC_BASE_URL    NEXT_PUBLIC_GTM_ID
SPOTIFY_CLIENT_ID       SPOTIFY_CLIENT_SECRET     SPOTIFY_REFRESH_TOKEN
GITHUB_TOKEN
```
