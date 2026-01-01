---
name: init-project
description: Initialize a new project with CLAUDE.md (including inlined rules) and beads issue tracking. Brainstorms ideas, asks clarifying questions, and sets up structured task tracking.
user_invocable: true
arguments:
  - name: name
    description: Project name (optional - will prompt if not provided)
    required: false
  - name: stack
    description: Tech stack hint (typescript, dotnet, elixir, or auto-detect)
    required: false
---

# Init Project

Guides you through initializing a new project or documenting an existing one.

Uses [beads](https://github.com/steveyegge/beads) for git-backed issue tracking and inlines relevant rules directly into CLAUDE.md.

## Process

### 0. Beads Check (First!)

Before anything else, verify beads is installed:

```bash
bd --version
```

**If beads is NOT installed**, ask the user:

```
Beads is required for task tracking but isn't installed.

Would you like me to install it? (y/n)

Installation options:
1. npm install -g @beads/bd (recommended for most users)
2. brew install steveyegge/beads/bd (macOS/Linux with Homebrew)
3. go install github.com/steveyegge/beads/cmd/bd@latest (if you have Go)
```

If user says yes, run the appropriate install command based on their environment:
- If `npm` is available: `npm install -g @beads/bd`
- If `brew` is available (macOS/Linux): `brew install steveyegge/beads/bd`
- If `go` is available: `go install github.com/steveyegge/beads/cmd/bd@latest`

After installation, verify with `bd --version` before proceeding.

If user says no, explain they can still create CLAUDE.md but beads features won't be available.

---

### 1. Discovery Phase

First, understand what we're working with:

**For new projects:**
- What problem are we solving?
- Who are the users?
- What's the core value proposition?
- What tech stack are we using?

**For existing projects:**
- Scan the codebase structure
- Identify the tech stack from config files
- Understand current state
- Check for existing PROGRESS.md/PRD.md (offer migration)

### 2. Stack Detection

If stack not provided, detect from these indicators:

| Stack | Indicators |
|-------|-----------|
| TypeScript/Vue | `package.json` with vue, `nuxt.config.ts`, `.vue` files |
| TypeScript/React | `package.json` with react, `next.config.js`, `.tsx` files |
| .NET/C# | `*.csproj`, `*.sln`, `Program.cs` |
| .NET/F# | `*.fsproj`, `*.fs` files |
| Elixir | `mix.exs`, `*.ex` files, `lib/` folder |
| Phoenix | `mix.exs` with phoenix dep, `_web/` folders |

**If detection is ambiguous, ask the user:**

```
Which tech stack is this project using?

1. TypeScript/Vue
2. TypeScript/React
3. .NET/C#
4. .NET/F#
5. Elixir/Phoenix
```

### 3. Migration Check

**If `docs/PROGRESS.md` or `docs/PRD.md` exist:**

Ask user: "Found existing PROGRESS.md/PRD.md. Import to beads? (y/n)"

If yes, proceed to Migration section below before continuing.

### 4. Brainstorming (New Projects)

Ask clarifying questions:

1. **Core Features**: What are the 3-5 must-have features for MVP?
2. **User Flows**: What's the primary user journey?
3. **Data Model**: What are the main entities?
4. **Constraints**: Any technical requirements? (offline, real-time, etc.)
5. **Timeline**: What's the scope? (weekend project vs. long-term)

### 5. Generate CLAUDE.md with Inlined Rules

Create `CLAUDE.md` that includes:
1. Project-specific documentation (vision, stack, data model)
2. Inlined rules from the detected stack

**Read and inline these rule files based on stack:**

| Stack | Rules to Inline |
|-------|-----------------|
| TypeScript/Vue | `patterns.md` + `typescript/core.md` + `typescript/vue.md` |
| TypeScript/React | `patterns.md` + `typescript/core.md` + `typescript/react.md` |
| .NET/C# | `patterns.md` + `dotnet/core.md` + `dotnet/csharp.md` |
| .NET/F# | `patterns.md` + `dotnet/core.md` + `dotnet/fsharp.md` |
| Elixir/Phoenix | `patterns.md` + `elixir/setup.md` |

**CLAUDE.md Structure:**

```markdown
# [Project Name]

## Overview

[Brief description of what this project does]

## Vision

[One-liner describing the goal]

## Problem

[What problem does this solve?]

## Users

[Who is this for?]

## Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Frontend | [Choice] | [Why] |
| Backend | [Choice] | [Why] |
| Database | [Choice] | [Why] |

## Key Commands

```bash
[dev command]      # Development
[test command]     # Test
[build command]    # Build
```

## Data Model

### [Entity 1]

- id, field1, field2

### [Entity 2]

- id, field1, field2

## Architecture

[High-level architecture notes]

## Conventions

- [Convention 1]
- [Convention 2]

---

*Run `bd ready` for available work. Run `bd show <id>` for task details.*

---

# Development Rules

[INLINE CONTENTS OF patterns.md HERE]

---

# [Stack Name] Rules

[INLINE CONTENTS OF stack-specific rules HERE]
```

**Important**: When inlining rules, copy the full content but remove any YAML frontmatter (the `---` blocks at the top).

### 6. Initialize Beads

Run these commands to set up beads:

```bash
# Initialize beads in the project
bd init

# Set up Claude Code hooks
bd setup claude --project
```

**Important**: Beads creates an `AGENTS.md` file, but Claude Code doesn't auto-read it. After beads init:

1. Read the generated `AGENTS.md`
2. Append its contents to the end of `CLAUDE.md` (under a `## Beads Workflow` section)
3. Delete `AGENTS.md`

This ensures Claude has the beads workflow instructions in its context.

### 7. Create Issues from Brainstorming

Convert the brainstormed features into a beads issue hierarchy:

**Structure:**
- **Epics** = Phases (Phase 1: MVP, Phase 2, etc.)
- **Features** = Feature groups
- **Tasks** = Individual work items

**Example commands:**

```bash
# Create phase epic
bd create "Phase 1: MVP" -t epic -p 0 --json
# Returns: {"id": "bd-abc123", ...}

# Create feature under epic
bd create "User Authentication" -t feature --parent bd-abc123 --json
# Returns: {"id": "bd-abc123.1", ...}

# Create tasks under feature
bd create "Implement login endpoint" -t task -p 1 --parent bd-abc123.1 --json
bd create "Add session handling" -t task -p 1 --parent bd-abc123.1 --json
bd create "Create registration form" -t task -p 2 --parent bd-abc123.1 --json

# Open questions become labeled issues
bd create "Should we support SSO?" -t task -l question -p 3 --json
```

**Priority levels:**
- P0: Critical/blocking
- P1: High priority (MVP must-have)
- P2: Medium priority (nice-to-have)
- P3: Low priority (future consideration)

### 8. Cleanup

After CLAUDE.md is created with inlined rules, remove redundant files:

```bash
# Remove rules (now inlined into CLAUDE.md)
rm -rf .claude/rules/

# Remove templates (used once, no longer needed)
rm -rf .claude/templates/
```

**Keep these** (still required):
- `.claude/skills/` - needed for `/next-feature`, `/review-loop`, `/browser-check`
- `.claude/settings.local.json` - permissions

### 9. Output & Restart

Report back with:

1. Created/updated files (CLAUDE.md with inlined rules)
2. Tech stack detected/selected
3. Beads initialized: show `bd ready` output
4. Files cleaned up (rules removed)

**Then instruct the user:**

```
## Setup Complete!

Please restart Claude Code to pick up the new configuration:
- CLAUDE.md with your project info and inlined rules
- Beads hooks for task tracking

After restart, run `/next-feature` to begin work.
```

**Important**: The restart is necessary for Claude to load the new CLAUDE.md context and beads hooks.

---

## Migration (from PROGRESS.md/PRD.md)

If the user accepts migration from existing files:

### Step 1: Initialize Beads

```bash
bd init
bd setup claude --project
```

### Step 2: Parse and Import PROGRESS.md

For each phase in PROGRESS.md:

1. Create an epic: `bd create "Phase N: [Name]" -t epic -p 0 --json`

For each feature group under the phase:

2. Create a feature: `bd create "[Feature Group]" -t feature --parent <epic-id> --json`

For each task in the feature group:

3. Create a task: `bd create "[Task]" -t task --parent <feature-id> --json`
4. If task was checked `[x]`, immediately close it: `bd close <task-id> --reason "Previously completed"`

### Step 3: Parse and Import PRD.md

1. Extract Vision/Problem/Users/Stack/Data Model sections
2. Add these to CLAUDE.md (merge with existing if present)
3. For any "Open Questions" items:
   - `bd create "[Question]" -t task -l question -p 3 --json`

### Step 4: Archive Original Files

```bash
mkdir -p docs/archive
mv docs/PROGRESS.md docs/archive/PROGRESS.md.bak
mv docs/PRD.md docs/archive/PRD.md.bak
```

### Step 5: Sync

```bash
bd sync
```

Report migration summary:
- Epics created: X
- Features created: X
- Tasks created: X (Y already completed)
- Open questions imported: X

---

## Notes

- Beads installation is checked/offered in Step 0
- Preserve any existing CLAUDE.md content while adding structure
- Use `--json` flag for programmatic parsing of beads output
- Rules are inlined once during init - no need for separate rule files in the project
