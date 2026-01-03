---
name: brainstorm
description: Deep-dive interview to discover features, requirements, and edge cases. Use when starting a project, planning features, or user says "brainstorm", "spec", "interview me", "let's plan".
arguments:
  - name: spec
    description: Path to spec file (defaults to SPEC.md)
    required: false
  - name: create-issues
    description: Create beads issues from spec when done (defaults to true if beads initialized)
    required: false
---

# Brainstorm

Interview the user to build a comprehensive spec, then optionally create beads issues.

## Constraints

- Ask non-obvious questions - assume user has thought about the basics
- Go deep on technical implementation, UX, edge cases, tradeoffs
- Continue until user signals completion
- Never ask yes/no questions - ask open-ended or offer specific options
- Challenge assumptions respectfully

## Question Categories

Cycle through these, adapting to context:

**Technical depth**
- "How should X behave when Y fails?"
- "What's the recovery path if Z gets corrupted?"
- "Where does this data live and who owns it?"

**UX and interaction**
- "What does the user see while waiting for X?"
- "How do they undo this action?"
- "What happens on the second use vs first use?"

**Edge cases**
- "What if there are 10,000 of these?"
- "What if the user is offline?"
- "What if two users do this simultaneously?"

**Tradeoffs**
- "Speed vs correctness - where do you lean here?"
- "Do we build X now or defer it?"
- "What's the MVP vs the ideal?"

**Concerns**
- "What keeps you up at night about this?"
- "What's the riskiest assumption?"
- "Where might we be wrong?"

## Process

1. Gather context (in order of preference):

   **If spec file exists:**
   - Read it, use as foundation for interview
   - Goal: go deeper, find gaps, challenge assumptions

   **Else if beads initialized (`bd version` succeeds):**
   - Run `bd list --json` to get existing issues
   - Read epics and tasks to understand project scope
   - Summarise understanding to user: "Based on your issues, this looks like X. Is that right?"
   - Goal: expand scope, discover new features, refine existing

   **Else (greenfield):**
   - Ask user: "What are you looking to build?"
   - Get high-level description before diving deep
   - Goal: shape the vision, then drill into details

2. Interview loop:
   - Ask 1-2 probing questions per round using AskUserQuestion
   - Listen to answers, note gaps and assumptions
   - Go deeper on vague areas
   - Track decisions made
   - Continue until user says "done", "that's it", or similar

3. Write spec:
   - Update/create spec file with everything learned
   - Structure: Overview, Requirements, Technical Design, Open Questions
   - Be concrete - include decisions made, not just questions asked

4. If beads is initialized (`bd version` succeeds) and create-issues not disabled:
   - Ask user if they want to create issues from the spec
   - If yes, create epic + tasks using `bd create`
   - Link tasks to epic

5. Summarise what was captured and next steps.

## Interview Style

- Be curious, not interrogative
- "Tell me more about..." not "Explain..."
- Offer options when useful: "Would you lean toward A (simpler) or B (more flexible)?"
- Acknowledge good answers briefly, then push deeper
- If user is unsure, help them think through it rather than moving on
