---
summary: OAuth implementation — encrypted credential storage, connector factory pattern, and token refresh flow.
read_when: Working on authentication, adding new OAuth providers, or debugging token refresh.
---

# OAuth & Credential Management

## Architecture

```
User → Gateway OAuth Route → Provider Authorization
  ↓
Callback → Exchange code for tokens → Encrypt → Store in PostgreSQL
  ↓
Later: Factory retrieves config → Decrypt → Use tokens → Auto-refresh if expired
```

## Encrypted Storage

Credentials are stored **encrypted in PostgreSQL**, not in env vars:

```typescript
// Encryption uses AES with AIT_ENCRYPTION_KEY env var
import { encrypt, decrypt } from '@ait/core/utils/encryption';

// Storing credentials
const encryptedTokens = encrypt(JSON.stringify({
  accessToken: tokens.access_token,
  refreshToken: tokens.refresh_token,
  expiresAt: Date.now() + tokens.expires_in * 1000,
}));

await db.connectorConfigs.insert({
  userId,
  vendor: 'spotify',
  credentials: encryptedTokens,
});
```

## Connector Factory Pattern

```typescript
// Get a configured service instance for a specific user's connector
const service = connectorServiceFactory.getServiceByConfig(configId, userId);

// The factory:
// 1. Loads the connector config from DB
// 2. Decrypts credentials
// 3. Checks token expiry, refreshes if needed
// 4. Returns a fully configured service instance
```

## Token Refresh Flow

```typescript
async function refreshTokens(config: ConnectorConfig): Promise<Result<Tokens>> {
  const credentials = decrypt(config.credentials);
  const parsed = JSON.parse(credentials);

  if (Date.now() < parsed.expiresAt - 60_000) {
    // Token still valid (with 1-minute buffer)
    return ok(parsed);
  }

  // Refresh the token
  const response = await fetch(config.tokenEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: parsed.refreshToken,
      client_id: config.clientId,
      client_secret: config.clientSecret,
    }),
  });

  if (!response.ok) {
    return err(new AItError('AUTH_ERROR', 'Token refresh failed'));
  }

  const newTokens = await response.json();

  // Re-encrypt and update in DB
  const encrypted = encrypt(JSON.stringify({
    accessToken: newTokens.access_token,
    refreshToken: newTokens.refresh_token ?? parsed.refreshToken,
    expiresAt: Date.now() + newTokens.expires_in * 1000,
  }));

  await db.connectorConfigs.update(config.id, { credentials: encrypted });
  return ok(newTokens);
}
```

## Gateway OAuth Routes

```
GET  /api/{vendor}/auth         → Redirect to provider's authorization URL
GET  /api/{vendor}/auth/callback → Exchange code, encrypt, store, redirect to UI
POST /api/{vendor}/auth/revoke   → Revoke tokens, delete config
```

## Supported Providers

| Provider | OAuth Type | Scopes |
|----------|-----------|--------|
| GitHub | OAuth 2.0 | `repo`, `read:user`, `read:org` |
| Spotify | OAuth 2.0 | `user-read-recently-played`, `user-top-read`, `user-library-read`, `playlist-read-private` |
| Linear | OAuth 2.0 | `read`, `issues:read` |
| Notion | OAuth 2.0 | `read_content` |
| Slack | OAuth 2.0 | `channels:history`, `channels:read`, `users:read` |
| Google | OAuth 2.0 | Varies by service (Calendar, YouTube, Contacts, Photos, Gmail) |

## Security Considerations

- `AIT_ENCRYPTION_KEY` must be set in environment (not committed)
- Tokens are never logged or returned in API responses
- Each user has isolated credentials (multi-tenant)
- Revocation deletes encrypted data from DB
