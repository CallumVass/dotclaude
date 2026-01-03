---
name: self-improve
description: Run autonomous experiments to test and improve dotclaude rules. Creates experiment branches, builds test projects, analyzes results, and proposes rule improvements via PR.
user_invocable: true
arguments:
  - name: template
    description: Experiment template name (default: todo-api)
    required: false
  - name: auto-pr
    description: Automatically create PR when done (default: false)
    required: false
---

# Self-Improve

Run autonomous experiments to test and improve dotclaude rules through practice.

---

## Overview

This skill runs a complete feedback loop:

```
1. Create experiment branch
2. Build test project using dotclaude conventions
3. Complete all beads tasks via /next-feature
4. Analyze what worked and what didn't
5. Apply learnings to rules
6. Create PR for human review
```

---

## Usage

```
/self-improve                    # Run with default template (todo-api)
/self-improve vue-dashboard      # Run with specific template
/self-improve todo-api --auto-pr # Auto-create PR when done
```

---

## Available Templates

| Template | Description | Beads |
|----------|-------------|-------|
| `todo-api` | TypeScript REST API with Express | 7 tasks |

Templates are in `.claude/sandbox/templates/`.

---

## How It Works

### Phase 1: Setup
- Creates branch: `experiment/<template>-<timestamp>`
- Creates directory: `experiments/<id>/`
- Initializes beads with sync branch
- Seeds tasks from template

### Phase 2: Execution
- Runs `/init-project typescript`
- Loops `/next-feature` until all beads complete
- Each session captured to `sessions/*.json`
- Landing protocol ensures all work committed

### Phase 3: Analysis
- Collects all session outputs
- Compares against dotclaude conventions
- Identifies what was followed/missed
- Proposes rule improvements

### Phase 4: Learning
- Applies targeted rule changes
- Only evidence-based improvements
- No speculative changes

### Phase 5: PR
- Pushes experiment branch
- Creates PR (if --auto-pr)
- Includes summary and diff

---

## Execution

```
STEPS:
  1. VERIFY we're in dotclaude repo root

  2. RUN the experiment runner:
     .claude/sandbox/runner.sh <template> [--auto-pr]

  3. MONITOR output for:
     - Beads task completion
     - Session logs created
     - Analysis results
     - Rule changes proposed

  4. REPORT final status:
     - Branch name
     - Sessions completed
     - Rules changed
     - PR link (if created)
```

---

## Templates

### Creating New Templates

Templates define what Claude should build. Format:

```markdown
# Experiment: [Name]

[Description of what to build]

## Pre-seeded Beads

```bash
bd create --title="Task 1" --type=task --priority=1
bd create --title="Task 2" --type=task --priority=2
```

## Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Convention Checks

After completion, verify:

1. **Category**
   - [ ] Convention followed?
   - [ ] Pattern used correctly?

## Stack

```json
{
  "runtime": "node",
  "language": "typescript"
}
```
```

---

## Output Structure

```
experiments/<id>/
├── template.md           # Copy of experiment template
├── beads-initial.txt     # Initial bead state
├── beads-after-N.txt     # State after each iteration
├── sessions/
│   ├── 01-init-project.json
│   ├── 02-next-feature.json
│   └── ...
├── analysis.json         # Experiment analysis
├── applied-learnings.md  # What rules were changed
├── SUMMARY.md            # Human-readable summary
└── project/              # The built test project
    ├── src/
    ├── tests/
    └── ...
```

---

## Safety

- Experiments run in isolated branches
- No changes to main without PR review
- Human approves all rule changes via PR
- Can discard experiment: `git checkout main && git branch -D <branch>`

---

## Quick Reference

```
| Action               | Command                                |
|----------------------|----------------------------------------|
| Run experiment       | /self-improve                          |
| With template        | /self-improve <template>               |
| With auto PR         | /self-improve <template> --auto-pr     |
| List templates       | ls .claude/sandbox/templates/          |
| View results         | cat experiments/<id>/SUMMARY.md        |
| Discard experiment   | git checkout main && git branch -D ... |
```
