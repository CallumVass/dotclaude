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

Guided feature development combining PROGRESS.md workflow with parallel subagents.

**Philosophy**: Main agent coordinates, subagents do heavy lifting. Keep main context lean.

---

## Phase 1: Feature Selection

**Actor**: Main agent | **Context**: ~5%

1. Read `docs/PROGRESS.md`, find unchecked `[ ]` items in current phase
2. Group related items (same subsection, dependencies, shared files)
3. Apply steer hint if provided
4. Present to user:

```
## Current Phase: [Phase Name]

Progress: X/Y items complete

### Suggested Work Group

1. [ ] First item
2. [ ] Second item

**Scope:** [Small/Medium/Large]
**Branch:** `feat/[name]`

Ready to start? (y/n)
```

5. On confirmation: `git checkout -b feat/<feature-name>`

---

## Phase 2: Codebase Exploration

**Actor**: 2-3 parallel subagents | **Context**: ~5% (summaries only)

Launch explorers in parallel with different focuses:

```
Task(
  subagent_type: "feature-dev:code-explorer",
  prompt: "Find features similar to [feature] and trace their implementation.
    Return: architecture patterns, key abstractions, 5-10 important files."
)

Task(
  subagent_type: "feature-dev:code-explorer",
  prompt: "Map the architecture for [relevant area].
    Return: component relationships, data flow, integration points."
)

Task(
  subagent_type: "feature-dev:code-explorer",
  prompt: "Analyze [existing related feature] implementation.
    Return: patterns used, extension points, conventions to follow."
)
```

After agents return, read the key files they identified to build understanding.

---

## Phase 3: Clarifying Questions

**Actor**: Main agent | **Context**: ~5%

**CRITICAL**: Do not skip. This catches requirements you haven't thought of.

1. Review exploration findings and feature requirements
2. Identify ambiguities:
   - Edge cases and error handling
   - Scope boundaries (what's in/out)
   - Integration points
   - User preferences that affect design
3. Present questions using `AskUserQuestion`
4. **Wait for answers before proceeding**

If user says "whatever you think", give your recommendation and get confirmation.

---

## Phase 4: Architecture Design

**Actor**: 2-3 parallel subagents | **Context**: ~5% (summaries only)

Launch architects with different approaches:

```
Task(
  subagent_type: "feature-dev:code-architect",
  prompt: "Design MINIMAL implementation for: [feature]
    Requirements: [from Phase 1]
    User decisions: [from Phase 3]
    Constraints: Smallest change, maximum reuse of existing code.
    Return: files to modify, changes needed, trade-offs."
)

Task(
  subagent_type: "feature-dev:code-architect",
  prompt: "Design CLEAN implementation for: [feature]
    Requirements: [from Phase 1]
    User decisions: [from Phase 3]
    Constraints: Maintainability, elegant abstractions, future-proof.
    Return: files to create/modify, component design, trade-offs."
)

Task(
  subagent_type: "feature-dev:code-architect",
  prompt: "Design PRAGMATIC implementation for: [feature]
    Requirements: [from Phase 1]
    User decisions: [from Phase 3]
    Constraints: Balance speed and quality, practical for this scope.
    Return: files to modify, implementation approach, trade-offs."
)
```

Present all approaches with trade-offs and your recommendation. Ask user to pick.

---

## Phase 5: Implementation

**Actor**: Main agent | **Context**: ~40%

1. Create todo list from chosen architecture's implementation steps
2. Read all relevant files identified in exploration
3. Implement step by step, marking todos complete as you go
4. Follow codebase conventions strictly
5. Keep changes focused - don't add unrequested features

---

## Phase 6: Review Loop

**Actor**: Main agent | **Context**: ~10%

Run the review-fix loop on all changed files. Same pattern as `/review-loop`.

**NOTE**: Plugin subagent types (like `feature-dev:code-reviewer`) cannot be spawned from
nested subagents. The main agent must run this loop directly.

### Loop until clean:

1. **REVIEW**: Spawn the code reviewer
   ```
   Task(
     subagent_type: "feature-dev:code-reviewer",
     prompt: "Review these files: [list from implementation]
       Check for: bugs, security issues, missing error handling, convention violations.
       Return numbered list with file:line references, or 'NO ISSUES FOUND' if clean."
   )
   ```

2. **EVALUATE**: For each issue - real problem? in scope? should fix?

3. **FIX**: Use Edit tool for valid issues, dismiss others with justification

4. **REPEAT**: Spawn code-reviewer again (fixes may introduce issues)

Exit when reviewer returns "NO ISSUES FOUND".

---

## Phase 7: Completion

**Actor**: Main agent | **Context**: ~5%

1. Run tests: `mix test` (or project equivalent)
2. Fix any test failures
3. Update `docs/PROGRESS.md`: mark items `[x]`
4. Present summary:

```
## Feature Complete

**Branch:** feat/[name]
**Items completed:**
- [x] Item 1
- [x] Item 2

**Files changed:** [count]
**Review iterations:** [from subagent]

Ready to commit.
```

---

## Context Budget

| Phase | Budget | Actor |
|-------|--------|-------|
| 1. Feature Selection | ~5% | Main |
| 2. Exploration | ~5% | Subagents (parallel) |
| 3. Clarification | ~5% | Main |
| 4. Architecture | ~5% | Subagents (parallel) |
| 5. Implementation | ~40% | Main |
| 6. Review Loop | ~10% | Main (spawns reviewer) |
| 7. Completion | ~5% | Main |
| **Total** | **~75%** | |

---

## Quick Reference

- No PROGRESS.md? → Suggest `/init-project` first
- Subagents return summaries → Read key files they identify
- User picks architecture → Don't proceed without selection
- Review loop runs in main → Plugin subagents can't be nested
- Complete phases in order → Don't skip ahead
