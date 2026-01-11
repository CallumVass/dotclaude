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

**Deployment & Operations** (if not already configured - see Detection)
- "Where should this run - edge, containers, serverless?"
- "What's the deploy cadence - continuous on merge, or batched releases?"
- "Any database or persistent storage needs?"

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

4. **For new projects** (no existing CI/deployment detected):
   - Establish CI and deployment infrastructure BEFORE feature work
   - See **Deployment & CI Phase** below

5. **If app has a UI** (React, Vue, Svelte, Next.js, dashboards, web apps, etc.):
   - Establish design system BEFORE creating implementation issues
   - See **Design System Phase** below

6. If beads is initialized (`bd version` succeeds) and create-issues not disabled:
   - Ask user if they want to create issues from the spec
   - If yes, create epic + tasks using `bd create`
   - Link tasks to epic
   - **CRITICAL: Use the Issue Description Format** from the "Autonomous-Ready Issues" section below
   - **Always use `--validate` flag** to ensure required sections are present
   - **Tasks must be vertical slices** - each task includes its boundary and tests:
     - "Add user profile page" = component + component test
     - "Add profile API endpoint" = controller + request test
     - Never separate "implement X" from "test X" - testing is part of done
   - **Issue creation order** (infrastructure before features):
     1. "Set up GitHub Actions CI" (if no CI detected)
     2. "Set up deployment to [Platform]" (if no deployment detected)
     3. "Configure production environment" (secrets, env vars, DB connection)
     4. "Set up design system" (if UI app)
     5. Feature issues...
   - **After creating issues**: Run `bd lint` to verify all issues have required sections

7. Summarise what was captured and next steps.

---

## Deployment & CI Phase (New Projects)

For new projects, establish CI and deployment infrastructure BEFORE feature work. "Deploy early, deploy often" - every vertical slice should be deployable from day one.

### Detection - Skip If Already Configured

Check for existing infrastructure before asking deployment questions:

**CI Detection:**
```bash
# GitHub Actions
ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null
```
If workflows exist → skip CI questions, note existing setup in spec.

**Deployment Detection:**
```bash
# Fly.io
ls fly.toml 2>/dev/null

# Cloudflare
ls wrangler.toml wrangler.json wrangler.jsonc 2>/dev/null
```
If deployment config exists → skip deployment questions, note existing setup in spec.

### When to Trigger

Only ask deployment/CI questions when:
- No existing CI config detected AND/OR no deployment config detected
- Project appears to be new (few commits, no releases)
- User mentions "new project", "starting fresh", "greenfield"

### Stack → Platform Recommendations

| Stack | Recommended Platform | Reason |
|-------|---------------------|--------|
| Elixir/Phoenix | Fly.io | Native BEAM support, easy clustering |
| .NET | Fly.io | Container-based, good .NET support |
| Node.js (full-stack) | Fly.io | Containers with persistent storage |
| Node.js (edge/static) | Cloudflare Pages/Workers | Edge-first, excellent DX |
| Static + API | Cloudflare Pages + Workers | Fast global CDN |
| Any with PostgreSQL | Fly.io | Fly Postgres or easy DB attachment |

### Deployment Questions

Ask using AskUserQuestion (only if not detected):

1. **Platform preference**:
   - Fly.io (containers, databases, full-stack)
   - Cloudflare (edge, static, serverless)
   - Other (specify)

2. **Deploy trigger**:
   - Continuous (deploy on every main merge)
   - Manual (deploy on demand/tag)

### Output: Infrastructure Spec

Add an **Infrastructure** section to the spec file:

```markdown
## Infrastructure

### CI (GitHub Actions)
- Trigger: Push to main, PRs
- Steps: Lint → Test → Build
- Required checks before merge: Yes

### Deployment
- Platform: [Fly.io / Cloudflare]
- Trigger: [On main merge / Manual]
- Environment: [Production only / Staging + Production]
```

### Persist to CLAUDE.md

Key infrastructure decisions must survive session boundaries. Append to CLAUDE.md:

```markdown
## Infrastructure

### Deployment
- Platform: [Fly.io / Cloudflare]
- Deploy command: [fly deploy / wrangler deploy]
- Secrets: [fly secrets set / wrangler secret put]

### CI
- All PRs must pass CI before merge
- Run `[mix test / npm test / dotnet test]` locally before pushing

### Environment Variables
See `.env.example` for required variables.
```

### First Beads Issues (Infrastructure)

When creating issues, infrastructure comes FIRST:

```bash
# 1. CI (always first)
bd create "Set up GitHub Actions CI" --validate --description "$(cat <<'EOF'
## Summary
Configure GitHub Actions for continuous integration.

## Acceptance Criteria
- [ ] Workflow runs on push to main and PRs
- [ ] Runs lint, test, build steps
- [ ] Required status check before merge enabled

## Implementation Hints
- Create .github/workflows/ci.yml
- Use appropriate action for stack (actions/setup-node, erlef/setup-beam, actions/setup-dotnet)
EOF
)"

# 2. Deployment (second)
bd create "Set up deployment to [Platform]" --validate --description "$(cat <<'EOF'
## Summary
Configure automated deployment to [Fly.io/Cloudflare].

## Acceptance Criteria
- [ ] Deploy succeeds on main branch merge
- [ ] Secrets configured in GitHub
- [ ] Health check passes post-deploy

## Implementation Hints
- Fly.io: fly launch, add deploy job to CI
- Cloudflare: wrangler.toml, pages/workers config
EOF
)"

# 3. Production environment (third)
bd create "Configure production environment" --validate --description "$(cat <<'EOF'
## Summary
Set up production secrets, environment variables, and external service connections.

## Acceptance Criteria
- [ ] All required secrets documented in README or .env.example
- [ ] Secrets configured in deployment platform
- [ ] Database connection configured (if applicable)
- [ ] External API keys configured (if applicable)
- [ ] App boots successfully in production with all services connected

## Implementation Hints
- Create .env.example with all required variables (no values)
- Document secret setup in README
- Fly.io: fly secrets set KEY=value
- Cloudflare: wrangler secret put KEY
EOF
)"
```

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

### Persist to CLAUDE.md

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

**Stack-specific component locations:**

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

### First Beads Issue

When creating issues, infrastructure and design system issues come first (see Issue Creation Order above).

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

```bash
bd create "Add user avatar upload to profile settings" --validate --description "$(cat <<'EOF'
## Summary
Add avatar image upload functionality to the profile settings page.

## Acceptance Criteria
- [ ] Upload button appears on /settings/profile
- [ ] Accepts PNG, JPG, GIF under 2MB
- [ ] Shows preview before save
- [ ] Saves to user record on submit
- [ ] Shows error for invalid files

## Implementation Hints
- Entry point: src/pages/settings/profile.vue
- Pattern to follow: src/pages/settings/notifications.vue (similar form)
- Key files: src/api/users.ts, src/components/ImageUpload.vue (create)
EOF
)"
```

**Note:** The `--validate` flag ensures beads rejects issues missing required sections (e.g., `## Acceptance Criteria` for tasks).

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
