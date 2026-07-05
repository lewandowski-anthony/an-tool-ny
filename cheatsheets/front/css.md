# CSS Cheatsheet

> A practical CSS guide covering core concepts, Flexbox/Grid layout, common fixes, and modern patterns. For React or Angular specifics, see the sibling cheatsheets.

---

## The Box Model

Every element is a box: `content → padding → border → margin`.

```css
* { box-sizing: border-box; }   /* width now INCLUDES padding + border */
```

> **Tip:** **Set `box-sizing: border-box` globally.** It's the single most important sanity fix — `width: 100%` then behaves intuitively instead of overflowing when you add padding.

---

## Selectors & Specificity

```css
#id          /* specificity 1-0-0  (highest, avoid overusing) */
.class       /* specificity 0-1-0 */
div          /* specificity 0-0-1  (lowest) */
.a.b         /* combine: 0-2-0 */
```

* Specificity wins over source order. When two rules tie, **the later one wins**.
* `!important` overrides everything — a code smell; use it only as a last resort.
* Keep specificity **low and flat** (prefer classes) so styles stay easy to override.

Useful combinators & pseudo:
```css
.parent > .child      /* direct child */
.a + .b               /* immediately after */
.a ~ .b               /* any sibling after */
li:nth-child(2n)      /* even items */
a:hover, :focus-visible
input:not([disabled])
:is(h1, h2, h3)       /* group without repeating */
.card:has(> img)      /* parent selector (modern browsers) */
```

---

## Layout: Flexbox (1D)

Best for laying out items in a row or a column.

```css
.container {
  display: flex;
  flex-direction: row;          /* or column */
  justify-content: space-between;  /* main axis alignment */
  align-items: center;             /* cross axis alignment */
  gap: 1rem;                       /* spacing between items */
  flex-wrap: wrap;                 /* allow wrapping */
}
.item { flex: 1; }                 /* grow to fill (shorthand: 1 1 0) */
```

**Center anything** (the classic):
```css
.center { display: flex; justify-content: center; align-items: center; }
```

---

## Layout: Grid (2D)

Best when you need rows and columns working together.

```css
.grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);   /* 3 equal columns */
  gap: 1rem;
}

/* Responsive without media queries: */
.grid {
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
}

/* Named areas */
.layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  grid-template-columns: 200px 1fr;
}
.header { grid-area: header; }
```

> **Tip:** **Flexbox for one dimension, Grid for two.** `auto-fit` + `minmax` gives fluid responsive grids with zero media queries.

---

## Responsive Design

```css
/* Mobile-first: base styles, then scale up */
.card { padding: 1rem; }

@media (min-width: 768px) {
  .card { padding: 2rem; }
}

/* Fluid sizing without breakpoints */
h1 { font-size: clamp(1.5rem, 4vw, 3rem); }   /* min, preferred, max */
.container { width: min(90%, 1200px); }
```

* **Use relative units**: `rem` (root-relative), `em`, `%`, `vw/vh`, `ch`.
* Reserve `px` for borders/hairlines.
* `clamp()`, `min()`, `max()` reduce the need for breakpoints.

---

## Custom Properties (CSS Variables)

```css
:root {
  --primary: #4f46e5;
  --space: 1rem;
}
.button {
  background: var(--primary);
  padding: var(--space);
  color: var(--text, #111);      /* fallback if undefined */
}

/* Theming: swap variables, not rules */
[data-theme="dark"] { --primary: #818cf8; --text: #eee; }
```

> **Tip:** Variables cascade and are live — change them at runtime with JS for instant theming.

---

## Common Problems & Fixes

### 1. Element overflows / adds up wrong
→ You forgot `box-sizing: border-box`. Set it globally.

### 2. Margins "collapse" or leak
Adjacent vertical margins **collapse** into the largest one; a parent's margin can "escape."
→ Use `padding` on the parent, or create a BFC (`display: flow-root`), or use `gap` in flex/grid instead of margins.

### 3. Can't vertically center
→ Flexbox: `display:flex; align-items:center;` — or Grid: `display:grid; place-items:center;`.

### 4. `z-index` doesn't work
`z-index` only applies to **positioned** elements (`position` ≠ `static`) and is scoped to its **stacking context**.
→ Add `position: relative;`. Beware: `transform`, `opacity < 1`, `filter`, and `will-change` create new stacking contexts that trap children.

### 5. Child ignores parent height / `height: 100%` fails
`height: %` needs the parent to have a defined height.
→ Give the parent a height, or use Flex/Grid (`align-items: stretch`), or `min-height: 100vh` on the root.

### 6. Horizontal scrollbar appears
→ Something exceeds the viewport: a fixed `width`, negative margin, or `100vw` (includes scrollbar width). Use `width: 100%` and hunt with `* { outline: 1px solid red; }`.

### 7. Image distorted or overflowing
```css
img { max-width: 100%; height: auto; display: block; }
.cover { width: 100%; height: 300px; object-fit: cover; }  /* crop, keep ratio */
```

### 8. Text overflows its box
```css
.truncate { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.wrap { overflow-wrap: break-word; }              /* break long words/URLs */
.clamp { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
```

### 9. Sticky element won't stick
→ `position: sticky` needs a `top`/`bottom` value **and** a scrollable ancestor that isn't `overflow: hidden`.

### 10. Flex item won't shrink / text won't truncate inside flex
→ Add `min-width: 0;` to the flex item (default `min-width: auto` prevents shrinking below content size).

---

## Handy Tricks

```css
/* Aspect ratio boxes */
.video { aspect-ratio: 16 / 9; }

/* Full-bleed / smooth scroll */
html { scroll-behavior: smooth; }

/* Hide visually but keep for screen readers */
.sr-only {
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden; clip: rect(0,0,0,0); border: 0;
}

/* Logical properties (RTL-friendly) */
.box { margin-inline: auto; padding-block: 1rem; }

/* Transitions */
.btn { transition: background 0.2s ease, transform 0.1s ease; }
.btn:active { transform: scale(0.97); }

/* Container queries — respond to the container, not viewport */
.card-wrap { container-type: inline-size; }
@container (min-width: 400px) { .card { display: flex; } }
```

---

## Performance & Maintainability

* **Animate only `transform` and `opacity`** — they're GPU-accelerated and don't trigger layout/paint. Avoid animating `width`, `top`, `margin`.
* Keep selectors shallow and avoid deep descendant chains.
* Use a naming convention (**BEM**: `.block__element--modifier`) or utility CSS (Tailwind) for scale.
* Prefer `gap` over margins for spacing in flex/grid.
* Reduce specificity wars by keeping one class focused on one responsibility.
* Respect user preferences: `@media (prefers-reduced-motion: reduce)` and `(prefers-color-scheme: dark)`.

---

## Gotchas Checklist

* Forgot `box-sizing: border-box`? → overflow bugs.
* `z-index` not working? → element must be positioned; watch stacking contexts.
* `100vw` causes horizontal scroll (includes scrollbar) → use `100%`.
* Collapsing margins surprise you → use padding/`gap` or `display: flow-root`.
* Flex child won't truncate → `min-width: 0`.
* `height: 100%` chain broken → parent needs a height.
* `!important` creeping in → your specificity is too high somewhere; refactor.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
