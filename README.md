# dotclaude

Personal Claude Code configuration - skills, rules, and workflows.

## Quick Start

Clone into your home directory or symlink to `~/.claude`:

```bash
git clone https://github.com/CallumVass/dotclaude ~/.claude
```

## Workflow

### 1. Setup Project

```
/setup-rules    # Detect tech stack, consolidate rules into CLAUDE.md
/setup-beads    # Initialize beads issue tracker (protected branch workflow)
```

### 2. Plan Features

```
/brainstorm     # Deep discovery interview → spec → design system → issues
```

Adapts to context:
- Has spec file? Interviews to go deeper
- Has beads issues? Reads them, expands scope
- Greenfield? Asks what you're building
- **UI apps?** Establishes design system (Tailwind/UnoCSS tokens, component patterns)

### 3. Build

**Interactive mode:**
```
/next-feature   # Full dev cycle with human-in-the-loop
```

Auto-detects complexity, asks clarifying questions, gets architecture approval.

**Autonomous mode (Ralph):**
```bash
# Unix/Mac
./scripts/ralph.sh 10    # Max 10 iterations

# Windows
.\scripts\ralph.ps1 -MaxIterations 10 -Notify
```

Runs Claude in autonomous loop: pick issue → implement → test → PR → review → merge → repeat.

See [Autonomous Workflow](#autonomous-workflow-ralph) for details.

### 4. Document

```
/write-human    # British English, no AI slop
```

## Skills

| Skill | Purpose |
|-------|---------|
| `/setup-rules` | Detect stack, consolidate `.claude/rules/` into `CLAUDE.md` |
| `/setup-beads` | Initialize beads with protected branch workflow |
| `/brainstorm` | Interview → spec → design system (UI apps) → issues |
| `/next-feature` | Interactive: Pick issue → explore → architect → implement → review → done |
| `/ralph-task` | Autonomous: Pick issue → implement → test → PR → review → merge |
| `/ralph-review` | Batch audit: Verify acceptance criteria, spec alignment, create corrective issues |
| `/review-loop` | Code review loop until clean |
| `/write-human` | Human-sounding prose (British English) |

## Rules

Stack-specific coding standards in `.claude/rules/`:

```
rules/
├── patterns.md           # Universal (DRY, YAGNI, testing)
├── frontend.md           # Tailwind/UnoCSS constraints, semantic tokens
├── windows.md            # Windows-specific (nul redirection, paths)
├── dotnet/
│   ├── core.md           # .NET conventions
│   ├── csharp.md         # C# 12+ features
│   └── fsharp.md         # F# idioms
├── elixir/
│   └── setup.md          # Phoenix/Elixir setup
└── typescript/
    ├── core.md           # TS conventions
    ├── react.md          # React/Next.js
    └── vue.md            # Vue/Nuxt
```

Run `/setup-rules` in a project to consolidate relevant rules into its `CLAUDE.md`.

## Beads Integration

Skills integrate with [beads](https://github.com/steveyegge/beads) for task tracking:

- `/setup-beads` initializes with protected branch workflow
- `/brainstorm` creates issues from discovered requirements
- `/next-feature` picks from `bd ready`, creates feature branch, marks done on completion
- Commits reference issue IDs: `git commit -m "Add feature (bd-abc)"`
- `bd sync` runs automatically to keep issues pushed

## Customisation

### Add a new stack

Create rules in `.claude/rules/[stack]/` and update detection logic in `/setup-rules`.

### Add a new skill

Create `.claude/skills/[name]/SKILL.md` with:

```yaml
---
name: skill-name
description: When to trigger this skill
arguments:
  - name: arg
    description: What it does
    required: false
---
```

Keep skills lean - focus on constraints and intent, not pseudo-code.

## Autonomous Workflow (Ralph)

The Ralph workflow enables fully autonomous development - Claude picks up issues, implements them, and merges PRs without human intervention.

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  ralph.sh / ralph.ps1 (external loop)                       │
│                                                             │
│  for i in 1..max_iterations:                                │
│    result = claude /ralph-task                              │
│    if COMPLETE → continue to next issue                     │
│    if NO_ISSUES → exit (all done)                           │
│    if BLOCKED → exit (human needed)                         │
└─────────────────────────────────────────────────────────────┘
```

Each `/ralph-task` iteration:
1. Picks next issue from `bd ready`
2. Creates feature branch
3. Explores codebase, implements feature
4. Writes boundary tests
5. Runs quality checks (lint, typecheck, test)
6. Commits, pushes, creates PR
7. Runs `/code-review` (up to 3 iterations)
8. Auto-merges on success
9. Outputs promise word for loop control

**Batch Review** (every 5 tasks by default):
- Verifies acceptance criteria are actually met
- Checks alignment with SPEC.md (if exists)
- Validates convention adherence (CLAUDE.md, AGENTS.md)
- Creates high-priority corrective issues for any drift

### Running Ralph

**Unix/Mac:**
```bash
# Make scripts executable (first time only)
chmod +x scripts/ralph.sh

# Run with max 10 iterations
./scripts/ralph.sh 10

# With notifications (set NOTIFY_CMD)
NOTIFY_CMD="terminal-notifier -message" ./scripts/ralph.sh 10

# Custom review interval (default: 5)
REVIEW_INTERVAL=3 ./scripts/ralph.sh 10
```

**Windows:**
```powershell
# Run with max 10 iterations
.\scripts\ralph.ps1 -MaxIterations 10

# With toast notifications
.\scripts\ralph.ps1 -MaxIterations 10 -Notify

# Custom log file
.\scripts\ralph.ps1 -MaxIterations 20 -LogFile "C:\logs\ralph.log"

# Custom review interval (default: 5)
.\scripts\ralph.ps1 -MaxIterations 10 -ReviewInterval 3
```

### Creating Autonomous-Ready Issues

Use `/brainstorm` to create properly-sized issues with:

- **Clear acceptance criteria** - specific, testable conditions
- **Implementation hints** - entry points, patterns to follow
- **Test requirements** - what boundary tests are needed
- **Right size** - completable in ~30-60 minutes

Example good issue:
```markdown
## Summary
Add avatar image upload to profile settings.

## Acceptance Criteria
- [ ] Upload button appears on /settings/profile
- [ ] Accepts PNG, JPG, GIF under 2MB
- [ ] Shows preview before save
- [ ] Boundary tests cover component and API

## Implementation Hints
- Entry point: src/pages/settings/profile.vue
- Pattern: src/pages/settings/notifications.vue
```

### Promise Words

The loop script looks for these in Claude's output:

| Promise Word | Meaning | Script Action |
|--------------|---------|---------------|
| `<promise>COMPLETE</promise>` | Task done, merged | Continue to next |
| `<promise>NO_ISSUES</promise>` | No more issues | Exit success |
| `<promise>BLOCKED</promise>` | Needs human | Exit with error |

### When to Use

**Good for:**
- Well-defined tasks with clear acceptance criteria
- Greenfield projects with good issue breakdown
- Overnight/background development
- Tasks with automatic verification (tests, linters)

**Not good for:**
- Tasks requiring design decisions or human judgement
- Production debugging
- Unclear or ambiguous requirements
- One-shot operations
