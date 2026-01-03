#!/bin/bash
#
# Autonomous Experiment Runner
#
# Runs experiments within the dotclaude repo, testing conventions and
# collecting feedback for rule improvements.
#
# Usage: ./runner.sh <template-name> [--max-iterations N] [--auto-pr]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCLAUDE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_success() { echo -e "${CYAN}[SUCCESS]${NC} $1"; }

# Parse arguments
TEMPLATE_NAME=""
MAX_ITERATIONS=10
AUTO_PR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --max-iterations)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --auto-pr)
            AUTO_PR=true
            shift
            ;;
        *)
            if [[ -z "$TEMPLATE_NAME" ]]; then
                TEMPLATE_NAME="$1"
            fi
            shift
            ;;
    esac
done

TEMPLATE_NAME="${TEMPLATE_NAME:-fsharp-api}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXPERIMENT_ID="${TEMPLATE_NAME}-${TIMESTAMP}"
EXPERIMENT_BRANCH="experiment/${EXPERIMENT_ID}"
EXPERIMENT_DIR="$DOTCLAUDE_ROOT/experiments/${EXPERIMENT_ID}"

# Validate template
TEMPLATE_FILE="$TEMPLATES_DIR/${TEMPLATE_NAME}.md"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template not found: $TEMPLATE_FILE"
    echo "Available templates:"
    ls -1 "$TEMPLATES_DIR"/*.md 2>/dev/null | xargs -n1 basename | sed 's/.md$//'
    exit 1
fi

echo ""
echo "============================================"
echo "DOTCLAUDE SELF-IMPROVEMENT EXPERIMENT"
echo "============================================"
echo ""
log_info "Experiment: $EXPERIMENT_ID"
log_info "Template: $TEMPLATE_NAME"
log_info "Branch: $EXPERIMENT_BRANCH"
log_info "Max iterations: $MAX_ITERATIONS"
log_info "Auto PR: $AUTO_PR"
echo ""

cd "$DOTCLAUDE_ROOT"

# Ensure we're on main and up to date
log_step "1. Preparing repository..."
git fetch origin
git checkout main
git pull origin main

# Create experiment branch
log_step "2. Creating experiment branch..."
git checkout -b "$EXPERIMENT_BRANCH"

# Create experiment workspace (no nested git - just a subdirectory)
mkdir -p "$EXPERIMENT_DIR/sessions"
mkdir -p "$EXPERIMENT_DIR/project"

# Copy template
cp "$TEMPLATE_FILE" "$EXPERIMENT_DIR/template.md"

# Extract stack info from template
STACK=$(grep -A5 "## Stack" "$TEMPLATE_FILE" | grep "language" | sed 's/.*"language": *"\([^"]*\)".*/\1/' || echo "unknown")
log_info "Detected stack: $STACK"

PROJECT_DIR="$EXPERIMENT_DIR/project"
cd "$PROJECT_DIR"

# Note: Beads will be initialized and created by init-project, not pre-seeded
log_step "3. Preparing for init-project..."
log_info "Beads will be created by init-project based on the project spec"

# Track success criteria
SUCCESS_CRITERIA="$EXPERIMENT_DIR/success-criteria.json"
cat > "$SUCCESS_CRITERIA" << 'EOF'
{
  "init_project_ran": false,
  "next_feature_ran": false,
  "review_loop_executed": false,
  "tests_written": false,
  "all_beads_completed": false,
  "build_passes": false,
  "tests_pass": false,
  "errors": []
}
EOF

#
# Phase 1: Run /init-project
#
log_step "4. Running /init-project..."
SESSION_FILE="$EXPERIMENT_DIR/sessions/01-init-project.json"

cd "$PROJECT_DIR"

# Extract project spec and decisions from template
PROJECT_SPEC=$(sed -n '/## Project Spec/,/## Expected Scope/p' "$EXPERIMENT_DIR/template.md")
DECISIONS=$(sed -n '/## Decisions/,/## Expected Scope/p' "$EXPERIMENT_DIR/template.md")

claude --print "
## AUTONOMOUS MODE - ORCHESTRATOR PROVIDES ANSWERS

You are running in an autonomous experiment. When you need to make decisions or would
normally ask questions, consult the DECISIONS section below for pre-made answers.

If a question isn't covered, make the pragmatic choice and document your reasoning.

---

/init-project $STACK

This is a NEW PROJECT. Run the full init-project workflow:
1. Use the project spec below (no need to brainstorm - spec is complete)
2. Create CLAUDE.md with inlined rules for the stack
3. Initialize beads and create tasks based on the Expected Scope
4. When you would ask a question, check DECISIONS first

$PROJECT_SPEC

$DECISIONS

## Expected Behavior
- Create CLAUDE.md with project info and inlined $STACK rules
- Initialize beads (bd init, bd setup claude --project)
- Create beads tasks for the features described in the spec
- The spec is detailed enough - proceed without asking clarifying questions" \
    --dangerously-skip-permissions \
    --output-format json \
    > "$SESSION_FILE" 2>&1 || log_warn "init-project session ended"

# Check if init succeeded
if [[ -f "CLAUDE.md" ]]; then
    log_success "init-project created CLAUDE.md"
    sed -i 's/"init_project_ran": false/"init_project_ran": true/' "$SUCCESS_CRITERIA"
else
    log_warn "CLAUDE.md not created"
    echo "init-project failed to create CLAUDE.md" >> "$EXPERIMENT_DIR/errors.txt"
fi

# Save beads state after init-project
bd list > "$EXPERIMENT_DIR/beads-after-init.txt" 2>/dev/null || echo "No beads created" > "$EXPERIMENT_DIR/beads-after-init.txt"
INIT_BEADS=$(bd ready 2>/dev/null | grep -c "project-" || echo "0")
log_info "Beads created by init-project: $INIT_BEADS"

# Commit progress to experiment branch
cd "$DOTCLAUDE_ROOT"
git add -A
git commit -m "Experiment $EXPERIMENT_ID: after init-project" --allow-empty

#
# Phase 2: Work loop - complete beads tasks
#
log_step "5. Starting work loop (max $MAX_ITERATIONS iterations)..."
SESSION_NUM=2
FEATURES_COMPLETED=0

while [[ $SESSION_NUM -le $((MAX_ITERATIONS + 1)) ]]; do
    cd "$PROJECT_DIR"

    # Count lines that contain a project ID (format: "1. [P1] [task] project-xxx: Title")
    READY_COUNT=$(bd ready 2>/dev/null | grep -c "project-" || echo "0")

    if [[ "$READY_COUNT" -eq 0 ]]; then
        log_success "All beads completed!"
        sed -i 's/"all_beads_completed": false/"all_beads_completed": true/' "$SUCCESS_CRITERIA"
        break
    fi

    if [[ $SESSION_NUM -gt $MAX_ITERATIONS ]]; then
        log_warn "Hit max iterations ($MAX_ITERATIONS). $READY_COUNT beads remaining."
        break
    fi

    log_info "Iteration $((SESSION_NUM - 1))/$MAX_ITERATIONS: $READY_COUNT beads remaining"

    SESSION_FILE="$EXPERIMENT_DIR/sessions/$(printf '%02d' $SESSION_NUM)-next-feature.json"

    claude --print "
## AUTONOMOUS MODE - ORCHESTRATOR PROVIDES ANSWERS

When you need to make decisions, check the DECISIONS section below first.
If not covered, pick the pragmatic option.

$DECISIONS

---

Let's work on the next feature. Use your /next-feature skill.

Complete ONE task fully:
- Pick a ready task from beads
- Implement following CLAUDE.md conventions
- Write tests at boundary level (API endpoints)
- Run review loop until clean
- Close the bead when done
- Run bd sync

For decisions: check DECISIONS above, or pick pragmatic option.
For architecture: pick option 2 or 3 (pragmatic).
For review issues: fix real ones, dismiss false positives with brief reason.

Report what you accomplished." \
        --dangerously-skip-permissions \
        --output-format json \
        > "$SESSION_FILE" 2>&1 || log_warn "Session ended"

    # Check for evidence of success
    if grep -q "next-feature\|next_feature" "$SESSION_FILE" 2>/dev/null; then
        sed -i 's/"next_feature_ran": false/"next_feature_ran": true/' "$SUCCESS_CRITERIA"
    fi

    if grep -q "review\|Review" "$SESSION_FILE" 2>/dev/null; then
        sed -i 's/"review_loop_executed": false/"review_loop_executed": true/' "$SUCCESS_CRITERIA"
    fi

    # Sync beads
    bd sync 2>/dev/null || true

    # Save state
    bd list > "$EXPERIMENT_DIR/beads-after-$((SESSION_NUM - 1)).txt" 2>/dev/null || true

    # Commit progress
    cd "$DOTCLAUDE_ROOT"
    git add -A
    git commit -m "Experiment $EXPERIMENT_ID: iteration $((SESSION_NUM - 1))" --allow-empty

    ((SESSION_NUM++))
    ((FEATURES_COMPLETED++))
done

ITERATIONS_RUN=$((SESSION_NUM - 2))
log_info "Completed $ITERATIONS_RUN iterations, $FEATURES_COMPLETED features"

#
# Phase 3: Automated verification
#
log_step "6. Running automated verification..."

cd "$PROJECT_DIR"

# Check for test files
TEST_FILES=$(find . -name "*.Tests.*" -o -name "*Test*.fs" -o -name "*Tests*.fs" -o -name "*.test.*" 2>/dev/null | head -20)
if [[ -n "$TEST_FILES" ]]; then
    log_success "Test files found"
    sed -i 's/"tests_written": false/"tests_written": true/' "$SUCCESS_CRITERIA"
    echo "$TEST_FILES" > "$EXPERIMENT_DIR/test-files.txt"
else
    log_warn "No test files found"
fi

# Try to build (F# specific)
if [[ -f "*.fsproj" ]] || find . -name "*.fsproj" -type f | head -1 | grep -q .; then
    log_info "Attempting dotnet build..."
    if dotnet build 2>&1 | tee "$EXPERIMENT_DIR/build-output.txt"; then
        log_success "Build passed"
        sed -i 's/"build_passes": false/"build_passes": true/' "$SUCCESS_CRITERIA"
    else
        log_warn "Build failed"
    fi

    log_info "Attempting dotnet test..."
    if dotnet test 2>&1 | tee "$EXPERIMENT_DIR/test-output.txt"; then
        log_success "Tests passed"
        sed -i 's/"tests_pass": false/"tests_pass": true/' "$SUCCESS_CRITERIA"
    else
        log_warn "Tests failed or no tests"
    fi
fi

#
# Phase 4: Analysis and feedback
#
log_step "7. Analyzing experiment results..."

cd "$DOTCLAUDE_ROOT"

# Collect session summaries
SESSIONS_SUMMARY=""
for session in "$EXPERIMENT_DIR/sessions"/*.json; do
    if [[ -f "$session" ]]; then
        # Extract just key info, not full output
        SESSIONS_SUMMARY="$SESSIONS_SUMMARY
--- $(basename "$session") ---
$(head -c 15000 "$session" | tail -c 10000)"
    fi
done

# Generate analysis
ANALYSIS_FILE="$EXPERIMENT_DIR/analysis.md"

claude --print "
# Experiment Analysis: $EXPERIMENT_ID

## Template
$(cat "$EXPERIMENT_DIR/template.md")

## Success Criteria Results
$(cat "$SUCCESS_CRITERIA")

## Session Summaries (abbreviated)
$SESSIONS_SUMMARY

## Build/Test Output
Build: $(cat "$EXPERIMENT_DIR/build-output.txt" 2>/dev/null | tail -20 || echo "N/A")
Tests: $(cat "$EXPERIMENT_DIR/test-output.txt" 2>/dev/null | tail -20 || echo "N/A")

## Files Created
$(find "$PROJECT_DIR" -type f -name "*.fs" -o -name "*.fsproj" -o -name "*.md" 2>/dev/null | head -30)

---

# Analysis Task

Provide a structured analysis:

## 1. Success Criteria Evaluation
For each criterion, state PASS/FAIL with evidence:
- init-project ran successfully
- next-feature workflow executed
- Review loop was used
- Tests written at boundary level
- All beads completed
- Build passes
- Tests pass

## 2. Convention Adherence
Which dotclaude conventions were followed/missed?
Reference specific files and line patterns.

## 3. What Worked Well
Patterns that succeeded.

## 4. What Needs Improvement
Specific issues encountered.

## 5. Rule Improvement Proposals
If conventions were unclear or missing, propose specific changes:
- File: .claude/rules/dotnet/fsharp.md
- Section: [which section]
- Current: [what it says now]
- Proposed: [what it should say]
- Rationale: [why]

## 6. Recommendations for Next Experiment
What should we test next?
" > "$ANALYSIS_FILE" 2>&1 || log_warn "Analysis generation ended"

log_info "Analysis saved: $ANALYSIS_FILE"

#
# Phase 5: Summary and commit
#
log_step "8. Generating summary..."

SUMMARY_FILE="$EXPERIMENT_DIR/SUMMARY.md"
cat > "$SUMMARY_FILE" << EOF
# Experiment Summary: $EXPERIMENT_ID

**Date:** $(date)
**Template:** $TEMPLATE_NAME
**Stack:** $STACK
**Iterations:** $ITERATIONS_RUN / $MAX_ITERATIONS max
**Features completed:** $FEATURES_COMPLETED

## Success Criteria

\`\`\`json
$(cat "$SUCCESS_CRITERIA")
\`\`\`

## Quick Assessment

$(grep -E "^- |PASS|FAIL" "$ANALYSIS_FILE" 2>/dev/null | head -20 || echo "See analysis.md for details")

## Files Changed in Experiment

\`\`\`
$(find "$PROJECT_DIR" -type f \( -name "*.fs" -o -name "*.fsproj" -o -name "*.md" \) 2>/dev/null | wc -l) source files
$(find "$PROJECT_DIR" -type f -name "*Test*" 2>/dev/null | wc -l) test files
\`\`\`

## Next Steps

1. Review analysis.md for detailed findings
2. Check sessions/ for full session logs
3. Review any rule proposals
4. Merge or discard this experiment branch

---

*Generated by dotclaude self-improvement runner*
EOF

# Final commit
git add -A
git commit -m "Experiment $EXPERIMENT_ID: analysis and summary" --allow-empty

# Push
log_step "9. Pushing experiment branch..."
git push -u origin "$EXPERIMENT_BRANCH"

#
# Phase 6: Optional PR creation
#
if [[ "$AUTO_PR" == "true" ]]; then
    log_step "10. Creating Pull Request..."

    gh pr create \
        --title "Experiment: $EXPERIMENT_ID" \
        --body "$(cat << EOF
## Self-Improvement Experiment

**Template:** \`$TEMPLATE_NAME\`
**Iterations:** $ITERATIONS_RUN
**Stack:** $STACK

### Success Criteria
\`\`\`json
$(cat "$SUCCESS_CRITERIA")
\`\`\`

### Summary
See \`experiments/$EXPERIMENT_ID/SUMMARY.md\` for full details.

### Review Checklist
- [ ] Check success criteria results
- [ ] Review analysis.md findings
- [ ] Evaluate any rule proposals
- [ ] Verify no unintended changes

---
*Generated by /self-improve*
EOF
)" \
        --base main \
        --head "$EXPERIMENT_BRANCH" || log_warn "Could not create PR"
fi

#
# Final report
#
echo ""
echo "============================================"
echo "EXPERIMENT COMPLETE"
echo "============================================"
echo ""
log_info "Branch: $EXPERIMENT_BRANCH"
log_info "Directory: experiments/$EXPERIMENT_ID/"
echo ""
echo "Key files:"
echo "  - SUMMARY.md      Quick overview"
echo "  - analysis.md     Detailed analysis"
echo "  - success-criteria.json"
echo "  - sessions/       Full session logs"
echo ""

# Print success criteria
echo "Success Criteria:"
cat "$SUCCESS_CRITERIA" | grep -E '"[a-z_]+":' | while read line; do
    if echo "$line" | grep -q "true"; then
        echo -e "  ${GREEN}✓${NC} $(echo "$line" | sed 's/[",:]//g')"
    else
        echo -e "  ${RED}✗${NC} $(echo "$line" | sed 's/[",:]//g')"
    fi
done

echo ""
if [[ "$AUTO_PR" != "true" ]]; then
    log_info "To create a PR:"
    echo "  gh pr create --base main --head $EXPERIMENT_BRANCH"
fi
echo ""
log_info "To discard:"
echo "  git checkout main && git branch -D $EXPERIMENT_BRANCH"
