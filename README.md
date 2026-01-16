# dotclaude

Personal Claude Code configuration for autonomous development.

## Quick Start

Clone to your home directory:

```bash
git clone https://github.com/CallumVass/dotclaude ~/.claude
```

## Workflow

### 1. Setup

In a new project, run `/setup`. This detects your stack, copies the rules into `CLAUDE.md`, and optionally sets up beads.

**Stacks:**
- `dotnet-csharp` / `dotnet-fsharp`
- `typescript-react` / `typescript-vue`
- `elixir` (Phoenix + daisyUI)
- `elixir-livevue` (Phoenix + LiveVue, all UI in Vue)

### 2. Plan

Run `/brainstorm` for a discovery interview. Produces a spec, design tokens (for UI), and beads issues with acceptance criteria.

### 3. Build

```bash
# Unix/Mac
./scripts/ralph.sh 10

# Windows
.\scripts\ralph.ps1 -MaxIterations 10 -Notify
```

Ralph works autonomously: picks an issue, implements it, writes tests, creates a PR, reviews it, merges, repeats.

### 4. Document

Run `/write-human` for prose that sounds human. British English, no AI slop.

## Skills

| Skill | What it does |
|-------|--------------|
| `/setup` | Detect stack, copy rules, init beads |
| `/brainstorm` | Interview → spec → design system → issues |
| `/ralph-task` | Autonomous: issue → implement → test → PR → merge |
| `/ralph-review` | Batch audit of Ralph's work |
| `/review-loop` | Code review until clean |
| `/write-human` | Human-sounding prose |

## Rules

Pre-composed stack rules live in `.claude/rules/`:

```
rules/
├── dotnet-csharp.md      # MC: no sync-over-async, tests
├── dotnet-fsharp.md      # MC: no nulls, tests
├── typescript-react.md   # MC: no any, Tailwind, semantic tokens, tests
├── typescript-vue.md     # MC: no any, Tailwind, semantic tokens, tests
├── elixir.md             # MC: Tailwind + daisyUI, tests
├── elixir-livevue.md     # MC: Vue components only, semantic tokens, tests
└── windows.md            # Windows quirks (nul redirection)
```

Each file has **Mandatory Constraints (MC)** at the top. These apply to all code regardless of what acceptance criteria say. Ralph verifies them.

## Beads

Skills work with [beads](https://github.com/steveyegge/beads) for issue tracking:

- `/setup` initialises beads with protected branch workflow
- `/brainstorm` creates issues from requirements
- `/ralph-task` picks from `bd ready`, closes on merge
- Commits reference issues: `git commit -m "Add feature (bd-abc)"`

## Ralph

Autonomous development. Claude picks issues, implements them, merges PRs.

```
┌─────────────────────────────────────────────────────────────┐
│  ralph.sh / ralph.ps1                                       │
│                                                             │
│  for i in 1..max:                                           │
│    result = claude /ralph-task                              │
│    COMPLETE → next issue                                    │
│    NO_ISSUES → done                                         │
│    BLOCKED → stop, human needed                             │
└─────────────────────────────────────────────────────────────┘
```

Each iteration:
1. Check for in-progress work (resume if found)
2. Pick next issue from `bd ready`
3. Create branch, explore, implement
4. Write boundary tests
5. Run quality checks
6. Push, create PR
7. Code review (max 3 rounds)
8. Verify all AC and MC
9. Merge

**Running it:**

```bash
# Unix
chmod +x scripts/ralph.sh
./scripts/ralph.sh 10

# Windows
.\scripts\ralph.ps1 -MaxIterations 10 -Notify
```

**Promise words:**

| Word | Meaning |
|------|---------|
| `<promise>COMPLETE</promise>` | Merged, continue |
| `<promise>NO_ISSUES</promise>` | Queue empty |
| `<promise>BLOCKED</promise>` | Human needed |

**Good issues** have clear acceptance criteria, implementation hints, and are completable in 30-60 minutes. Use `/brainstorm` to create them.

## Customisation

**New stack:** Create `.claude/rules/[name].md` with Mandatory Constraints at the top. Update detection in `/setup`.

**New skill:** Create `.claude/skills/[name]/SKILL.md`. Run `/skill-creator` for guidance.
