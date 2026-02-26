---
summary: Git conventions for commits, branches, and pull requests.
read_when: Making commits, creating branches, or reviewing PRs.
---

# Git Conventions

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Types

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no feature/fix) |
| `style` | Formatting, linting (no logic change) |
| `docs` | Documentation only |
| `test` | Adding/updating tests |
| `chore` | Maintenance, dependencies, config |
| `perf` | Performance improvement |
| `ci` | CI/CD changes |

### Scopes

Use scopes that match your project's domain areas. Examples:

- Frontend: `ui`, `a11y`, `seo`, `blog`, `auth`
- Backend: `api`, `db`, `auth`, `connectors`, `cache`
- Infrastructure: `docker`, `ci`, `deps`

### Examples

```
feat(ui): add playlist grid with SWR polling
fix(a11y): add aria-live to now-playing widget
refactor(api): extract common OAuth refresh logic
chore(deps): update next to 16.1.6
test(db): add migration edge case coverage
```

## Branch Naming

```
<type>/<short-description>

# Examples
feat/spotify-playlists
fix/oauth-token-refresh
refactor/connector-factory
chore/update-dependencies
```

## Atomic Commits

- Each commit should be a single logical change
- The codebase should build and pass lint after every commit
- Don't mix feature work with formatting/refactoring in the same commit

## Co-Authorship

When AI assists with code, include the co-author footer:

```
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Pre-commit Hooks

Use Husky (or similar) for pre-commit validation:

```bash
# .husky/pre-commit
biome check --staged
```

Checks only staged files, keeping commits fast.

## Pull Request Guidelines

- Keep PRs focused on a single feature or fix
- Include a clear description of what changed and why
- Reference related issues
- Ensure CI passes before requesting review
