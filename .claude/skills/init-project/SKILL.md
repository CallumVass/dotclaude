---
name: init-project
description: Initialize a new project with PRD, PROGRESS.md, and project structure. Brainstorms ideas and asks clarifying questions.
user_invocable: true
arguments:
  - name: name
    description: Project name (optional - will prompt if not provided)
    required: false
  - name: stack
    description: Tech stack hint (typescript, dotnet, elixir, or auto-detect)
    required: false
---

# Init Project

Guides you through initializing a new project or documenting an existing one.

## Process

### 1. Discovery Phase

First, understand what we're working with:

**For new projects:**
- What problem are we solving?
- Who are the users?
- What's the core value proposition?
- What tech stack are we using?

**For existing projects:**
- Scan the codebase structure
- Identify the tech stack from config files
- Understand current state
- Document what exists

### 2. Stack Detection

Look for these indicators:

| Stack | Indicators |
|-------|-----------|
| TypeScript/Vue | `package.json` with vue, `nuxt.config.ts`, `.vue` files |
| TypeScript/React | `package.json` with react, `next.config.js`, `.tsx` files |
| .NET/C# | `*.csproj`, `*.sln`, `Program.cs` |
| .NET/F# | `*.fsproj`, `*.fs` files |
| Elixir | `mix.exs`, `*.ex` files, `lib/` folder |
| Phoenix | `mix.exs` with phoenix dep, `_web/` folders |

### 3. Brainstorming (New Projects)

Ask clarifying questions:

1. **Core Features**: What are the 3-5 must-have features for MVP?
2. **User Flows**: What's the primary user journey?
3. **Data Model**: What are the main entities?
4. **Constraints**: Any technical requirements? (offline, real-time, etc.)
5. **Timeline**: What's the scope? (weekend project vs. long-term)

### 4. Generate PRD

Create `docs/PRD.md` with:

```markdown
# [Project Name]

## Vision
[One-liner describing what this is]

## Problem
[What problem does this solve?]

## Users
[Who is this for?]

## Core Features

### MVP (Phase 1)
- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

### Phase 2
- [ ] Feature 4
- [ ] Feature 5

## Technical Decisions

### Stack
- [Framework/Language]
- [Database]
- [Key libraries]

### Architecture
[High-level architecture notes]

## Data Model

### [Entity 1]
- field1: type
- field2: type

### [Entity 2]
- field1: type
- field2: type

## Open Questions
- [ ] Question 1?
- [ ] Question 2?
```

### 5. Generate PROGRESS.md

Create `docs/PROGRESS.md` with:

```markdown
# Progress Tracker

**Last Updated:** [Date]
**Current Phase:** Phase 1 - MVP

## Summary

| Phase | Status | Progress |
|-------|--------|----------|
| Phase 1 - MVP | In Progress | 0/X |
| Phase 2 | Not Started | 0/X |

---

## Phase 1: MVP

### 1.1 [Feature Group]

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### 1.2 [Feature Group]

- [ ] Task 1
- [ ] Task 2

---

## Phase 2: [Name]

### 2.1 [Feature Group]

- [ ] Task 1
- [ ] Task 2
```

### 6. Stack-Specific Setup

**For TypeScript projects:**
- Suggest appropriate rules to enable in `.claude/`
- Note any useful shortcuts or patterns

**For .NET projects:**
- Suggest solution structure
- Note F# vs C# patterns if applicable

**For Elixir/Phoenix projects:**

Follow `.claude/rules/elixir/setup.md` - uses ecosystem tooling (Igniter, usage_rules, AGENTS.md) rather than prescriptive rules.

### 7. Output

Report back with:

1. Created/updated files
2. Detected stack and recommended rules
3. Next steps to start development
4. Suggestion to use `/next-feature` to begin work

## Notes

- Always create `docs/` directory if it doesn't exist
- If PRD.md or PROGRESS.md exist, ask before overwriting
- Preserve any existing work while adding structure
