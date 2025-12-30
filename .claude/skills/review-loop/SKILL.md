---
name: review-loop
description: Run iterative code review until clean. Use after making changes, on feature branches, or anytime you want automated review and fixes. Detects changed files from git diff.
user_invocable: true
arguments:
  - name: files
    description: Optional specific files to review (defaults to git diff)
    required: false
---

# Review Loop

Iterative review-fix cycle using specialized code reviewer. Runs until no issues remain.

**Use cases:**
- After manual code changes
- After `/next-feature` implementation
- On any feature branch
- Before committing

---

## Step 1: Detect Changed Files

If files argument provided, use those. Otherwise:

```bash
git diff --name-only HEAD~1  # or compare to main branch
```

Present to user:
```
## Review Loop

Files to review:
- path/to/file1.ts
- path/to/file2.ts

Starting review loop...
```

---

## Step 2: Run Review Loop

Run this loop yourself until no issues remain:

### 2a. REVIEW (spawn specialized reviewer)

Use the Task tool with these parameters:
- `subagent_type`: `feature-dev:code-reviewer`
- `prompt`: Include the file list and review criteria

```
Task(
  subagent_type: "feature-dev:code-reviewer",
  prompt: "Review these files: [list of files]

    Check for:
    - Bugs and logic errors
    - Security vulnerabilities
    - Missing error handling
    - Project convention violations
    - Code quality issues

    Return numbered list of issues with file:line references,
    or 'NO ISSUES FOUND' if clean."
)
```

### 2b. EVALUATE each issue

For each issue returned, decide:
- Is it a real problem? (not false positive)
- Is it in scope? (not unrelated code)
- Should it be fixed? (not intentional design)

### 2c. FIX valid issues

Use Edit tool to fix each valid issue. Track what you changed.
Dismiss invalid issues with justification.

### 2d. LOOP

After fixing, spawn `feature-dev:code-reviewer` AGAIN.
Fixes may introduce new issues.

**REPEAT steps 2a-2d** until reviewer returns "NO ISSUES FOUND".

---

## Step 3: Report Results

When subagent returns, present summary:

```
## Review Complete

**Iterations:** [count]
**Fixes made:**
- [fix 1]
- [fix 2]

**Dismissed (with reason):**
- [issue]: [reason]

Ready to commit.
```

---

## Quick Reference

- No changes detected? → Nothing to review
- Main agent runs the loop → Spawns code-reviewer each iteration
- All issues get addressed → Fixed or dismissed with reason
- Plugin subagents can't be nested → Must spawn from main agent
