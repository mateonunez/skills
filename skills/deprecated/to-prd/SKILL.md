---
name: to-prd
description: Turn the current conversation context into a PRD and publish it to the issue tracker. Use when user wants to create a PRD from the current context.
---

# To PRD

Synthesize the current conversation and codebase understanding into a PRD. I do NOT interview the user — just synthesize what I already know.

Assumes your repo has a `CONTEXT.md` (domain glossary) and `docs/adr/` (decisions recorded). If not, run `/setup-mateonunez-skills` first. The issue tracker and triage label vocabulary come from setup.

## Process

### 1. Explore

Understand the current state of the codebase if not already familiar. Use domain glossary vocabulary throughout the PRD and respect ADRs in the touched area.

### 2. Sketch modules

Identify the major modules you'll need to build or modify. Look for opportunities to extract deep modules (high functionality behind simple, testable interfaces, rarely changing).

Check with the user:
- Do these modules match your expectations?
- Which modules should have tests written for them?

### 3. Write the PRD

Use the template below, then publish to the issue tracker. Apply the `ready-for-agent` triage label — no additional triage needed.

**PRD template:**

```
## Problem Statement

The problem the user faces, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories in the format:

As an <actor>, I want a <feature>, so that <benefit>

Example:
As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending

Cover all aspects of the feature exhaustively.

## Implementation Decisions

A list of implementation decisions made, including:

- Modules that will be built/modified
- Interfaces that will change
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets — they go stale quickly.

Exception: if a prototype produced a snippet encoding a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly it came from a prototype. Trim to decision-rich parts only.

## Testing Decisions

A list of testing decisions made, including:

- What makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (similar types of tests in the codebase)

## Out of Scope

Description of things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.
```
