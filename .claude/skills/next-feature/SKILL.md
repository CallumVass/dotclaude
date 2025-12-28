---
name: next-feature
description: Start planning the next feature. Reads PROGRESS.md to find related unchecked items that can be worked on together.
user_invocable: true
arguments:
  - name: steer
    description: Optional direction to steer towards a specific feature area
    required: false
---

# Next Feature

Helps you pick and start the next vertical slice of work.

## Arguments

- **steer** (optional): A hint towards a specific feature area. Examples:
  - `/next-feature auth` - focus on authentication
  - `/next-feature api` - work on API endpoints
  - `/next-feature UI` - prioritize UI work
  - `/next-feature` - (no steer) auto-suggest based on progress order

## Process

### 1. Read PROGRESS.md

- Read `docs/PROGRESS.md` (or find it if in different location)
- Find the current phase section (marked as "Current Phase" or "In Progress")
- Parse the checkbox format: `[x]` = done, `[ ]` = not done

### 2. Find Related Items (Group Work)

Look at ALL unchecked `[ ]` items in the current phase and group items that are related:

- Same subsection (e.g., "1.2 User Authentication")
- Dependent on each other
- Touch the same files/systems
- If user provided a steer, prioritize matching groups

### 3. Present Grouped Items

Show the group of related items (not just one!):

- Explain why they belong together
- Estimate scope (small/medium/large vertical slice)
- List key files likely to be touched

### 4. Recommend Workflow

Suggest using `/feature-dev` plugin for planning the implementation - this provides guided architecture-first development.

### 5. On Confirmation

- Create feature branch: `git checkout -b feat/<feature-name>`
- Use the `feature-dev:feature-dev` skill to plan implementation

## Grouping Logic

Items should be grouped when they:

1. **Same subsection** - All items under a heading go together
2. **Shared dependencies** - If B needs A, suggest A+B together
3. **Same system** - Items touching the same service/module
4. **Logical unit** - A feature isn't complete without all parts

## Output Format

```
## Current Phase: [Phase Name]

Progress: X/Y items complete

### Suggested Work Group

These items should be done together:

1. [ ] First item - why it's needed
2. [ ] Second item - how it relates
3. [ ] Third item - completes the slice

**Why grouped:**
- [Explanation of relationship]
- [What completing them together achieves]

**Scope:** [Small/Medium/Large] vertical slice
**Branch:** `feat/[name]`
**Files likely touched:** [key files]

### Recommended Workflow

Use `/feature-dev` to plan the architecture before implementing.

Ready to start? (y/n)
```

## Stack-Specific Notes

### TypeScript (Vue/React/Node)
- Check `package.json` scripts for test/build commands
- Look for existing patterns in `src/` or `app/`

### .NET (C#/F#)
- Check solution structure for project organization
- Look for existing patterns in the main project
- Note if using minimal APIs, MVC, or Blazor

### Elixir (Phoenix)
- Check `mix.exs` for available tasks
- Look at context organization in `lib/`
- Check for existing patterns in web layer

## Notes

- Always complete current phase before moving to next
- Prefer completing a full vertical slice over starting multiple features
- If no PROGRESS.md exists, suggest running `/init-project` first
