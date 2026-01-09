# Test script to verify claude output streaming

Write-Host "Test 1: Direct invocation" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
& claude --permission-mode acceptEdits -p "Count from 1 to 5, one number per line"

Write-Host ""
Write-Host "Test 2: With Tee-Object" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
& claude --permission-mode acceptEdits -p "Count from 1 to 5, one number per line" 2>&1 | Tee-Object -FilePath "$env:TEMP\test-output.txt"

Write-Host ""
Write-Host "Test 3: With Tee-Object and Write-Host" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
& claude --permission-mode acceptEdits -p "Count from 1 to 5, one number per line" 2>&1 | Tee-Object -FilePath "$env:TEMP\test-output2.txt" | Write-Host

Write-Host ""
Write-Host "Test 4: With ForEach-Object (line by line)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
& claude --permission-mode acceptEdits -p "Count from 1 to 5, one number per line" 2>&1 | ForEach-Object {
    Write-Host $_
    Add-Content -Path "$env:TEMP\test-output3.txt" -Value $_
}

Write-Host ""
Write-Host "Done. Check if output appeared in real-time or all at once." -ForegroundColor Green
