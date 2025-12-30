# dotclaude

Reusable [Claude Code](https://claude.ai/code) configuration for multi-stack projects.

## What's This?

Like dotfiles for your shell, this is a portable `.claude/` configuration with:

- **Skills**: `/init-project`, `/next-feature`, `/review-loop`, `/browser-check`
- **Rules**: Stack-specific patterns for TypeScript, .NET, and Elixir
- **Templates**: PRD and progress tracking documents

## Supported Stacks

| Stack | Rules | Notes |
|-------|-------|-------|
| TypeScript/Vue | `typescript/core.md` + `typescript/vue.md` | Composition API, UnoCSS/Tailwind |
| TypeScript/React | `typescript/core.md` + `typescript/react.md` | Hooks, Next.js App Router |
| .NET/C# | `dotnet/core.md` + `dotnet/csharp.md` | Minimal APIs, EF Core |
| .NET/F# | `dotnet/core.md` + `dotnet/fsharp.md` | Result types, Railway-oriented |
| Elixir/Phoenix | Uses ecosystem tooling | Igniter, usage_rules, AGENTS.md |

## Prerequisites

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

### 2. Keep Rules for Your Stack

Delete rules you don't need. All `.md` files in `.claude/rules/` auto-load:

```
.claude/rules/
├── patterns.md              # Keep - universal patterns
├── typescript/              # Keep if using TypeScript
├── dotnet/                  # Delete if not using .NET
└── elixir/                  # Delete if not using Elixir
```

For path-specific rules, add YAML frontmatter:

```markdown
---
paths: src/**/*.ts
---
# These rules only apply to TypeScript files
```

### 3. Start Building

```
/init-project    # Brainstorm, generate PRD & progress tracker
/next-feature    # Full feature workflow with auto-review loop
/review-loop     # Standalone review-fix cycle (used by next-feature)
/browser-check   # UI verification with Playwright
/commit          # Standardized conventional commits (built-in)
```

## Workflow

```
/init-project → /next-feature → /commit → repeat
```

`/next-feature` handles the full cycle: exploration, architecture, implementation, and review loop.

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
├── rules/
│   ├── patterns.md         # Universal patterns
│   ├── typescript/         # TS/Vue/React rules
│   ├── dotnet/             # C#/F# rules
│   └── elixir/             # Setup guide (defers to tooling)
├── skills/
│   ├── init-project/       # Project scaffolding
│   ├── next-feature/       # Full feature workflow
│   ├── review-loop/        # Iterative review-fix cycle
│   └── browser-check/      # UI verification
└── templates/
    ├── PRD.md              # Product requirements
    └── PROGRESS.md         # Progress tracker
```

## License

MIT - Use however you like.
