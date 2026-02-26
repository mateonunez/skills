---
summary: Connector system — supported vendors, service architecture, domain mappers, and adding new connectors.
read_when: Working with external service integrations, adding new connectors, or debugging data sync.
---

# Connectors

## Supported Vendors

| Vendor | Package Path | Entity Types |
|--------|-------------|-------------|
| GitHub | `connectors/src/services/vendors/github/` | repository, pull_request, commit, issue, file |
| Spotify | `connectors/src/services/vendors/spotify/` | track, artist, playlist, album, recently_played |
| Linear | `connectors/src/services/vendors/linear/` | issue |
| Notion | `connectors/src/services/vendors/notion/` | page |
| Slack | `connectors/src/services/vendors/slack/` | message |
| Google Calendar | `connectors/src/services/vendors/google-calendar/` | calendar_event, calendar |
| Google YouTube | `connectors/src/services/vendors/google-youtube/` | youtube_subscription |
| Google Contacts | `connectors/src/services/vendors/google-contacts/` | contact |
| Google Photos | `connectors/src/services/vendors/google-photos/` | photo |
| Gmail | `connectors/src/services/vendors/gmail/` | message, thread |

## Architecture (per vendor)

```
connectors/src/
├── domain/
│   ├── entities/{vendor}.entity.ts     # Vendor-specific entity class
│   └── mappers/{vendor}.mapper.ts      # Raw API → NormalizedEntity
├── infrastructure/
│   └── vendors/{vendor}/
│       └── {vendor}.client.ts          # Low-level API client
├── services/
│   └── vendors/{vendor}/
│       └── {vendor}.service.ts         # High-level service (uses mapper + client)
└── shared/
    ├── auth/                            # OAuth helpers
    ├── constants/                       # API URLs, rate limits
    └── utils/                           # Shared utilities
```

## Connector Service Pattern

```typescript
// Each vendor service follows this interface:
interface IConnectorService {
  // Sync all data for a user
  syncAll(userId: string, configId: string): Promise<Result<SyncResult>>;

  // Sync specific entity types
  syncByType(type: EntityType, userId: string, configId: string): Promise<Result<SyncResult>>;

  // Get fresh data without storing
  fetch(type: EntityType, params?: FetchParams): Promise<Result<NormalizedEntity[]>>;
}
```

## Connector Factory

```typescript
// Get the right service for a connector config
const service = connectorServiceFactory.getServiceByConfig(configId, userId);

// The factory:
// 1. Loads connector config from DB (includes vendor type)
// 2. Decrypts OAuth credentials
// 3. Instantiates the correct vendor service
// 4. Injects authenticated API client
```

## Mapper Pattern

Every vendor has a mapper that transforms raw API responses:

```typescript
// domain/mappers/github.mapper.ts
export class GitHubMapper {
  static mapRepository(raw: GitHubApiRepo): NormalizedEntity {
    return {
      __type: 'github_repository',
      id: `github_repository_${raw.id}`,
      externalId: String(raw.id),
      title: raw.full_name,
      description: raw.description ?? '',
      url: raw.html_url,
      metadata: {
        stars: raw.stargazers_count,
        forks: raw.forks_count,
        language: raw.language,
        topics: raw.topics,
        isArchived: raw.archived,
      },
      createdAt: new Date(raw.created_at),
      updatedAt: new Date(raw.updated_at),
    };
  }

  static mapPullRequest(raw: GitHubApiPR): NormalizedEntity { /* ... */ }
  static mapCommit(raw: GitHubApiCommit): NormalizedEntity { /* ... */ }
}
```

## Adding a New Connector

1. Define entity types in `@ait/core/types/entities.ts`
2. Create type definitions in `@ait/core/types/integrations/{vendor}.ts`
3. Create API client in `connectors/infrastructure/vendors/{vendor}/`
4. Create mapper in `connectors/domain/mappers/{vendor}.mapper.ts`
5. Create service in `connectors/services/vendors/{vendor}/`
6. Register in connector factory
7. Add OAuth routes in gateway
8. Create Qdrant collection for the vendor
9. Add scheduler task for periodic sync

## OpenAPI Generation

```bash
pnpm generate:openapi  # Generates specs for connector APIs
```

Used for documentation and contract testing.
