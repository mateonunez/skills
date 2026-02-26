---
summary: Development environment setup guide.
read_when: Setting up a new machine, onboarding, or troubleshooting environment issues.
---

# Development Setup

## Prerequisites

| Tool | Version | Installation |
|------|---------|-------------|
| Node.js | 22+ | `brew install node` or nvm |
| pnpm | 10.x | `corepack enable && corepack prepare pnpm@latest --activate` |
| Docker | Latest | Docker Desktop |
| Git | Latest | `brew install git` |

## Global Setup

```bash
# Enable corepack for pnpm management
corepack enable
corepack prepare pnpm@latest --activate

# Verify
node -v    # v22.x+
pnpm -v    # 10.x
docker -v  # Docker version 2x+
```

## Project Setup Pattern

```bash
cd ~/source/project
pnpm install

# Create local env from example
cp .env.example .env.local
# Fill in required values

# Start infrastructure (if applicable)
pnpm start:services

# Run migrations (if applicable)
pnpm migrate

# Start dev server
pnpm dev
```

## Editor Setup

### VS Code

```json
{
  "editor.defaultFormatter": "biomejs.biome",
  "editor.formatOnSave": true,
  "[javascript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescript]": { "editor.defaultFormatter": "biomejs.biome" },
  "[typescriptreact]": { "editor.defaultFormatter": "biomejs.biome" }
}
```

### Neovim

See [dotfiles skill](../skills/dotfiles/SKILL.md) for full Neovim + Colemak setup.

## Troubleshooting

### Port already in use

```bash
# Check what's using a port
lsof -i :3000

# Kill process on port
kill -9 $(lsof -t -i :3000)
```

### pnpm install fails

```bash
# Clear pnpm store
pnpm store prune

# Remove node_modules and reinstall
rm -rf node_modules
pnpm install
```

### Docker services won't start

```bash
# Check Docker is running
docker info

# Reset Docker compose state
docker compose down -v
docker compose up -d
```
