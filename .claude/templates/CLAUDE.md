# {{PROJECT_NAME}}

## Overview

{{BRIEF_DESCRIPTION}}

## Work Initiation Protocol

**ALL work MUST go through beads.** Before starting ANY implementation:

1. **Check for existing issue**: `bd ready` or `bd list --status=open`
2. **If no issue exists, create one first**:
   ```bash
   bd create --title="<brief description>" --type=task|bug|feature --priority=2
   ```
3. **Run the next-feature skill** to execute the work:
   ```
   /next-feature
   ```

The `next-feature` skill handles: picking up the issue, planning, implementation, and beads status updates.

**This applies to ALL requests:**
- Explicit features ("add dark mode")
- Ad-hoc cleanup ("tidy up the boilerplate")
- Bug fixes ("fix the login error")
- Refactoring ("clean up this module")

**No code changes without a tracking issue. No implementation without next-feature.**

## Vision

{{ONE_LINER}}

## Problem

{{PROBLEM_DESCRIPTION}}

## Users

{{TARGET_USERS}}

## Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Frontend | {{FRONTEND}} | {{WHY}} |
| Backend | {{BACKEND}} | {{WHY}} |
| Database | {{DATABASE}} | {{WHY}} |

## Key Commands

```bash
{{DEV_COMMAND}}      # Development
{{TEST_COMMAND}}     # Test
{{BUILD_COMMAND}}    # Build
```

## Data Model

### {{ENTITY_1}}

- id, {{FIELD_1}}, {{FIELD_2}}

### {{ENTITY_2}}

- id, {{FIELD_1}}, {{FIELD_2}}

## Architecture

{{KEY_ARCHITECTURE_NOTES}}

## Conventions

- {{CONVENTION_1}}
- {{CONVENTION_2}}

---

*Run `bd ready` for available work. Run `bd show <id>` for task details.*

---

# Development Rules

{{INLINE_PATTERNS_RULES}}

---

# {{STACK_NAME}} Rules

{{INLINE_STACK_RULES}}
