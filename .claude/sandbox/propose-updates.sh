#!/bin/bash
#
# Propose Rule Updates
#
# Takes an analysis JSON file and proposes changes to dotclaude rules.
#
# Usage: ./propose-updates.sh <analysis.json>
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
LEARNINGS_DIR="$SCRIPT_DIR/learnings"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

ANALYSIS_FILE="$1"

if [[ -z "$ANALYSIS_FILE" ]] || [[ ! -f "$ANALYSIS_FILE" ]]; then
    echo "Usage: $0 <analysis.json>"
    exit 1
fi

PROPOSALS_DIR="$LEARNINGS_DIR/rule-proposals"
mkdir -p "$PROPOSALS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROPOSAL_FILE="$PROPOSALS_DIR/proposal-${TIMESTAMP}.md"

log_info "Generating rule update proposal from: $ANALYSIS_FILE"

# Use Claude to generate a structured proposal
claude --print "
You are proposing rule updates based on experiment analysis.

## Analysis Results
$(cat "$ANALYSIS_FILE")

## Current Rules

### patterns.md
$(cat "$DOTCLAUDE_DIR/rules/patterns.md" 2>/dev/null | head -200)

### typescript/core.md
$(cat "$DOTCLAUDE_DIR/rules/typescript/core.md" 2>/dev/null | head -200)

## Task

Generate a markdown document with:

1. **Summary**: What was learned from this experiment

2. **Proposed Changes**: For each rule change:
   - File to modify
   - Section affected
   - Current text (brief)
   - Proposed text (brief)
   - Rationale

3. **Priority**: High/Medium/Low for each change

4. **Risks**: Any potential downsides to the changes

Format as a clean markdown document that a human can review.
" > "$PROPOSAL_FILE" 2>&1 || {
    log_warn "Proposal generation ended"
}

log_info "Proposal saved to: $PROPOSAL_FILE"

# Also append to cumulative learnings
cat >> "$LEARNINGS_DIR/cumulative.md" << EOF

---

## Proposal Generated: $TIMESTAMP

See: $PROPOSAL_FILE

EOF

echo ""
echo "============================================"
echo "PROPOSAL GENERATED"
echo "============================================"
echo ""
cat "$PROPOSAL_FILE"
echo ""
echo "============================================"
echo ""
log_info "Review the proposal above."
log_info "To apply changes manually, edit the rule files in: $DOTCLAUDE_DIR/rules/"
