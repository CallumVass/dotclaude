#!/usr/bin/env bash
#
# ralph.sh - Autonomous Claude Code loop runner
#
# Usage: ./ralph.sh [max_iterations]
#
# Loops claude CLI calls until:
#   - Promise word COMPLETE (success, continue to next issue)
#   - Promise word NO_ISSUES (no more issues, exit success)
#   - Promise word BLOCKED (needs human, exit with error)
#   - Max iterations reached
#
# Environment variables:
#   NOTIFY_CMD - Command to run for notifications (e.g., "terminal-notifier -message")
#   LOG_FILE - Path to log file (default: ./ralph.log)
#

set -euo pipefail

# Configuration
MAX_ITERATIONS="${1:-10}"
NOTIFY_CMD="${NOTIFY_CMD:-}"
LOG_FILE="${LOG_FILE:-./ralph.log}"

# Promise words
PROMISE_COMPLETE="<promise>COMPLETE</promise>"
PROMISE_NO_ISSUES="<promise>NO_ISSUES</promise>"
PROMISE_BLOCKED="<promise>BLOCKED</promise>"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg"
    echo "$msg" >> "$LOG_FILE"
}

notify() {
    local message="$1"
    if [[ -n "$NOTIFY_CMD" ]]; then
        eval "$NOTIFY_CMD '$message'" 2>/dev/null || true
    fi
}

check_dependencies() {
    local missing=()

    if ! command -v claude &> /dev/null; then
        missing+=("claude")
    fi

    if ! command -v bd &> /dev/null; then
        missing+=("bd (beads)")
    fi

    if ! command -v gh &> /dev/null; then
        missing+=("gh (GitHub CLI)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "${RED}Error: Missing dependencies: ${missing[*]}${NC}"
        exit 1
    fi
}

run_ralph_iteration() {
    local iteration=$1
    local output_file
    output_file=$(mktemp)

    log "${BLUE}========================================${NC}"
    log "${BLUE}Iteration $iteration of $MAX_ITERATIONS${NC}"
    log "${BLUE}========================================${NC}"
    log "Running claude... (no real-time output - CLI limitation)"
    log ""

    # Run claude and capture output
    # Note: Claude CLI doesn't support streaming text output when piped
    claude --permission-mode acceptEdits -p '/ralph-task' > "$output_file" 2>&1
    local exit_code=$?

    local output
    output=$(cat "$output_file")

    # Check for promise words in full output
    if [[ "$output" == *"$PROMISE_COMPLETE"* ]]; then
        log "${GREEN}Task completed successfully${NC}"
        rm -f "$output_file"
        return 0  # Continue loop
    elif [[ "$output" == *"$PROMISE_NO_ISSUES"* ]]; then
        log "${YELLOW}No more issues available${NC}"
        notify "Ralph: All issues complete!"
        rm -f "$output_file"
        return 1  # Stop loop - success
    elif [[ "$output" == *"$PROMISE_BLOCKED"* ]]; then
        log "${RED}Task blocked - human intervention required${NC}"
        notify "Ralph: BLOCKED! Human needed"
        rm -f "$output_file"
        return 2  # Stop loop - error
    else
        log "${RED}Unexpected output (no promise word found)${NC}"
        echo ""
        echo "--- Last 50 lines of raw output ---"
        tail -50 "$output_file"
        echo "-----------------------------------"
        rm -f "$output_file"
        return 2
    fi
}

main() {
    log "${BLUE}==========================================${NC}"
    log "${BLUE}Ralph Wiggum - Autonomous Dev Loop${NC}"
    log "${BLUE}==========================================${NC}"
    log "Max iterations: $MAX_ITERATIONS"
    log "Log file: $LOG_FILE"
    log ""

    check_dependencies

    local completed=0
    local iteration=1

    while [[ $iteration -le $MAX_ITERATIONS ]]; do
        run_ralph_iteration $iteration
        local result=$?

        if [[ $result -eq 0 ]]; then
            # Success - task completed, continue to next
            ((completed++))
            ((iteration++))
            log ""
            log "Completed $completed task(s) so far. Continuing..."
            log ""
            # Brief pause between iterations
            sleep 2
        elif [[ $result -eq 1 ]]; then
            # No more issues - clean exit
            log ""
            log "${GREEN}==========================================${NC}"
            log "${GREEN}Ralph finished - no more issues${NC}"
            log "${GREEN}Completed: $completed task(s)${NC}"
            log "${GREEN}==========================================${NC}"
            notify "Ralph done! Completed $completed tasks"
            exit 0
        else
            # Error/blocked
            log ""
            log "${RED}==========================================${NC}"
            log "${RED}Ralph stopped - human intervention needed${NC}"
            log "${RED}Completed before stop: $completed task(s)${NC}"
            log "${RED}==========================================${NC}"
            exit 1
        fi
    done

    log ""
    log "${YELLOW}==========================================${NC}"
    log "${YELLOW}Max iterations ($MAX_ITERATIONS) reached${NC}"
    log "${YELLOW}Completed: $completed task(s)${NC}"
    log "${YELLOW}==========================================${NC}"
    notify "Ralph: Max iterations reached ($completed tasks done)"
}

# Handle interrupts gracefully
trap 'log "${YELLOW}Interrupted by user${NC}"; exit 130' INT TERM

main "$@"
