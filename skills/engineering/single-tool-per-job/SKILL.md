---
name: single-tool-per-job
description: Biome is enough. I don't run ESLint or Prettier — never alongside Biome, never instead of it. For every other job (types, tests, packages, build, scripts), one tool. Use when adding lint/format/build/test tooling, when proposing dev dependencies, or when user mentions "Biome", "ESLint", "Prettier", "consolidate tools", or asks "should I add X".
---

# Single tool per job

> Music on; nonsense off.

Tooling sprawl is debt. ESLint + Prettier + import-sort plugin + sort-keys plugin is four tools doing what Biome does in one — four config files, four peer-dependency trees, four editor extensions, four CI steps, four ways to break.

I don't pay that tax. Biome is enough.

## When this skill is active

You are about to:

- Add a dev dependency for linting, formatting, testing, building, or workspace management
- Configure a new tool's config file
- Add a CI step that wraps a tool
- Recommend a tool to me without checking what's already in `package.json`

## The Biome rule (non-negotiable)

In my repos, **Biome is the linter and the formatter**. Both jobs. Together. There is no "Biome alongside ESLint", no "Biome but Prettier for Markdown". If `eslint`, `prettier`, `eslint-*`, or `prettier-*` shows up in a `pnpm add` you're proposing, the answer is no.

If a repo I'm in already has ESLint or Prettier (legacy work, third-party fork), the migration is its own task — surface it, propose it, but don't run two linters at once "for safety". Two linters at once is the worst of both worlds: contradictory autofixes and double the CI time.

This is the one place in `single-tool-per-job` where the rule isn't "prefer the existing tool" — it's "Biome wins".

## The defaults table (everywhere else)

| Job | My tool | Don't add |
|---|---|---|
| Lint + format + import sort | **Biome** | ESLint, Prettier, `eslint-*`, `prettier-*`, `simple-import-sort` |
| Types | **tsc** | Babel for type-stripping, Flow |
| Tests | **node:test + borp + c8** | Jest, Vitest, Mocha, Chai, Sinon, `@types/jest`, `nyc` |
| Packages + workspaces | **pnpm** (via corepack) | npm, yarn, lerna, nx for workspace orchestration alone |
| Pre-commit | **`biome check --staged`** | husky + lint-staged + prettier + eslint chain |
| Build (TS lib) | **tsdown** or **tsc --build** | rollup + plugins + tsup + babel |
| Run TS scripts | **node --experimental-strip-types** (22.6+) or **tsx** | ts-node + @types/node + esbuild-register |

For tools other than ESLint/Prettier, the principle is "don't migrate unprompted" — see [`result-not-throw`](../result-not-throw/SKILL.md). New additions to the repo follow this table; existing Jest/Mocha setups don't get rewritten as a side effect.

## Biome quick reference

```bash
biome lint .                  # lint only
biome format .                # format only
biome check .                 # lint + format + organize imports
biome check --write .         # auto-fix safe transforms
biome check --write --unsafe  # auto-fix including unsafe
biome ci .                    # CI-optimised output
biome check --staged          # pre-commit
```

```jsonc
// package.json
{
  "scripts": {
    "lint": "biome check .",
    "lint:fix": "biome check --write ."
  }
}
```

For the full `biome.json` template, see [`setup-mateonunez-skills/seeds/seed-biome-2x.json`](../setup-mateonunez-skills/seeds/seed-biome-2x.json).

## The check before adding anything

Before `pnpm add -D <thing>`:

1. **What job does this tool do?** Name it in one phrase.
2. **Is a tool in the current `package.json` already responsible for that job?** If yes, replacement only — not addition.
3. **Is the runtime / language standard library responsible for it?** If yes (`node:test`, `node:assert`, `Intl`), the new tool needs to justify why the standard isn't enough.
4. **Can you write a one-paragraph rationale for the tool's config?** If not, you don't need the tool.

If it doesn't hold up against those four, it doesn't make the cut.

## Anti-patterns

- **ESLint *and* Biome.** No. Biome is enough.
- **Prettier *and* Biome.** No. Biome formats.
- **"Just for `.md` files we'll keep Prettier"** / **"Just for the legacy package we'll keep ESLint"**. Carve-outs become permanent. Pick one, retire the other.
- **husky + lint-staged when `biome check --staged` works.** Two tools to do what one does.
- **Adding `nx` to a small monorepo for caching.** pnpm + `--filter` covers it. Reach for nx/turbo only when build times actually hurt.
- **Replacing a working tool because it trended.** "I saw it on Twitter" is not a justification.
- **Adding a CLI for something a one-line script handles.** If `find . -name '*.ts' | xargs ...` works, no tool needed.

## When two tools are genuinely complementary

Some pairings are fine because the jobs are different: Biome (lint/format) + tsc (types) + node:test (tests). The rule isn't "one tool total" — it's "one tool per job". Type-checking is not formatting; testing is not linting.
