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
#   LOG_FILE - Path to log file (default: ~/.claude/ralph.log)
#   TIMEOUT_MINUTES - Timeout per iteration in minutes (default: 45)
#   MAX_RETRIES - Retries per iteration for crashes/malformed requests (default: 3)
#
# Signals:
#   Ctrl+C - Graceful stop after current operation (second Ctrl+C force-quits)
#

set -uo pipefail

# Configuration
MAX_ITERATIONS="${1:-10}"
NOTIFY_CMD="${NOTIFY_CMD:-}"
LOG_FILE="${LOG_FILE:-$HOME/.claude/ralph.log}"
TIMEOUT_MINUTES="${TIMEOUT_MINUTES:-45}"  # Timeout per iteration
MAX_RETRIES="${MAX_RETRIES:-3}"  # Retries per iteration for crashes/malformed requests

# Track if we're being interrupted
INTERRUPTED=false

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
    # Strip ANSI codes for log file
    echo -e "$msg" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
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

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
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
    log "Running claude (timeout: ${TIMEOUT_MINUTES}m)..."
    log ""

    # Run claude with:
    # - timeout: prevent infinite hangs
    # - --dangerously-skip-permissions: no permission prompts
    # - --output-format stream-json --verbose: for streaming
    # - -p: non-interactive print mode
    #
    # Stream text to terminal while capturing full JSON for promise word detection
    local exit_code=0
    timeout "${TIMEOUT_MINUTES}m" claude \
        --dangerously-skip-permissions \
        --output-format stream-json \
        --verbose \
        -p '/ralph-task' 2>&1 | tee "$output_file" | \
        jq -r 'select(.type == "assistant") | .message.content[]? | select(.type? == "text") | .text' 2>/dev/null || exit_code=$?

    # Append extracted text to log file (after streaming completes)
    jq -r 'select(.type == "assistant") | .message.content[]? | select(.type? == "text") | .text' "$output_file" 2>/dev/null >> "$LOG_FILE"

    # Check for timeout (exit code 124) - retry-able
    if [[ $exit_code -eq 124 ]]; then
        log "${YELLOW}Iteration timed out after ${TIMEOUT_MINUTES} minutes${NC}"
        rm -f "$output_file"
        return 3  # Retry-able
    fi

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
        log ""
        log "--- Last 50 lines of raw output ---"
        tail -50 "$output_file"
        tail -50 "$output_file" >> "$LOG_FILE"
        log "-----------------------------------"
        rm -f "$output_file"
        return 3  # Retry-able error
    fi
}

main() {
    log "${BLUE}==========================================${NC}"
    log "${BLUE}Ralph Wiggum - Autonomous Dev Loop${NC}"
    log "${BLUE}==========================================${NC}"
    log "Max iterations: $MAX_ITERATIONS"
    log "Timeout per iteration: ${TIMEOUT_MINUTES}m"
    log "Max retries per iteration: $MAX_RETRIES"
    log "Log file: $LOG_FILE"
    log ""

    check_dependencies

    local completed=0
    local iteration=1

    while [[ $iteration -le $MAX_ITERATIONS ]]; do
        # Check if interrupted
        if [[ "$INTERRUPTED" == "true" ]]; then
            log "${YELLOW}Stopping due to interrupt...${NC}"
            break
        fi

        local retry=0
        local result=3  # Start with retry-able state

        # Retry loop for crashes/malformed requests
        while [[ $result -eq 3 && $retry -lt $MAX_RETRIES ]]; do
            if [[ $retry -gt 0 ]]; then
                log "${YELLOW}Retry $retry of $MAX_RETRIES for iteration $iteration${NC}"
                sleep 5  # Brief pause before retry
            fi

            run_ralph_iteration $iteration
            result=$?
            ((++retry))

            # Check if interrupted during iteration
            if [[ "$INTERRUPTED" == "true" ]]; then
                break
            fi
        done

        # Check if interrupted
        if [[ "$INTERRUPTED" == "true" ]]; then
            log "${YELLOW}Stopping due to interrupt...${NC}"
            break
        fi

        if [[ $result -eq 0 ]]; then
            # Success - task completed, continue to next
            ((++completed))
            ((++iteration))
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
        elif [[ $result -eq 3 ]]; then
            # Exhausted retries
            log ""
            log "${RED}==========================================${NC}"
            log "${RED}Ralph stopped - exhausted $MAX_RETRIES retries${NC}"
            log "${RED}Completed before stop: $completed task(s)${NC}"
            log "${RED}==========================================${NC}"
            notify "Ralph: Exhausted retries after $completed tasks"
            exit 1
        else
            # Error/blocked (result=2)
            log ""
            log "${RED}==========================================${NC}"
            log "${RED}Ralph stopped - human intervention needed${NC}"
            log "${RED}Completed before stop: $completed task(s)${NC}"
            log "${RED}==========================================${NC}"
            exit 1
        fi
    done

    # If we got here via interrupt, show status
    if [[ "$INTERRUPTED" == "true" ]]; then
        log ""
        log "${YELLOW}==========================================${NC}"
        log "${YELLOW}Ralph interrupted by user${NC}"
        log "${YELLOW}Completed: $completed task(s)${NC}"
        log "${YELLOW}==========================================${NC}"
        exit 130
    fi

    log ""
    log "${YELLOW}==========================================${NC}"
    log "${YELLOW}Max iterations ($MAX_ITERATIONS) reached${NC}"
    log "${YELLOW}Completed: $completed task(s)${NC}"
    log "${YELLOW}==========================================${NC}"
    notify "Ralph: Max iterations reached ($completed tasks done)"
}

# Handle interrupts gracefully - kill children and set flag
cleanup() {
    INTERRUPTED=true
    log "${YELLOW}Interrupt received - killing child processes...${NC}"
    # Kill all child processes of this script
    pkill -P $$ 2>/dev/null || true
    trap - INT TERM  # Reset trap to allow force-quit on second Ctrl+C
}

trap cleanup INT TERM

main "$@"
