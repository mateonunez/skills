---
summary: Spotify integration — OAuth refresh-token flow, SWR polling, in-memory LRU cache, and retry logic.
read_when: Working on Spotify features, music display, or OAuth token refresh.
---

# Spotify Integration

## Architecture

```
SpotifyClient (lib/spotify.ts)
├── OAuth refresh-token flow (server-side)
├── In-memory LRU cache (Map + timestamps)
├── fetchWithRetry (AbortController + exponential backoff)
└── React cache() exports for server components

SWR hooks (client-side)
├── Currently listening → 20s polling
└── Recently played → 10min polling
```

## OAuth Token Refresh

Uses the Authorization Code flow with offline refresh. The refresh token is stored as an env var (initial setup done manually via Spotify Developer Dashboard).

```typescript
// Token refresh (server-side only)
const response = await fetch('https://accounts.spotify.com/api/token', {
  method: 'POST',
  headers: {
    Authorization: `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: SPOTIFY_REFRESH_TOKEN,
  }),
});
```

**Env vars required**:
- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `SPOTIFY_REFRESH_TOKEN`
- `SPOTIFY_REDIRECT_URI`

## SpotifyClient Class

Singleton with internal caching and retry logic:

```typescript
class SpotifyClient {
  private cache = new Map<string, { data: any; timestamp: number }>();
  private cacheTTL = 60_000; // 1 minute default

  // All methods follow this pattern:
  async getTopTracks(): Promise<SpotifyTrack[]> {
    const cached = this.getFromCache('top-tracks');
    if (cached) return cached;
    const data = await this.fetchWithRetry('/me/top/tracks?limit=20');
    this.setCache('top-tracks', data.items);
    return data.items;
  }

  // getCurrentlyListening SKIPS cache (always fresh)
  async getCurrentlyListening(): Promise<SpotifyTrack | null> {
    const data = await this.fetchWithRetry('/me/player/currently-playing');
    return data?.item ?? null;
  }
}
```

## Retry Logic

```typescript
private async fetchWithRetry(
  endpoint: string,
  options?: RequestInit,
  retries = 3,
  timeout = 5000,
): Promise<any> {
  for (let attempt = 0; attempt < retries; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    try {
      const res = await fetch(`https://api.spotify.com/v1${endpoint}`, {
        ...options,
        signal: controller.signal,
        headers: { Authorization: `Bearer ${await this.getAccessToken()}` },
      });
      clearTimeout(timeoutId);
      if (res.ok) return res.json();
      if (res.status === 401) { await this.refreshToken(); continue; }
      throw new Error(`Spotify API ${res.status}`);
    } catch (e) {
      clearTimeout(timeoutId);
      if (attempt === retries - 1) throw e;
      await new Promise(r => setTimeout(r, 2 ** attempt * 1000));
    }
  }
}
```

## Server-Side Exports

All exports use React `cache()` for request deduplication:

```typescript
const spotifyClient = new SpotifyClient();

export const getCurrentlyListening = cache(() => spotifyClient.getCurrentlyListening());
export const getRecentlyPlayed = cache(() => spotifyClient.getRecentlyPlayed());
export const getTopArtists = cache(() => spotifyClient.getTopArtists());
export const getTopTracks = cache(() => spotifyClient.getTopTracks());
export const getUserPlaylists = cache(() => spotifyClient.getUserPlaylists());
```

## Client-Side Polling (SWR)

```typescript
// Currently listening — polls every 20 seconds
const { data: nowPlaying } = useSWR('/api/spotify/currently-playing', fetcher, {
  refreshInterval: 20_000,
});

// Recently played — polls every 10 minutes
const { data: recentTracks } = useSWR('/api/spotify/recently-played', fetcher, {
  refreshInterval: 600_000,
});
```

API routes in `app/api/spotify/` proxy to the SpotifyClient, keeping secrets server-side.

## Available Methods

| Method | Cache | Description |
|--------|-------|-------------|
| `getCurrentlyListening()` | No | Currently playing track |
| `getRecentlyPlayed()` | Yes (1min) | Last 20 played tracks |
| `getTopArtists()` | Yes (1min) | User's top artists |
| `getTopTracks()` | Yes (1min) | User's top tracks |
| `getUserPlaylists()` | Yes (1min) | User's playlists |
| `getUserPublicPlaylists()` | Yes (1min) | Public playlists only |
