---
name: brainstorm
description: Deep-dive interview for existing projects to plan the next phase of work. Reviews completed work, interviews about next steps, and creates beads. Use when user says "brainstorm", "what's next", "plan next phase", or wants to discuss future work.
user_invocable: true
arguments:
  - name: focus
    description: Optional focus area (e.g., "performance", "testing", "new feature")
    required: false
---

# Brainstorm

In-depth interview for existing projects to discover and plan the next phase of work.

---

## When to Use

- Project already has CLAUDE.md and beads set up
- Some work has been completed
- User wants to figure out what to work on next
- Planning a new phase or feature area

---

## Constraints

```
REQUIRE existing_project:
  - CLAUDE.md must exist
  - Beads must be initialized

INVARIANT non_obvious_questions:
  - Never ask questions with obvious answers
  - Probe edge cases, tradeoffs, concerns
  - Challenge assumptions
  - Explore what could go wrong

INVARIANT continuous_interview:
  - Keep interviewing until user signals completion
  - Don't stop after one round
  - Build on previous answers
  - Go deeper, not wider
```

---

## Phases

### Phase 1: Context Gathering

```
INPUTS: CLAUDE.md, beads state
OUTPUTS: project_context, completed_work[], open_work[]

READ CLAUDE.md to understand:
  - Project vision and goals
  - Tech stack and architecture
  - Conventions in use

RUN beads commands:
  - bd list --status=closed → completed_work[]
  - bd list --status=open → open_work[]
  - bd ready → ready_work[]

SUMMARIZE to user:
  "## Current State

  **Completed:** [count] tasks
  [list key completed items]

  **Open:** [count] tasks
  [list open items]

  **Ready to work on:** [count] tasks

  Let's discuss what's next."
```

### Phase 2: Deep Interview

```
STYLE:
  - Use AskUserQuestion for structured choices where applicable
  - Ask non-obvious questions that probe edge cases
  - Explore tradeoffs, not just features
  - Challenge assumptions
  - Follow up where answers are thin
  - Drive interview to completion - don't stop early

INTERVIEW ROUNDS (adapt based on project state):

  Round 1 - Reflection on Completed Work:
    - What worked well in what you've built?
    - What would you do differently if starting over?
    - Any technical debt that's bothering you?
    - Anything that felt harder than it should be?

  Round 2 - Next Priority:
    - What's the most valuable thing to build next?
    - What's blocking you from shipping to users?
    - What would make the biggest difference to UX?
    - Is there something you've been avoiding?

  Round 3 - Technical Concerns:
    - Where are the performance bottlenecks likely to appear?
    - What happens when this scales 10x? 100x?
    - Where is error handling weakest?
    - What's the testing gap?

  Round 4 - Edge Cases & Risks:
    - What's the worst thing a user could do?
    - What data loss scenarios exist?
    - What happens if external services fail?
    - What's underspecified that will bite you later?

  Round 5 - UX & Polish:
    - Where is the UX confusing or clunky?
    - What feedback are users missing?
    - What would make power users happy?
    - What's the mobile story?

  Round 6 - Scope & Priorities:
    - What can be cut or deferred?
    - What's the MVP for the next phase?
    - What's a nice-to-have vs must-have?
    - What order should things be built?

CONTINUE UNTIL:
  - User signals they're done
  - OR comprehensive next phase is defined
  - OR user says "that's enough" / "let's stop"

SIGNALS interview is complete:
  - Clear set of next features/tasks identified
  - Priorities understood
  - Edge cases acknowledged
  - User has no more to add
```

### Phase 3: Synthesize & Create Beads

```
PRECONDITION: Interview complete
INPUTS: interview_answers, project_context
OUTPUTS: new_beads[]

SYNTHESIZE into task breakdown:
  - Group related items into features
  - Identify dependencies
  - Estimate relative priority (P1/P2/P3)
  - Note any open questions as question-type beads

PRESENT proposed tasks:
  "## Proposed Next Phase

  ### Feature: [Name]
  - [ ] Task 1 (P1)
  - [ ] Task 2 (P2)

  ### Feature: [Name]
  - [ ] Task 1 (P1)

  ### Open Questions
  - [ ] Question to resolve later

  Does this capture it? Any changes?"

WAIT for user confirmation

ON confirm:
  FOR EACH feature:
    CREATE: bd create "[Feature]" -t feature -p 1 --json
    FOR EACH task:
      CREATE: bd create "[Task]" -t task -p [1|2|3] --parent <feature-id> --json

  FOR EACH question:
    CREATE: bd create "[Question]" -t task -l question -p 3 --json

RUN: bd sync

REPORT:
  "Created [X] features, [Y] tasks, [Z] questions.

  Run `bd ready` to see what's ready to work on.
  Run `/next-feature` to start implementing."
```

---

## Interview Tips

```
GOOD questions (non-obvious, probe depth):
  - "You mentioned X - what happens if Y fails during that?"
  - "How does this interact with [existing feature]?"
  - "What's the failure mode you're most worried about?"
  - "If you had to ship tomorrow, what would you cut?"

BAD questions (obvious, surface-level):
  - "What features do you want?"
  - "What's the project about?"
  - "Do you want tests?"
  - "Should we use TypeScript?"

FOLLOW-UP patterns:
  - "You said X - can you elaborate on the edge cases?"
  - "What about [related concern] - is that handled?"
  - "Earlier you mentioned Y - does that conflict with this?"
  - "What's the worst case scenario there?"
```

---

## Quick Reference

```
| Step | Action |
|------|--------|
| 1 | Read CLAUDE.md and beads state |
| 2 | Summarize current state to user |
| 3 | Interview (multiple rounds, non-obvious questions) |
| 4 | Synthesize into task breakdown |
| 5 | Get user confirmation |
| 6 | Create beads |
| 7 | Report and suggest next steps |
```
