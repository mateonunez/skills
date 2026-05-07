---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable issues using vertical-slice tracer bullets. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
---

# To Issues

Break a plan into independently-grabbable issues using vertical slices (tracer bullets).

Assumes your repo has a `CONTEXT.md` (domain glossary) and `docs/adr/` (decisions recorded). If not, run `/setup-mateonunez-skills` first. The issue tracker and triage label vocabulary come from setup.

## Process

### 1. Gather context

Work from whatever is in conversation. If user passes an issue reference (number, URL, or path), fetch it and read the full body + comments.

### 2. Explore the codebase (optional)

If not already familiar, explore to understand current state. Issue titles should use domain glossary vocabulary and respect ADRs in the touched area.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues — each is a thin vertical slice cutting through ALL layers end-to-end, not one horizontal layer.

Slices may be 'HITL' (human-in-the-loop, needs architectural decision or design review) or 'AFK' (can be merged without human interaction). Prefer AFK over HITL.

**Vertical-slice rules:**
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- Completed slice is demoable or verifiable on its own
- Many thin slices > few thick ones

### 4. Quiz the user

Present the breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices must complete first
- **User stories covered**: which stories this addresses (if source material has them)

Ask:
- Does granularity feel right? (too coarse / too fine)
- Are dependency relationships correct?
- Should any slices merge or split further?
- Are the correct slices marked HITL vs AFK?

Iterate until user approves.

### 5. Publish to issue tracker

For each approved slice, publish a new issue using the template below. These are considered ready for AFK agents, so apply the correct triage label unless told otherwise.

Publish in dependency order (blockers first) so you can reference real issue identifiers in "Blocked by" field.

**Issue template:**

```
## Parent

A reference to the parent issue (if source was an existing issue, otherwise omit).

## What to build

Concise description of this vertical slice. Describe end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale. Exception: if a prototype produced a snippet encoding a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly it came from a prototype. Trim to decision-rich parts only.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- A reference to the blocking ticket (if any)

Or "None - can start immediately" if no blockers.
```

Do NOT close or modify any parent issue.
