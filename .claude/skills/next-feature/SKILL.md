---
name: next-feature
description: Pick next beads issue, explore codebase, design architecture, implement, review. Use when user says "next feature", "next task", "pick an issue", "what's next", "start working", "implement issue", "work on bd-xxx", "let's build".
---

# Next Feature

Pick a beads issue, understand the codebase, design the approach, implement, review, complete.

## Constraints

- Require beads initialized (`bd version` succeeds)
- Never implement without user approval on architecture (full path)
- Always run `/review-loop` before marking complete
- Commit with issue ID in message
- **Boundary tests are mandatory** - task is not complete without them

## Process

### 1. Pick issue

If `issue` argument provided, use that. Otherwise run `bd ready --json` and pick the top issue.

Show user: title, description, any parent epic context. Confirm this is what they want to work on.

### 2. Create feature branch

```
git checkout -b feature/bd-xxx-short-description
```

Use issue ID and slugified title. Example: `feature/bd-a1b2-add-user-auth`

### 3. Assess scope

Quick analysis to determine lite vs full path:

**Lite path indicators:**
- Issue mentions single file or component
- Language like "fix", "change", "update", "tweak", "rename"
- Quick grep shows 1-3 files affected
- No architectural decisions needed

**Full path indicators:**
- New feature spanning multiple files
- Language like "add", "implement", "create", "integrate"
- Touches multiple layers (API, service, UI)
- Needs design decisions

Tell user which path and why. Let them override if they disagree.

---

## Lite Path

For small, focused changes.

### 3. Implement

Make the change directly. Keep it focused.

### 4. Review & Complete

Run `/review-loop`, then go to **Complete** below.

---

## Full Path

For complex features needing exploration and design.

### 3. Explore codebase

Spawn `feature-dev:code-explorer` to:
- Find relevant existing code
- Trace similar features
- Map architecture layers
- Identify 5-10 key files

Present findings summary to user.

### 4. Clarifying questions

Based on the issue and exploration, identify gaps:
- Edge cases not specified
- Error handling approach
- Scope boundaries
- Integration points

Ask user using AskUserQuestion. Don't proceed until clear.

### 5. Architecture design

Spawn `feature-dev:code-architect` to:
- Analyse patterns and conventions found
- Design implementation approach
- Identify files to create/modify
- Define build sequence

Present architecture to user. Get explicit approval before implementing.

### 6. Implement

Build the feature following approved architecture and codebase conventions.

### 7. Review & Complete

Run `/review-loop`, then go to **Complete** below.

---

## Complete

Both paths end here.

### Pre-completion gate

Before marking done, verify boundary tests exist:

| If you created... | You must have... |
|-------------------|------------------|
| Vue/React component | Component test (mount, interact, assert) |
| LiveView | LiveViewTest with `live()` |
| Controller/API endpoint | Request test (HTTP in, response out) |
| CLI command | Integration test (invoke, check output) |

**If boundary tests are missing, write them before proceeding.**

Unit tests for internal helpers (composables, services, utils) do NOT satisfy this requirement - the test must exercise the boundary itself.

### Finish

```
bd status <issue-id> done
git add -A
git commit -m "Description (bd-xxx)"
git push -u origin HEAD
bd sync
```

Ask user if they want to create a PR. If yes:

```
gh pr create --title "Description (bd-xxx)" --body "Closes bd-xxx"
```

Summarise what was built and any follow-up tasks.
