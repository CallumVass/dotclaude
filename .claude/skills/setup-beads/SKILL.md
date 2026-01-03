---
name: setup-beads
description: Initialize beads issue tracker with protected branch workflow. Use when user says "setup beads", "init beads", "add beads".
arguments:
  - name: branch
    description: Sync branch name (defaults to beads-sync)
    required: false
---

# Setup Beads

Initialize beads with protected branch workflow for feature branch development.

## Constraints

- Require `bd` CLI installed before proceeding
- Use protected branch workflow (git worktrees) by default
- Add agent workflow rules to CLAUDE.md
- Get user confirmation before making changes

## Process

1. Check `bd` is installed (`bd version`). If not, show install instructions:
   ```
   brew tap steveyegge/beads && brew install bd
   ```
   Or: `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`

2. Initialize with protected branch workflow:
   ```
   bd init --quiet --branch beads-sync
   ```
   Use custom branch name if `branch` argument provided.

3. Set up Claude Code integration:
   ```
   bd setup claude
   ```

4. Install git hooks for automatic sync:
   ```
   bd hooks install
   ```

5. Start the daemon with auto-commit:
   ```
   bd daemon --start --auto-commit
   ```

6. Run `bd doctor` and resolve any issues:
   - Fix all errors and warnings reported
   - Re-run until clean
   - Common fixes: missing hooks, orphaned issues, sync state

7. Append beads workflow rules to CLAUDE.md (see below).

8. Report what was configured.

## Agent Workflow Rules

Add this to CLAUDE.md:

```markdown
## Beads Workflow

Use `bd` for task tracking. Key rules:

**All dev work through beads**: When user asks for any development or design work (features, fixes, refactoring), first create a beads issue, then invoke `/next-feature` to work on it. This ensures all work is tracked, uses feature branches, and follows the proper workflow.

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
