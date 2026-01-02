---
name: next-feature
description: Feature development workflow with mandatory quality gates. Use when user says "next feature", "work on", "let's build", "implement", "add a feature", describes a feature, or pastes a JIRA ticket. ALWAYS use this skill for feature work.
user_invocable: true
arguments:
  - name: steer
    description: Optional direction to steer towards a specific feature area
    required: false
---

# Next Feature

Guided feature development with beads tracking and mandatory quality gates.

**Philosophy**: Main agent coordinates, subagents do heavy lifting. Gates are non-negotiable.

---

## Gates (NEVER SKIP)

```
GATE tests_before_review:
  Phase 7 (Review) BLOCKED until Phase 6 (Testing) complete
  
  REQUIRED: test_files[] is non-empty OR explicit_justification provided
  EXPLICIT JUSTIFICATION must state why no tests needed
  "It's a small change" is NOT valid justification

GATE review_before_complete:
  Phase 8 (Completion) BLOCKED until Phase 7 (Review) returns clean
  
  REQUIRED: reviewer returned "NO ISSUES FOUND"
  No exceptions for "simple" changes
  No manual override

GATE track_all_work:
  ALL work creates beads issues
  - Path A: uses existing issues
  - Path B: creates issues before starting
  
  Completion BLOCKED until issues closed with reason
```

---

## Invariants

```
INVARIANT branch_per_feature:
  Every feature gets its own branch: feat/<feature-name>
  Never work directly on main/master

INVARIANT subagent_summaries_only:
  Subagents return summaries, not full content
  Main agent reads key files they identify
  Keeps main context lean

INVARIANT user_picks_architecture:
  Phase 5 (Implementation) BLOCKED until user selects approach
  "Whatever you think" → give recommendation, get explicit confirmation
```

---

## Modes

```
MODE full (default):
  All 8 phases
  Parallel subagents for exploration and architecture
  
MODE light:
  TRIGGER: user says "quick fix", "small change", "just update"
           OR estimated scope < 50 lines
           OR single-file change
  
  SKIP: Phase 2 (Exploration), Phase 4 (Architecture)
  KEEP: Phase 6 (Testing), Phase 7 (Review) ← NEVER SKIPPABLE
  
  EXPLICIT: Tell user "Using light mode - skipping exploration/architecture"
```

---

## Context Budget

```
| Phase                | Budget | Actor              |
|----------------------|--------|--------------------|
| 1. Feature Selection | ~5%    | Main               |
| 2. Exploration       | ~5%    | Subagents          |
| 3. Clarification     | ~5%    | Main               |
| 4. Architecture      | ~5%    | Subagents          |
| 5. Implementation    | ~40%   | Main               |
| 6. Testing           | ~5%    | Main               |
| 7. Review Loop       | ~10%   | Main → Subagent    |
| 8. Completion        | ~5%    | Main               |
| TOTAL                | ~80%   | Reserve 20%        |
```

---

## Phases

### Phase 1: Feature Selection

```
INPUTS: user request, optional steer hint, bd ready output
OUTPUTS: selected_tasks[], branch_name, scope (small|medium|large)
NEXT: Phase 2 (full) or Phase 3 (light)

PATH A - Beads issues exist:
  RUN: bd ready --json
  PARSE: available work items
  GROUP BY: parent (epic/feature)
  FILTER BY: steer hint if provided
  
  PRESENT:
    "## Ready Work
    
    **Epic:** [name] ([id])
    **Feature:** [name] ([id])
    
    Ready tasks:
    1. [task] ([id]) - [priority]
    2. [task] ([id]) - [priority]
    
    **Scope:** [Small/Medium/Large]
    **Branch:** feat/[name]
    
    Ready to start? (y/n)"
  
  ON confirm:
    FOR EACH task: bd update <id> --status in_progress --json
    RUN: git checkout -b feat/<feature-name>

PATH B - Ad-hoc feature (user describes feature inline):
  EXTRACT: requirements from description
  BREAK DOWN: into discrete tasks
  
  PRESENT:
    "## Ad-hoc Feature
    
    ### Tasks
    1. [task]
    2. [task]
    3. [task]
    
    **Scope:** [Small/Medium/Large]
    **Branch:** feat/[name]
    
    Does this capture it? (y/n)"
  
  ON confirm:
    CREATE feature: bd create "[Feature]" -t feature -p 1 --json
    FOR EACH task:
      CREATE: bd create "[Task]" -t task -p 1 --parent <feature-id> --json
      UPDATE: bd update <task-id> --status in_progress --json
    RUN: git checkout -b feat/<feature-name>
    
    REPORT created issues before proceeding

DETERMINE mode:
  IF scope = small OR user said "quick"/"small": MODE = light
  ELSE: MODE = full

DONE WHEN: branch created, tasks marked in_progress, mode determined
```

### Phase 2: Exploration

```
CONDITION: MODE = full
SKIP WHEN: MODE = light

INPUTS: feature requirements from Phase 1
OUTPUTS: key_files[], patterns[], architecture_notes[]
NEXT: Phase 3

SPAWN parallel subagents:

  TASK 1 (similar features):
    subagent_type: "feature-dev:code-explorer"
    prompt: "Find features similar to [feature] and trace implementation.
            Return: architecture patterns, key abstractions, 5-10 important files."

  TASK 2 (area mapping):
    subagent_type: "feature-dev:code-explorer"  
    prompt: "Map architecture for [relevant area].
            Return: component relationships, data flow, integration points."

  TASK 3 (existing patterns):
    subagent_type: "feature-dev:code-explorer"
    prompt: "Analyze [related feature] implementation.
            Return: patterns used, extension points, conventions to follow."

WAIT for all subagents

COLLECT: summaries only (not full file contents)
READ: key files identified by subagents

DONE WHEN: key_files populated, patterns documented
```

### Phase 3: Clarification

```
INPUTS: exploration findings (if full mode), feature requirements
OUTPUTS: user_decisions[], resolved_ambiguities[]
NEXT: Phase 4 (full) or Phase 5 (light)

NEVER SKIP this phase - even in light mode

IDENTIFY ambiguities:
  - Edge cases and error handling
  - Scope boundaries (what's in/out)
  - Integration points with existing code
  - User preferences affecting design

IF ambiguities found:
  PRESENT questions using AskUserQuestion
  WAIT for answers - do not proceed without them
  
  IF user says "whatever you think":
    GIVE explicit recommendation
    GET confirmation before proceeding

IF no ambiguities:
  CONFIRM: "No clarifying questions - proceeding to [architecture/implementation]"

DONE WHEN: all ambiguities resolved or confirmed none exist
```

### Phase 4: Architecture Design

```
CONDITION: MODE = full
SKIP WHEN: MODE = light

PRECONDITION: Phase 3 complete
INPUTS: requirements, user_decisions, exploration findings
OUTPUTS: chosen_approach, implementation_steps[]
NEXT: Phase 5

SPAWN parallel subagents with DIFFERENT approaches:

  TASK 1 (minimal):
    subagent_type: "feature-dev:code-architect"
    prompt: "Design MINIMAL implementation for: [feature]
            Requirements: [from Phase 1]
            User decisions: [from Phase 3]
            Constraints: Smallest change, maximum reuse.
            Return: files to modify, changes needed, trade-offs."

  TASK 2 (clean):
    subagent_type: "feature-dev:code-architect"
    prompt: "Design CLEAN implementation for: [feature]
            Requirements: [from Phase 1]
            User decisions: [from Phase 3]
            Constraints: Maintainability, elegant abstractions.
            Return: files to create/modify, component design, trade-offs."

  TASK 3 (pragmatic):
    subagent_type: "feature-dev:code-architect"
    prompt: "Design PRAGMATIC implementation for: [feature]
            Requirements: [from Phase 1]
            User decisions: [from Phase 3]
            Constraints: Balance speed and quality.
            Return: files to modify, approach, trade-offs."

WAIT for all subagents

PRESENT all three approaches:
  - Summary of each
  - Trade-offs comparison
  - Your recommendation with reasoning

ASK user to pick (1/2/3)
WAIT for selection - BLOCKED until user chooses

DONE WHEN: user selected approach
```

### Phase 5: Implementation

```
PRECONDITION: Phase 3 complete (light) OR Phase 4 complete (full)
INPUTS: chosen_approach (full) OR requirements (light), key_files
OUTPUTS: files_changed[], implementation_complete
NEXT: Phase 6

USES: ~40% of context budget

STEPS:
  1. CREATE todo list from implementation steps
  2. READ all relevant files identified in exploration
  3. FOR EACH todo:
     - Implement the change
     - Mark todo complete
     - Stay focused - no unrequested features
  4. FOLLOW codebase conventions strictly

TRACK: files_changed[] for Phase 6 and 7

DONE WHEN: all todos complete, feature functional
```

### Phase 6: Testing

```
PRECONDITION: Phase 5 complete
INPUTS: files_changed[]
OUTPUTS: test_files[], justification (if no tests)
NEXT: Phase 7
BLOCKS: Phase 7 (via tests_before_review gate)

╔═══════════════════════════════════════════════════════════════╗
║  THIS PHASE IS MANDATORY - NO EXCEPTIONS                      ║
║  Even in light mode. Even for "small" changes.                ║
╚═══════════════════════════════════════════════════════════════╝

RULES (from CLAUDE.md patterns):
  | Changed                  | Must test                    |
  |--------------------------|------------------------------|
  | API endpoint/Controller  | Request → response behavior  |
  | View/Page/LiveView       | User interactions, renders   |
  | Context module           | New public functions         |
  | CLI command              | Input → output behavior      |

FOR EACH boundary component in files_changed:
  IF no corresponding test exists:
    CREATE test file
  ELSE:
    UPDATE existing test

BEFORE proceeding, LIST:
  "Tests created/modified:
   - [ ] path/to/test1 - tests for X
   - [ ] path/to/test2 - tests for Y"

IF genuinely no tests needed:
  PROVIDE explicit justification
  VALID: "Only changed private helper, covered by existing boundary test at [path]"
  INVALID: "It's a small change" / "It's obvious it works"

RUN tests: mix test / npm test / dotnet test (project appropriate)

DONE WHEN: test_files[] documented OR explicit justification provided
```

### Phase 7: Review Loop

```
PRECONDITION: Phase 6 complete (tests documented or justified)
INPUTS: files_changed[], test_files[]
OUTPUTS: review_iterations, fixes_made[], dismissed[]
NEXT: Phase 8
BLOCKS: Phase 8 (via review_before_complete gate)

╔═══════════════════════════════════════════════════════════════╗
║  THIS PHASE IS MANDATORY - NO EXCEPTIONS                      ║
║  Code is NOT ready until reviewer returns "NO ISSUES FOUND"   ║
╚═══════════════════════════════════════════════════════════════╝

NOTE: Plugin subagents cannot spawn from nested subagents.
      Main agent MUST run this loop directly.

LOOP:
  iteration = 0
  
  REPEAT:
    iteration++
    
    SPAWN reviewer:
      subagent_type: "feature-dev:code-reviewer"
      prompt: "Review these files: [files_changed + test_files]
              
              Check for:
              - Bugs and logic errors
              - Security vulnerabilities
              - Missing error handling
              - Convention violations
              - Code quality issues
              
              Return numbered list with file:line references,
              or 'NO ISSUES FOUND' if clean."
    
    WAIT for reviewer
    
    IF "NO ISSUES FOUND":
      EXIT loop
    
    FOR EACH issue:
      EVALUATE:
        - Real problem? (not false positive)
        - In scope? (not unrelated code)
        - Should fix? (not intentional design)
      
      IF valid: FIX using Edit tool, add to fixes_made[]
      IF invalid: DISMISS with reason, add to dismissed[]
    
    CONTINUE loop (fixes may introduce new issues)

DONE WHEN: reviewer returned "NO ISSUES FOUND"
```

### Phase 8: Completion

```
PRECONDITION: Phase 7 returned clean
INPUTS: selected_tasks[], files_changed[], test_files[], review_iterations
OUTPUTS: feature complete, beads closed

STEPS:
  1. RUN tests (final verification):
     mix test / npm test / dotnet test
     
     IF failures: FIX and return to Phase 7
  
  2. CLOSE beads:
     FOR EACH task in selected_tasks:
       bd close <id> --reason "Implemented: [brief description]" --json
  
  3. SYNC: bd sync

PRESENT summary:
  "## Feature Complete
  
  **Branch:** feat/[name]
  **Issues closed:**
  - [x] [id] - [description]
  - [x] [id] - [description]
  
  **Files changed:** [count]
  **Tests created:** [list]
  **Review iterations:** [count]
  **Fixes made:** [count]
  
  Ready to commit."

DONE WHEN: all tasks closed, summary presented
```

---

## Quick Reference

```
PATH SELECTION:
  - Beads issues exist? → Path A (use existing)
  - User describes feature? → Path B (create issues first)
  - Path B ALWAYS creates beads before starting

MODE SELECTION:
  - "quick fix" / "small change" / < 50 lines → light mode
  - Everything else → full mode
  - Light mode skips exploration + architecture
  - Light mode KEEPS testing + review

GATES (cannot bypass):
  - tests_before_review: Phase 6 → Phase 7
  - review_before_complete: Phase 7 clean → Phase 8
  - track_all_work: issues created AND closed

SUBAGENT RULES:
  - Summaries only returned to main
  - Main reads files they identify
  - Plugin subagents can't nest (review runs from main)
```

---

## Beads Commands

```
| Action         | Command                                    |
|----------------|--------------------------------------------|
| Find work      | bd ready --json                            |
| Claim task     | bd update <id> --status in_progress --json |
| Complete task  | bd close <id> --reason "..." --json        |
| Create task    | bd create "Title" -t task -p 1 --json      |
| Show details   | bd show <id> --json                        |
| Sync to git    | bd sync                                    |
```
