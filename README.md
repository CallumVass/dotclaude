# dotclaude

Reusable [Claude Code](https://claude.ai/code) configuration with **mandatory quality gates**.

## Philosophy

Most AI coding workflows let you skip quality steps. This one doesn't.

```
GATE tests_before_review:
  Review phase BLOCKED until tests documented

GATE review_before_complete:  
  Completion BLOCKED until reviewer returns clean

GATE track_all_work:
  All work tracked in beads - no orphan features
```

These gates are enforced in the skill definitions, not just suggested.

## What's This?

Like dotfiles for your shell, this is a portable `.claude/` configuration with:

- **Skills**: `/init-project`, `/next-feature`, `/review-loop`, `/browser-check`
- **Rules**: Stack-specific patterns for TypeScript, .NET, and Elixir
- **Gates**: Mandatory testing and review phases that cannot be skipped
- **Task Tracking**: Uses [beads](https://github.com/steveyegge/beads) for git-backed issues

## Supported Stacks

| Stack | Rules | Notes |
|-------|-------|-------|
| TypeScript/Vue | `typescript/core.md` + `typescript/vue.md` | Composition API, Tailwind |
| TypeScript/React | `typescript/core.md` + `typescript/react.md` | Hooks, Next.js App Router |
| .NET/C# | `dotnet/core.md` + `dotnet/csharp.md` | Minimal APIs, EF Core |
| .NET/F# | `dotnet/core.md` + `dotnet/fsharp.md` | Result types, Railway-oriented |
| Elixir/Phoenix | Uses ecosystem tooling | Igniter, usage_rules, AGENTS.md |

## Prerequisites

### Beads CLI

This configuration requires [beads](https://github.com/steveyegge/beads) - a git-backed issue tracker for AI agents.

```bash
# Via npm (recommended)
npm install -g @beads/bd

# Via Homebrew
brew install steveyegge/beads/bd

# Via Go
go install github.com/steveyegge/beads/cmd/bd@latest
```

### Claude Code Plugins

Enable these plugins in Claude Code settings:

```json
{
  "enabledPlugins": {
    "feature-dev@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "context7@claude-plugins-official": true
  }
}
```

| Plugin | Used By |
|--------|---------|
| `feature-dev` | `/next-feature` and `/review-loop` subagents (explorer, architect, reviewer) |
| `playwright` | `/browser-check` UI verification |
| `frontend-design` | Quality UI component generation |
| `context7` | Up-to-date library documentation |

## Quick Start

### 1. Copy to Your Project

```bash
git clone https://github.com/CallumVass/dotclaude.git
cp -r dotclaude/.claude your-project/
```

### 2. Initialize

```bash
/init-project
```

This will:
- Check/install beads
- Detect your tech stack
- Create CLAUDE.md with inlined rules
- Initialize beads issue tracking
- Clean up template files

### 3. Start Building

```bash
/init-project    # Full workflow with gates
/next-feature    # Feature development with gates
/review-loop     # Standalone review cycle
/browser-check   # UI verification
/write-human     # British English, no AI slop
```

## The Gate System

### Why Gates?

AI coding assistants are happy to skip testing and review. They'll say "this is a small change" and go straight to completion. The result: bugs ship.

Gates make skipping impossible:

```
Phase 6 (Testing) ──BLOCKS──► Phase 7 (Review)
Phase 7 (Review)  ──BLOCKS──► Phase 8 (Completion)
```

### How It Works

The skills use declarative constraints:

```markdown
GATE tests_before_review:
  Phase 7 BLOCKED until Phase 6 complete
  
  REQUIRED: test_files[] non-empty OR explicit_justification
  VALID: "Changed private helper, covered by test at [path]"  
  INVALID: "It's a small change"
```

This isn't a suggestion - it's a precondition that must be satisfied.

### Light Mode

For genuinely small changes, use light mode:

```
MODE light:
  TRIGGER: "quick fix", "small change", or < 50 lines
  SKIP: Exploration, Architecture
  KEEP: Testing, Review ← NEVER skippable
```

Light mode skips the heavyweight phases but **never** skips quality gates.

## Workflow

```
/init-project → /next-feature → /commit → repeat
```

### /next-feature Phases

| Phase | Mode | Description |
|-------|------|-------------|
| 1. Selection | Both | Pick work from beads or create ad-hoc |
| 2. Exploration | Full | Subagents map codebase |
| 3. Clarification | Both | Resolve ambiguities |
| 4. Architecture | Full | Subagents propose approaches |
| 5. Implementation | Both | Build the feature |
| 6. Testing | Both | **MANDATORY** - document tests |
| 7. Review | Both | **MANDATORY** - loop until clean |
| 8. Completion | Both | Close beads, present summary |

## /write-human

Writes documentation, PR reviews, spikes, and emails in British English without AI tells.

**Modes:** `docs`, `pr-review`, `spike`, `email`, `general`

**Bans:** "I'd be happy to", "Great question!", "leverage", "robust", "dive into", and ~40 other AI-isms.

**Enforces:** British spelling, short sentences, direct tone, no hedging.

```
/write-human docs      # Technical documentation
/write-human pr-review # PR comments  
/write-human spike     # Investigation summaries
```

## Beads Commands

| Action | Command |
|--------|---------|
| Find ready work | `bd ready` |
| Show task | `bd show <id>` |
| Create task | `bd create "Title" -t task -p 1` |
| Complete task | `bd close <id>` |
| Sync to git | `bd sync` |

## Structure

```
.claude/
├── settings.local.json     # Permissions
├── rules/                  # Reference (inlined by /init-project)
│   ├── patterns.md         # Universal patterns + testing rules
│   ├── typescript/         # TS/Vue/React
│   ├── dotnet/             # C#/F#
│   └── elixir/             # Setup guide
├── skills/
│   ├── init-project/       # Setup with gates
│   ├── next-feature/       # Feature workflow with gates
│   ├── review-loop/        # Review cycle
│   ├── browser-check/      # UI verification
│   └── write-human/        # British English, no AI slop
└── templates/
    └── CLAUDE.md           # Project template
```

## Declarative Skill Style

Skills use a declarative style with explicit constraints:

```markdown
## Constraints

GATE review_before_complete:
  Phase 8 BLOCKED until Phase 7 returns "NO ISSUES FOUND"

INVARIANT track_all_work:
  All features create beads issues
  Completion closes beads with reason

## Phases

### Phase 6: Testing
PRECONDITION: Phase 5 complete
POSTCONDITION: test_files[] documented
BLOCKS: Phase 7
```

This makes dependencies explicit and harder to skip.

## License

MIT
