---
name: write-a-skill
description: Create new agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, or build a new skill.
---

# Writing Skills

I write skills as behavior interventions — each one solves one named failure mode. Skills are organized into buckets (engineering/productivity/misc/personal), public skills indexed in `plugin.json` and README, personal skills kept local.

## Process

1. **Gather requirements** — ask about:
   - What failure mode does this skill prevent?
   - What specific use cases should it fire on?
   - Does it need executable scripts or just instructions?
   - Any reference materials or real examples to include?

2. **Draft the skill** — create:
   - SKILL.md with terse instructions (target: <150 lines for most skills)
   - Trigger phrase in the YAML `description` ("Use when…")
   - One explicit anti-patterns section (failures I've seen)
   - Additional reference files only if SKILL.md would exceed 100 lines

3. **Review with user** — present draft and ask:
   - Does this capture the failure mode?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Skill Structure

```
skill-name/
├── SKILL.md              # Main instructions (required)
├── REFERENCE.md          # Detailed docs (if needed)
└── scripts/              # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template

```markdown
---
name: skill-name
description: One-sentence failure mode. Use when [specific triggers].
---

# Skill Name

[Opening: what this skill prevents, in first-person voice]

## When this skill is active

[Describe the contexts where this fires]

## Phases / Checklist

[ ] Phase 1
[ ] Phase 2

## Anti-patterns

- **Bad pattern X** — why it fails
- **Bad pattern Y** — consequences
```

## Key Guidelines

- **Voice**: first-person for public skills ("I do X", "in my code"), pragmatic tone
- **Description**: max 1024 chars, concrete triggers ("Use when user says 'foo'")
- **Length**: aim for <150 lines — if longer, split into REFERENCE.md
- **Anti-patterns**: ≥3 explicit callouts of what agents do wrong
- **Examples**: 1-2 concrete code snippets or scenarios
- **Structure**: for complex skills, use phases or checklists with explicit breakpoints

## When to Add Scripts

Add utility scripts when:
- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

## When to Split Files

Split into separate files when:
- SKILL.md exceeds 100 lines
- Content has distinct domains (separate testing strategies)
- Advanced features are rarely needed

## Bucket Assignment

- `engineering/` — solves daily code work failures
- `productivity/` — solves workflow/meta failures
- `misc/` — kept around, rarely used
- `personal/` — tied to your projects, not promoted
- `in-progress/` — drafts, not ready
- `deprecated/` — no longer used

Public skills (engineering/productivity/misc) must appear in:
- Top-level README.md Reference section
- `.claude-plugin/plugin.json`
- Corresponding bucket README.md

## Review Checklist

- [ ] One clear failure mode named in opening
- [ ] Trigger phrase in description ("Use when...")
- [ ] SKILL.md under 150 lines (split if needed)
- [ ] ≥3 anti-patterns explicit
- [ ] ≥1 concrete example
- [ ] No time-sensitive info
- [ ] First-person voice for public skills
- [ ] Bucket assignment correct (public ⟹ plugin.json+README)
