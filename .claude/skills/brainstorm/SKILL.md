---
name: brainstorm
description: Deep-dive interview to discover features, requirements, and edge cases. Use when starting a project, planning features, or user says "brainstorm", "spec", "interview me", "let's plan".
arguments:
  - name: spec
    description: Path to spec file (defaults to SPEC.md)
    required: false
  - name: create-issues
    description: Create beads issues from spec when done (defaults to true if beads initialized)
    required: false
---

# Brainstorm

Interview the user to build a comprehensive spec, then optionally create beads issues.

## Constraints

- Ask non-obvious questions - assume user has thought about the basics
- Go deep on technical implementation, UX, edge cases, tradeoffs
- Continue until user signals completion
- Never ask yes/no questions - ask open-ended or offer specific options
- Challenge assumptions respectfully

## Question Categories

Cycle through these, adapting to context:

**Technical depth**
- "How should X behave when Y fails?"
- "What's the recovery path if Z gets corrupted?"
- "Where does this data live and who owns it?"

**UX and interaction**
- "What does the user see while waiting for X?"
- "How do they undo this action?"
- "What happens on the second use vs first use?"

**Edge cases**
- "What if there are 10,000 of these?"
- "What if the user is offline?"
- "What if two users do this simultaneously?"

**Tradeoffs**
- "Speed vs correctness - where do you lean here?"
- "Do we build X now or defer it?"
- "What's the MVP vs the ideal?"

**Concerns**
- "What keeps you up at night about this?"
- "What's the riskiest assumption?"
- "Where might we be wrong?"

## Process

1. Gather context (in order of preference):

   **If spec file exists:**
   - Read it, use as foundation for interview
   - Goal: go deeper, find gaps, challenge assumptions

   **Else if beads initialized (`bd version` succeeds):**
   - Run `bd list --json` to get existing issues
   - Read epics and tasks to understand project scope
   - Summarise understanding to user: "Based on your issues, this looks like X. Is that right?"
   - Goal: expand scope, discover new features, refine existing

   **Else (greenfield):**
   - Ask user: "What are you looking to build?"
   - Get high-level description before diving deep
   - Goal: shape the vision, then drill into details

2. Interview loop:
   - Ask 1-2 probing questions per round using AskUserQuestion
   - Listen to answers, note gaps and assumptions
   - Go deeper on vague areas
   - Track decisions made
   - Continue until user says "done", "that's it", or similar

3. Write spec:
   - Update/create spec file with everything learned
   - Structure: Overview, Requirements, Technical Design, Open Questions
   - Be concrete - include decisions made, not just questions asked

4. **If app has a UI** (React, Vue, Svelte, Next.js, dashboards, web apps, etc.):
   - Establish design system BEFORE creating implementation issues
   - See **Design System Phase** below

5. If beads is initialized (`bd version` succeeds) and create-issues not disabled:
   - Ask user if they want to create issues from the spec
   - If yes, create epic + tasks using `bd create`
   - Link tasks to epic
   - **Tasks must be vertical slices** - each task includes its boundary and tests:
     - "Add user profile page" = component + component test
     - "Add profile API endpoint" = controller + request test
     - Never separate "implement X" from "test X" - testing is part of done
   - **For UI apps**: Create "Set up design system" as the FIRST issue

6. Summarise what was captured and next steps.

---

## Design System Phase (UI Apps)

For apps with a frontend, establish the design system BEFORE implementation begins. This constrains all subsequent UI work to consistent, composable patterns.

### When to Trigger

Detect UI app via:
- Framework mentions: React, Vue, Svelte, Next.js, Nuxt, Remix, etc.
- UI-related requirements: "dashboard", "landing page", "admin panel", "component", etc.
- User explicitly mentions frontend/UI work

### Design Direction Questions

Ask the user using AskUserQuestion:

1. **Tone/personality**: What feel should this have?
   - Precision & density (Linear, Raycast style)
   - Warmth & approachability (Notion, Coda style)
   - Sophistication & trust (Stripe, Mercury style)
   - Bold & minimal (Vercel style)
   - Utility & function (GitHub style)
   - Dark & moody
   - Playful & colourful

2. **Palette preference**:
   - Light mode, dark mode, or both?
   - Primary brand colour (if any)?
   - Warm, cool, or neutral foundation?

3. **Inspiration**: Any reference sites or design systems to draw from?

### Output: Design System Spec

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

### First Beads Issue

When creating issues, the FIRST issue for a UI app should be:

```
bd create "Set up design system" --description "Configure Tailwind/UnoCSS with semantic tokens, establish base component patterns per SPEC.md design system section"
```

This ensures the design system is implemented before any feature work begins.

## Interview Style

- Be curious, not interrogative
- "Tell me more about..." not "Explain..."
- Offer options when useful: "Would you lean toward A (simpler) or B (more flexible)?"
- Acknowledge good answers briefly, then push deeper
- If user is unsure, help them think through it rather than moving on

---

## Autonomous-Ready Issues (Ralph Workflow)

When creating issues destined for autonomous execution via `/ralph-task`, ensure they meet these criteria.

### Size Guidelines

Issues must be completable in a single Claude session (roughly 30-60 minutes of work):

| Good Size | Too Large |
|-----------|-----------|
| Add single API endpoint with tests | Add entire CRUD API |
| Create one component with tests | Build complete page with multiple components |
| Fix specific bug with regression test | Refactor entire module |
| Add single feature flag | Implement feature flagging system |

**Rule of thumb**: If you can't describe the implementation in 3-5 bullet points, break it down further.

### Issue Description Format

When creating issues with `bd create`, use this structure:

```markdown
## Summary
[One sentence describing what needs to be built]

## Acceptance Criteria
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Boundary test added]

## Implementation Hints
- Entry point: [file path or pattern to start from]
- Pattern to follow: [reference to similar existing feature]
- Key files: [2-3 files likely to need changes]

## Test Requirements
| Boundary | Test Type |
|----------|-----------|
| [Component/Endpoint/View] | [Component test/Request test/LiveViewTest] |

## Dependencies
- Blocked by: [bd-xxx] (if any)
- Blocks: [bd-yyy] (if any)
```

### Example: Good Autonomous Issue

```
bd create "Add user avatar upload to profile settings"
```

With description:

```markdown
## Summary
Add avatar image upload functionality to the profile settings page.

## Acceptance Criteria
- [ ] Upload button appears on /settings/profile
- [ ] Accepts PNG, JPG, GIF under 2MB
- [ ] Shows preview before save
- [ ] Saves to user record on submit
- [ ] Shows error for invalid files
- [ ] Boundary tests cover component and API

## Implementation Hints
- Entry point: src/pages/settings/profile.vue
- Pattern to follow: src/pages/settings/notifications.vue (similar form)
- Key files: src/api/users.ts, src/components/ImageUpload.vue (create)

## Test Requirements
| Boundary | Test Type |
|----------|-----------|
| ProfileSettings page | Component test with file upload mock |
| PUT /api/users/:id/avatar | Request test |

## Dependencies
- Blocked by: none
- Blocks: bd-c3d4 (avatar display in header)
```

### Example: Too Vague (Not Autonomous-Ready)

```markdown
## Summary
Improve user profile functionality.

## Notes
Make the profile better. Users have complained.
```

This issue needs breaking down into specific, testable tasks.

### Dependency Hierarchy

For complex features, create an epic with ordered tasks:

```bash
# Create epic
bd create "User Profile Improvements" --epic

# Create tasks linked to epic
bd create "Add avatar upload endpoint" --parent bd-epic-id
bd create "Add avatar upload component" --parent bd-epic-id
bd create "Add avatar display to header" --parent bd-epic-id
```

Tasks should be ordered so dependencies are completed first. The autonomous workflow will pick them up in order via `bd ready`.
