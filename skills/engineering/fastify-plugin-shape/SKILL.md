---
name: fastify-plugin-shape
description: How I write Fastify plugins — fastify-plugin wrapper, idempotency guard, decorator pattern, withX() helper for TS narrowing, module augmentation. The shape I use for fastify-orama, fastify-at-mysql, lyra-impact. Use when writing or reviewing a Fastify plugin, when proposing a new decorator, when configuring `fp()`, or when user mentions "Fastify plugin", "decorate", or "fastify-plugin".
---

# Fastify plugin shape

> If it doesn't hold up in production, it doesn't make the cut.

I publish Fastify plugins ([fastify-orama](https://github.com/mateonunez/fastify-orama), [fastify-at-mysql](https://github.com/mateonunez/fastify-at-mysql), [lyra-impact](https://github.com/mateonunez/lyra-impact)). The shape below is what every one of mine looks like. It's small, it's deliberate, and it doesn't drift between repos.

## When this skill is active

You are about to:

- Write a new Fastify plugin (in-repo or standalone package)
- Add a `fastify.decorate(...)` call
- Configure or modify a `fastify-plugin` (`fp`) wrapper
- Add a TypeScript module augmentation (`declare module 'fastify' {}`)
- Validate plugin options or decide what to expose

## The shape

```javascript
'use strict'

const fp = require('fastify-plugin')

async function fastifyMyPlugin (fastify, options) {
  if (fastify.myPlugin) {
    throw new Error('fastify-my-plugin is already registered')
  }

  const { /* my-plugin options */ ...rest } = options

  // ... build api, open connections, restore state ...

  function withMyPlugin () {
    return this
  }

  fastify.decorate('myPlugin', api)
  fastify.decorate('withMyPlugin', withMyPlugin)
}

module.exports = fp(fastifyMyPlugin, {
  fastify: '5.x',
  name: 'fastify-my-plugin'
})

// Re-export raw function + helpers as named exports
module.exports.fastifyMyPlugin = fastifyMyPlugin
```

That's the spine. Eight non-negotiables:

1. **`'use strict'`** at the top, CommonJS, JS source — TS lives in `index.d.ts`.
2. **`fastify-plugin` wrapper.** Without it, decorators are encapsulated and your plugin "doesn't work" outside its register scope. `fp` is the de-encapsulation primitive.
3. **`async (fastify, options)` signature.** Even if you don't await — keep it async for symmetry.
4. **Idempotency guard.** First line of the body checks `if (fastify.myPlugin) throw`. Stops the foot-gun where two registers silently clobber each other.
5. **Destructure plugin-only options before forwarding.** Your plugin's options are not the underlying library's options — separate them at the boundary, don't leak them.
6. **`withMyPlugin()` helper that returns `this`.** No-op at runtime; pure TypeScript narrowing tool. Lets users write `fastify.withMyPlugin().myPlugin.foo()` in handlers where the decorator's type isn't yet visible.
7. **`module.exports = fp(plugin, { fastify, name })`** — pin the Fastify major (`'5.x'`) and the plugin name. The name is what shows up in `fp` warnings.
8. **Re-export named.** Default-export the wrapped plugin, named-export the raw async function and any side classes (persistence adapters, helpers). Lets consumers compose.

## TypeScript module augmentation

Ship types in `index.d.ts`. Augment Fastify, don't subclass it:

```typescript
import 'fastify'

declare module 'fastify' {
  interface FastifyInstance {
    myPlugin: MyPluginApi
    withMyPlugin: () => FastifyInstance & { myPlugin: MyPluginApi }
  }
}

export interface MyPluginOptions { /* ... */ }
export interface MyPluginApi { /* ... */ }

declare const fastifyMyPlugin: FastifyPluginAsync<MyPluginOptions>
export default fastifyMyPlugin
```

Module augmentation is the only correct way — it composes with other plugins, it's discoverable, it works with Fastify's type inference.

## Options validation

Validate at the entry point, fail fast:

```javascript
if (!options.schema && !options.persistence) {
  throw new Error('You must provide a schema or a persistence adapter')
}
```

Don't reach for `ajv` for plugin options — overkill. Plain checks at the top of the function are enough; the schema for **request/response** is what `ajv` is for.

## Decorator naming

- **Singular noun for the resource**: `fastify.orama`, `fastify.mysql`, `fastify.redis`. Not `fastify.oramaClient`, not `fastify.dbConnection`.
- **`with<Name>()` helper** for the type-narrowing trick. Always returns `this`.
- **No verbs as decorator names.** `fastify.search()` is wrong — that lives on the API object: `fastify.orama.search()`.

## Anti-patterns

- **Plugin without `fastify-plugin`.** Decorators get encapsulated and disappear in handlers. The bug is silent and infuriating to debug.
- **`fastify.decorate('orama', () => api)`** — passing a function instead of the value. Now every callsite invokes it (`fastify.orama().search`). Pass the API object directly.
- **Leaking the underlying library's instance** instead of an API surface. Don't `fastify.decorate('orama', oramaDb)` and let consumers call `Orama.search(fastify.orama, …)`. Wrap the methods so the db instance is implicit: `fastify.orama.search(...)`.
- **No idempotency guard.** Two `register` calls silently overwrite the decorator and you spend an afternoon hunting it down.
- **Pinning Fastify with `^5.0.0`** instead of `'5.x'`. The `fp` peer constraint is a major-version range, not a npm range.
- **TS via subclassing or extension** instead of module augmentation. Won't compose with other plugins.
- **No `withX()` helper.** Users have to cast `fastify as FastifyInstance & { myPlugin: ... }` everywhere. Annoying. The helper costs three lines.

## When the plugin needs cleanup

Use `fastify.addHook('onClose', async () => { /* close db, drain queue, persist state */ })`. Don't expose a manual `close()` decorator — the framework already has the lifecycle hook.

## Cross-references

- Real example: [`deprecated/fastify-orama/references/core-plugin-api.md`](../../deprecated/fastify-orama/references/core-plugin-api.md)
- Source: [github.com/mateonunez/fastify-orama](https://github.com/mateonunez/fastify-orama)
