---
name: improve-codebase-arch
description: Find deepening opportunities in a codebase, informed by domain language in CONTEXT.md and decisions in docs/adr/. Use when you want to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable.
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. Goal: testability and AI-navigability.

## Glossary

Use these terms exactly. Consistent language matters — don't drift into "component," "service," "API," or "boundary." Full definitions in CONTEXT.md.

- **Module** — anything with an interface and implementation (function, class, package, slice)
- **Interface** — everything a caller must know: types, invariants, error modes, ordering, config
- **Implementation** — the code inside
- **Depth** — leverage at the interface: a lot of behaviour behind a small interface
- **Shallow** — interface nearly as complex as the implementation
- **Seam** — where an interface lives; a place behavior can be altered without editing in place
- **Adapter** — a concrete thing satisfying an interface at a seam
- **Deep module** — high functionality, simple interface, rarely changing. Wins: locality + leverage for callers

Key principle: **Deletion test**. Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep.

## Process

### 1. Explore

Read CONTEXT.md (domain glossary) and ADRs in the touched area first. Then explore the codebase organically. Note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules shallow — interface nearly as complex as implementation?
- Where have pure functions been extracted just for testability, but real bugs hide in how they're called (no locality)?
- Where do tightly-coupled modules leak across seams?
- Which parts are untested or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? "Yes, concentrates" is the signal you want.

### 2. Present candidates

Present a numbered list of deepening opportunities. For each candidate:

- **Files** — which files/modules are involved
- **Problem** — why current architecture causes friction
- **Solution** — plain English description of what would change
- **Benefits** — in terms of locality and leverage, and how tests would improve

**Use CONTEXT.md vocabulary for the domain.** If CONTEXT.md defines "Order," talk about "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant reopening the ADR. Mark it clearly (e.g. _"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. Ask: "Which of these would you like to explore?"

### 3. Grilling loop

Once user picks a candidate, drop into grilling conversation. Walk the design tree — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize:

- **Naming a deepened module after a concept not in `CONTEXT.md`?** Add the term to `CONTEXT.md` — same discipline as creating a new glossary entry. Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term during conversation?** Update `CONTEXT.md` right there.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR, framed as: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Only offer when the reason would actually prevent future re-suggestion — skip ephemeral reasons ("not worth it right now") and self-evident ones.
- **Want to explore alternative interfaces?** Dive into design iterations, surface tradeoffs.

## Anti-patterns

- **Don't refactor without understanding the failure mode first.** I've watched agents refactor by aesthetic rules, then discover the friction was elsewhere.
- **Don't propose microservices to solve a monolith problem.** The issue is usually interface design or locality, not physical separation. Separation without a seam just spreads the mess.
- **Don't rename things and call it refactoring.** Renaming is hygiene, not architecture. Real refactors change how code is organized, tested, or reasoned about.
