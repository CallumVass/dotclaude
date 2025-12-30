---
name: next-feature
description: Start work on the next feature. Use when user says "next feature", "start the next feature", "what should we work on next", or similar. Reads PROGRESS.md to find related unchecked items.
user_invocable: true
arguments:
  - name: steer
    description: Optional direction to steer towards a specific feature area
    required: false
---

# Next Feature

Guided feature development with architecture-first approach and iterative review.

**Context Strategy**: Uses subagents for heavy exploration, keeps main context for coordination and implementation. Target: ~80-90% context for medium features.

## Arguments

- **steer** (optional): Hint towards a specific feature area
  - `/next-feature auth` - focus on authentication
  - `/next-feature UI` - prioritize UI work
  - `/next-feature` - auto-suggest based on progress order

---

## Phase 1: Feature Selection

**Context cost: ~5%**

### 1.1 Read PROGRESS.md

Read `docs/PROGRESS.md` and find unchecked `[ ]` items in current phase.

### 1.2 Group Related Items

Group items that belong together:
- Same subsection
- Dependent on each other
- Touch same files/systems
- Apply steer if provided

### 1.3 Present to User

```
## Current Phase: [Phase Name]

Progress: X/Y items complete

### Suggested Work Group

1. [ ] First item - why needed
2. [ ] Second item - how it relates

**Scope:** [Small/Medium/Large]
**Branch:** `feat/[name]`

Ready to start? (y/n)
```

### 1.4 On Confirmation

```bash
git checkout -b feat/<feature-name>
```

---

## Phase 2: Requirements Clarification

**Context cost: ~5%**

Before designing architecture, identify ambiguities and get user input.

### 2.1 Analyze Requirements

Review the feature items and identify:
- **Ambiguous requirements** - multiple valid interpretations
- **Missing details** - what's not specified but needed
- **Design choices** - where user preference matters
- **Scope boundaries** - what's included vs excluded

### 2.2 Ask Clarifying Questions

Use `AskUserQuestion` tool for important decisions:

```
AskUserQuestion(
  questions: [
    {
      question: "How should X behave when Y?",
      header: "Behavior",
      options: [
        { label: "Option A", description: "Does this..." },
        { label: "Option B", description: "Does that..." }
      ]
    }
  ]
)
```

**When to ask:**
- Multiple valid approaches exist
- User preference significantly affects implementation
- Scope is unclear

**When NOT to ask:**
- Obvious from codebase patterns
- Standard/conventional approach exists
- Minor implementation detail

### 2.3 Document Decisions

After clarification, briefly note the decisions made before proceeding.

---

## Phase 3: Architecture Design (Iterative)

**Context cost: ~10% (subagent returns summary only)**

### 3.1 Initial Architecture

**MUST use Task tool** - do not do this yourself:

```
Task(
  subagent_type: "feature-dev:code-architect",
  prompt: "Design implementation for: [feature]

  Requirements:
  - [item 1 from PROGRESS.md]
  - [item 2]

  User decisions:
  - [decision 1 from Phase 2]
  - [decision 2]

  Analyze existing patterns in this codebase and return:
  1. Files to create/modify (with paths)
  2. Component/module design
  3. Data flow
  4. Implementation sequence (order matters)

  Keep it focused - no over-engineering."
)
```

### 3.2 Review Architecture with User

Present the architect's plan and ask:

```
AskUserQuestion(
  questions: [{
    question: "Does this architecture approach look good?",
    header: "Architecture",
    options: [
      { label: "Looks good", description: "Proceed with implementation" },
      { label: "Needs changes", description: "I have feedback on the approach" }
    ]
  }]
)
```

### 3.3 Iterate if Needed

If user has feedback:
1. Note their concerns
2. Call architect subagent again with the feedback
3. Present revised plan
4. Repeat until approved

**Exit criteria:** User approves the architecture.

---

## Phase 4: Implementation

**Context cost: ~40%**

### 4.1 Setup Tracking

Use TodoWrite to track implementation steps from the architecture plan:

```
TodoWrite([
  { content: "Create migration for X", status: "pending", activeForm: "Creating migration" },
  { content: "Add schema for Y", status: "pending", activeForm: "Adding schema" },
  ...
])
```

### 4.2 Implement Step by Step

For each step:
1. Mark as `in_progress`
2. Implement the change
3. Mark as `completed`
4. Move to next

### 4.3 Implementation Guidelines

- Follow the architect's sequence
- Match existing codebase patterns
- Keep changes minimal and focused
- Don't add unrequested features

---

## Phase 5: Code Review Loop

**Context cost: ~15% (multiple subagent iterations)**

### CRITICAL: Loop Enforcement

```
╔═══════════════════════════════════════════════════════════════╗
║  THIS LOOP MUST CONTINUE UNTIL REVIEWER RETURNS "NO ISSUES"   ║
║  DO NOT STOP AFTER ONE ITERATION                              ║
║  DO NOT ASK USER IF YOU SHOULD CONTINUE                       ║
║  KEEP GOING AUTOMATICALLY                                     ║
╚═══════════════════════════════════════════════════════════════╝
```

### 5.1 Review Loop Structure

```
loop_count = 0

WHILE true:
    loop_count += 1

    # Run reviewer subagent
    issues = Task(feature-dev:code-reviewer)

    IF issues == "NO ISSUES FOUND":
        BREAK  # Exit loop

    # Fix each issue
    FOR issue IN issues:
        IF fixable:
            fix(issue)
        ELSE:
            dismiss(issue, reason)

    # Automatically continue to next iteration
    # DO NOT STOP HERE
    # DO NOT ASK USER

END WHILE

report("Review complete after {loop_count} iterations")
```

### 5.2 Run Reviewer (Subagent)

**MUST use Task tool**:

```
Task(
  subagent_type: "feature-dev:code-reviewer",
  prompt: "Review changes in this feature branch.

  Feature: [description]
  Files changed: [list from implementation]

  Check for:
  - Bugs and logic errors
  - Security issues
  - Project convention violations
  - Missing error handling
  - Performance issues

  Return EXACTLY ONE of:
  - 'NO ISSUES FOUND' (if clean)
  - Numbered list of issues with file:line references"
)
```

### 5.3 Process Issues

For each issue returned:

**Fix** (default):
- Make the code change
- Note what was fixed

**Dismiss** (only if valid reason):
- False positive
- Intentional design decision
- Out of scope
- Contradicts project conventions

```
DISMISSED: [issue]
REASON: [specific justification]
```

### 5.4 Continue Loop

After fixing/dismissing all issues from current iteration:

1. **Immediately** call reviewer subagent again
2. **Do not** ask user if you should continue
3. **Do not** stop to report progress
4. **Keep iterating** until "NO ISSUES FOUND"

### 5.5 Exit Criteria

The loop exits ONLY when:
- Reviewer returns "NO ISSUES FOUND", OR
- All issues in an iteration are dismissed with valid justifications

---

## Phase 6: Completion

**Context cost: ~5%**

### 6.1 Run Tests

```bash
mix test  # or equivalent
```

Fix any test failures before proceeding.

### 6.2 Update PROGRESS.md

Mark completed items: `[ ]` → `[x]`

### 6.3 Summary Report

```
## Feature Complete

**Branch:** feat/[name]
**Items completed:**
- [x] Item 1
- [x] Item 2

**Files changed:** [count]
**Review iterations:** [count]

Ready for: commit or merge
```

---

## Context Budget Summary

| Phase | Budget | Method |
|-------|--------|--------|
| 1. Feature Selection | ~5% | Direct reads |
| 2. Clarification | ~5% | AskUserQuestion |
| 3. Architecture | ~10% | Subagent (summary only) |
| 4. Implementation | ~40% | Focused edits |
| 5. Review Loop | ~15% | Subagent iterations |
| 6. Completion | ~5% | Tests, updates |
| **Total** | **~80%** | |

---

## Notes

- Complete current phase before moving to next
- Use subagents via Task tool - don't do their work yourself
- Review loop is NON-NEGOTIABLE - it must run until clean
- If no PROGRESS.md exists, suggest `/init-project` first
