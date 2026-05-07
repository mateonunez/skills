---
name: a11y-default-review
description: Quick accessibility pass after UI changes — keyboard nav, focus visibility, semantic HTML, aria-live for async, reduced motion. The bar is WCAG 2.1 AA, the same bar I hold mateonunez.co to. Use when reviewing UI changes, when adding interactive components, or when user mentions "accessibility", "a11y", "WCAG", "screen reader", or "keyboard".
---

# A11y default review

> The site works for everyone or it doesn't work.

Accessibility regressions ship by default unless someone is looking. After a UI change, run this checklist before declaring it done. The bar is WCAG 2.1 AA — the same bar [`mateonunez.co`](https://mateonunez.co) is built to.

This is a review skill, not a teaching skill. It assumes you know what `aria-live` does; it tells you when to look for it.

## When this skill is active

You just edited:

- A React/Vue/Svelte component that renders interactive elements
- A page route or layout
- Anything with `onClick`, `onKeyDown`, or focus management
- A form, modal, drawer, menu, tooltip, or toast
- Any element using `tabindex` or `aria-*`

## The checklist

### Keyboard

- [ ] Every interactive element is reachable by `Tab` in source order.
- [ ] `Enter` and `Space` activate buttons; `Enter` follows links.
- [ ] `Escape` closes modals, drawers, menus, popovers.
- [ ] Arrow keys work where expected (menu, listbox, tablist, slider).
- [ ] No keyboard trap — `Tab` can always escape.

### Focus visibility

- [ ] `:focus-visible` outline is visible against the background. No `outline: none` without a replacement.
- [ ] Focus moves into a modal when it opens; returns to the trigger when it closes.
- [ ] Skip-nav link exists on pages with substantial top-of-page chrome.

### Semantics

- [ ] Buttons are `<button>`, not `<div onClick>`. Links are `<a href>`, not `<div onClick>`.
- [ ] One `<h1>` per page. Heading levels don't skip (h2 → h4 is wrong).
- [ ] Form fields have associated labels (`<label for>` or wrapping `<label>`).
- [ ] Images have `alt` (empty `alt=""` for decorative; descriptive for content).
- [ ] Lists use `<ul>`/`<ol>`/`<li>`, not `<div>` siblings.

### ARIA (only if semantics aren't enough)

- [ ] No `aria-label` on a button that already has visible text — duplicates the announcement.
- [ ] `aria-live="polite"` on async status regions (search results count, save indicators).
- [ ] `aria-expanded`, `aria-controls` on disclosure widgets.
- [ ] `role="dialog"` + `aria-modal="true"` + `aria-labelledby` on modals.
- [ ] No `role` that contradicts the element (e.g. `role="button"` on an `<a href>`).

### Motion + colour

- [ ] Animations respect `prefers-reduced-motion`. Critical motion is gated.
- [ ] Colour is not the only signal (e.g. error state has an icon or text, not just red).
- [ ] Text contrast ≥ 4.5:1 (3:1 for large text). Check against the actual background.

### Async + dynamic

- [ ] Loading states announce ("Loading…" via `aria-live` or `role="status"`).
- [ ] Errors are announced, not just rendered silently.
- [ ] Toasts/alerts are reachable or auto-dismiss with enough time (≥ 5s default).

## Anti-patterns

- **`<div onClick>`** — not focusable, not keyboard-activatable, not announced as a button. Use `<button>`.
- **`<a>` with `href="#"` for buttons** — use `<button>`. Reserve `<a>` for navigation.
- **`tabindex` > 0** — breaks source-order focus. Almost always wrong.
- **`aria-hidden="true"` on a focusable element** — invisible to AT but reachable by keyboard. Use `inert` instead, or remove from tab order.
- **Auto-playing video/audio with sound** — WCAG 1.4.2 violation.
- **Placeholder-as-label.** Placeholders disappear on focus and have low contrast. Use a real `<label>`.
- **`alt="image of a cat"`** — screen readers already announce "image". Just `alt="a cat sleeping"`.

## When you find issues

Don't bundle the fixes into an unrelated PR. Note them, prioritise (keyboard > semantics > ARIA polish), and either fix in a separate commit or surface to me as a follow-up. A11y debt is real debt — track it.

If it doesn't hold up for a keyboard-only or screen-reader user, it doesn't make the cut.
