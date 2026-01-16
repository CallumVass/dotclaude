---
name: setup
description: Initialize project with stack-specific rules and beads issue tracker. Supports dotnet-csharp, dotnet-fsharp, typescript-react, typescript-vue, elixir, elixir-livevue. Use when user says "setup", "init", "setup rules", "setup beads", "bootstrap", "configure project".
---

# Setup

Initialize a new project with stack-specific coding rules and beads issue tracking.

## Constraints

- Never overwrite existing CLAUDE.md content - append to it
- Copy rules verbatim from ~/.claude/rules/ - no interpretation
- Get user confirmation before making changes
- Beads setup is optional if `bd` is not installed

## Process

### 1. Detect Stack

Scan project root for these indicators:

| Found | Stack |
|-------|-------|
| `*.csproj` or `*.sln` with `*.cs` files | dotnet-csharp |
| `*.fsproj` or `*.sln` with `*.fs` files | dotnet-fsharp |
| `package.json` with `react` dep or `*.tsx` | typescript-react |
| `package.json` with `vue` dep or `*.vue` | typescript-vue |
| `mix.exs` with `live_vue` dep | elixir-livevue |
| `mix.exs` | elixir |

If `stack` argument provided, use that instead of auto-detection.

### 2. Confirm with User

Present detected stack and ask for confirmation:
- Show which rule file will be copied
- Ask if they want beads setup (if `bd` is available)

### 3. Copy Rules

Copy the appropriate rule file from `~/.claude/rules/` to project's CLAUDE.md:

```bash
# Example for typescript-react
cat ~/.claude/rules/typescript-react.md >> CLAUDE.md
```

If CLAUDE.md exists, append. If not, create it.

### 4. Setup Beads (if requested)

Check if `bd` is installed:

```bash
bd version
```

If not installed, show install instructions and skip beads setup:
```
brew tap steveyegge/beads && brew install bd
```
Or: `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`

If installed, run:

```bash
bd init --quiet --branch beads-sync
bd setup claude
bd hooks install
bd daemon --start --auto-commit
bd doctor
```

Resolve any issues reported by `bd doctor`.

### 5. Copy Ralph Scripts

Copy the ralph automation scripts to the project:

```bash
cp -r ~/.claude/scripts ./scripts
```

This provides `scripts/ralph.sh` and `scripts/ralph.ps1` for autonomous workflow.

### 6. Add Beads Workflow to CLAUDE.md

If beads was set up, append this to CLAUDE.md:

```markdown

## Beads Workflow

Use `bd` for task tracking. Key rules:

**All dev work through beads**: When user asks for any development or design work (features, fixes, refactoring), first create a beads issue. This ensures all work is tracked and follows the proper workflow.

**Session end**: Always run `bd sync` to export, commit, and push changes.

**Land the plane**: Never say "ready to push when you are." The plane hasn't landed until `git push` succeeds. Always:
1. File remaining work as issues
2. Run quality gates (lint, test)
3. Update issue statuses
4. Push to remote

**Commits**: Include issue IDs in commit messages: `git commit -m "Fix bug (bd-abc)"`

**Agent output**: Use `--json` flag for machine-readable output.

**Commands**:
- `bd ready` - show next actionable tasks
- `bd create "title"` - create new issue
- `bd status <id> done` - mark complete
- `bd sync` - sync and push
```

### 7. Report

Summarise what was configured:
- Stack rules copied
- Ralph scripts copied
- Beads setup status
- Any manual steps needed

Surface any post-setup commands:

**Elixir / Elixir-LiveVue**:
- Check for `AGENTS.md` (Phoenix 1.8+) and read it for project-specific guidance
- Run `mix igniter.install claude` to sync dependency rules

**TypeScript** (if no node_modules):
```
npm install
```

**.NET** (if no obj/bin):
```
dotnet restore
```
