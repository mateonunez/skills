---
summary: GitHub integration — GraphQL client, activity feed, contribution data, and repository queries.
read_when: Working on open-source portfolio, GitHub activity feed, or contribution display.
---

# GitHub Integration

## Architecture

```
GitHubClient (lib/github.ts)
├── @octokit/graphql with Bearer token
├── In-memory LRU cache (same pattern as SpotifyClient)
├── fetchWithRetry (AbortController + exponential backoff)
├── Reusable GraphQL fragment (RepositoryFields)
└── React cache() exports for server components
```

## GitHubClient Class

Singleton with the same caching and retry patterns as SpotifyClient:

```typescript
class GitHubClient {
  private graphql: typeof graphql;
  private cache = new Map<string, { data: any; timestamp: number }>();

  constructor() {
    this.graphql = graphql.defaults({
      headers: { authorization: `Bearer ${GITHUB_TOKEN}` },
    });
  }
}
```

**Env var**: `GITHUB_TOKEN` (PAT with `read:user`, `repo`, `read:org` scopes)

## GraphQL Fragment

Reusable fragment for repository queries:

```graphql
fragment RepositoryFields on Repository {
  name
  description
  url
  stargazerCount
  forkCount
  primaryLanguage { name color }
  repositoryTopics(first: 5) { nodes { topic { name } } }
  updatedAt
  isArchived
  isFork
}
```

## Available Methods

| Method | Description |
|--------|-------------|
| `getProfile()` | User profile with followers, repo count, contributions calendar, sponsors |
| `getReadme()` | Profile README content |
| `getRepository(name)` | Single repository details |
| `getLastActivities()` | Recent PRs, issues, stars, commits |

## Server-Side Exports

```typescript
const githubClient = new GitHubClient();

export const getProfile = cache(() => githubClient.getProfile());
export const getReadme = cache(() => githubClient.getReadme());
export const getRepository = cache((name: string) => githubClient.getRepository(name));
export const getLastActivities = cache(() => githubClient.getLastActivities());
```

## Activity Feed

The `getLastActivities()` method returns recent activity across:
- Pull requests (opened, merged)
- Issues (opened, closed)
- Stars given
- Commits pushed

Used on the open-source page to show a live activity feed.

## Data Flow

```
Server Component
  └── getProfile() / getLastActivities()  (React cache dedup)
        └── GitHubClient.fetchWithRetry()
              └── @octokit/graphql (Bearer token)
                    └── GitHub GraphQL API

Client Component (open-source page)
  └── useSWR('/api/open-source', fetcher)
        └── API Route (app/api/open-source/route.ts)
              └── GitHubClient (server-side)
```

## Personal Config Reference

```typescript
// lib/config/personal.ts
const config = {
  name: 'Mateo Nunez',
  role: 'Senior Software Engineer',
  github: 'mateonunez',
  website: 'https://mateonunez.co',
  location: 'Colombia → Milan',
};
```
