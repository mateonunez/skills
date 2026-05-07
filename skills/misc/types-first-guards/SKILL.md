---
name: types-first-guards
description: Use strict TypeScript patterns — discriminated unions for domain concepts, exhaustive checks, nominal typing where needed. Use when writing domain logic that deals with user IDs, order IDs, or other concepts that should not be interchangeable even if their runtime type is the same.
---

# Types First Guards

> "If the types don't catch the error, the types are lying."

## Philosophy

I use TypeScript as a guardrail against the entire class of "oops, I passed the wrong ID" bugs. The type system should make certain mistakes impossible at compile time, not catch them at runtime.

## The Pattern

**Nominal domain types** for anything that should never be confused at the type level, even if runtime representation is identical:

```typescript
type UserId = string & { readonly __brand: 'UserId' };
const userId = (id: string): UserId => id as UserId;

type OrgId = string & { readonly __brand: 'OrgId' };
const orgId = (id: string): OrgId => id as OrgId;

// Now this type-checks:
const user = await fetchUser(userId('42'));
const org = await fetchOrg(orgId('42'));

// But this does NOT:
const badUser = await fetchUser(orgId('42')); // ✗ Type error
```

No reflexive runtime checks. The type system prevents the mistake in the first place.

## Discriminated Unions for Multi-State Data

For domain concepts that have distinct states or variants, use `__type` discriminator unions:

```typescript
type Order =
  | { __type: 'pending'; id: OrderId; items: OrderItem[] }
  | { __type: 'confirmed'; id: OrderId; items: OrderItem[]; confirmedAt: Date }
  | { __type: 'shipped'; id: OrderId; items: OrderItem[]; trackingNumber: string }
  | { __type: 'cancelled'; id: OrderId; reason: string };

function handleOrder(order: Order) {
  switch (order.__type) {
    case 'pending': return processPayment(order);
    case 'confirmed': return scheduleShipment(order);
    case 'shipped': return notifyCustomer(order);
    case 'cancelled': return refund(order);
  }
  // ✓ TypeScript enforces exhaustiveness
}
```

The compiler forces you to handle every case. Refactoring adds a state? The compiler catches you.

## When Nominal Types Help Most

- **IDs that should never be mixed**: UserId, OrgId, ProjectId, OrderId. Use this pattern aggressively.
- **Concepts from your domain glossary** (in CONTEXT.md) that have different meanings even if they're structurally the same string/number.
- **Auth boundaries**: SessionToken vs RefreshToken vs ApiKey — different tokens, different lifespans, different threat models.

Do NOT do this for every string. Use it for semantic differences, not syntactic ones.

## Anti-Patterns

- **`unknown` in business logic.** Unknown is "I don't know the type." If you don't know, you're missing domain understanding. Dig until you do.
- **`as any` to make TypeScript shut up.** This is a sign the types don't reflect reality. Fix the types, not the code.
- **Discriminated unions without exhaustiveness checking.** If you write a switch on `__type` without handling all cases, the type system should reject it. Ensure you're using `never` in unreachable branches to force exhaustiveness.

```typescript
function handleOrder(order: Order) {
  switch (order.__type) {
    case 'pending': return processPayment(order);
    case 'confirmed': return scheduleShipment(order);
    // ✗ Missing 'shipped' and 'cancelled' cases
    default: return never; // Type error: can't assign Order to never
  }
}
```

- **Mixing domain and primitive types.** Never do `const userId: string` when you have a UserId type. Always use the nominal type.
- **Type assertions on untrusted data at boundaries.** `JSON.parse(userInput) as Order` is a lie. Validate first, then type-assert.

## Phases

1. **Identify domain concepts** — what are the distinct semantic types in your domain? (from CONTEXT.md if it exists)
2. **Create nominal types or discriminated unions** for each
3. **Enforce at boundaries** — HTTP handlers, DB queries, external API calls. Validate untrusted data, then assert types.
4. **Use in business logic** — pass these types through your service layer so mistakes are caught early
5. **Verify exhaustiveness** — switch statements on discriminated unions should have type-checker enforcement via `never` in unreachable code
