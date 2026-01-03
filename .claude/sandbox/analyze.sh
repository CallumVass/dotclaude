#!/bin/bash
#
# Experiment Analyzer
#
# Analyzes completed experiment results and proposes rule improvements.
#
# Usage: ./analyze.sh <result-dir>
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
LEARNINGS_DIR="$SCRIPT_DIR/learnings"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

RESULT_DIR="$1"

if [[ -z "$RESULT_DIR" ]] || [[ ! -d "$RESULT_DIR" ]]; then
    echo "Usage: $0 <result-dir>"
    echo ""
    echo "Available results:"
    ls -1d "$SCRIPT_DIR/results"/*/ 2>/dev/null | xargs -n1 basename
    exit 1
fi

EXPERIMENT_ID=$(basename "$RESULT_DIR")
ANALYSIS_FILE="$RESULT_DIR/analysis.json"

log_info "Analyzing experiment: $EXPERIMENT_ID"

# Collect all session outputs
SESSIONS=""
for session in "$RESULT_DIR/sessions"/*.json; do
    if [[ -f "$session" ]]; then
        SESSIONS="$SESSIONS
--- Session: $(basename "$session") ---
$(head -c 50000 "$session")"  # Limit size per session
    fi
done

# Collect current rules
RULES=$(cat "$DOTCLAUDE_DIR/rules/patterns.md" "$DOTCLAUDE_DIR/rules/typescript/core.md" 2>/dev/null | head -c 20000)

# Collect template (expected behavior)
TEMPLATE=$(cat "$RESULT_DIR/template.md" 2>/dev/null || echo "Template not found")

# Collect final project state
FILES=$(cat "$RESULT_DIR/files.txt" 2>/dev/null || echo "No files list")
TEST_OUTPUT=$(cat "$RESULT_DIR/test-output.txt" 2>/dev/null || echo "No test output")

# Build the analysis prompt
ANALYSIS_PROMPT=$(cat << 'PROMPT_EOF'
You are analyzing a Claude Code experiment to improve our dotclaude rules.

## Your Task

Review the experiment sessions and evaluate:
1. Did Claude follow our conventions correctly?
2. Where did it deviate from expected patterns?
3. What rules were unclear or missing?
4. What improvements should we make?

## Output Format

Return valid JSON:

```json
{
  "experiment_id": "string",
  "overall_success": true|false,
  "conventions_followed": [
    {"rule": "string", "example": "string"}
  ],
  "conventions_missed": [
    {"rule": "string", "expected": "string", "actual": "string", "severity": "high|medium|low"}
  ],
  "unclear_rules": [
    {"rule": "string", "confusion": "string"}
  ],
  "rule_proposals": [
    {
      "file": "rules/typescript/core.md",
      "section": "string",
      "current": "string (brief)",
      "proposed": "string (brief)",
      "rationale": "string"
    }
  ],
  "patterns_observed": [
    "string - things that worked well repeatedly"
  ],
  "antipatterns_observed": [
    "string - things that failed repeatedly"
  ]
}
```

Be specific. Reference actual code/decisions from the sessions.
PROMPT_EOF
)

log_info "Running analysis with Claude..."

# Run the analysis
claude --print "
$ANALYSIS_PROMPT

## Current Rules (Abbreviated)

$RULES

## Experiment Template (Expected Behavior)

$TEMPLATE

## Session Outputs

$SESSIONS

## Final Project State

Files created:
$FILES

Test output:
$TEST_OUTPUT

---

Now analyze the experiment and output JSON:
" --output-format json > "$ANALYSIS_FILE" 2>&1 || {
    log_warn "Analysis session ended"
}

log_info "Analysis saved to: $ANALYSIS_FILE"

# Extract learnings and append to cumulative file
LEARNINGS_FILE="$LEARNINGS_DIR/cumulative.md"
mkdir -p "$LEARNINGS_DIR"

# Append to learnings log
cat >> "$LEARNINGS_FILE" << EOF

---

## Experiment: $EXPERIMENT_ID
Date: $(date)

### Summary
See: $ANALYSIS_FILE

EOF

log_info "Learnings appended to: $LEARNINGS_FILE"

# Show quick summary
echo ""
echo "============================================"
echo "ANALYSIS COMPLETE"
echo "============================================"
echo ""
echo "Results: $RESULT_DIR"
echo "Analysis: $ANALYSIS_FILE"
echo ""

# Try to extract key findings if jq is available
if command -v jq &> /dev/null; then
    echo "Key findings:"
    jq -r '.conventions_missed[]? | "  - MISSED: \(.rule)"' "$ANALYSIS_FILE" 2>/dev/null || true
    jq -r '.rule_proposals[]? | "  - PROPOSAL: \(.file) - \(.section)"' "$ANALYSIS_FILE" 2>/dev/null || true
fi

echo ""
log_info "To view full analysis:"
echo "  cat $ANALYSIS_FILE"
echo ""
log_info "To propose rule changes based on learnings:"
echo "  $SCRIPT_DIR/propose-updates.sh $ANALYSIS_FILE"
