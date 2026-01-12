---
name: ralph-review
description: Batch audit of autonomous Ralph work. Verifies acceptance criteria, spec alignment, and convention adherence. Creates corrective issues for drift.
arguments:
  - name: start_commit
    description: Git commit hash from start of batch (defaults to HEAD~5)
    required: false
  - name: tasks_count
    description: Number of recently completed tasks to review (default 5)
    required: false
---

# Ralph Review (Batch Audit)

Audit a batch of autonomously completed tasks. Catches drift before it compounds.

## Promise Words

Output EXACTLY ONE at the END of your response:

| Word | Meaning |
|------|---------|
| `<promise>REVIEW_COMPLETE</promise>` | Review finished. Any issues created as high-priority beads tickets. |
| `<promise>REVIEW_BLOCKED</promise>` | Review itself failed (can't access data, beads error, etc.). |

## Critical Rule

**YOU MUST OUTPUT EXACTLY ONE PROMISE WORD BEFORE ENDING YOUR RESPONSE.**

## Constraints

- **No user interaction** - fully autonomous
- **No AskUserQuestion** - make all decisions
- **Create issues, don't fix** - this is an audit, not a fix-it session
- **High priority only** - created issues get priority 1 (worked on next)
- **Be specific** - issues must have clear acceptance criteria

---

## Process

### 1. Gather Context

```bash
# Get start commit (use argument or default to HEAD~5)
START_COMMIT="${start_commit:-$(git rev-parse HEAD~5)}"

# Get current HEAD
git rev-parse HEAD
```

Read project context files (if they exist):
- `SPEC.md` - Product specification
- `CLAUDE.md` - Project conventions and mandatory constraints
- `AGENTS.md` - Agent-specific guidance

### 2. Get Completed Issues

```bash
# Get recently completed issues (newest first)
bd list --status=done --json | jq -r '.[:5]'
```

Parse the JSON. Extract for each issue:
- Issue ID
- Title
- Acceptance criteria
- Implementation hints (if any)

If no completed issues found:
```
No completed issues to review.
<promise>REVIEW_COMPLETE</promise>
```

### 3. Get Git Changes

```bash
# Files changed in batch
git diff --name-only $START_COMMIT HEAD

# Full diff for analysis
git diff $START_COMMIT HEAD --stat
```

### 4. Audit Each Issue

For each completed issue, verify:

#### 4.1 Acceptance Criteria Check

```
For each AC item in the issue:
  - Locate the implementation (search codebase)
  - Verify it actually works as specified
  - Check tests exist and cover the criterion
  - Mark as: VERIFIED | PARTIAL | MISSING | BROKEN
```

**Findings to flag:**
- AC marked complete but implementation missing
- AC marked complete but tests missing
- AC implemented but behaviour incorrect
- AC partially implemented (missing edge cases)

#### 4.2 SPEC.md Alignment (if exists)

```
If SPEC.md exists:
  - Find section(s) relevant to completed issues
  - Verify implementation matches spec intent
  - Check for deviations or misinterpretations
```

**Findings to flag:**
- Implementation contradicts spec
- Implementation misses spec requirements
- Implementation adds unspecified behaviour

#### 4.3 Convention Check (CLAUDE.md / AGENTS.md)

```
For each mandatory constraint:
  - Check if any changed files violate it
  - Check if any new patterns introduced break conventions
```

**Findings to flag:**
- Raw Tailwind values instead of semantic tokens
- Missing tests for boundary code
- Wrong framework/library used
- Code style violations

### 5. Compile Findings

Group findings by severity:

| Severity | Description | Action |
|----------|-------------|--------|
| CRITICAL | Broken functionality, security issue, data loss risk | Must fix immediately |
| HIGH | AC not met, spec deviation, convention violation | Should fix soon |
| MEDIUM | Partial implementation, missing edge cases | Can batch with related work |

### 6. Create Corrective Issues

For each finding at CRITICAL or HIGH severity, create a beads issue:

```bash
bd add --priority=1 --json << 'EOF'
{
  "title": "[Ralph Review] Fix: <brief description>",
  "body": "## Origin\nIdentified during batch review of tasks: <issue-ids>\n\n## Problem\n<what was found>\n\n## Acceptance Criteria\n- [ ] <specific fix criterion 1>\n- [ ] <specific fix criterion 2>\n\n## Context\n- Original issue: <issue-id>\n- Files affected: <file list>\n- Spec reference: <if applicable>"
}
EOF
```

**Issue title patterns:**
- `[Ralph Review] Fix: <AC item> not implemented in <issue>`
- `[Ralph Review] Fix: <file> violates <constraint>`
- `[Ralph Review] Fix: <feature> deviates from SPEC.md`

### 7. Summary Report

Output a summary:

```
## Ralph Review Summary

**Batch:** $START_COMMIT → HEAD
**Issues reviewed:** <count>
**Files changed:** <count>

### Findings

| Issue | Finding | Severity | Corrective Issue |
|-------|---------|----------|------------------|
| bd-xxx | AC item missing tests | HIGH | bd-yyy |
| bd-xxx | Uses bg-gray-100 not bg-surface | HIGH | bd-yyy |

### Created Issues
- bd-yyy: [Ralph Review] Fix: Add tests for user avatar upload
- bd-zzz: [Ralph Review] Fix: Replace raw Tailwind with semantic tokens

### Stats
- Verified: X items
- Partial: Y items
- Issues created: Z

<promise>REVIEW_COMPLETE</promise>
```

If no issues found:

```
## Ralph Review Summary

**Batch:** $START_COMMIT → HEAD
**Issues reviewed:** <count>
**Files changed:** <count>

All acceptance criteria verified. No spec deviations. Conventions followed.

<promise>REVIEW_COMPLETE</promise>
```

---

## Failure States

| Situation | Action |
|-----------|--------|
| Can't access git history | Output `<promise>REVIEW_BLOCKED</promise>` |
| Beads not available | Output `<promise>REVIEW_BLOCKED</promise>` |
| No completed issues | Output `<promise>REVIEW_COMPLETE</promise>` (nothing to review) |
| Issues found | Create tickets, output `<promise>REVIEW_COMPLETE</promise>` |
| No issues found | Output `<promise>REVIEW_COMPLETE</promise>` |

---

## Example Output (Issues Found)

```
## Ralph Review Summary

**Batch:** a1b2c3d → e4f5g6h
**Issues reviewed:** 3
**Files changed:** 12

### Findings

| Issue | Finding | Severity | Corrective Issue |
|-------|---------|----------|------------------|
| bd-a1b | Avatar upload missing size validation | CRITICAL | bd-x1y |
| bd-a1b | ImageUpload.vue uses bg-white not bg-surface | HIGH | bd-x2z |
| bd-c3d | Dashboard stats endpoint missing tests | HIGH | bd-x3w |

### Created Issues
- bd-x1y: [Ralph Review] Fix: Add 2MB size validation to avatar upload
- bd-x2z: [Ralph Review] Fix: Replace bg-white with bg-surface in ImageUpload.vue
- bd-x3w: [Ralph Review] Fix: Add boundary tests for /api/dashboard/stats

### Stats
- Verified: 8 items
- Partial: 2 items
- Issues created: 3

<promise>REVIEW_COMPLETE</promise>
```

## Example Output (Clean)

```
## Ralph Review Summary

**Batch:** a1b2c3d → e4f5g6h
**Issues reviewed:** 5
**Files changed:** 23

All acceptance criteria verified. No spec deviations. Conventions followed.

### Stats
- Verified: 15 items
- Partial: 0 items
- Issues created: 0

<promise>REVIEW_COMPLETE</promise>
```

---

## Catch-All Safety Net

If you reach an unexpected state:

```
## Unexpected State

<explain what happened>

<promise>REVIEW_BLOCKED</promise>
```

**NEVER end your response without a promise word.**
