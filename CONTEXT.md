# Context

Domain language for this skills repo. The skills below assume these terms; agents reading them inherit the vocabulary.

## Language

**Skill**:
A single `SKILL.md` (with optional bundled files) that addresses a named failure mode in agent collaboration. Lives under one of the bucket folders.
_Avoid_: "command", "prompt", "rule" — those are different primitives.

**Bucket**:
The folder a skill lives in (`engineering/`, `productivity/`, `misc/`, `personal/`, `in-progress/`, `deprecated/`). Determines whether the skill is promoted (top README + `plugin.json`) or kept private. Governance is in [`CLAUDE.md`](./CLAUDE.md).

**Public skill**:
A skill in `engineering/`, `productivity/`, or `misc/`. Listed in the top-level `README.md` and `.claude-plugin/plugin.json`.

**Personal skill**:
A skill in `personal/`. Tied to my own projects (`mateonunez.co`, `ait`) or my dev environment. Linked locally by `link-skills.sh` but not promoted.

**Trigger phrase**:
The "Use when…" clause in a skill's `description` frontmatter. Tells the agent when to surface the skill. A skill without a trigger phrase will not auto-invoke.

**Boundary code**:
HTTP handlers, CLI entry points, framework adapters, top-level `main()`, tests. Code that has no caller in my own modules. The opposite of business logic. Throws are allowed at boundaries — see the `result-not-throw` skill.

**Business logic**:
Service-layer methods, domain functions, pure utilities that can fail meaningfully. Returns `Result<T, E>`, never throws.

**`Result<T, E>`**:
Discriminated union for representing success or typed failure: `{ ok: true, value: T } | { ok: false, error: E }` where `E extends Error`. Constructed with `ok(value)` / `err(error)`. Errors are real `Error` subclasses (e.g. `AItError`) carrying a `code` string discriminant — not plain objects, not literal-tagged unions. Defined in the `result-not-throw` skill; canonical implementation in [`personal/ait/references/core-result-type.md`](./skills/personal/ait/references/core-result-type.md).

**`AItError`**:
The `Error` subclass used in `ait`. Carries `code: string`, optional `meta: Record<string, unknown>`, and optional `cause`. The `code` is the discriminant the boundary code switches on (`USER_NOT_FOUND`, `DB_ERROR`, `RATE_LIMIT`, etc.). Other repos can ship their own subclass — the shape is what matters.

**Vertical slice**:
A feature owns its handlers, services, types, tests, and migrations in one workspace package. Opposite of layered organisation (`controllers/`, `services/`, `repositories/` as siblings). See the `vertical-slices` skill.

**Workspace package**:
A package inside a pnpm monorepo, scoped (`@scope/feature-name`), depending on internal packages via `workspace:*`. The unit of vertical-slice ownership.

**Scope** (commit):
The parenthesised area in a Conventional Commit subject — `feat(seo): …`, `fix(spotify): …`. Drawn from the repo's existing scope catalogue, not invented per commit. See the `conventional-commits-scoped` skill.

**Colemak nav cluster**:
On my keyboard, navigation keys are `h n e i` (left/down/up/right), not QWERTY `h j k l`. Applies to vim/Neovim, tmux, and anywhere a tool exposes layout-sensitive chords. See the `colemak-pair-programming` skill.

## Relationships

- A **skill** lives in one **bucket**.
- A **public skill** appears in the top README and `plugin.json`; a **personal skill** does not.
- **Boundary code** may throw; **business logic** returns `Result<T, E>`.
- A **vertical slice** is enforced by a **workspace package** boundary.

## Flagged ambiguities

- "**reference**" was previously used for both (a) the `references/` folder inside a skill and (b) the README's link list. Resolved: `references/` is a folder containing supporting `.md` files for a single skill; the top README's list is called the **Reference section**.
- "**setup**" overloaded — could mean dev-environment setup (dotfiles) or per-repo conventions setup (the skill). Resolved: `setup-mateonunez-skills` is the per-repo conventions skill; `colemak-pair-programming` covers dev-environment specifics on my machine.
