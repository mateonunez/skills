---
summary: Normalized entity types — the EntityType union, __type strings, and vendor-specific type mappings.
read_when: Working with entity normalization, adding new connectors, or querying across vendors.
---

# Entity Types

## EntityType Union

All external data is normalized into typed entities with `__type` discriminators:

```typescript
// packages/core/src/types/entities.ts
export type EntityType =
  // Spotify
  | 'spotify_track'
  | 'spotify_artist'
  | 'spotify_playlist'
  | 'spotify_album'
  | 'spotify_recently_played'
  // GitHub
  | 'github_repository'
  | 'github_pull_request'
  | 'github_commit'
  | 'github_issue'
  | 'github_file'
  // Linear
  | 'linear_issue'
  // X (Twitter)
  | 'x_tweet'
  // Notion
  | 'notion_page'
  // Slack
  | 'slack_message'
  // Google
  | 'google_calendar_event'
  | 'google_calendar_calendar'
  | 'google_youtube_subscription'
  | 'google_contact'
  | 'google_photo'
  // Gmail
  | 'gmail_message'
  | 'gmail_thread';
```

## Valid Entity Types Set

```typescript
export const VALID_ENTITY_TYPES: ReadonlySet<EntityType> = new Set([
  'spotify_track', 'spotify_artist', /* ... all values */
]);
```

Used for runtime validation when processing unknown input.

## Entity Structure Pattern

Every entity follows this normalized shape:

```typescript
interface NormalizedEntity {
  __type: EntityType;           // Discriminator
  id: string;                    // Vendor-specific ID
  externalId: string;            // Original ID from vendor
  title: string;                 // Display name
  description?: string;          // Optional description
  url?: string;                  // Link to original
  metadata: Record<string, unknown>; // Vendor-specific extra data
  createdAt: Date;
  updatedAt: Date;
}
```

## Vendor → Entity Mapping

| Vendor | Entity Types |
|--------|-------------|
| Spotify | `spotify_track`, `spotify_artist`, `spotify_playlist`, `spotify_album`, `spotify_recently_played` |
| GitHub | `github_repository`, `github_pull_request`, `github_commit`, `github_issue`, `github_file` |
| Linear | `linear_issue` |
| X | `x_tweet` |
| Notion | `notion_page` |
| Slack | `slack_message` |
| Google | `google_calendar_event`, `google_calendar_calendar`, `google_youtube_subscription`, `google_contact`, `google_photo` |
| Gmail | `gmail_message`, `gmail_thread` |

## Mapper Pattern

Each connector has mappers that transform vendor API responses into normalized entities:

```typescript
// packages/connectors/src/domain/mappers/spotify.mapper.ts
export function mapSpotifyTrack(raw: SpotifyApi.TrackObject): NormalizedEntity {
  return {
    __type: 'spotify_track',
    id: `spotify_track_${raw.id}`,
    externalId: raw.id,
    title: raw.name,
    description: `${raw.artists.map(a => a.name).join(', ')} — ${raw.album.name}`,
    url: raw.external_urls.spotify,
    metadata: {
      duration_ms: raw.duration_ms,
      popularity: raw.popularity,
      album: raw.album.name,
      artists: raw.artists.map(a => a.name),
    },
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}
```

## Type-Specific Integrations

Detailed type definitions for each vendor live in `packages/core/src/types/integrations/`:

```
types/integrations/
├── github.ts       # GitHubRepository, GitHubPullRequest, etc.
├── spotify.ts      # SpotifyTrack, SpotifyArtist, etc.
├── linear.ts       # LinearIssue
├── notion.ts       # NotionPage
├── slack.ts        # SlackMessage
├── google-calendar.ts
├── google-youtube.ts
├── google-contacts.ts
├── google-photos.ts
└── gmail.ts        # GmailMessage, GmailThread
```
