---
name: prototyping
description: Build a throwaway prototype to flush out a design before committing. Routes between two branches — a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route. Use when you want to prototype, sanity-check a data model or state machine, mock up a UI, explore design options, or says "prototype this", "let me play with it", "try a few designs".
---

# Prototyping

A prototype is **throwaway code that answers a question**. The question decides the shape.

> "Build to learn, not to ship."

## Pick a branch

Identify which question is being answered — from context, surrounding code, or by asking the user:

- **"Does this logic / state model feel right?"** → Build a tiny interactive terminal app that pushes the state machine through cases hard to reason about on paper. Surface the state after every action.
- **"What should this look like?"** → Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar. Surface state changes on every variant switch.

Getting this wrong wastes the whole prototype. If genuinely ambiguous and user isn't reachable, default to whichever branch better matches the surrounding code (backend module → logic; page/component → UI).

## Rules that apply to both

1. **Throwaway from day one, clearly marked as such.** Locate prototype code close to where it will actually be used (next to the module or page it's prototyping for) so context is obvious — but name it so any reader can see it's a prototype, not production. For UI routes, obey whatever routing convention the project already uses; don't invent new structure.

2. **One command to run.** Whatever the project supports — `pnpm <name>`, `node <path>`, `tsx <path>`, etc. User must start it without thinking.

3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or local file with a clear "PROTOTYPE — wipe me" name.

4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. Point is to learn something fast and then delete it.

5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.

6. **Delete or absorb when done.** When the prototype has answered its question, either delete it or fold the validated decision into real code — don't leave it rotting in the repo.

## When done

The _answer_ is the only thing worth keeping. Capture it somewhere durable (commit message, ADR, issue, or a `NOTES.md` next to the prototype) along with the question it was answering. If user is around, that capture is a quick conversation; if not, leave a placeholder so they (or you, on next pass) can fill in the verdict before deleting the prototype.

## Anti-patterns

- **Prototype that grows into production code.** I've watched prototypes escape the "delete me" mindset and become technical debt. If it's still around after 2 weeks, it's not a prototype anymore.
- **Answering the wrong question.** User asks "does this state machine work?" and I build a UI. Wrong branch. Clarify first.
- **Prototype with abstraction or error handling.** Defeats the point. Messy temporary code is fine. Polish it later if it survives.
