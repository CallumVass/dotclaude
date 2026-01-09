#!/usr/bin/env bash
# Test script to verify claude output streaming
#
# WORKING SOLUTION:
#   claude --verbose -p "prompt" --output-format stream-json | \
#     jq -r 'select(.type == "assistant") | .message.content[]? | select(.type? == "text") | .text'
#
# This streams text output in real-time when run from bash.

set -euo pipefail

echo "Claude CLI Streaming Test"
echo "========================="
echo ""
echo "Testing streaming with jq filter..."
echo "----------------------------------------"

claude --verbose -p "Say hello, wait 2 seconds, then say goodbye" --output-format stream-json | \
  jq -r 'select(.type == "assistant") | .message.content[]? | select(.type? == "text") | .text'

echo ""
echo "----------------------------------------"
echo "If you saw 'hello' first, then 'goodbye' after a delay, streaming works!"
