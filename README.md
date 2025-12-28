# dotclaude

Reusable [Claude Code](https://claude.ai/claude-code) configuration for multi-stack projects.

## What's This?

Like dotfiles for your shell, this is a portable `.claude/` configuration with:

- **Skills**: `/init-project`, `/next-feature`, `/review-merge`, `/browser-check`
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
| `feature-dev` | `/next-feature` recommends this for implementation planning |
| `code-review` | `/review-merge` uses this for code review |
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

### 2. Configure for Your Stack

Edit `.claude/settings.local.json`:

```json
{
  "rules": {
    "include": [
      ".claude/rules/patterns.md",
      ".claude/rules/typescript/core.md",
      ".claude/rules/typescript/vue.md"
    ]
  }
}
```

### 3. Start Building

```
/init-project    # Brainstorm, generate PRD & progress tracker
/next-feature    # Pick next work items
/feature-dev     # Plan implementation (built-in plugin)
/commit          # Standardized conventional commits
/review-merge    # Review code, update progress, merge
```

## Workflow

```
/init-project → /next-feature → /feature-dev → /review-merge → repeat
```

## Elixir Projects

Elixir uses ecosystem tooling instead of prescriptive rules:

```elixir
# Add igniter to mix.exs
{:igniter, "~> 0.6", only: [:dev, :test]}
```

```bash
mix deps.get
mix igniter.install usage_rules
mix usage_rules.sync --all
```

Phoenix 1.8+ generates `AGENTS.md` which Claude will read automatically.

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
│   ├── next-feature/       # Feature selection
│   ├── review-merge/       # Code review + progress
│   └── browser-check/      # UI verification
└── templates/
    ├── PRD.md              # Product requirements
    └── PROGRESS.md         # Progress tracker
```

## License

MIT - Use however you like.
