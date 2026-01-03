---
name: init-project
description: Initialize a new project with CLAUDE.md and beads issue tracking. Use when user says "init project", "initialize", "set up project", "start new project", or wants to document an existing codebase.
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

Initialize a project with CLAUDE.md (inlined rules) and beads issue tracking.

---

## Constraints

```
REQUIRE beads_installed:
  - Check `bd --version` BEFORE any other step
  - If missing: offer installation, wait for confirmation
  - If user declines: warn that beads features unavailable, continue without

REQUIRE stack_confirmed:
  - Never assume stack - detect OR ask user
  - Ambiguous detection → ask user to pick

INVARIANT preserve_existing:
  - Never overwrite CLAUDE.md without asking
  - Existing content merged, not replaced

INVARIANT rules_inlined:
  - Rules copied INTO CLAUDE.md, not referenced
  - Source rule files deleted after inlining
```

---

## Modes

```
MODE new_project (default):
  - Full brainstorming phase
  - Create issue hierarchy from scratch

MODE existing_project:
  - WHEN: codebase files detected (package.json, mix.exs, *.csproj, etc.)
  - SKIP: brainstorming
  - DO: scan structure, detect conventions, document existing state

MODE migration:
  - WHEN: docs/PROGRESS.md OR docs/PRD.md exist
  - DO: import existing items to beads before continuing
  - THEN: archive originals to docs/archive/
```

---

## Phases

### Phase 0: Beads Check

```
INPUTS: none
OUTPUTS: beads_available (boolean)
BLOCKS: all other phases if beads required

CHECK: bd --version

IF missing:
  PROMPT: "Beads required but not installed. Install now? (y/n)"
  
  IF yes:
    DETECT environment:
      - npm available → npm install -g @beads/bd
      - brew available → brew install steveyegge/beads/bd
      - go available → go install github.com/steveyegge/beads/cmd/bd@latest
    VERIFY: bd --version
  
  IF no:
    WARN: "Continuing without beads - task tracking unavailable"
    SET beads_available = false

DONE WHEN: beads_available determined
```

### Phase 1: Discovery

```
INPUTS: existing files, user context
OUTPUTS: project_type (new|existing), detected_stack, existing_docs[]

SCAN for:
  - package.json → TypeScript (check for vue/react)
  - *.csproj/*.fsproj → .NET (check language)
  - mix.exs → Elixir (check for phoenix)
  - docs/PROGRESS.md, docs/PRD.md → migration candidates

IF ambiguous stack:
  ASK: "Which stack? 1) TS/Vue 2) TS/React 3) .NET/C# 4) .NET/F# 5) Elixir"
  WAIT for answer

DONE WHEN: stack confirmed by detection or user
```

### Phase 2: Migration Check

```
PRECONDITION: Phase 1 complete
INPUTS: existing_docs[] from Phase 1
OUTPUTS: migration_complete (boolean)

IF docs/PROGRESS.md OR docs/PRD.md exist:
  ASK: "Found existing PROGRESS.md/PRD.md. Import to beads? (y/n)"
  
  IF yes:
    RUN migration subroutine (see Migration section)
    SET migration_complete = true
  
  IF no:
    SET migration_complete = false

DONE WHEN: migration decision made and executed
```

### Phase 3: Brainstorming Interview

```
PRECONDITION: Phase 2 complete
CONDITION: MODE = new_project
SKIP WHEN: MODE = existing_project

INPUTS: user's project idea
OUTPUTS: spec document (features[], entities[], constraints[],
         technical_decisions[], ux_patterns[], tradeoffs[], risks[])

STYLE:
  - Use AskUserQuestion tool for structured choices where applicable
  - Ask non-obvious questions that probe edge cases
  - Explore tradeoffs, not just features
  - Follow up where answers are thin
  - Drive interview to completion - don't wait for user to end it

INTERVIEW ROUNDS (adapt based on project type):

  Round 1 - Problem Space:
    - What happens if this problem isn't solved?
    - Who else has tried? Why did they fail/succeed?
    - What's the smallest version that would still be valuable?

  Round 2 - User Behavior:
    - What's the user's state of mind when they arrive?
    - What action do they take immediately after using this?
    - What would make them abandon it mid-task?

  Round 3 - Technical Tradeoffs:
    - Offline-first vs always-connected?
    - Optimistic UI vs wait-for-server?
    - Where does data live? Who owns it?
    - What fails gracefully vs hard-fails?

  Round 4 - Edge Cases & Risks:
    - What happens at 10x scale? 100x?
    - What's the worst misuse scenario?
    - What data would be catastrophic to lose?

  Round 5 - UX Decisions:
    - Mobile-first or desktop-first?
    - Wizard flow or single-page?
    - Progressive disclosure or everything visible?

CONTINUE UNTIL:
  - Sufficient detail gathered to write comprehensive spec
  - No obvious gaps in problem/solution/technical approach
  - OR user signals early completion

SIGNALS spec is complete:
  - Core user flows are defined
  - Data model is clear
  - Key technical decisions made (auth, storage, real-time, etc.)
  - Edge cases acknowledged
  - MVP scope is bounded

SYNTHESIZE into structured spec document before Phase 4
```

### Phase 4: Generate CLAUDE.md

```
PRECONDITION: stack confirmed
INPUTS: detected_stack, features[], entities[] (if new project)
OUTPUTS: CLAUDE.md file

STRUCTURE:
  1. Project header (name, overview, vision, problem, users)
  2. Stack table with rationale
  3. Key commands (dev, test, build)
  4. Data model (entities)
  5. Architecture notes
  6. Conventions
  7. Separator: "---"
  8. Beads reference: "Run `bd ready` for work, `bd show <id>` for details"
  9. Separator: "---"
  10. INLINED patterns.md (remove YAML frontmatter)
  11. Separator: "---"
  12. INLINED stack rules (remove YAML frontmatter)

INLINE these files based on stack:
  | Stack          | Files to inline                                    |
  |----------------|---------------------------------------------------|
  | TypeScript/Vue | patterns.md + typescript/core.md + typescript/vue.md |
  | TypeScript/React | patterns.md + typescript/core.md + typescript/react.md |
  | .NET/C#        | patterns.md + dotnet/core.md + dotnet/csharp.md   |
  | .NET/F#        | patterns.md + dotnet/core.md + dotnet/fsharp.md   |
  | Elixir         | patterns.md + elixir/setup.md                     |

DONE WHEN: CLAUDE.md created with all sections
```

### Phase 5: Initialize Beads

```
PRECONDITION: Phase 4 complete, beads_available = true
SKIP WHEN: beads_available = false

INPUTS: none
OUTPUTS: beads initialized, hooks configured, sync branch set

RUN:
  # Initialize with sync branch for protected branch workflow
  bd init --branch beads-sync

  # OR if --branch not supported:
  bd init
  bd config set sync.branch beads-sync

  # Set up Claude integration
  bd setup claude --project

  # Install git hooks (required for proper sync)
  bd hooks install

  # Verify setup
  bd doctor

IF bd doctor reports issues:
  FOLLOW its suggestions before continuing

IF AGENTS.md created by beads:
  APPEND contents to CLAUDE.md under "## Beads Workflow"
  DELETE AGENTS.md

NOTE on sync branch workflow:
  - Beads commits to beads-sync branch, not main
  - This allows protected main branch
  - bd sync handles the branch automatically
  - Git hooks ensure changes are captured

DONE WHEN: bd doctor passes, hooks installed
```

### Phase 6: Create Issue Hierarchy

```
PRECONDITION: Phase 5 complete (or skipped if no beads)
CONDITION: beads_available = true
SKIP WHEN: beads_available = false

INPUTS: features[] from Phase 3
OUTPUTS: epic_ids[], feature_ids[], task_ids[]

STRUCTURE:
  - Epics = Phases (Phase 1: MVP, Phase 2, etc.)
  - Features = Feature groups
  - Tasks = Individual work items
  - Questions = Open items (label: question, priority: P3)

FOR EACH phase:
  CREATE epic: bd create "Phase N: [Name]" -t epic -p 0 --json
  
  FOR EACH feature group in phase:
    CREATE feature: bd create "[Name]" -t feature --parent <epic-id> --json
    
    FOR EACH task in feature:
      CREATE task: bd create "[Name]" -t task -p [1|2] --parent <feature-id> --json

FOR EACH open question:
  CREATE: bd create "[Question]" -t task -l question -p 3 --json

DONE WHEN: all items created, bd ready shows tasks
```

### Phase 7: Cleanup

```
PRECONDITION: Phase 6 complete (or Phase 4 if no beads)

INPUTS: none
OUTPUTS: cleaned directory structure

DELETE (now inlined into CLAUDE.md):
  - .claude/rules/
  - .claude/templates/

KEEP (still required):
  - .claude/skills/
  - .claude/settings.local.json

DONE WHEN: only skills and settings remain
```

### Phase 8: Report & Restart

```
PRECONDITION: Phase 7 complete

OUTPUT to user:
  1. Files created (CLAUDE.md)
  2. Stack detected/selected
  3. Beads status (bd ready output if available)
  4. Files cleaned up

INSTRUCT:
  "## Setup Complete!
   
   Restart Claude Code to load the new configuration.
   After restart, run `/next-feature` to begin work."

DONE WHEN: user acknowledged
```

---

## Migration Subroutine

```
TRIGGER: user accepts migration in Phase 2

STEP 1 - Init beads:
  bd init
  bd setup claude --project

STEP 2 - Parse PROGRESS.md:
  FOR EACH phase heading:
    CREATE epic: bd create "Phase N: [Name]" -t epic -p 0 --json
    
    FOR EACH feature group (### heading):
      CREATE feature: bd create "[Name]" -t feature --parent <epic-id> --json
      
      FOR EACH task line:
        CREATE task: bd create "[Task]" -t task --parent <feature-id> --json
        IF marked [x]:
          IMMEDIATELY: bd close <task-id> --reason "Previously completed"

STEP 3 - Parse PRD.md:
  EXTRACT: Vision, Problem, Users, Stack, Data Model sections
  MERGE into CLAUDE.md structure
  
  FOR EACH "Open Questions" item:
    CREATE: bd create "[Question]" -t task -l question -p 3 --json

STEP 4 - Archive:
  mkdir -p docs/archive
  mv docs/PROGRESS.md docs/archive/PROGRESS.md.bak
  mv docs/PRD.md docs/archive/PRD.md.bak

STEP 5 - Sync:
  bd sync

REPORT:
  - Epics created: X
  - Features created: X  
  - Tasks created: X (Y already completed)
  - Questions imported: X
```
