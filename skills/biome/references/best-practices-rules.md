---
summary: Biome rule management — common disabled rules, biome-ignore patterns, and per-directory overrides.
read_when: Encountering lint errors, deciding whether to disable a rule, or adding biome-ignore comments.
---

# Biome Rules Best Practices

## Default: Recommended Rules

Always start with `"recommended": true` which enables Biome's curated rule set.

## Common Disabled Rules

### `noExplicitAny`

Disable selectively when interfacing with external APIs that return truly unknown shapes:

```json
{
  "linter": {
    "rules": {
      "suspicious": {
        "noExplicitAny": "off"
      }
    }
  }
}
```

**Rationale**: External API responses can have deeply nested, partially-documented structures. Using `any` at the boundary and mapping to typed entities is the pragmatic approach.

### `noNonNullAssertion`

Disable for test files where values are known to exist:

```json
{
  "overrides": [
    {
      "include": ["**/*.spec.ts", "**/*.test.ts"],
      "linter": {
        "rules": {
          "style": {
            "noNonNullAssertion": "off"
          }
        }
      }
    }
  ]
}
```

**Rationale**: In tests, non-null assertions keep code concise when values are guaranteed by setup.

## biome-ignore Pattern

For one-off suppressions, use inline comments with a reason:

```typescript
// biome-ignore lint/suspicious/noExplicitAny: external API response type
function processVendorData(data: any): NormalizedEntity {
  // ...
}

// biome-ignore lint/style/noNonNullAssertion: guaranteed by test setup
const user = result.value!;
```

**Format**: `biome-ignore {rule}: {reason}`

Always include a reason. Naked `biome-ignore` comments are not acceptable.

## Rule Categories

| Category | Examples | Default Severity |
|----------|---------|-----------------|
| `correctness` | `noUnusedVariables`, `noUndeclaredVariables` | Error |
| `suspicious` | `noExplicitAny`, `noDoubleEquals` | Warning |
| `style` | `noNonNullAssertion`, `useConst` | Warning |
| `performance` | `noDelete`, `noAccumulatingSpread` | Warning |
| `a11y` | `useAltText`, `useButtonType` | Warning |
| `nursery` | Experimental rules (promoted each release) | Off by default |

## Per-Directory Overrides

Use `overrides` for directory-specific rules:

```json
{
  "overrides": [
    {
      "include": ["app/api/**", "src/routes/**"],
      "linter": {
        "rules": {
          "style": {
            "noParameterAssign": "off"
          }
        }
      }
    }
  ]
}
```

## Guidelines

1. **Start with recommended** — only disable rules with documented rationale
2. **Prefer inline suppression** over global disable — keeps the rule active elsewhere
3. **Always include a reason** in biome-ignore comments
4. **Review disabled rules periodically** — upstream fixes may make them viable again
5. **Use overrides for test files** — test code has different constraints than production code
