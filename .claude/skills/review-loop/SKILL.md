---
name: review-loop
description: Iterative code review until clean. Use after making changes, before committing, or when user says "review", "check my code".
arguments:
  - name: files
    description: Specific files to review (defaults to git diff detection)
    required: false
---

# Review Loop

Run code review in a loop until no issues remain.

## Constraints

- Main agent must run this loop directly (plugin subagents can't spawn nested subagents)
- Every issue must be either fixed or dismissed with a reason
- Exit only when reviewer returns "NO ISSUES FOUND"

## File Detection

If `files` argument provided, use those. Otherwise detect via git:
1. Try `git diff --name-only HEAD~1`
2. Fallback to `git diff --name-only main`
3. Fallback to `git diff --name-only master`

If no files detected, inform user and exit.

## Process

1. Detect files to review. Show list to user.

2. Loop:
   - Spawn `feature-dev:code-reviewer` with the file list
   - If response is "NO ISSUES FOUND", exit loop
   - For each issue: evaluate if valid (real problem, in scope, should be fixed)
   - Fix valid issues with Edit tool
   - Dismiss invalid issues with documented reason
   - Continue loop (fixes may introduce new issues)

3. Report results:
   - Number of iterations
   - Fixes made (what and where)
   - Issues dismissed (what and why)
