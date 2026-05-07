---
name: entity-normalization
description: When data crosses a system boundary into my code, I normalise it into a typed entity with a __type discriminator and a fixed common shape. The vendor's wire format is not my domain model. Use when ingesting external API data, when adding a new connector, when proposing entity types, or when user mentions "normalize", "entity", "ETL", "__type", or "mapper".
---

# Entity normalisation

> The vendor's wire format is not my domain model.

External APIs return whatever they want — Spotify returns `external_urls.spotify`, GitHub returns `html_url`, Linear returns `url`. If raw vendor responses leak into the rest of the codebase, every consumer ends up special-casing every vendor. The fix is to normalise at the boundary: one shape, one discriminator, vendor-specific noise tucked into a `metadata` bag.

This is the [`ait`](../../personal/ait/SKILL.md) ETL pattern. It's the **data-channel** counterpart to [`result-not-throw`](../result-not-throw/SKILL.md) (the error channel). Together they make the type system useful: errors are typed, data is typed, the boundary is the only place either lives in the wild.

## When this skill is active

You are about to:

- Pull data from an external API and store / index / process it
- Add a new connector or integration
- Define a new entity type
- Write a mapper from vendor response → internal type
- Touch the `EntityType` union or its `VALID_ENTITY_TYPES` set

## The contract

```typescript
export type EntityType =
  | 'spotify_track' | 'spotify_artist' | 'spotify_album'
  | 'github_repository' | 'github_pull_request' | 'github_issue'
  | 'linear_issue' | 'notion_page' | 'slack_message'
  // ...
;

export interface NormalizedEntity {
  __type: EntityType;
  id: string;                          // namespaced: `${__type}_${externalId}`
  externalId: string;                  // vendor's ID, untouched
  title: string;
  description?: string;
  url?: string;
  metadata: Record<string, unknown>;   // vendor-specific extras
  createdAt: Date;
  updatedAt: Date;
}
```

Two invariants:

- **`__type` is the discriminator** the rest of the system switches on. Format: `<vendor>_<resource>`. Lowercase, snake_case. No exceptions — `SpotifyTrack` is wrong, `spotify-track` is wrong.
- **`id` is namespaced**: `${__type}_${externalId}`. Two vendors can have the same `externalId`; the namespaced `id` is globally unique.

## The mapper pattern

Every connector exports a function per resource: `map<Vendor><Resource>(raw) → NormalizedEntity`.

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

Mappers are **pure**. No IO, no logging, no side effects — just `vendor → domain`. That makes them trivial to test and trivial to compose.

## Adding a new entity type

1. **Add the literal to the `EntityType` union.** Stable name: `<vendor>_<resource>`.
2. **Add it to the `VALID_ENTITY_TYPES` set.** That's the runtime validator.
3. **Write the mapper** in `packages/connectors/src/domain/mappers/<vendor>.mapper.ts`.
4. **Add the vendor-specific raw type** under `packages/core/src/types/integrations/<vendor>.ts`.
5. **Register the mapper** in the connector's service layer.

Five steps, every time, in that order. Skipping any of them creates silent failure modes downstream.

## Querying across vendors

Because every entity has the same shape, downstream code can be vendor-agnostic:

```typescript
function summarise(entities: NormalizedEntity[]): string {
  return entities
    .map(e => `${e.__type}: ${e.title}`)
    .join('\n');
}
```

The discriminator is there when you want to specialise:

```typescript
switch (entity.__type) {
  case 'spotify_track':       return formatTrack(entity);
  case 'github_pull_request': return formatPR(entity);
  // ...
}
```

Exhaustiveness is checked by the compiler when you add a new `EntityType`.

## Anti-patterns

- **`__type: 'SpotifyTrack'`** (PascalCase) — break the convention. `__type` strings are kebab-style with `_` separators. The compiler doesn't enforce this; the convention does.
- **Putting vendor-specific fields at the top level** instead of in `metadata`. `entity.album` is wrong for a track that's also an album field on a playlist — vendor-specific extras live in `metadata`.
- **Mappers that throw.** If the raw payload is invalid, return `Result<NormalizedEntity, ValidationError>` (see `result-not-throw`) — don't throw inside a pure mapper.
- **Mappers that do IO** (fetch related data, hit the DB, log). Pure transformation only. If you need related data, fetch it before calling the mapper.
- **Forgetting to update `VALID_ENTITY_TYPES`** when adding a new literal. The TypeScript union is compile-time; the set is runtime. Both have to move together.
- **Different `id` formats per vendor.** `spotify_${id}` vs `gh-${id}` vs raw `id` — pick one (`${__type}_${externalId}`) and never deviate.
- **Storing the raw vendor payload alongside the entity** "just in case". It's `metadata` or it's gone. The vendor payload is not part of the domain.

## Cross-references

- Canonical implementation: [`personal/ait/references/core-entity-types.md`](../../personal/ait/references/core-entity-types.md)
- Connectors using this pattern: [`personal/ait/references/features-connectors.md`](../../personal/ait/references/features-connectors.md)
- Domain glossary: [`CONTEXT.md`](../../../CONTEXT.md)
