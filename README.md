# dotclaude

Reusable [Claude Code](https://claude.ai/code) configuration for multi-stack projects.

## What's This?

Like dotfiles for your shell, this is a portable `.claude/` configuration with:

- **Skills**: `/init-project`, `/next-feature`, `/review-loop`, `/browser-check`
- **Rules**: Stack-specific patterns for TypeScript, .NET, and Elixir
- **Templates**: CLAUDE.md template with architectural documentation
- **Task Tracking**: Uses [beads](https://github.com/steveyegge/beads) for git-backed issue tracking

## Supported Stacks

| Stack | Rules | Notes |
|-------|-------|-------|
| TypeScript/Vue | `typescript/core.md` + `typescript/vue.md` | Composition API, UnoCSS/Tailwind |
| TypeScript/React | `typescript/core.md` + `typescript/react.md` | Hooks, Next.js App Router |
| .NET/C# | `dotnet/core.md` + `dotnet/csharp.md` | Minimal APIs, EF Core |
| .NET/F# | `dotnet/core.md` + `dotnet/fsharp.md` | Result types, Railway-oriented |
| Elixir/Phoenix | Uses ecosystem tooling | Igniter, usage_rules, AGENTS.md |

## Prerequisites

### Beads CLI (Required)

This configuration requires [beads](https://github.com/steveyegge/beads) - a git-backed issue tracker designed for AI agents.

Install beads:

```bash
# Via Homebrew (macOS/Linux)
brew install steveyegge/beads/bd

# Or via npm
npm install -g @beads/bd

# Or via Go
go install github.com/steveyegge/beads/cmd/bd@latest
```

See the [beads documentation](https://github.com/steveyegge/beads#readme) for detailed setup instructions.

### Claude Code Settings

Enable extended thinking and install these plugins:

```json
{
  "alwaysThinkingEnabled": true,
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true,
    "code-review@claude-plugins-official": true
  }
}
```

You can set these via `claude config` or in your settings file.

| Plugin | Used By |
|--------|---------|
| `feature-dev` | `/next-feature` and `/review-loop` use explorer/architect/reviewer subagents |
| `code-review` | Standalone PR reviews via `/code-review` |
| `playwright` | `/browser-check` uses this for UI verification |
| `frontend-design` | Quality UI component generation |
| `context7` | Up-to-date library documentation |

## Quick Start

### 1. Copy to Your Project

```bash
# Clone and copy
git clone https://github.com/CallumVass/dotclaude.git
cp -r dotclaude/.claude your-project/

# Or use degit
npx degit CallumVass/dotclaude/.claude your-project/.claude
```

> **Already have a `.claude/` folder?** Degit will refuse by default.
> Back up your existing config first, or manually copy only the
> `rules/` and `skills/` subdirectories you need.

### 2. Initialize Your Project

Run `/init-project` which will:
- Ask for your tech stack (or auto-detect)
- Create CLAUDE.md with inlined rules for your stack
- Initialize beads for issue tracking
- Set up the project structure

Rules are **inlined directly into CLAUDE.md** - no need to manage separate rule files in your project.

> **Upgrading?** If you have existing `PROGRESS.md` or `PRD.md` files from an older dotclaude version, `/init-project` will offer to migrate them to beads.

### 3. Start Building

```
/init-project    # Initialize beads + create CLAUDE.md
/next-feature    # Full feature workflow with beads tracking
/review-loop     # Standalone review-fix cycle (used by next-feature)
/browser-check   # UI verification with Playwright
/commit          # Standardized conventional commits (built-in)
```

## Workflow

```
/init-project → /next-feature → /commit → repeat
```

- `/init-project` initializes beads, creates CLAUDE.md, and sets up issue hierarchy
- `/next-feature` uses `bd ready` to find work, `bd close` to complete tasks
- Beads syncs automatically with git for persistent tracking

## Beads Commands

| Action | Command |
|--------|---------|
| Find ready work | `bd ready` |
| Show task details | `bd show <id>` |
| Create new task | `bd create "Title" -t task -p 1` |
| Complete task | `bd close <id>` |
| Sync to git | `bd sync` |

## Elixir Projects

Elixir uses ecosystem tooling instead of prescriptive rules:

```bash
mix igniter.install claude
```

This automatically:
- Adds `usage_rules` dependency
- Creates/updates `CLAUDE.md` with links to dependency rules
- Syncs rules from all deps to `deps/` folder (keeps context lean)

To manually re-sync after adding dependencies:

```bash
mix usage_rules.sync CLAUDE.md --all --link-to-folder deps
```

Phoenix 1.8+ generates `AGENTS.md` which Claude reads automatically.

## Structure

```
.claude/
├── settings.local.json     # Permissions
├── rules/                  # Reference rules (inlined by /init-project)
│   ├── patterns.md         # Universal patterns
│   ├── typescript/         # TS/Vue/React rules
│   ├── dotnet/             # C#/F# rules
│   └── elixir/             # Ecosystem tooling guide
├── skills/
│   ├── init-project/       # Beads init + rules inlining
│   ├── next-feature/       # Feature workflow with beads
│   ├── review-loop/        # Review-fix cycle
│   └── browser-check/      # UI verification
└── templates/
    └── CLAUDE.md           # Project template
```

**Note**: The `rules/` folder contains reference rules that get inlined into your project's CLAUDE.md during `/init-project`. You don't need to copy these to your project separately.

## License

MIT - Use however you like.
