---
name: setup-mateonunez-skills
description: Scaffold the per-repo conventions my other engineering skills assume — pnpm + corepack, Biome (1.9 legacy or 2.x new), node:test posture, CONTEXT.md, docs/adr/. Run once per repo before using result-not-throw, vertical-slices, node-native-tests, or single-tool-per-job. Use when user says "setup mateonunez skills", "scaffold conventions", "wire up my skills", or invokes /setup-mateonunez-skills.
---

# setup-mateonunez-skills

> Music on; nonsense off.

My other skills ([`result-not-throw`](../result-not-throw/SKILL.md), [`vertical-slices`](../vertical-slices/SKILL.md), [`node-native-tests`](../node-native-tests/SKILL.md), [`single-tool-per-job`](../single-tool-per-job/SKILL.md)) assume the repo has a few things wired up: pnpm via corepack, a Biome config, a posture on the test runner, a `CONTEXT.md` glossary, and a `docs/adr/` directory. This skill scaffolds those once.

Run me before the others. After I'm done, the other skills have something to point at.

## Phase 1 — Detect

Read the repo first. Don't assume.

- [ ] `package.json` exists? Check `packageManager` field.
- [ ] Is there an existing `pnpm-workspace.yaml`, `pnpm-lock.yaml`, or `lerna.json`?
- [ ] Is there an existing `biome.json` or `biome.jsonc`? Capture its `$schema` version (1.9.x = legacy, 2.x = new).
- [ ] Is there an existing test setup? Look for `jest.config.*`, `vitest.config.*`, `node:test` imports, `borp` in dependencies.
- [ ] Does `CONTEXT.md` exist at the root? Does `docs/adr/` exist?
- [ ] What package manager is in the lockfile (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`)?

Show me what you found before changing anything. If the repo already has a conflicting setup (e.g. yarn lockfile, Vitest config), surface it and ask before overwriting.

## Phase 2 — Decide

Based on what you found, decide and confirm with me:

- **Package manager** — pnpm via corepack. If a `package-lock.json` or `yarn.lock` exists, **stop and ask** before deleting it.
- **Biome version** — default to 2.x for greenfield. If existing `biome.json` is 1.9.x, keep it (`ait` is on 1.9; don't migrate unprompted).
- **Test runner** — `node:test` + `borp` + `c8`. If Jest/Vitest is already in place with substantial test files, **stop and ask** before migrating.
- **Workspace shape** — if it's a monorepo, write `pnpm-workspace.yaml` with `packages/*` and `apps/*`. If single-package, skip.

## Phase 3 — Scaffold

Only after I confirm. Use the bundled seed templates:

- `seeds/seed-context.md` → `CONTEXT.md`
- `seeds/seed-adr-0001-conventions.md` → `docs/adr/0001-conventions.md`
- `seeds/seed-biome-2x.json` → `biome.json` (only if no Biome config exists)
- `seeds/seed-pnpm-workspace.yaml` → `pnpm-workspace.yaml` (only for monorepos)

Then patch `package.json`:

- Set `packageManager` to the current pnpm version (run `corepack prepare pnpm@latest --activate` first if missing).
- Add scripts if missing: `"check": "biome check"`, `"check:fix": "biome check --write"`, `"test": "borp"`.

Append a `## Mateo skills` block to `CLAUDE.md` (or `AGENTS.md` if that's what the repo uses) noting which skills are now available and pointing at `CONTEXT.md`.

## Phase 4 — Verify

- [ ] `pnpm install` runs cleanly.
- [ ] `pnpm check` (or `pnpm exec biome check`) runs and reports — even if there are existing issues, it must execute.
- [ ] `CONTEXT.md` and `docs/adr/0001-conventions.md` exist and are non-empty.
- [ ] `git status` shows the scaffolded files as the only changes.

## Anti-patterns

- **Migrating Jest/Vitest unprompted.** Existing tests are work product. Propose migration in a separate PR; don't bundle it here.
- **Overwriting a custom `biome.json`.** If one exists, leave it. Mention preferences (single quotes, 2-space, line width 120) and let me decide.
- **Adding ESLint or Prettier.** That's a `single-tool-per-job` violation. Biome is the answer.
- **Filling `CONTEXT.md` with a generic glossary.** It's empty for a reason — I fill it with this repo's domain terms during real work, not from a template. The seed should be a skeleton with section headers, not boilerplate definitions.
- **Writing the ADR with conclusions I haven't reached.** ADR 0001 records *that* I've adopted these conventions, not *why* every choice is correct. Keep it factual.

## When the repo already has these conventions

Don't re-scaffold. Confirm what's present, fill any gaps (e.g. add `docs/adr/` if missing but Biome is configured), and move on. The skill is idempotent.
