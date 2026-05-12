# mateonunez-skills

[![skills.sh](https://skills.sh/b/mateonunez/skills)](https://skills.sh/mateonunez/skills)

> Shipping AIt. Music on; nonsense off.

My agent skills — small, composable, behaviour-focused. Each one addresses a real failure mode I've watched coding agents hit, and steers the agent away from it before the failure happens. Organised the way [Matt Pocock](https://github.com/mattpocock/skills) organises his.

These are not tool docs. They're behaviour interventions in my voice, encoding the way I work — `Result<T, E>` over throws, vertical slices over layers, Biome over the ESLint+Prettier stack, `node:test` over Jest. Forged on real projects: [`ait`](https://github.com/mateonunez/ait) (a personal AI platform), [`mateonunez.co`](https://mateonunez.co) (Next.js 16 + WCAG 2.1 AA), and a fistful of [Fastify plugins](https://github.com/mateonunez/fastify-orama).

If it doesn't hold up in production, it doesn't make the cut.

## Quick start

```bash
npx skills add mateonunez/skills
```

> or

```bash
git clone https://github.com/mateonunez/skills.git
cd agentfiles
./scripts/link-skills.sh
```

The script symlinks every `SKILL.md` under `skills/` (excluding `deprecated/`) into `~/.claude/skills/`, where Claude Code picks them up.

## Why these skills exist

I built these for the failure modes I see most often when collaborating with coding agents.

### #1 — The agent throws everywhere

> "Errors are values."  
> — Rob Pike

**The problem**: agents reflexively `throw new Error()` in service-layer code, then bury `try/catch` three layers up at the call site. Control flow becomes invisible. The type system can't help me — every function lies about what it can fail with.

**The fix**: [`/result-not-throw`](./skills/engineering/result-not-throw/SKILL.md). Business logic returns `Result<T, E>` with discriminated `__type` errors. Throws are reserved for boundaries (HTTP handlers, CLI entry, framework adapters). The compiler enforces exhaustive error handling.

### #2 — The agent reaches for Jest

> "The standard library is the first thing you should reach for."  
> — common sense, often ignored

**The problem**: every greenfield package gets `jest`, `@types/jest`, `ts-jest`, `babel-jest` by default. Half a megabyte of dependencies for what `node:test` ships built into the runtime. Same story with ESLint + Prettier when Biome covers both.

**The fix**: [`/node-native-tests`](./skills/engineering/node-native-tests/SKILL.md) and [`/single-tool-per-job`](./skills/engineering/single-tool-per-job/SKILL.md). Use the runtime. Use the one tool that does the job. New dev dependencies have to clear a real bar.

### #3 — The agent organises by layer

> "The best modules are deep. They allow a lot of functionality to be accessed through a simple interface."  
> — John Ousterhout, [A Philosophy of Software Design](https://www.amazon.com/Philosophy-Software-Design-2nd/dp/173210221X)

**The problem**: `controllers/` here, `services/` there, `repositories/` over there. Every feature change touches five folders. The horizontal cuts ripple across the codebase on every PR.

**The fix**: [`/vertical-slices`](./skills/engineering/vertical-slices/SKILL.md). Package by feature. The seam between features is a workspace package boundary, not a layer convention. Workspace protocol (`workspace:*`) and scoped packages (`@scope/feature`) make the boundary visible at every import site.

### #4 — The agent normalises nothing

> "The vendor's wire format is not my domain model."  
> — every ETL pipeline that ever survived a vendor breaking change

**The problem**: `fetch('https://api.spotify.com/...').then(r => r.json())` and the response goes straight to the database. Three vendors later, every consumer special-cases every shape, and a Spotify API change cascades through six files.

**The fix**: [`/entity-normalization`](./skills/engineering/entity-normalization/SKILL.md). At the boundary, normalise to a typed `NormalizedEntity` with a `__type` discriminator. Vendor noise lives in `metadata`. Downstream code is vendor-agnostic by construction.

### #5 — The agent ships UI without a11y

> "Accessibility is a baseline, not a feature."  
> — most of the web, getting it wrong

**The problem**: `<div onClick>` in place of `<button>`. Missing `alt`. `outline: none` with no replacement. Modals that don't trap focus. The agent ships UI that works for sighted, mouse-using users — and silently breaks for everyone else.

**The fix**: [`/a11y-default-review`](./skills/misc/a11y-default-review/SKILL.md). A short checklist run after every UI change. Keyboard, focus, semantics, ARIA polish. The bar is WCAG 2.1 AA — the same bar I hold [mateonunez.co](https://mateonunez.co) to.

## Reference

### Engineering

Skills I use daily for code work.

- **[setup-mateonunez-skills](./skills/engineering/setup-mateonunez-skills/SKILL.md)** — Scaffold the per-repo conventions my other engineering skills assume — pnpm + corepack, Biome (1.9 legacy or 2.x new), node:test posture, CONTEXT.md, docs/adr/. Run once per repo.
- **[result-not-throw](./skills/engineering/result-not-throw/SKILL.md)** — I return Result<T, E extends Error> from business logic — never throw. Errors are typed Error subclasses with a code field (AItError pattern).
- **[entity-normalization](./skills/engineering/entity-normalization/SKILL.md)** — When data crosses a system boundary into my code, I normalise it into a typed entity with a __type discriminator and a fixed common shape. The vendor's wire format is not my domain model.
- **[vertical-slices](./skills/engineering/vertical-slices/SKILL.md)** — I organise code by feature, not by layer. Every feature is a workspace package; new files live with the feature they belong to.
- **[node-native-tests](./skills/engineering/node-native-tests/SKILL.md)** — I use node:test + borp + c8, not Jest or Vitest. The runtime ships a test runner — I use it.
- **[single-tool-per-job](./skills/engineering/single-tool-per-job/SKILL.md)** — Biome is enough. I don't run ESLint or Prettier. For every other job, one tool per job.
- **[fastify-plugin-shape](./skills/engineering/fastify-plugin-shape/SKILL.md)** — How I write Fastify plugins — fastify-plugin wrapper, idempotency guard, decorator pattern, withX() helper for TS narrowing, module augmentation.
- **[improve-codebase-arch](./skills/engineering/improve-codebase-arch/SKILL.md)** — Surface architectural friction and propose deepening opportunities — refactors that turn shallow modules into deep ones. Aim: testability and AI-navigability.
- **[tdd](./skills/engineering/tdd/SKILL.md)** — Test-driven development with red-green-refactor loop. Vertical slices: one test, one implementation, repeat. Never write all tests first.
- **[prototyping](./skills/engineering/prototyping/SKILL.md)** — Build throwaway prototypes to flush out design before committing. Routes between state/logic questions (terminal app) and UI questions (multiple variations on one route).
- **[zoom-out](./skills/engineering/zoom-out/SKILL.md)** — Get a map of relevant modules and callers using the project's domain glossary vocabulary.
- **[code-review](./skills/engineering/code-review/SKILL.md)** — Review a diff or PR against my conventions. Findings are triaged by severity (correctness → conventions → polish), each convention finding cites the skill it violates.

### Productivity

General workflow tools, not code-specific.

- **[caveman](./skills/productivity/caveman/SKILL.md)** — Ultra-compressed communication mode. Cuts token usage ~75% by dropping filler, articles, pleasantries while keeping technical accuracy.
- **[conventional-commits-scoped](./skills/productivity/conventional-commits-scoped/SKILL.md)** — I write Conventional Commits with scopes. Scope comes from the repo's existing catalogue, never invented.
- **[grill-me-mateo](./skills/productivity/grill-me-mateo/SKILL.md)** — Grill me on a plan or change before I write code, with my canonical four questions baked in: package boundary, error code, vertical slice, ADR.
- **[write-a-skill](./skills/productivity/write-a-skill/SKILL.md)** — Create new agent skills with proper structure, progressive disclosure, and bundled resources.
- **[to-issues](./skills/productivity/to-issues/SKILL.md)** — Break a plan, spec, or PRD into independently-grabbable issues using vertical-slice tracer bullets.
- **[to-prd](./skills/productivity/to-prd/SKILL.md)** — Turn the current conversation context into a PRD and publish it to the issue tracker.
- **[triage](./skills/productivity/triage/SKILL.md)** — Triage issues through a state machine driven by triage roles — category (bug/enhancement) and state (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix).

### Misc

Tools I keep around but rarely use.

- **[a11y-default-review](./skills/misc/a11y-default-review/SKILL.md)** — Quick accessibility pass after UI changes — keyboard nav, focus visibility, semantic HTML, aria-live, reduced motion. WCAG 2.1 AA bar.
- **[types-first-guards](./skills/misc/types-first-guards/SKILL.md)** — Use strict TypeScript patterns — discriminated unions for domain concepts, exhaustive checks, nominal typing where needed to prevent ID mix-ups at compile time.
- **[production-observability](./skills/misc/production-observability/SKILL.md)** — Include error telemetry, request context, and queue visibility in production code. Structured logging, tracing, metrics for external IO failures.

## Personal

Skills tied to my own projects ([mateonunez.co](https://mateonunez.co), [ait](https://github.com/mateonunez)) and my dev environment (Colemak + Neovim + Tmux). Linked locally for me but not promoted publicly. See [`skills/personal/README.md`](./skills/personal/README.md).

## Structure

```
agentfiles/
├── CLAUDE.md                  # bucket governance
├── CONTEXT.md                 # domain glossary
├── .claude-plugin/
│   └── plugin.json            # public skills only
├── skills/
│   ├── engineering/           # daily code discipline
│   ├── productivity/          # daily non-code workflow
│   ├── misc/                  # rarely used
│   ├── personal/              # tied to my projects, not promoted
│   ├── in-progress/           # drafts
│   └── deprecated/            # excluded from symlinks
├── scripts/
│   ├── link-skills.sh         # symlinks SKILL.md → ~/.claude/skills/
│   └── list-skills.sh         # inventory
└── docs/
    └── adr/                   # repo-level architecture decisions
```

## License

[MIT](LICENSE) — Mateo Nunez · [mateonunez.co](https://mateonunez.co) · [@mateonunez](https://github.com/mateonunez)

> I create MIT bugs.
