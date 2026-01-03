#!/bin/bash
#
# Autonomous Experiment Runner (In-Repo Version)
#
# Runs experiments within the dotclaude repo itself, in a dedicated branch.
# When complete, creates a PR with rule improvements.
#
# Usage: ./runner.sh <template-name> [--auto-pr]
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
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Parse arguments
TEMPLATE_NAME="${1:-todo-api}"
AUTO_PR="${2:-}"
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
log_info "Directory: experiments/${EXPERIMENT_ID}"
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

# Create experiment workspace directory
mkdir -p "$EXPERIMENT_DIR"
mkdir -p "$EXPERIMENT_DIR/sessions"
mkdir -p "$EXPERIMENT_DIR/project"

# Copy template
cp "$TEMPLATE_FILE" "$EXPERIMENT_DIR/template.md"

# Create experiment project directory (this is where Claude builds the test project)
PROJECT_DIR="$EXPERIMENT_DIR/project"
cd "$PROJECT_DIR"

# Initialize as a nested git repo for isolation (optional, can be .gitignore'd)
# Or just work directly - let's keep it simple and work in the project dir

# Initialize git in project dir
git init
git config user.email "experiment@dotclaude.local"
git config user.name "Experiment Runner"
echo "node_modules/" > .gitignore
git add .gitignore
git commit -m "Initial experiment project"

# Initialize beads with sync branch
log_step "3. Setting up beads..."
bd init --branch beads-sync 2>/dev/null || {
    bd init
    bd config set sync.branch beads-sync 2>/dev/null || true
}
bd hooks install 2>/dev/null || log_warn "Could not install beads hooks"

# Seed beads from template
log_info "Seeding beads from template..."
grep "^bd create" "$EXPERIMENT_DIR/template.md" | while read -r cmd; do
    log_info "  $cmd"
    eval "$cmd" 2>/dev/null || true
done
bd sync 2>/dev/null || true

log_info "Beads ready:"
bd ready || echo "(no ready tasks)"

# Save initial state
bd list > "$EXPERIMENT_DIR/beads-initial.txt" 2>/dev/null || true

#
# Phase 1: Run /init-project
#
log_step "4. Running /init-project..."
SESSION_FILE="$EXPERIMENT_DIR/sessions/01-init-project.json"

cd "$PROJECT_DIR"
claude --print "/init-project typescript" \
    --dangerously-skip-permissions \
    --output-format json \
    > "$SESSION_FILE" 2>&1 || log_warn "init-project session ended"

git add -A
git commit -m "After init-project" --allow-empty

#
# Phase 2: Work loop
#
log_step "5. Starting autonomous work loop..."
SESSION_NUM=2
MAX_ITERATIONS=20

while [[ $SESSION_NUM -le $MAX_ITERATIONS ]]; do
    cd "$PROJECT_DIR"

    READY_COUNT=$(bd ready 2>/dev/null | grep -c "^[0-9]" || echo "0")

    if [[ "$READY_COUNT" -eq 0 ]]; then
        log_info "All beads completed!"
        break
    fi

    log_info "Iteration $SESSION_NUM: $READY_COUNT beads remaining"

    SESSION_FILE="$EXPERIMENT_DIR/sessions/$(printf '%02d' $SESSION_NUM)-next-feature.json"

    claude --print "/next-feature

Complete this task fully. After implementation:
1. Run bd sync
2. Commit all changes
3. Report what was accomplished" \
        --dangerously-skip-permissions \
        --output-format json \
        > "$SESSION_FILE" 2>&1 || log_warn "Session ended"

    # Landing protocol
    bd sync 2>/dev/null || true
    git add -A
    git commit -m "After iteration $SESSION_NUM" --allow-empty

    bd list > "$EXPERIMENT_DIR/beads-after-$SESSION_NUM.txt" 2>/dev/null || true

    ((SESSION_NUM++))
done

#
# Phase 3: Analysis
#
log_step "6. Analyzing results..."

cd "$DOTCLAUDE_ROOT"

# Collect all session outputs for analysis
SESSIONS_CONTENT=""
for session in "$EXPERIMENT_DIR/sessions"/*.json; do
    if [[ -f "$session" ]]; then
        SESSIONS_CONTENT="$SESSIONS_CONTENT
--- $(basename "$session") ---
$(head -c 30000 "$session")"
    fi
done

# Run analysis
ANALYSIS_FILE="$EXPERIMENT_DIR/analysis.json"

claude --print "
You are analyzing a Claude Code self-improvement experiment.

## Experiment: $EXPERIMENT_ID

## Template (Expected Behavior)
$(cat "$EXPERIMENT_DIR/template.md")

## Session Outputs
$SESSIONS_CONTENT

## Current Rules (to potentially improve)
$(cat .claude/rules/patterns.md | head -100)
$(cat .claude/rules/typescript/core.md | head -100)

## Task

Analyze the experiment:
1. Did Claude follow the conventions in our rules?
2. What worked well?
3. What conventions were missed or unclear?
4. What rule improvements would help future runs?

Output as JSON:
{
  \"success\": true|false,
  \"conventions_followed\": [\"...\"],
  \"conventions_missed\": [{\"rule\": \"...\", \"issue\": \"...\"}],
  \"rule_proposals\": [{
    \"file\": \"rules/typescript/core.md\",
    \"section\": \"...\",
    \"change\": \"...\",
    \"rationale\": \"...\"
  }]
}
" --output-format json > "$ANALYSIS_FILE" 2>&1 || log_warn "Analysis ended"

log_info "Analysis saved: $ANALYSIS_FILE"

#
# Phase 4: Apply learnings (if any)
#
log_step "7. Applying learnings to rules..."

LEARNINGS_FILE="$EXPERIMENT_DIR/applied-learnings.md"

claude --print "
Based on this analysis, make targeted improvements to the dotclaude rules.

## Analysis
$(cat "$ANALYSIS_FILE")

## Instructions

1. Review the rule_proposals from the analysis
2. For each valid proposal, use the Edit tool to update the rule file
3. Keep changes minimal and targeted
4. Document what you changed in a summary

Only make changes that are clearly beneficial based on the experiment evidence.
Do NOT make speculative changes.
" --dangerously-skip-permissions \
  --output-format json > "$LEARNINGS_FILE" 2>&1 || log_warn "Learnings session ended"

# Commit any rule changes
git add -A
git diff --cached --quiet || git commit -m "Apply learnings from experiment $EXPERIMENT_ID"

#
# Phase 5: Summary and PR
#
log_step "8. Generating summary..."

# Generate summary
SUMMARY_FILE="$EXPERIMENT_DIR/SUMMARY.md"
cat > "$SUMMARY_FILE" << EOF
# Experiment: $EXPERIMENT_ID

**Template:** $TEMPLATE_NAME
**Date:** $(date)
**Sessions:** $((SESSION_NUM - 1))

## Results

$(cat "$ANALYSIS_FILE" 2>/dev/null | head -100 || echo "See analysis.json")

## Files Changed

\`\`\`
$(git diff main --stat)
\`\`\`

## Rule Updates Applied

$(git diff main -- .claude/rules/ 2>/dev/null || echo "No rule changes")
EOF

git add "$SUMMARY_FILE"
git commit -m "Add experiment summary" --allow-empty

# Push the experiment branch
log_step "9. Pushing experiment branch..."
git push -u origin "$EXPERIMENT_BRANCH"

#
# Phase 6: Create PR (if requested)
#
if [[ "$AUTO_PR" == "--auto-pr" ]]; then
    log_step "10. Creating Pull Request..."

    PR_BODY=$(cat << EOF
## Self-Improvement Experiment: $EXPERIMENT_ID

This PR contains rule improvements discovered through automated experimentation.

### What was tested
- Template: \`$TEMPLATE_NAME\`
- Task: Build a project following dotclaude conventions
- Sessions: $((SESSION_NUM - 1))

### Changes
$(git diff main --stat)

### How to review
1. Check the \`experiments/$EXPERIMENT_ID/\` directory for full session logs
2. Review rule changes in \`.claude/rules/\`
3. Verify changes make sense based on the analysis

---
*Generated by dotclaude self-improvement runner*
EOF
)

    gh pr create \
        --title "Self-improvement: $EXPERIMENT_ID" \
        --body "$PR_BODY" \
        --base main \
        --head "$EXPERIMENT_BRANCH" || log_warn "Could not create PR (gh CLI may not be configured)"
else
    log_info "Experiment branch pushed. Create PR manually:"
    echo "  gh pr create --base main --head $EXPERIMENT_BRANCH"
fi

echo ""
echo "============================================"
echo "EXPERIMENT COMPLETE"
echo "============================================"
echo ""
log_info "Branch: $EXPERIMENT_BRANCH"
log_info "Results: experiments/$EXPERIMENT_ID/"
log_info "Analysis: experiments/$EXPERIMENT_ID/analysis.json"
echo ""
log_info "To create a PR:"
echo "  gh pr create --base main --head $EXPERIMENT_BRANCH"
echo ""
log_info "To discard experiment:"
echo "  git checkout main && git branch -D $EXPERIMENT_BRANCH"
