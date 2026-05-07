# Engineering

Skills I use daily for code work.

- **[setup-mateonunez-skills](./setup-mateonunez-skills/SKILL.md)** — Scaffold the per-repo conventions my other engineering skills assume — pnpm + corepack, Biome (1.9 legacy or 2.x new), node:test posture, CONTEXT.md, docs/adr/. Run once per repo.
- **[result-not-throw](./result-not-throw/SKILL.md)** — I return Result<T, E extends Error> from business logic — never throw. Errors are typed Error subclasses with a code field (AItError pattern).
- **[entity-normalization](./entity-normalization/SKILL.md)** — When data crosses a system boundary into my code, I normalise it into a typed entity with a __type discriminator and a fixed common shape. The vendor's wire format is not my domain model.
- **[vertical-slices](./vertical-slices/SKILL.md)** — I organise code by feature, not by layer. Every feature is a workspace package; new files live with the feature they belong to.
- **[node-native-tests](./node-native-tests/SKILL.md)** — I use node:test + borp + c8, not Jest or Vitest. The runtime ships a test runner — I use it.
- **[single-tool-per-job](./single-tool-per-job/SKILL.md)** — Biome is enough. I don't run ESLint or Prettier. For every other job, one tool per job.
- **[fastify-plugin-shape](./fastify-plugin-shape/SKILL.md)** — How I write Fastify plugins — fastify-plugin wrapper, idempotency guard, decorator pattern, withX() helper for TS narrowing, module augmentation.
- **[improve-codebase-arch](./improve-codebase-arch/SKILL.md)** — Surface architectural friction and propose deepening opportunities — refactors that turn shallow modules into deep ones. Aim: testability and AI-navigability.
- **[tdd](./tdd/SKILL.md)** — Test-driven development with red-green-refactor loop. Vertical slices: one test, one implementation, repeat. Never write all tests first.
- **[prototyping](./prototyping/SKILL.md)** — Build throwaway prototypes to flush out design before committing. Routes between state/logic questions (terminal app) and UI questions (multiple variations on one route).
- **[zoom-out](./zoom-out/SKILL.md)** — Get a map of relevant modules and callers using the project's domain glossary vocabulary.
