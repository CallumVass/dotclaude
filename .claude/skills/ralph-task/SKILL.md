---
name: ralph-task
description: Autonomous single-iteration beads task execution. Picks a beads issue, implements with tests, reviews, and auto-merges. Use with external loop script. Outputs promise word on completion. Use when user says "ralph", "autonomous task", "run ralph", "auto-implement".
---

# Ralph Task (Autonomous Single Iteration)

Complete ONE beads issue autonomously. Designed to be called in a loop by external script.

## Promise Words

Output EXACTLY ONE at the END of your response:

| Word | Meaning |
|------|---------|
| `<promise>COMPLETE</promise>` | Task merged successfully. Loop can continue. |
| `<promise>NO_ISSUES</promise>` | No issues in bd ready. Loop should stop. |
| `<promise>BLOCKED</promise>` | Needs human intervention. Loop should stop. |

**CRITICAL: Every execution path must end with exactly one promise word. When in doubt, use BLOCKED.**

## Constraints

- **No user interaction** - fully autonomous, no AskUserQuestion
- **No skill invocation by default** - do NOT run skills unless explicitly specified in the issue's Agent Instructions section
- **ONLY spawn feature-dev:code-reviewer** - for code review in step 8
- **Max 3 code review cycles** - then output BLOCKED
- **Boundary tests mandatory** - task not complete without them
- **ALL acceptance criteria mandatory** - every AC item must be completed
- **ALL mandatory constraints from CLAUDE.md apply** - check for "Mandatory Constraints" section
- **Auto-merge on success**

---

## Process

### 0. Check for In-Progress Work (Resume Detection)

**ALWAYS check this first.**

```bash
bd list --status=in_progress --json
```

If in-progress issue exists:
1. Read issue requirements with `bd show <issue-id>`
2. Check for existing branch: `git branch -a | grep -i <issue-id>`
3. Check for existing PR: `gh pr list --head "feature/<issue-id>" --json number,state,url`
4. Assess current state and determine resume point:

| State | Resume From |
|-------|-------------|
| PR exists and OPEN | Step 8 (code review) |
| Branch has commits, quality passes, no PR | Step 7 (create PR) |
| Branch has commits, quality fails | Step 5 (fix issues) |
| Branch has commits, implementation incomplete | Step 4 (continue) |
| Branch exists but empty | Step 3 (explore) |
| No branch exists | Step 2 (create branch) |

### 1. Get Next Issue

If no in-progress issue, check for new work:

```bash
bd ready --json
```

If empty: output `<promise>NO_ISSUES</promise>` and stop.

Otherwise, mark top issue as in-progress:
```bash
bd update <issue-id> --status=in_progress
```

### 2. Create Feature Branch

```bash
git checkout main && git pull origin main
git checkout -b feature/<issue-id>-short-description
```

### 3. Explore Codebase

Use Grep, Glob, Read directly (no agents):
- Search for keywords from issue
- Find similar features
- Read 5-10 relevant files
- Identify entry points, patterns, test patterns

### 4. Implement

Build feature following codebase conventions.

**Boundary tests are mandatory:**

| Created | Required Test |
|---------|---------------|
| Vue/React component | Component test (mount, interact, assert) |
| LiveView | LiveViewTest with `live()` |
| Controller/API | Request test (HTTP in, response out) |
| CLI command | Integration test |

### 5. Run Quality Checks

Detect project type and run appropriate commands:

- **Node.js**: `npm install && npm run lint && npm test`
- **Elixir**: `mix deps.get && mix compile --warnings-as-errors && mix test && mix format --check-formatted`
- **.NET**: `dotnet restore && dotnet build && dotnet test`

If fails 3x: output `<promise>BLOCKED</promise>`

### 6. Commit and Push

```bash
git add -A
git commit -m "Description (bd-xxx)"
git push -u origin HEAD
```

### 7. Create PR

```bash
gh pr create --title "Description (bd-xxx)" --body "$(cat <<'EOF'
## Summary
[1-3 bullet points]

## Test Plan
- [x] Boundary tests added
- [x] Quality checks pass

Closes bd-xxx
EOF
)"
```

### 8. Code Review Loop (Max 3 iterations)

Get changed files: `git diff --name-only main...HEAD`

Loop (max 3):
1. Spawn `feature-dev:code-reviewer` with files, AC, and mandatory constraints from CLAUDE.md
2. If "NO ISSUES FOUND": exit loop, continue to step 8.5
3. For each issue found:
   - **[AC] and [MC] issues are NON-DISMISSIBLE** - must fix or BLOCK
   - Fix the issue
4. Commit fixes: `git commit --amend --no-edit && git push --force-with-lease`
5. Continue loop

If exceeds 3 iterations: output `<promise>BLOCKED</promise>`

### 8.5 AC Verification (MANDATORY)

Before step 9, verify EVERY acceptance criterion:

1. Parse each AC item from the issue
2. For each: state criterion, describe implementation, verify it works, mark DONE or NOT DONE
3. Also verify relevant mandatory constraints from CLAUDE.md
4. If ANY item NOT DONE: implement it NOW or output `<promise>BLOCKED</promise>`

See [references/examples.md](references/examples.md) for verification format.

### 9. Verify CI

```bash
gh pr checks
```

If failing: attempt fix (max 2), then `<promise>BLOCKED</promise>` if still failing.

### 10. Auto-Merge

```bash
gh pr merge --squash --delete-branch
```

If fails: output `<promise>BLOCKED</promise>`

### 11. Cleanup

```bash
git checkout main && git pull origin main
bd close <issue-id>
bd sync
```

### 12. Complete

Output summary and promise word:

```
## Completed: [Issue Title]

- Created: [files]
- Modified: [files]
- Tests: [test files]
- PR: [URL]

<promise>COMPLETE</promise>
```

---

## Failure States

| Situation | Action |
|-----------|--------|
| No issues in bd ready | `<promise>NO_ISSUES</promise>` |
| Quality checks fail 3x | `<promise>BLOCKED</promise>` |
| Code review exceeds 3 iterations | `<promise>BLOCKED</promise>` |
| AC item not met | `<promise>BLOCKED</promise>` |
| MC violated | `<promise>BLOCKED</promise>` |
| CI fails after fixes | `<promise>BLOCKED</promise>` |
| Merge conflict | `<promise>BLOCKED</promise>` |
| Unexpected error | `<promise>BLOCKED</promise>` |

**NEVER end without a promise word.**
