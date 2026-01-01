---
name: next-feature
description: Use this skill when user says "next feature", "work on next feature", "lets work on", "let's work on", "start the next feature", "implement a feature", "add a feature", "build a feature", "I want to add", "what should I work on", or describes a feature to implement. Also use for JIRA tickets or feature descriptions. ALWAYS use this skill for feature work - do not use bd commands directly without going through this skill's phases.
user_invocable: true
arguments:
  - name: steer
    description: Optional direction to steer towards a specific feature area
    required: false
---

# Next Feature

Guided feature development using beads for task tracking and parallel subagents for exploration.

**Philosophy**: Main agent coordinates, subagents do heavy lifting. Keep main context lean.

---

## Phase 1: Feature Selection

**Actor**: Main agent | **Context**: ~5%

### Path A: Beads issues exist

1. Run `bd ready --json` to get unblocked tasks
2. Parse JSON to identify available work items
3. Group by parent (epic/feature) for related work
4. Apply steer hint if provided to filter results
5. Present to user:

```
## Ready Work

**Epic:** Phase 1 - MVP (bd-abc123)
**Feature:** User Authentication (bd-abc123.1)

Ready tasks:
1. Implement login endpoint (bd-abc123.1.1) - P1
2. Add session handling (bd-abc123.1.2) - P1

**Scope:** [Small/Medium/Large]
**Branch:** `feat/[name]`

Ready to start? (y/n)
```

6. On confirmation:
   - `bd update <id> --status in_progress --json` for each task being worked on
   - `git checkout -b feat/<feature-name>`

### Path B: Ad-hoc feature (user describes feature inline)

If user provides a feature description (e.g., "next feature which is to add user authentication"):

1. Extract feature requirements from user's description
2. Break down into discrete tasks/acceptance criteria
3. Present to user:

```
## Ad-hoc Feature

### Tasks (from your description)

1. First task
2. Second task
3. Third task

**Scope:** [Small/Medium/Large]
**Branch:** `feat/[name]`

Does this capture the feature correctly? (y/n)
```

4. On confirmation, **create beads issues first**:
   ```bash
   # Create a feature for this work
   bd create "[Feature Name]" -t feature -p 1 --json
   # Returns: {"id": "bd-xyz789", ...}

   # Create tasks under the feature
   bd create "[Task 1]" -t task -p 1 --parent bd-xyz789 --json
   # Returns: {"id": "bd-xyz789.1", ...}
   bd create "[Task 2]" -t task -p 1 --parent bd-xyz789 --json
   bd create "[Task 3]" -t task -p 1 --parent bd-xyz789 --json

   # Mark tasks as in progress
   bd update bd-xyz789.1 --status in_progress --json
   bd update bd-xyz789.2 --status in_progress --json
   bd update bd-xyz789.3 --status in_progress --json
   ```

5. Create branch: `git checkout -b feat/<feature-name>`

6. Report created issues:
   ```
   ## Beads Issues Created

   - bd-xyz789: [Feature Name]
     - bd-xyz789.1: [Task 1] (in progress)
     - bd-xyz789.2: [Task 2] (in progress)
     - bd-xyz789.3: [Task 3] (in progress)

   Proceeding to exploration...
   ```

**Important**: All work must be tracked in beads. This ensures completion is properly recorded and work can be resumed across sessions.

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

## Phase 6: Testing (MANDATORY)

**Actor**: Main agent | **Context**: ~5%

```
+===============================================================+
|  DO NOT PROCEED TO REVIEW without completing this phase       |
|  Every boundary component changed MUST have a corresponding   |
|  test. A feature is NOT complete without tests.               |
+===============================================================+
```

Follow the testing patterns in CLAUDE.md (Development Rules section):

| When you change... | You must test... |
|-------------------|------------------|
| LiveView (`*_live.ex`) | LiveView test (`*_live_test.exs`) |
| Controller | Controller test |
| API endpoint | Request -> response behavior |
| Context module | Context test (if new public functions) |

**Before proceeding, list the test files created/modified:**

```
Tests created/modified:
- [ ] test/..._test.exs - tests for X
- [ ] test/..._test.exs - tests for Y
```

If no tests needed, explicitly justify why (e.g., "only changed private helper, tested via existing boundary test").

---

## Phase 7: Review Loop

**Actor**: Main agent | **Context**: ~10%

```
+===============================================================+
|  MANDATORY: DO NOT SKIP THIS PHASE                            |
|  You MUST run the review loop before proceeding to Phase 8    |
|  Code is NOT ready to commit until reviewer returns clean     |
+===============================================================+
```

**NOTE**: Plugin subagent types cannot be spawned from nested subagents.
The main agent must run this loop directly.

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

## Phase 8: Completion

**Actor**: Main agent | **Context**: ~5%

1. Run tests: `mix test` (or project equivalent)
2. Fix any test failures
3. Close completed beads:
   ```bash
   bd close <id> --reason "Implemented [brief description]" --json
   ```
4. Sync to git: `bd sync`
5. Present summary:

```
## Feature Complete

**Branch:** feat/[name]
**Issues closed:**
- [x] bd-abc123.1.1 - Implement login endpoint
- [x] bd-abc123.1.2 - Add session handling

**Files changed:** [count]
**Tests created:** [list test files]
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
| 6. Testing | ~5% | Main |
| 7. Review Loop | ~10% | Main (spawns reviewer) |
| 8. Completion | ~5% | Main |
| **Total** | **~80%** | |

---

## Beads Command Reference

| Action | Command |
|--------|---------|
| Find ready work | `bd ready --json` |
| Claim task | `bd update <id> --status in_progress --json` |
| Complete task | `bd close <id> --reason "..." --json` |
| Sync to git | `bd sync` |
| Show task details | `bd show <id> --json` |
| Create ad-hoc task | `bd create "Title" -t task -p 1 --json` |

---

## Quick Reference

- No beads issues? -> Use Path B (creates issues from user description)
- User describes feature inline? -> Use Path B even if beads exist
- **Path B always creates beads** -> All work must be tracked
- Subagents return summaries -> Read key files they identify
- User picks architecture -> Don't proceed without selection
- **Testing is MANDATORY** -> Phase 6, follow CLAUDE.md testing rules
- **Review loop is MANDATORY** -> Must run before Phase 8, no exceptions
- Review loop runs in main -> Plugin subagents can't be nested
- Complete phases in order -> Don't skip ahead
