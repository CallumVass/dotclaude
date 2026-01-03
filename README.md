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
/brainstorm     # Deep discovery interview → spec → beads issues
```

Adapts to context:
- Has spec file? Interviews to go deeper
- Has beads issues? Reads them, expands scope
- Greenfield? Asks what you're building

### 3. Build

```
/next-feature   # Full dev cycle: issue → branch → build → review → PR
```

Auto-detects complexity:

**Lite path** (small fixes, single file):
- Pick issue → create branch → implement → review → PR

**Full path** (new features, multi-file):
- Pick issue → create branch
- Explore codebase (`code-explorer` agent)
- Ask clarifying questions
- Design architecture (`code-architect` agent)
- Implement (with approval) → review → PR

### 4. Document

```
/write-human    # British English, no AI slop
```

## Skills

| Skill | Purpose |
|-------|---------|
| `/setup-rules` | Detect stack, consolidate `.claude/rules/` into `CLAUDE.md` |
| `/setup-beads` | Initialize beads with protected branch workflow |
| `/brainstorm` | Interview → spec → issues |
| `/next-feature` | Pick issue → explore → architect → implement → review → done |
| `/review-loop` | Code review loop until clean |
| `/write-human` | Human-sounding prose (British English) |

## Rules

Stack-specific coding standards in `.claude/rules/`:

```
rules/
├── patterns.md           # Universal (DRY, YAGNI, testing)
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
