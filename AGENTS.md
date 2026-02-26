# AGENTS.md — Central Guardrails

Conventions and guardrails for AI agents working in this repository.

## Repository Purpose

Personal AI knowledge base. Structured skill packs, agent definitions, and operational docs extracted from real projects. Content is reference material, not executable code.

## File Conventions

### Skills (`skills/`)

- Entry point: `SKILL.md` (uppercase)
- YAML frontmatter: `name`, `description` (required for discoverability)
- References in `references/` subdirectory
- Reference filenames: `{category}-{topic}.md` (e.g., `core-architecture.md`, `features-spotify.md`)
- Categories: `core`, `features`, `best-practices`
- Keep `SKILL.md` as an index under 500 lines — detailed content belongs in `references/`
- Write descriptions in third person for consistent system prompt injection

### Agents (`agents/`)

- Flat directory structure (no subdirectories)
- YAML frontmatter: `name`, `description`, `tools`, `model`
- Description: third person, explains what the agent does and when to use it
- Content: concise system prompt with responsibilities and conventions
- Keep agents generic and project-agnostic — they should work across any codebase

### Docs (`docs/`)

- YAML frontmatter: `summary`, `read_when`
- Content is actionable and concise

## Writing Guidelines

- Use kebab-case for file and directory names (except `SKILL.md`, `AGENTS.md`, `README.md`)
- Keep reference files focused on one topic
- Include concrete code examples, not abstract descriptions
- Prefer specific versions and actual config values over vague guidance
- Generic skills (biome, pnpm-monorepo) must not reference specific projects
- Project-specific skills (website, ait) document particular codebases

## Editing Rules

- Do not remove YAML frontmatter from any file
- Do not merge separate reference files into a single file
- When updating a skill, also update the reference table in `SKILL.md`

## Code Style (for examples in docs)

- TypeScript/JavaScript: 2-space indent, single quotes, semicolons
- Shell: bash, `set -euo pipefail`
- Markdown: 120-char line width where practical
