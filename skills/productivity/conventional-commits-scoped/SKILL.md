---
name: conventional-commits-scoped
description: I write Conventional Commits with scopes (feat(seo): …, fix(spotify): …). Scope comes from the repo's existing scope catalogue, never invented. Use when staging or proposing commits, when user says "commit", "commit message", or invokes /commit.
---

# Conventional commits, scoped

> `chore: stuff` is not a commit message.

A commit should answer "what changed, in what area, why" at a glance. The scope tells me the area; the type tells me the kind of change; the subject tells me what I'll see in the diff. Without a scope, I'm reading every commit subject in the dark.

Format:

```
<type>(<scope>): <imperative subject>

<optional body explaining why, not what>
```

## When this skill is active

You are about to:

- Stage and commit changes
- Propose a commit message
- Write a PR title (same rules)

## Detect the scope catalogue first

Before writing the message, read the most recent ~30 commits to see which scopes the repo actually uses:

```bash
git log -30 --pretty=format:'%s' | grep -oE '^[a-z]+\([a-z0-9-]+\):' | sort -u
```

Use one of those. If the change doesn't fit any existing scope, tell me — I'd rather expand the catalogue deliberately than have you guess.

If a `commitlint.config.{js,cjs,ts}` exists, read its `scope-enum` for the canonical list.

## Types

`feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `build`, `ci`, `style`, `revert`. Lowercase. Imperative.

## Subject

- Imperative mood: `add`, not `adding` or `adds`.
- Lowercase first letter.
- No trailing period.
- Under ~70 characters.

## Anti-patterns

- **Scopeless commits** in a repo that uses scopes. `chore: bump deps` → `chore(deps): bump zod to 3.23`.
- **Capitalised subjects.** `feat(api): Add endpoint` → `feat(api): add endpoint`.
- **Gerunds.** `feat(auth): adding refresh token` → `feat(auth): add refresh token`.
- **Inventing scopes.** `feat(stuff)` is worse than no scope. If nothing fits, ask.
- **Multi-purpose commits dressed as single ones.** If the diff is a feat + a refactor + a fix, it's three commits, not one.
- **`feat: WIP`**, **`chore: misc`**, **`fix: bug`** — non-messages. Reject.
- **Past tense.** `fix(auth): fixed token expiry` → `fix(auth): fix token expiry`.

## When the repo doesn't use Conventional Commits

Don't introduce them silently. Match the existing style. If I want to switch the repo to Conventional Commits, that's a separate conversation (and likely an ADR).

The exception: my own repos (`agentfiles`, `mateonunez.co`, `ait`, my Fastify plugins) all use Conventional Commits with scopes. If you're in one of mine, this skill is non-optional.
