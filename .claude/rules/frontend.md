# Frontend Rules

Rules for building frontend interfaces. These enforce the design system established during `/brainstorm`.

---

## Styling: Tailwind/UnoCSS Only

```
╔═══════════════════════════════════════════════════════════════╗
║  NEVER write custom CSS, inline styles, or <style> blocks     ║
║  ALWAYS use Tailwind/UnoCSS utility classes                   ║
║  EXTEND the config for custom values, don't hardcode          ║
╚═══════════════════════════════════════════════════════════════╝
```

### NEVER / INSTEAD

| NEVER | INSTEAD |
|-------|---------|
| `style={{ color: '#64748b' }}` | `className="text-foreground-muted"` |
| `className="text-gray-500"` | `className="text-foreground-muted"` |
| `className="bg-white"` | `className="bg-surface"` |
| `className="border-gray-200"` | `className="border-border"` |
| `className="rounded-lg"` (arbitrary) | `className="rounded"` (from system) |
| Custom CSS file | Extend Tailwind config |
| `<style>` blocks | Utility classes |

---

## Semantic Tokens

Use the semantic tokens defined in the project's design system, not raw Tailwind values.

### Surface Tokens
```
bg-surface         // Primary background (cards, modals)
bg-surface-muted   // Secondary background (page bg)
bg-surface-subtle  // Tertiary background (hover states)
```

### Border Tokens
```
border-border      // Primary borders
border-border-subtle // Subtle separators
```

### Foreground (Text) Tokens
```
text-foreground       // Primary text
text-foreground-muted // Secondary text (descriptions)
text-foreground-faint // Tertiary text (placeholders)
```

### Accent Tokens
```
bg-accent          // Primary actions
bg-accent-hover    // Hover state
text-accent        // Accent text/links
```

### Status Tokens
```
text-success / bg-success
text-warning / bg-warning
text-error / bg-error
```

---

## Before Creating a Component

1. **Check the design system** - Does a pattern exist in SPEC.md?
2. **Check existing components** - Can something be composed/extended?
3. **Only create new** if truly necessary

### Standard Component Patterns

```tsx
// Card
<div className="bg-surface rounded border border-border p-4">
  {children}
</div>

// Button (primary)
<button className="bg-accent text-white rounded px-4 py-2 hover:bg-accent-hover">
  {label}
</button>

// Button (secondary)
<button className="bg-surface border border-border rounded px-4 py-2 hover:bg-surface-muted">
  {label}
</button>

// Input
<input className="bg-surface border border-border rounded px-3 py-2 text-sm focus:border-accent focus:outline-none" />

// Label
<label className="text-sm font-medium text-foreground-muted">
  {label}
</label>
```

---

## Typography

### Headings
```
text-2xl font-semibold tracking-tight  // Page titles
text-lg font-semibold tracking-tight   // Section headings
text-base font-medium                  // Card titles
```

### Body Text
```
text-sm text-foreground                // Primary body
text-sm text-foreground-muted          // Secondary/descriptions
text-xs text-foreground-faint          // Tertiary/hints
```

### Data & Numbers
```
font-mono tabular-nums                 // Always for numeric data
```

### Labels & UI Text
```
text-sm font-medium text-foreground-muted
```

---

## Spacing (4px Grid)

All spacing uses the 4px grid:

| Class | Value | Use |
|-------|-------|-----|
| `p-1` / `gap-1` | 4px | Micro spacing (icon gaps) |
| `p-2` / `gap-2` | 8px | Tight spacing (within components) |
| `p-3` / `gap-3` | 12px | Standard spacing |
| `p-4` / `gap-4` | 16px | Comfortable spacing (section padding) |
| `p-6` / `gap-6` | 24px | Generous spacing |
| `p-8` / `gap-8` | 32px | Major separation |

### Symmetrical Padding

Prefer symmetrical padding. If asymmetric is needed, it should be intentional:

```tsx
// Good
<div className="p-4">

// Good (horizontal needs more room)
<div className="px-6 py-4">

// Avoid (arbitrary asymmetry)
<div className="pt-6 pb-4 px-3">
```

---

## Border Radius

Stick to the defined system:

```
rounded-sm   // 4px - tight/technical
rounded      // 6px - default
rounded-md   // 8px - softer
```

Don't mix systems. Consistency creates coherence.

---

## Depth Strategy

Choose ONE approach for the project and commit:

### Borders Only (Flat)
```tsx
<div className="border border-border">
  // Clean, technical, dense - Linear/Raycast style
</div>
```

### Subtle Shadow
```tsx
<div className="shadow-sm border border-border">
  // Soft lift - approachable products
</div>
```

### Surface Colour Shift
```tsx
<div className="bg-surface"> // on bg-surface-muted page
  // Elevation through colour, no shadows
</div>
```

Don't mix approaches within a project.

---

## Dark Mode

When implementing dark mode:

- Borders over shadows (shadows less visible on dark backgrounds)
- Adjust status colours (may need desaturation)
- Same semantic tokens, different values in config

```tsx
// Dark mode config extends light mode
colors: {
  surface: {
    DEFAULT: '#0f172a',  // Inverted
    muted: '#1e293b',
    subtle: '#334155',
  },
  // ... etc
}
```

---

## Anti-Patterns

### NEVER Do This

- Dramatic drop shadows (`shadow-2xl`, `shadow-xl`)
- Large border radius on small elements (`rounded-2xl` on buttons)
- Asymmetric padding without clear reason
- Pure white cards on coloured backgrounds
- Thick borders for decoration (`border-2`)
- Multiple accent colours in one interface
- Gradients for decoration
- Spring/bouncy animations in enterprise UI

### Always Question

- "Am I using a semantic token or a raw value?"
- "Does this component already exist in the design system?"
- "Is this spacing on the 4px grid?"
- "Is my depth strategy consistent?"
