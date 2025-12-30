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

## Step 2: Run Review Loop (Subagent)

**Hand off to subagent. Do not do this yourself.**

```
Task(
  subagent_type: "general-purpose",
  prompt: "Review and fix code until clean.

    Files to review:
    [list of files]

    ## Your Task

    Run this loop until no issues remain:

    ### 1. REVIEW (use specialized reviewer)

    Spawn a code-reviewer subagent:

    Task(
      subagent_type: 'feature-dev:code-reviewer',
      prompt: 'Review these files:
        [list of files]

        Check for:
        - Bugs and logic errors
        - Security vulnerabilities
        - Missing error handling
        - Project convention violations
        - Code quality issues

        Return numbered list of issues with file:line references,
        or NO ISSUES FOUND if clean.'
    )

    ### 2. EVALUATE each issue returned

    For each issue, decide:
    - Is it a real problem? (not false positive)
    - Is it in scope? (not unrelated code)
    - Should it be fixed? (not intentional design)

    ### 3. FIX valid issues

    Use Edit tool to fix each valid issue. Note what you changed.
    Dismiss invalid issues with justification.

    ### 4. LOOP

    After fixing, spawn code-reviewer AGAIN.
    Fixes may have introduced new issues.
    REPEAT until reviewer returns 'NO ISSUES FOUND'.

    ## Exit Criteria

    Return ONLY when:
    - Code-reviewer returns 'NO ISSUES FOUND', OR
    - All remaining issues are dismissed with valid justification

    ## Return Format

    When complete, return:
    - Number of review iterations
    - Summary of fixes made
    - Any dismissed issues with justification
    - Confirmation: 'Code is clean and ready to commit'"
)
```

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
- Subagent runs autonomously → Wait for completion
- All issues get addressed → Fixed or dismissed with reason
