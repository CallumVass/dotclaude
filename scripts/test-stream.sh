#!/usr/bin/env bash
# Test script to verify claude output streaming

echo "Test 1: Direct invocation"
echo "========================="
claude --permission-mode acceptEdits -p "Count from 1 to 5, one number per line, with a 1 second pause between each"

echo ""
echo "Test 2: With tee"
echo "================"
claude --permission-mode acceptEdits -p "Count from 1 to 5, one number per line" 2>&1 | tee /tmp/test-output.txt

echo ""
echo "Test 3: With script command"
echo "==========================="
script -q -c "claude --permission-mode acceptEdits -p 'Count from 1 to 5, one number per line'" /tmp/test-script.txt

echo ""
echo "Done. Check if output appeared in real-time or all at once."
