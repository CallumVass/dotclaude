# Claude Code Configuration

Generic project configuration for Claude Code that works across multiple tech stacks.

## Supported Stacks

- **TypeScript**: Vue, React, Node.js
- **.NET**: C#, F#
- **Elixir**: Phoenix

## Quick Start

### 1. Copy to Your Project

Copy this `.claude/` directory to your project root.

### 2. Configure for Your Stack

Edit `settings.local.json` to include relevant rules:

**TypeScript/Vue:**
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

**TypeScript/React:**
```json
{
  "rules": {
    "include": [
      ".claude/rules/patterns.md",
      ".claude/rules/typescript/core.md",
      ".claude/rules/typescript/react.md"
    ]
  }
}
```

**.NET/C#:**
```json
{
  "rules": {
    "include": [
      ".claude/rules/patterns.md",
      ".claude/rules/dotnet/core.md",
      ".claude/rules/dotnet/csharp.md"
    ]
  }
}
```

**.NET/F#:**
```json
{
  "rules": {
    "include": [
      ".claude/rules/patterns.md",
      ".claude/rules/dotnet/core.md",
      ".claude/rules/dotnet/fsharp.md"
    ]
  }
}
```

**Elixir/Phoenix:**

Elixir uses ecosystem tooling instead of prescriptive rules. See [Elixir Setup](#elixir-setup) below.

### 3. Initialize Your Project

Run `/init-project` to:
- Generate a PRD.md with your requirements
- Create a PROGRESS.md to track work
- Set up the project structure

## Skills

### `/init-project`

Start a new project or document an existing one. Guides you through brainstorming and generates:
- `docs/PRD.md` - Product requirements
- `docs/PROGRESS.md` - Progress tracker

### `/next-feature`

Pick the next feature to work on. Reads PROGRESS.md and suggests related items to tackle together.

```
/next-feature          # Auto-suggest based on progress
/next-feature auth     # Focus on auth-related items
/next-feature UI       # Focus on UI work
```

### `/review-merge`

Review code changes and update progress:
1. Invokes the `code-review` plugin for thorough review
2. Updates PROGRESS.md with completed items
3. Guides merge workflow

### `/browser-check`

Verify UI in the browser using Playwright:

```
/browser-check http://localhost:3000 "Verify login form works"
```

## Directory Structure

```
.claude/
├── settings.local.json     # Project-specific permissions
├── README.md               # This file
├── rules/
│   ├── patterns.md         # Universal patterns
│   ├── typescript/
│   │   ├── core.md         # TypeScript fundamentals
│   │   ├── vue.md          # Vue/Nuxt specific
│   │   └── react.md        # React/Next.js specific
│   ├── dotnet/
│   │   ├── core.md         # .NET fundamentals
│   │   ├── csharp.md       # C# specific
│   │   └── fsharp.md       # F# specific
│   └── elixir/
│       └── setup.md        # Points to ecosystem tooling
├── skills/
│   ├── init-project/       # Project initialization
│   ├── next-feature/       # Feature selection
│   ├── review-merge/       # Code review + progress update
│   └── browser-check/      # UI verification
└── templates/
    ├── PRD.md              # Product requirements template
    └── PROGRESS.md         # Progress tracker template
```

## Workflow

1. **Start**: `/init-project` - Define what you're building
2. **Plan**: `/next-feature` - Pick work items
3. **Build**: `/feature-dev` - Architecture-first development
4. **Review**: `/review-merge` - Review, update progress, merge
5. **Repeat**: Back to step 2

## Elixir Setup

See `.claude/rules/elixir/setup.md` for detailed instructions.

Quick start:
```bash
# Add {:igniter, "~> 0.6", only: [:dev, :test]} to mix.exs
mix deps.get
mix igniter.install usage_rules
mix usage_rules.sync --all
```

## Customization

### Adding Project-Specific Rules

Create additional rule files in `.claude/rules/`:

```markdown
---
paths: ["src/specific/**/*.ts"]
---

# My Custom Rules

Rules specific to this project...
```

### Adding Custom Skills

Create a new skill in `.claude/skills/my-skill/skill.md`:

```markdown
---
name: my-skill
description: What it does
user_invocable: true
---

# My Skill

Instructions for the skill...
```

Then add to permissions in `settings.local.json`:
```json
"Skill(my-skill)"
```
