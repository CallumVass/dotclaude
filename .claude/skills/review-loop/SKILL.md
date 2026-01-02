---
name: review-loop
description: Iterative code review until clean. Use after making changes, before committing, on feature branches, or when user says "review", "check my code", "review loop", "run review".
user_invocable: true
arguments:
  - name: files
    description: Specific files to review (defaults to git diff detection)
    required: false
---

# Review Loop

Iterative review-fix cycle. Runs until reviewer returns clean.

---

## Constraints

```
REQUIRE files_to_review:
  Must have files to review - either provided or detected
  Empty file list → inform user, exit gracefully

REQUIRE main_agent_runs_loop:
  Plugin subagents cannot spawn from nested subagents
  Main agent MUST run this loop directly
  
INVARIANT all_issues_addressed:
  Every issue either FIXED or DISMISSED with reason
  No issues left unaddressed
```

---

## Inputs/Outputs

```
INPUTS:
  - files: explicit file list (optional)
  - git diff: auto-detected if files not provided

OUTPUTS:
  - iterations: number of review cycles
  - fixes_made[]: list of fixes applied
  - dismissed[]: list of issues dismissed with reasons
  - status: "clean" | "no_changes"
```

---

## Process

### Step 1: Detect Files

```
IF files argument provided:
  USE provided files
ELSE:
  DETECT via git:
    TRY: git diff --name-only HEAD~1
    FALLBACK: git diff --name-only main
    FALLBACK: git diff --name-only master

IF no files detected:
  INFORM: "No changed files detected. Nothing to review."
  EXIT with status = "no_changes"

PRESENT:
  "## Review Loop
  
  Files to review:
  - path/to/file1
  - path/to/file2
  
  Starting review..."
```

### Step 2: Review Loop

```
SET iteration = 0
SET fixes_made = []
SET dismissed = []

LOOP:
  iteration++
  
  ┌─────────────────────────────────────────────────────────┐
  │ STEP 2a: SPAWN REVIEWER                                 │
  └─────────────────────────────────────────────────────────┘
  
  SPAWN:
    subagent_type: "feature-dev:code-reviewer"
    prompt: "Review these files: [file_list]
            
            Check for:
            - Bugs and logic errors
            - Security vulnerabilities  
            - Missing error handling
            - Project convention violations
            - Code quality issues
            
            Return numbered list with file:line references,
            or 'NO ISSUES FOUND' if clean."
  
  WAIT for response
  
  ┌─────────────────────────────────────────────────────────┐
  │ STEP 2b: CHECK EXIT CONDITION                           │
  └─────────────────────────────────────────────────────────┘
  
  IF response contains "NO ISSUES FOUND":
    EXIT loop with status = "clean"
  
  ┌─────────────────────────────────────────────────────────┐
  │ STEP 2c: EVALUATE EACH ISSUE                            │
  └─────────────────────────────────────────────────────────┘
  
  FOR EACH issue in response:
    EVALUATE:
      Q1: Is this a real problem? (not false positive)
      Q2: Is it in scope? (not unrelated code)
      Q3: Should it be fixed? (not intentional design)
    
    IF all yes → mark as VALID
    IF any no → mark as INVALID with reason
  
  ┌─────────────────────────────────────────────────────────┐
  │ STEP 2d: FIX OR DISMISS                                 │
  └─────────────────────────────────────────────────────────┘
  
  FOR EACH valid issue:
    FIX using Edit tool
    APPEND to fixes_made[]:
      { issue: "...", file: "...", fix: "..." }
  
  FOR EACH invalid issue:
    APPEND to dismissed[]:
      { issue: "...", reason: "..." }
  
  ┌─────────────────────────────────────────────────────────┐
  │ STEP 2e: CONTINUE                                       │
  └─────────────────────────────────────────────────────────┘
  
  NOTE: Fixes may introduce new issues
  CONTINUE loop (spawn reviewer again)

END LOOP
```

### Step 3: Report

```
PRESENT:
  "## Review Complete
  
  **Status:** Clean
  **Iterations:** [iteration]
  
  **Fixes made:**
  - [fix 1 description]
  - [fix 2 description]
  
  **Dismissed (with reason):**
  - [issue]: [reason]
  - [issue]: [reason]
  
  Ready to commit."

IF called from /next-feature:
  RETURN status to calling skill
ELSE:
  DONE
```

---

## Quick Reference

```
TRIGGER: 
  - Explicitly via /review-loop
  - Called from /next-feature Phase 7
  - User says "review my code", "check this"

FILE DETECTION:
  - Explicit files argument takes priority
  - Falls back to git diff detection
  - No files = nothing to do

LOOP BEHAVIOR:
  - Spawns reviewer each iteration
  - Fixes may create new issues
  - Exits ONLY when "NO ISSUES FOUND"

ISSUE HANDLING:
  - Valid issues get fixed
  - Invalid issues get dismissed WITH reason
  - No issues left unaddressed
```
