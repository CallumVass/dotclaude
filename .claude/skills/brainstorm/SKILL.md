---
name: brainstorm
description: Deep-dive interview to discover features, requirements, and edge cases. Use when starting a project, planning features, or user says "brainstorm", "spec", "interview me", "let's plan", "help me think through", "what should I build".
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

**Deployment & Operations** (if not already configured)
- "Where should this run - edge, containers, serverless?"
- "What's the deploy cadence - continuous on merge, or batched releases?"
- "Any database or persistent storage needs?"

## Process

1. **Gather context** (in order of preference):

   **If spec file exists:** Read it, use as foundation. Goal: go deeper, find gaps.

   **Else if beads initialized (`bd version` succeeds):** Run `bd list --json`, summarise understanding. Goal: expand scope, refine existing.

   **Else (greenfield):** Ask "What are you looking to build?" Goal: shape vision, then drill into details.

2. **Interview loop:**
   - Ask 1-2 probing questions per round using AskUserQuestion
   - Go deeper on vague areas, track decisions made
   - Continue until user says "done", "that's it", or similar

3. **Write spec:**
   - Update/create spec file with everything learned
   - Structure: Overview, Requirements, Technical Design, Open Questions
   - Be concrete - include decisions made, not just questions asked

4. **For new projects** (no existing CI/deployment detected):
   - Establish CI and deployment infrastructure BEFORE feature work
   - See [references/deployment-ci.md](references/deployment-ci.md) for full process

5. **If app has a UI** (React, Vue, Svelte, Next.js, etc.):
   - Establish design system BEFORE creating implementation issues
   - See [references/design-system.md](references/design-system.md) for full process

6. **Create beads issues** (if beads initialized and user agrees):
   - Create epic + tasks using `bd create`
   - **Use issue format from [references/autonomous-issues.md](references/autonomous-issues.md)**
   - **Always use `--validate` flag**
   - **Tasks must be vertical slices** - each includes boundary + tests
   - **Issue creation order**: CI → Deployment → Prod config → Design system → Features
   - Run `bd lint` to verify all issues have required sections

7. **Summarise** what was captured and next steps.

## Interview Style

- Be curious, not interrogative
- "Tell me more about..." not "Explain..."
- Offer options when useful: "Would you lean toward A (simpler) or B (more flexible)?"
- Acknowledge good answers briefly, then push deeper
- If user is unsure, help them think through it rather than moving on
