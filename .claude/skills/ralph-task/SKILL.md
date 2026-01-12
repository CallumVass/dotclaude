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

## Critical Rule

**YOU MUST OUTPUT EXACTLY ONE PROMISE WORD BEFORE ENDING YOUR RESPONSE.**

No exceptions. Every execution path must end with `<promise>COMPLETE</promise>`, `<promise>NO_ISSUES</promise>`, or `<promise>BLOCKED</promise>`. If you reach the end of your response without having output a promise word, you have failed.

## Constraints

- **No user interaction** - make all decisions autonomously
- **No AskUserQuestion** - this is fully autonomous
- **No general subagent spawning** - do codebase exploration directly with Grep/Glob/Read
- **ONLY spawn feature-dev:code-reviewer** - for code review in step 8, via Task tool
- **No skill invocation** - do NOT run skills like /next-feature, /review-loop, /code-review, etc.
- **Max 3 code review cycles** - if code-reviewer returns issues 3 times in a row, output BLOCKED
- **Boundary tests mandatory** - task not complete without them
- **ALL acceptance criteria mandatory** - every AC item must be completed, no exceptions
- **Auto-merge on success** - merge PR when review passes
- **Follow ALL steps in order** - do not skip steps or stop early without a promise word

## Mandatory Constraints

**In addition to issue-specific acceptance criteria, ALL implementations must satisfy mandatory constraints from the project's CLAUDE.md.**

At the start of any task, check if CLAUDE.md contains a "Mandatory Constraints" section (typically marked with a box like `╔═══...═══╗`). These rules define HOW to build, while AC defines WHAT to build.

Common mandatory constraints include:
- Framework/library choices (e.g., "All UI is Vue components")
- Styling rules (e.g., "Tailwind only, semantic tokens")
- Testing requirements (e.g., "Every feature MUST include tests")
- Accessibility rules (e.g., "44px touch targets")

**These are enforced alongside AC during code review (step 8) and verification (step 8.5).**

---

## Process

**Follow steps 0-12 in order. The ONLY valid exit points are:**
- Step 1: Output `<promise>NO_ISSUES</promise>` if no issues available
- Step 8: Output `<promise>BLOCKED</promise>` if code review exceeds 3 iterations
- Step 8.5: Output `<promise>BLOCKED</promise>` if ANY acceptance criterion is not met
- Step 9: Output `<promise>BLOCKED</promise>` if CI fails after fixes
- Step 10: Output `<promise>BLOCKED</promise>` if merge fails
- Step 12: Output `<promise>COMPLETE</promise>` after successful merge

**Do not stop at any other point without a promise word.**

### 0. Check for In-Progress Work (Resume Detection)

**ALWAYS check this first before looking for new issues.**

```bash
bd list --status=in_progress --json
```

If there's an in-progress issue:

1. **Note the issue ID and read its requirements**
   ```bash
   bd show <issue-id>
   ```

2. **Check for existing branch**
   ```bash
   git branch -a | grep -i <issue-id>
   ```

3. **Check for existing PR**
   ```bash
   gh pr list --head "feature/<issue-id>" --json number,state,url
   ```

4. **If branch exists, assess current state:**
   ```bash
   git checkout <branch-name>
   git log --oneline main..<branch-name>  # What's been committed
   git status                              # Any uncommitted work
   git diff --stat main                    # Overall changes from main
   ```

5. **Compare state to issue requirements and determine resume point:**

   | State | Resume From |
   |-------|-------------|
   | PR exists and OPEN | Step 8 (code review loop) |
   | Branch has commits, quality checks pass, no PR | Step 7 (create PR) |
   | Branch has commits, quality checks fail | Step 5 (fix and re-run quality checks) |
   | Branch has commits but implementation incomplete | Step 4 (continue implementation) |
   | Branch has uncommitted changes | Review changes, then step 4 or 5 |
   | Branch exists but empty (no commits beyond main) | Step 3 (explore codebase) |
   | No branch exists | Step 2 (create branch) |

6. **To assess if implementation is complete:**
   - Read the issue acceptance criteria
   - Check if relevant files were created/modified
   - Run quality checks: `mix compile --warnings-as-errors && mix test`
   - If tests pass and criteria appear met → ready for PR
   - If tests fail or criteria not met → continue implementation

**Example resume scenarios:**

```bash
# Scenario A: Crashed during code review
# - Branch exists, PR exists and open
# - Resume at step 8

# Scenario B: Crashed during implementation
# - Branch exists with some commits
# - git status shows uncommitted changes
# - Tests fail
# - Resume at step 4 (continue implementing)

# Scenario C: Crashed after implementation but before PR
# - Branch exists with commits
# - Tests pass
# - No PR yet
# - Resume at step 7 (create PR)
```

If no in-progress issues found, continue to step 1.

### 1. Check for New Issues

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

Mark it as in-progress:
```bash
bd update <issue-id> --status=in_progress
```

### 2. Create Feature Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/<issue-id>-short-description
```

Use issue ID and slugified title. Example: `feature/kanban-vfa.2-add-user-auth`

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
git add -A
git commit -m "Description (bd-xxx)"
git push -u origin HEAD
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

**IMPORTANT**: This is ONE step in the workflow. You are reviewing YOUR OWN PR that you just created in step 7. After code review completes, you MUST either fix issues or continue to step 9. Do not end here.

**Use `feature-dev:code-reviewer` agent** - DO NOT use the `/code-review` skill. The agent returns issues directly which allows proper fix/re-review cycling.

First, get the list of changed files:
```bash
git diff --name-only main...HEAD
```

Then run the review loop:

```
review_count = 0

LOOP:
  review_count += 1

  IF review_count > 3:
    Output: "Code review exceeded 3 iterations. Human review required."
    Output: <promise>BLOCKED</promise>
    STOP ENTIRELY (do not continue to step 9)

  Spawn Task with:
    - subagent_type: "feature-dev:code-reviewer"
    - prompt: |
        Review the following files for bugs, logic errors, security issues, and code quality problems.

        ## Task Context
        Issue: [issue-id]
        Title: [issue title]
        Acceptance Criteria:
        [paste acceptance criteria from bd show output captured in step 0/1]

        ## Mandatory Constraints (from CLAUDE.md)
        [If CLAUDE.md has a "Mandatory Constraints" section, paste it here. These apply to ALL code.]
        Example constraints to check for:
        - Framework/library requirements (e.g., Vue-only UI, no Phoenix function components)
        - Styling rules (e.g., Tailwind-only, semantic tokens like bg-surface not bg-gray-100)
        - Testing requirements
        - Accessibility rules (e.g., 44px touch targets)

        ## Review Focus
        1. Does the implementation meet ALL acceptance criteria? (CRITICAL - check each one)
        2. Does the implementation follow ALL mandatory constraints from CLAUDE.md?
        3. Are there bugs, logic errors, or security issues?
        4. Does the code follow project patterns?

        **IMPORTANT**: Both AC issues AND mandatory constraint violations are BLOCKING.
        - AC issues: prefix with "[AC]"
        - Mandatory constraint violations: prefix with "[MC]"
        These cannot be dismissed or skipped.

        List ONLY issues with confidence >= 80. For each issue, include: file path, line number, description, and suggested fix.
        For AC issues, use format: "[AC] <criterion not met>: <what's missing>"
        For mandatory constraint issues, use format: "[MC] <constraint violated>: <what's wrong>"

        If ALL acceptance criteria are met, ALL mandatory constraints satisfied, and no other issues found, respond with exactly 'NO ISSUES FOUND'.

        Files to review:
        [list files from git diff]

  READ the agent response carefully.

  IF response contains "NO ISSUES FOUND":
    EXIT LOOP and CONTINUE TO STEP 9

  IF issues were found:
    For EACH issue in the response:
      1. Check if it's an [AC] issue (acceptance criteria) or [MC] issue (mandatory constraint)
      2. [AC] and [MC] issues are MANDATORY - you MUST fix them, no dismissing
      3. Read the file mentioned
      4. Fix the issue using Edit tool
      5. Log what you fixed

    **CRITICAL**: If an [AC] or [MC] issue requires installing a dependency, adding config,
    or any other action - DO IT. "Not installed" or "can't do this" is NOT acceptable.
    Either complete the requirement or output BLOCKED.

    After fixing ALL issues:
      git add -A
      git commit --amend --no-edit
      git push --force-with-lease

    CONTINUE LOOP (run code review again to verify fixes)
```

**Key points:**
- The code-reviewer agent returns issues directly to you (not posted as GitHub comments)
- You must parse the issues, fix them yourself, then re-review
- **[AC] and [MC] issues are NON-DISMISSIBLE** - they must be fixed or you must BLOCK
- Only exit when "NO ISSUES FOUND" or blocked after 3 iterations
- **DO NOT** end your response after seeing issues - you must fix them

After exiting the loop successfully, proceed immediately to step 8.5.

### 8.5 Acceptance Criteria & Mandatory Constraints Verification (MANDATORY)

**This step is NON-NEGOTIABLE. You cannot skip it or proceed without completing it.**

Before moving to step 9, explicitly verify EVERY acceptance criterion AND mandatory constraint is met:

1. **Parse AC into checklist**: Extract each acceptance criterion from the issue (captured in step 0/1)

2. **Parse MC into checklist**: Extract mandatory constraints from CLAUDE.md (if present)

3. **Verify EACH item individually**:
   ```
   For each AC item:
     - State the criterion
     - Describe how it was implemented (file, function, test)
     - Verify it works (run command, check file exists, etc.)
     - Mark as DONE or NOT DONE

   For each relevant MC item:
     - State the constraint
     - Verify the implementation follows it
     - Mark as DONE or NOT DONE
   ```

4. **Handle incomplete items**:
   - If ANY AC or MC item is NOT DONE: you must either implement it NOW or output BLOCKED
   - "Can't do this" is NOT acceptable - either do it or BLOCK
   - "Skipping because X isn't installed" is NOT acceptable - install X or BLOCK

**Example verification:**

```
## AC Verification for bd-a1b2

1. [x] "Add Credo to dependencies"
   - Implemented: Added {:credo, "~> 1.7"} to mix.exs deps
   - Verified: mix deps.get succeeds, credo available

2. [x] "Configure CI to run Credo in strict mode"
   - Implemented: Added "mix credo --strict" step to .github/workflows/ci.yml
   - Verified: File contains the step

3. [x] "Credo passes locally"
   - Verified: Ran `mix credo --strict`, exits 0

## MC Verification (Mandatory Constraints)

1. [x] "Tests required for every feature"
   - Verified: Added test in test/credo_integration_test.exs

2. [x] "Tailwind only, semantic tokens"
   - N/A: No UI changes in this task

3. [x] "44px touch targets"
   - N/A: No UI changes in this task

All AC and MC items complete. Proceeding to step 9.
```

**Example of WRONG behavior:**
```
AC: "Configure Credo in CI"
Response: "Credo isn't installed, skipping this AC item"
```
This is WRONG. Correct behavior: Install Credo, configure CI, or output BLOCKED.

**If ANY AC item cannot be completed:**
```
## AC Verification FAILED

Item not complete: "Configure Credo in CI"
Reason: [explain why it cannot be done]
Action needed: [what human needs to do]

<promise>BLOCKED</promise>
```

Only proceed to step 9 after ALL AC items are verified as DONE.

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

### 11. Cleanup and Close Issue

```bash
git checkout main
git pull origin main
bd close <issue-id>
bd sync
```

The `bd close` marks the issue as complete AFTER successful merge.

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
| **Acceptance criterion not met** | Output `<promise>BLOCKED</promise>` - NEVER skip AC items |
| **Mandatory constraint violated** | Output `<promise>BLOCKED</promise>` - NEVER skip MC items |
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

---

## Catch-All Safety Net

If you somehow reach a state where:
- You've completed some work but aren't sure which promise to output
- An unexpected error occurred
- You got confused about the workflow
- Any other edge case

**Output `<promise>BLOCKED</promise>` with an explanation of what happened.**

Example:
```
## Unexpected State

Reached end of workflow without clear completion status.
- Started working on: bd-a1b2
- Got to step: 7 (Create PR)
- Unexpected situation: [describe what happened]

Human review recommended.

<promise>BLOCKED</promise>
```

**NEVER end your response without a promise word. When in doubt, use BLOCKED.**
