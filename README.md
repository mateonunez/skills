# agentfiles

Personal AI knowledge base — structured skill packs, agent definitions, and operational docs for Claude Code and compatible AI tools.

Follows the [Agent Skills](https://agentskills.io/specification) open standard (`SKILL.md` + `references/`).

## Quick Start

```bash
# Clone
git clone https://github.com/mateonunez/agentfiles.git

# Sync to Claude Code
./scripts/sync-skills.sh
```

## Skills

### Generic (cross-project)

| Skill | Description |
|-------|-------------|
| [biome](skills/biome/SKILL.md) | Biome formatter/linter conventions for TypeScript projects |
| [pnpm-monorepo](skills/pnpm-monorepo/SKILL.md) | pnpm workspace patterns for monorepo management |
| [dotfiles](skills/dotfiles/SKILL.md) | Dev environment — Colemak layout, Neovim, Tmux, Zsh |

### Project-specific

| Skill | Description | Source |
|-------|-------------|--------|
| [website](skills/website/SKILL.md) | Next.js 16 personal site — MDX, Spotify/GitHub integrations, SEO | [mateonunez.co](https://mateonunez.co) |
| [ait](skills/ait/SKILL.md) | AI platform — monorepo, RAG pipeline, OAuth connectors | private |
| [fastify-orama](skills/fastify-orama/SKILL.md) | Fastify + Orama full-text search plugin | [GitHub](https://github.com/mateonunez/fastify-orama) |

## Agents

| Agent | Focus |
|-------|-------|
| [fullstack-developer](agents/fullstack-developer.md) | Frontend + backend web development |
| [ui-ux-designer](agents/ui-ux-designer.md) | UI components, accessibility, responsive design |
| [test-engineer](agents/test-engineer.md) | Testing, API validation, performance profiling |
| [devops-engineer](agents/devops-engineer.md) | Docker, CI/CD, Vercel, infrastructure |
| [rapid-prototyper](agents/rapid-prototyper.md) | Fast feature scaffolding, MVPs |
| [code-reviewer](agents/code-reviewer.md) | Code quality, security, maintainability reviews |

## Docs

| Doc | Purpose |
|-----|---------|
| [dev-setup](docs/dev-setup.md) | Development environment setup |
| [git-conventions](docs/git-conventions.md) | Commit conventions, branch naming |
| [deployment](docs/deployment.md) | Vercel + Docker deployment patterns |
| [colemak-reference](docs/colemak-reference.md) | Colemak navigation across all tools |

## Adding Skills

### From agentskill.sh

[skills.sh](https://skills.sh) is a public directory of 40,000+ agent skills.

```bash
# Install /learn command (Claude Code)
/plugin marketplace add https://agentskill.sh/marketplace.json
/plugin install learn@agentskill-sh

# Search and install skills
/learn fastify
/learn @vercel-labs/vercel-react-best-practices
```

### Manually

1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. Add reference docs in `skills/<name>/references/`
3. Run `./scripts/sync-skills.sh` to deploy

## Structure

```
agentfiles/
├── skills/          # Knowledge packs (SKILL.md + references/)
├── agents/          # Agent definitions (flat structure)
├── docs/            # Operational documentation
└── scripts/         # Helper scripts
```

## License

[MIT](LICENSE) — Mateo Nunez
