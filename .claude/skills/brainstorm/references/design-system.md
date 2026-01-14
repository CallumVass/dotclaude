# Design System Phase (UI Apps)

For apps with a frontend, establish the design system BEFORE implementation begins. This constrains all subsequent UI work to consistent, composable patterns.

## When to Trigger

Detect UI app via:
- Framework mentions: React, Vue, Svelte, Next.js, Nuxt, Remix, etc.
- UI-related requirements: "dashboard", "landing page", "admin panel", "component", etc.
- User explicitly mentions frontend/UI work

## Design Direction Questions

Ask the user using AskUserQuestion:

1. **CSS framework** (if not already in project):
   - Tailwind CSS
   - UnoCSS
   - Other

2. **Package manager** (for JS/TS projects, if not already configured):
   - pnpm (recommended)
   - npm
   - yarn
   - bun

3. **Tone/personality**: What feel should this have?
   - Precision & density (Linear, Raycast style)
   - Warmth & approachability (Notion, Coda style)
   - Sophistication & trust (Stripe, Mercury style)
   - Bold & minimal (Vercel style)
   - Utility & function (GitHub style)
   - Dark & moody
   - Playful & colourful

4. **Palette preference**:
   - Light mode, dark mode, or both?
   - Primary brand colour (if any)?
   - Warm, cool, or neutral foundation?

5. **Inspiration**: Any reference sites or design systems to draw from?

## Output: Design System Spec

Add a **Design System** section to the spec file with:

```markdown
## Design System

### Direction
[Chosen aesthetic, e.g., "Precision & Density - Linear/Raycast inspired"]

### Tailwind/UnoCSS Config Extensions

\`\`\`js
// tailwind.config.js or uno.config.ts theme.extend
{
  colors: {
    // Semantic surface tokens
    surface: {
      DEFAULT: '#ffffff',
      muted: '#f8fafc',
      subtle: '#f1f5f9',
    },
    // Semantic border tokens
    border: {
      DEFAULT: 'rgba(0,0,0,0.08)',
      subtle: 'rgba(0,0,0,0.05)',
    },
    // Semantic text tokens
    foreground: {
      DEFAULT: '#0f172a',
      muted: '#64748b',
      faint: '#94a3b8',
    },
    // Accent (adjust to brand)
    accent: {
      DEFAULT: '#3b82f6',
      hover: '#2563eb',
    },
    // Status colours
    success: '#22c55e',
    warning: '#f59e0b',
    error: '#ef4444',
  },
  fontFamily: {
    sans: ['Geist', 'system-ui', 'sans-serif'],
    mono: ['Geist Mono', 'monospace'],
  },
  fontSize: {
    '2xs': '0.6875rem', // 11px
    xs: '0.75rem',      // 12px
    sm: '0.8125rem',    // 13px
    base: '0.875rem',   // 14px
  },
  borderRadius: {
    sm: '4px',
    DEFAULT: '6px',
    md: '8px',
  },
}
\`\`\`

### Component Patterns

| Component | Classes | Notes |
|-----------|---------|-------|
| Card | \`bg-surface rounded border border-border p-4\` | |
| Button (primary) | \`bg-accent text-white rounded px-4 py-2 hover:bg-accent-hover\` | |
| Button (secondary) | \`bg-surface border border-border rounded px-4 py-2\` | |
| Input | \`bg-surface border border-border rounded px-3 py-2 text-sm\` | |
| Label | \`text-sm font-medium text-foreground-muted\` | |
| Heading | \`text-lg font-semibold tracking-tight\` | |
| Data/numbers | \`font-mono tabular-nums\` | |

### Constraints

- **Tailwind/UnoCSS only**: No inline styles, no CSS files, no \`style=\` attributes
- **Semantic tokens**: Use \`text-foreground-muted\` not \`text-gray-500\`
- **4px grid**: All spacing uses p-1 (4px), p-2 (8px), p-3 (12px), p-4 (16px)
- **Component reuse**: Check patterns before creating new components
```

## Persist to CLAUDE.md

**CRITICAL**: SPEC.md is not automatically read by new Claude sessions. Key constraints MUST be added to CLAUDE.md to survive session boundaries.

After establishing the design system, append to CLAUDE.md:

```markdown
## UI Development

**Read SPEC.md** for full design system before creating any UI.

### Tooling
- CSS: [Tailwind / UnoCSS]
- Package manager: [pnpm / npm / yarn / bun]

### Component Location
[Stack-specific - see below]

### Constraints
- Use semantic tokens from SPEC.md design system (e.g., `text-foreground-muted` not `text-gray-500`)
- Check existing components before creating new ones
- All shared/reusable components go in [component location]
```

## Stack-Specific Component Locations

| Stack | Shared Components Location | Notes |
|-------|---------------------------|-------|
| Phoenix/LiveView | `lib/[app]_web/components/core_components.ex` | Add to existing file, use `attr` and `slot` |
| React/Next.js | `src/components/ui/` | One component per file |
| Vue/Nuxt | `components/ui/` | Auto-imported |
| Svelte/SvelteKit | `src/lib/components/` | Export from `$lib` |

**Phoenix/LiveView example** (add to CLAUDE.md):

```markdown
## UI Development

**Read SPEC.md** for full design system before creating any UI.

### Component Location
All shared components go in `lib/[app]_web/components/core_components.ex`.

Before creating a component in a LiveView:
1. Check if it exists in core_components.ex
2. If similar component exists, extend it with variants
3. Only create inline if truly one-off (rare)

### Existing Components
- `<.button>` - primary, secondary, ghost variants
- `<.input>` - text, email, password, textarea
- `<.badge>` - status indicators
- [Add as you create them]
```

## First Beads Issue

When creating issues, infrastructure and design system issues come first.

For UI apps, the design system issue should be:

```bash
bd create "Set up design system" --validate --description "$(cat <<'EOF'
## Summary
Configure Tailwind/UnoCSS with semantic tokens and establish shared component patterns.

## Acceptance Criteria
- [ ] CSS framework config extended with semantic tokens from SPEC.md
- [ ] Base components added to [core_components.ex / components/ui/]
- [ ] CLAUDE.md updated with UI development constraints
- [ ] Component location documented

## Implementation Hints
- Entry point: SPEC.md design system section
- Tailwind: tailwind.config.js (or assets/tailwind.config.js for Phoenix)
- UnoCSS: uno.config.ts theme.extend
- Phoenix: extend core_components.ex
- Other: create components/ui/ directory
EOF
)"
```

This ensures the design system is implemented AND documented before any feature work begins.
