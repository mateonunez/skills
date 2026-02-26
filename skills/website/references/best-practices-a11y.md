---
summary: Accessibility patterns — WCAG 2.1 AA compliance, skip navigation, aria-live regions, and reduced motion support.
read_when: Working on accessibility, keyboard navigation, screen reader support, or WCAG compliance.
---

# Accessibility Best Practices

## Standard: WCAG 2.1 AA

All components must meet WCAG 2.1 AA. The website follows these specific patterns:

## Skip Navigation

```tsx
// app/layout.tsx — first element in <body>
<a
  href="#main-content"
  className="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-amber-600 focus:text-white focus:rounded"
>
  Skip to main content
</a>

// Target element
<main id="main-content">...</main>
```

## Heading Hierarchy

Exactly one `<h1>` per page, enforced via the `asHeading` prop on `PageHeader`:

```tsx
<PageHeader asHeading="h1" title="Blog" description="..." />
// Other sections use h2, h3, etc.
```

## Focus Management

Use `focus-visible` (not `focus`) for keyboard outlines — prevents focus rings on mouse clicks:

```tsx
// Correct
className="focus-visible:ring-2 focus-visible:ring-amber-600 focus-visible:ring-offset-2"

// Wrong — shows ring on mouse click too
className="focus:ring-2 focus:ring-amber-600"
```

## Reduced Motion

Framer Motion respects `prefers-reduced-motion` via `MotionConfig`:

```tsx
// components/providers/motion-provider.tsx
import { MotionConfig } from 'framer-motion';

export function MotionProvider({ children }: { children: React.ReactNode }) {
  return (
    <MotionConfig reducedMotion="user">
      {children}
    </MotionConfig>
  );
}
```

For CSS animations, use the media query:

```css
@media (prefers-reduced-motion: reduce) {
  .animate-pulse { animation: none; }
}
```

## Live Regions

Dynamic content (Spotify now-playing, open-source activity) uses `aria-live="polite"`:

```tsx
<div aria-live="polite" aria-atomic="true">
  {nowPlaying ? (
    <p>Now playing: {nowPlaying.name} by {nowPlaying.artist}</p>
  ) : (
    <p>Not currently listening</p>
  )}
</div>
```

## Screen Reader Text

Use `sr-only` class for content that should be read but not displayed:

```tsx
<span className="sr-only">
  Now playing: {track.name} by {track.artist}
</span>
```

## Interactive Elements

- All interactive elements must be keyboard accessible
- Buttons use `<button>`, not `<div onClick>`
- Links use `<a>` or Next.js `<Link>`
- Custom controls include proper `role`, `aria-label`, and `tabIndex`

## Color Contrast

- Primary: amber-600 on white (light mode), amber-400 on dark backgrounds
- All text meets 4.5:1 contrast ratio minimum
- Interactive states maintain sufficient contrast

## Form Accessibility

- All inputs have associated `<label>` elements
- Error messages linked via `aria-describedby`
- Required fields indicated with `aria-required="true"`
- Form validation errors announced to screen readers

## Testing Checklist

- [ ] Tab through entire page — logical focus order
- [ ] Screen reader announces all interactive elements
- [ ] No content only accessible via mouse hover
- [ ] All images have meaningful `alt` text
- [ ] Color is not the sole indicator of meaning
- [ ] Page works at 200% zoom
