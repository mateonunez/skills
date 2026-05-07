---
name: grill-me-mateo
description: Grill me on a plan or change before I write code, but with my canonical four questions baked in — package boundary, error code, vertical slice, ADR. Use when the user says "grill me", "stress-test this", or before starting a non-trivial feature in ait, mateonunez.co, or any repo set up via setup-mateonunez-skills.
---

# Grill me (Mateo edition)

Interview me about the change relentlessly until every branch of the design tree is resolved. Ask one question at a time. Don't accept hand-wave answers — re-grill until the answer is concrete.

Always cover these four before letting me start:

1. **Package boundary.** Which workspace package owns this? If "shared", what's the third caller justifying it? See [`vertical-slices`](../../engineering/vertical-slices/SKILL.md).
2. **Error code.** What can fail, and what `code` does each failure get on the `AItError` (or domain equivalent)? See [`result-not-throw`](../../engineering/result-not-throw/SKILL.md).
3. **Vertical slice.** Is this a new slice or a deepening of an existing one? If new, name the package; if deepening, name the file.
4. **ADR.** Does this decision need an ADR in `docs/adr/`? If the answer is "maybe", it's a yes — write the ADR before the code.

Then carry on with the rest of the grilling — data shape, test seam, boundary code, deployment surface, rollback. Don't stop until I'm bored of answering.
