---
name: code-review
description: Review a diff or PR against my conventions — Result not throw, vertical slices, AItError codes, node:test, Biome, entity normalisation, a11y. Findings are triaged by severity (correctness → conventions → polish), not piled in a flat list. Use when reviewing a diff, reviewing a PR before merge, self-reviewing before opening a PR, or when user says "review this", "review the diff", "code review", or invokes `/code-review`.
---

# Code review

> If it doesn't hold up in production, it doesn't make the cut.

Flat review piles — twelve nits next to one architectural break, all the same bullet weight — waste my time. Worse, agents review by aesthetics: rename suggestions, comment polish, "consider extracting" — while a `throw` in business logic or a cross-feature internal import sails through.

This skill is a review pass anchored on my other skills. It triages findings by severity, grounds them in `CONTEXT.md` and `docs/adr/`, and refuses to flag style when correctness is broken.

This is a review skill, not a teaching skill. It assumes you've read the rest of my engineering skills; it tells you when to invoke which.

## When this skill is active

You are about to:

- Review an open PR (mine or someone else's)
- Self-review a diff before opening a PR
- Audit a recent change (`git diff <base>..HEAD`, `gh pr diff`, staged changes)
- Respond to "review this", "review the diff", "what do you think of this change?"

This is **not** the skill for whole-repo architectural review — that's [`improve-codebase-arch`](../improve-codebase-arch/SKILL.md). This is for a bounded set of changes.

## Phase 1 — Ground yourself

Don't review the diff in isolation. Spend two minutes on context first.

- [ ] Read `CONTEXT.md` if you don't already know the domain vocabulary.
- [ ] Skim `docs/adr/` for ADRs in the touched area. A change that contradicts an ADR is a finding, not a nit.
- [ ] Scan the diff once end-to-end before commenting on any line. You're looking for the shape, not the typos.
- [ ] If a PR description exists, read it. A finding that the PR description already addresses is not a finding.

## Phase 2 — Triage by severity

Findings land in one of three buckets. Report them in this order, never flat.

### 1. Correctness (must-fix)

The change is wrong, will break, or will silently corrupt state.

- [ ] Logic bug — off-by-one, wrong branch, swapped args.
- [ ] Race condition, missing `await`, unhandled promise rejection.
- [ ] Type lies — `as any`, `!` non-null on a `Result`, `as unknown as T` smuggling.
- [ ] Boundary leak — secrets in logs, PII in URLs, user input flowing into a query without escaping.
- [ ] Missing test for a non-trivial code path. Bugs hide where tests don't reach — see [`tdd`](../tdd/SKILL.md).
- [ ] Migration that isn't reversible / isn't safe under concurrent writes.

### 2. Convention drift (should-fix, anchored on my skills)

The change works but breaks a house rule. Each finding cites the skill it violates.

- [ ] **Throws in business logic.** Service/domain code must return `Result<T, E>`. See [`result-not-throw`](../result-not-throw/SKILL.md).
- [ ] **New `AItError` code invented when the catalogue covers it.** Reuse existing codes (`USER_NOT_FOUND`, `DB_ERROR`, `RATE_LIMIT`, …) before adding.
- [ ] **Cross-feature import that bypasses the package's public API.** Boundary is fake. See [`vertical-slices`](../vertical-slices/SKILL.md).
- [ ] **New file dumped in `shared/` or `utils/` with one caller.** Inline it. Wait for the third caller.
- [ ] **Vendor payload going straight to the DB or downstream code.** Normalise at the boundary. See [`entity-normalization`](../entity-normalization/SKILL.md).
- [ ] **`jest`, `vitest`, `eslint`, `prettier`, `ts-jest` added to `package.json`.** Use the runtime + Biome. See [`node-native-tests`](../node-native-tests/SKILL.md) and [`single-tool-per-job`](../single-tool-per-job/SKILL.md).
- [ ] **Fastify plugin without `fp()` wrapper / idempotency guard / decorator.** See [`fastify-plugin-shape`](../fastify-plugin-shape/SKILL.md).
- [ ] **Boundary code missing error telemetry / request context / queue visibility.** See [`production-observability`](../../misc/production-observability/SKILL.md).
- [ ] **Domain IDs typed as bare `string`.** Use nominal typing where mix-ups would compile. See [`types-first-guards`](../../misc/types-first-guards/SKILL.md).
- [ ] **UI change with no a11y consideration.** Run [`a11y-default-review`](../../misc/a11y-default-review/SKILL.md) over the touched components.
- [ ] **Commit subject without scope (`feat: …` not `feat(spotify): …`).** See [`conventional-commits-scoped`](../../productivity/conventional-commits-scoped/SKILL.md).
- [ ] **Decision big enough to be re-litigated in three months, no ADR.** Write it before the code lands.

### 3. Polish (nits, optional)

Style, naming, redundant comments, dead code, doc gaps. Group them under a single "nits" heading. Never let polish drown out the first two buckets.

If the change is correct and convention-clean, polish is the whole review — and a short one. If correctness or conventions are broken, polish waits for the follow-up.

## Phase 3 — Report

Output shape:

```markdown
## Review

**Verdict:** approve / request changes / blocked on decision

### Correctness
- [file:line] One sentence on what's wrong and why it matters.

### Convention drift
- [file:line] What rule, which skill. `result-not-throw`: business logic must return `Result<T, E>`.

### Nits
- [file:line] One-liner. Group them tight.

### Questions
- Anything you couldn't answer from the diff alone. One question per ambiguity.
```

Rules:

- **Cite line numbers** so I can navigate. `file_path:line_number`.
- **Cite the skill** for every convention finding. Don't restate the rule — link it.
- **No essays.** One sentence per finding. If a finding needs a paragraph, it's an ADR, not a review comment.
- **Verdict goes first.** I want the headline before the body.

## Anti-patterns

- **Flat bullet list with no severity.** Twelve nits next to one architectural break, all weighted equally. Triage or don't bother.
- **Reviewing by aesthetics.** "Consider renaming," "this could be more idiomatic," "maybe extract a helper." If there's no failure mode, it's not a finding.
- **Restating what the code does.** I can read the diff. Tell me what's wrong, not what's there.
- **Flagging style when correctness is broken.** Lead with the throw in the service layer, not the import order.
- **Inventing house rules.** Every convention finding cites an existing skill or ADR. If you can't cite, it's a personal preference and belongs in nits — or nowhere.
- **Reviewing the diff without reading the PR description.** Re-asking what the description answered is noise.
- **Auto-suggesting a fix for a judgment call.** Surface the tradeoff, let me pick. Auto-fix the deterministic stuff (typos, missing `await`).
- **Bundling unrelated fixes into the review.** A11y debt found during a backend review goes on the follow-up list, not into the PR.

## When you find a structural problem mid-review

Stop the review. Surface it as **"blocked on decision"** with a verdict at the top, and call out which skill or ADR it conflicts with. Don't keep listing nits underneath — the design decision swallows them. If it warrants a new ADR, say so.

## Cross-references

- Severity-1 conventions: [`result-not-throw`](../result-not-throw/SKILL.md), [`vertical-slices`](../vertical-slices/SKILL.md), [`entity-normalization`](../entity-normalization/SKILL.md)
- Tooling conventions: [`node-native-tests`](../node-native-tests/SKILL.md), [`single-tool-per-job`](../single-tool-per-job/SKILL.md)
- Surface-specific: [`fastify-plugin-shape`](../fastify-plugin-shape/SKILL.md), [`a11y-default-review`](../../misc/a11y-default-review/SKILL.md), [`production-observability`](../../misc/production-observability/SKILL.md), [`types-first-guards`](../../misc/types-first-guards/SKILL.md)
- Pre-code grilling: [`grill-me-mateo`](../../productivity/grill-me-mateo/SKILL.md)
- Domain glossary: [`CONTEXT.md`](../../../CONTEXT.md)
