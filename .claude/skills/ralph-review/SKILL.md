---
name: ralph-review
description: Batch audit of autonomous Ralph work. Verifies acceptance criteria, spec alignment, and convention adherence. Creates corrective issues for drift. Use after running ralph-task multiple times or when user says "review ralph's work", "audit batch", "check autonomous work".
---

# Ralph Review (Batch Audit)

Audit a batch of autonomously completed tasks. Catches drift before it compounds.

## Promise Words

Output EXACTLY ONE at the END of your response:

| Word | Meaning |
|------|---------|
| `<promise>REVIEW_COMPLETE</promise>` | Review finished. Any issues created as high-priority beads tickets. |
| `<promise>REVIEW_BLOCKED</promise>` | Review itself failed (can't access data, beads error, etc.). |

**CRITICAL: Every execution path must end with exactly one promise word.**

## Constraints

- **No user interaction** - fully autonomous, no AskUserQuestion
- **Create issues, don't fix** - this is an audit, not a fix-it session
- **High priority only** - created issues get priority 1
- **Be specific** - issues must have clear acceptance criteria

---

## Process

### 1. Gather Context

```bash
START_COMMIT="${start_commit:-$(git rev-parse HEAD~5)}"
git rev-parse HEAD
```

Read project context files (if they exist): `SPEC.md`, `CLAUDE.md`, `AGENTS.md`

### 2. Get Completed Issues

```bash
bd list --status=done --json | jq -r '.[:5]'
```

If no completed issues: output `<promise>REVIEW_COMPLETE</promise>` and stop.

### 3. Get Git Changes

```bash
git diff --name-only $START_COMMIT HEAD
git diff $START_COMMIT HEAD --stat
```

### 4. Audit Each Issue

For each completed issue, verify:

**4.1 Acceptance Criteria Check**
- Locate the implementation
- Verify it works as specified
- Check tests exist and cover the criterion
- Mark as: VERIFIED | PARTIAL | MISSING | BROKEN

**4.2 SPEC.md Alignment** (if exists)
- Find relevant section(s)
- Verify implementation matches spec intent
- Check for deviations

**4.3 Convention Check** (CLAUDE.md / AGENTS.md)
- Check if changed files violate mandatory constraints
- Check if new patterns break conventions

### 5. Compile Findings

| Severity | Description | Action |
|----------|-------------|--------|
| CRITICAL | Broken functionality, security issue, data loss risk | Must fix immediately |
| HIGH | AC not met, spec deviation, convention violation | Should fix soon |
| MEDIUM | Partial implementation, missing edge cases | Can batch with related work |

### 6. Create Corrective Issues

For CRITICAL or HIGH findings:

```bash
bd add --priority=1 --json << 'EOF'
{
  "title": "[Ralph Review] Fix: <brief description>",
  "body": "## Origin\nIdentified during batch review of tasks: <issue-ids>\n\n## Problem\n<what was found>\n\n## Acceptance Criteria\n- [ ] <specific fix criterion 1>\n- [ ] <specific fix criterion 2>\n\n## Context\n- Original issue: <issue-id>\n- Files affected: <file list>"
}
EOF
```

### 7. Summary Report

```
## Ralph Review Summary

**Batch:** $START_COMMIT → HEAD
**Issues reviewed:** <count>
**Files changed:** <count>

### Findings

| Issue | Finding | Severity | Corrective Issue |
|-------|---------|----------|------------------|
| bd-xxx | Description | HIGH | bd-yyy |

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

All acceptance criteria verified. No spec deviations. Conventions followed.

<promise>REVIEW_COMPLETE</promise>
```

---

## Failure States

| Situation | Action |
|-----------|--------|
| Can't access git history | `<promise>REVIEW_BLOCKED</promise>` |
| Beads not available | `<promise>REVIEW_BLOCKED</promise>` |
| No completed issues | `<promise>REVIEW_COMPLETE</promise>` |
| Issues found | Create tickets, `<promise>REVIEW_COMPLETE</promise>` |
| Unexpected error | `<promise>REVIEW_BLOCKED</promise>` with explanation |

**NEVER end without a promise word.**
