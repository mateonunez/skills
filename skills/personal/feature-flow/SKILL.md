---
name: feature-flow
description: My default workflow for non-trivial features at work — understand read-only → plan mode + grill me on six fork categories → implement per approved plan → verify honestly. Use when starting any feature or non-trivial change in one of my work repos, when a prompt contains a GOAL/START FROM/FORKS block, or when I invoke /feature-flow.
---

# Feature flow

> Understand first. Grill me second. Code third. Verify honestly.

Agents given a feature request tend to sprint: they skim two files, pick the first plausible architecture, and start writing. On my work repos that fails predictably — the pipeline has infra I didn't mention, the decision they guessed was mine to make (cost, prod behavior), and the "obvious" pattern contradicts the peer repo we mirror. This skill is the antidote: a fixed four-phase order where coding is phase three, not phase one.

## Input contract

I invoke this with up to three blocks. Only GOAL is required:

- **GOAL** — what to add/change, current vs. desired behavior, who wants it. May include a role hint ("for the console work, act as a Senior UI Engineer").
- **START FROM** — anchors: `file.ts:line` pointers, entrypoints, the pattern to mirror, memory names to recall.
- **FORKS** — decisions where I already have a lean, stated inline ("I lean detail-only, YAGNI").

If START FROM is missing, do NOT free-explore: derive candidate anchors from the repo (entrypoints, routes, the closest existing feature) and confirm them with me before deep exploration. "Don't assume" applies to anchors too.

## Phase 1 — Understand (read-only)

Read every repo and infra surface the feature touches before proposing anything. No writes, no scaffolding, no "while I'm here" edits.

- Start from the anchors. Follow them outward: entrypoints → libs → schemas → auth → audit.
- Identify **the pattern to mirror** — the peer repo or existing feature that already does the closest thing (e.g. a sibling API's route/job shapes, an existing flow in the same domain). This single anchor outweighs any convention list.
- Recall memories matching the repos touched — both the ones I named and any others whose names match the repo/domain. Verify a memory's claims against the current code before relying on it.
- Note what you could NOT verify (env/creds visible only in cluster pods, manifests you can't read). These become questions, not assumptions.

## Phase 2 — Plan mode + grill

Enter plan mode. Before writing any plan, walk this fork checklist and resolve every applicable fork WITH me — including forks I didn't list but the checklist surfaces:

1. **Placement / sync-vs-async** — where does the work run? Enumerate 2–3 real options (in-process job, trigger existing infra, bounded inline).
2. **Trigger surface & feedback** — endpoint only? UI affordance? What does the operator actually see (toast, status panel, auto-refresh)?
3. **Scope** — exactly which slice of the pipeline/data is in; name what is explicitly OUT.
4. **Concurrency / consistency** — overlap with cron jobs, double-clicks, locking, idempotency.
5. **Cost & safety** — DRY_RUN / since-date knobs, LLM token spend, and explicit confirmation of prod behavior. Never assume spending money in prod is fine.
6. **Auth scope + audit + persistence** — reuse an existing scope or override (a semantic read behind a POST may deserve Read); is an audit event signal or noise; persist a run record or fire-and-forget.

Rules of the grill:

- Ask via AskUserQuestion when the tool is available; otherwise ask the same questions as plain numbered options in chat. The checklist is the essential part, not the tool.
- Every fork gets **a recommended option with a one-line why**. I veto cheaply; I don't want an open-ended survey.
- Respect my stated leans from the FORKS block — challenge them only with evidence from phase 1.
- Cost, prod behavior, and infra shape are genuinely MINE. Ask, don't assume — even if the answer seems obvious.
- Then present a short plan (not an essay) mapping each fork to its resolution, and get explicit approval before any code.

## Phase 3 — Implement

Per the approved plan, following repo conventions:

- Keep it simple and elegant. YAGNI: no speculative guards or validation a caller already enforces; no "future-proofing".
- Fixed business rules are constants, not new env knobs.
- LLM is Anthropic-only. Mirror the named pattern exactly — route shape, schema style, error consts, audit events.
- Rationale goes in memory / CONTEXT / ADR, never inline "why" comments.
- Tests: every test name starts with "should". Backend: vitest + testcontainers. Frontend: vitest + @testing-library/react.
- Frontend work is Senior-UI-Engineer grade: honest loading/disabled/error states (sonner for failures), abort in-flight requests on unmount/context-switch, keyboard + a11y on new affordances, no double-fire on re-render (hasRequested ref pattern).
- SQL changes → regenerate pgtyped against a throwaway Postgres on **:5433** (k9s shadows :5432 — see the pgtyped-regen memory), never the cluster DB. Migrations via node-pg-migrate.

## Phase 4 — Verify

- Backend: vitest full suite + tsc + eslint + prettier.
- Frontend (if touched): vitest + tsc + eslint.
- Report results honestly: failures with their output, skipped checks named as skipped. No "should pass".

## Hard constraints (all phases)

- Do NOT commit or push unless I explicitly approve. I usually commit myself.
- Do NOT kubectl / port-forward on your own initiative — ask me to open a tunnel or paste manifests/output.
- If a decision is genuinely mine — cost, prod behavior, infra shape — ask. A wrong guess in prod costs more than a question.
