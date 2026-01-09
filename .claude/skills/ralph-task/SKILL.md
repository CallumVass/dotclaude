---
name: ralph-task
description: Autonomous single-iteration task execution. Picks a beads issue, implements with tests, reviews, and auto-merges. Use with external loop script. Outputs promise word on completion.
arguments:
  - name: issue
    description: Specific issue ID (defaults to next from bd ready)
    required: false
---

# Ralph Task (Autonomous Single Iteration)

Complete ONE beads issue autonomously. Designed to be called in a loop by external script.

## Promise Words

Output EXACTLY ONE of these at the END of your response:

| Word | Meaning |
|------|---------|
| `<promise>COMPLETE</promise>` | Task complete, merged successfully. Loop can continue. |
| `<promise>NO_ISSUES</promise>` | No issues available in bd ready. Loop should stop. |
| `<promise>BLOCKED</promise>` | Blocked - needs human intervention. Loop should stop. |

## Constraints

- **No user interaction** - make all decisions autonomously
- **No AskUserQuestion** - this is fully autonomous
- **No subagent spawning** - do codebase exploration directly with Grep/Glob/Read
- **Max 3 code review cycles** - if `/code-review` fails 3 times, output BLOCKED
- **Boundary tests mandatory** - task not complete without them
- **Auto-merge on success** - merge PR when review passes

## Process

### 1. Check for Issues

If `issue` argument provided, use that. Otherwise:

```bash
bd ready --json
```

Parse JSON output. If empty array or no issues, output:

```
No issues available in beads.
<promise>NO_ISSUES</promise>
```

And stop.

Select top issue. Note the issue ID (e.g., `bd-a1b2`).

### 2. Create Feature Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/bd-xxx-short-description
```

Use issue ID and slugified title. Example: `feature/bd-a1b2-add-user-auth`

### 3. Explore Codebase

Directly explore using Grep, Glob, Read tools:

1. Search for keywords from issue description
2. Find similar existing features
3. Read relevant files (5-10 max)
4. Identify:
   - Entry points to modify
   - Patterns to follow
   - Test patterns to match
   - Dependencies to consider

Do NOT spawn agents - do this exploration yourself.

### 4. Implement

Build the feature following codebase conventions discovered during exploration.

**Implementation rules:**
- Follow existing patterns exactly
- Match code style of surrounding code
- Keep changes focused on issue scope

**Boundary tests are mandatory:**

| If you create... | You must create... |
|------------------|-------------------|
| Vue/React component | Component test (mount, interact, assert) |
| LiveView | LiveViewTest with `live()` |
| Controller/API endpoint | Request test (HTTP in, response out) |
| CLI command | Integration test (invoke, check output) |
| Service/context function | Tested via boundary that uses it |

### 5. Run Quality Checks

Detect project type and run appropriate quality commands. Common patterns:

**Node.js (package.json):**
```bash
npm install && npm run lint && npm test
```

**Elixir (mix.exs):**
```bash
mix deps.get && mix compile --warnings-as-errors && mix test && mix format --check-formatted
```

**.NET (*.sln/*.csproj):**
```bash
dotnet restore && dotnet build && dotnet test
```

If quality checks fail:
- Analyse failure output
- Fix issues
- Re-run quality checks
- Max 3 attempts, then output `<promise>BLOCKED</promise>`

### 6. Commit and Push

```bash
bd status <issue-id> done
git add -A
git commit -m "Description (bd-xxx)"
git push -u origin HEAD
bd sync
```

### 7. Create PR

```bash
gh pr create --title "Description (bd-xxx)" --body "$(cat <<'EOF'
## Summary
[1-3 bullet points from implementation]

## Test Plan
- [x] Boundary tests added
- [x] Quality checks pass

Closes bd-xxx
EOF
)"
```

Capture PR URL/number from output.

### 8. Code Review Loop (Max 3 iterations)

```
review_count = 0

LOOP:
  review_count += 1

  IF review_count > 3:
    Output: "Code review exceeded 3 iterations. Human review required."
    Output: <promise>BLOCKED</promise>
    STOP

  Run /code-review (the Anthropic code-review plugin)

  IF issues found:
    Fix issues
    git add -A
    git commit --amend --no-edit
    git push --force-with-lease
    CONTINUE LOOP

  IF no issues:
    EXIT LOOP
```

### 9. Verify CI (if applicable)

```bash
gh pr checks
```

If checks are failing:
- Read failure output
- Attempt fix (max 2 attempts)
- If still failing, output `<promise>BLOCKED</promise>`

### 10. Auto-Merge

```bash
gh pr merge --squash --delete-branch
```

If merge fails (e.g., conflict):
- Output `<promise>BLOCKED</promise>` with error details

### 11. Cleanup

```bash
git checkout main
git pull origin main
```

### 12. Complete

Output summary of what was built:

```
## Completed: [Issue Title]

- Created: [files created]
- Modified: [files modified]
- Tests: [test files]
- PR: [PR URL]

<promise>COMPLETE</promise>
```

---

## Failure States

| Situation | Action |
|-----------|--------|
| No issues in bd ready | Output `<promise>NO_ISSUES</promise>` |
| Quality checks fail 3x | Output `<promise>BLOCKED</promise>` with error details |
| Code review exceeds 3 iterations | Output `<promise>BLOCKED</promise>` |
| CI checks fail after fixes | Output `<promise>BLOCKED</promise>` |
| Merge conflict | Output `<promise>BLOCKED</promise>` |
| Any unexpected error | Output `<promise>BLOCKED</promise>` with context |

Always include context about what went wrong when outputting BLOCKED.

---

## Example Output (Success)

```
## Completed: Add user avatar upload (bd-a1b2)

- Created: src/components/ImageUpload.vue, src/components/__tests__/ImageUpload.spec.ts
- Modified: src/pages/settings/profile.vue, src/api/users.ts
- Tests: Component test for ImageUpload, request test for avatar endpoint
- PR: https://github.com/owner/repo/pull/123 (merged)

<promise>COMPLETE</promise>
```

## Example Output (Blocked)

```
## Blocked: Add user avatar upload (bd-a1b2)

Code review identified issues that could not be resolved after 3 iterations:
- Security concern: File upload validation insufficient
- Need human decision on max file size policy

PR: https://github.com/owner/repo/pull/123 (open, needs review)

<promise>BLOCKED</promise>
```
