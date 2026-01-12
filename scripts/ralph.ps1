#Requires -Version 7.0
<#
.SYNOPSIS
    ralph.ps1 - Autonomous Claude Code loop runner

.DESCRIPTION
    Loops claude CLI calls until:
    - Promise word COMPLETE (success, continue to next issue)
    - Promise word NO_ISSUES (no more issues, exit success)
    - Promise word BLOCKED (needs human, exit with error)
    - Max iterations reached

.PARAMETER MaxIterations
    Maximum number of iterations to run (default: 10)

.PARAMETER TimeoutMinutes
    Timeout per iteration in minutes (default: 45)

.PARAMETER MaxRetries
    Retries per iteration for crashes/malformed requests (default: 3)

.PARAMETER LogFile
    Path to log file (default: ~/.claude/ralph.log)

.PARAMETER NotifyCmd
    Command to run for notifications (optional)

.EXAMPLE
    ./ralph.ps1
    ./ralph.ps1 -MaxIterations 5
    ./ralph.ps1 -TimeoutMinutes 30 -MaxRetries 2
#>

[CmdletBinding()]
param(
    [int]$MaxIterations = 10,
    [int]$TimeoutMinutes = 45,
    [int]$MaxRetries = 3,
    [string]$LogFile = (Join-Path $env:USERPROFILE ".claude\ralph.log"),
    [string]$NotifyCmd = $env:NOTIFY_CMD
)

# Ensure strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Promise words
$PROMISE_COMPLETE = "<promise>COMPLETE</promise>"
$PROMISE_NO_ISSUES = "<promise>NO_ISSUES</promise>"
$PROMISE_BLOCKED = "<promise>BLOCKED</promise>"

# Track interruption and current job
$script:Interrupted = $false
$script:CurrentJob = $null

# Colours (ANSI escape codes for cross-platform support)
$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$BLUE = "`e[0;34m"
$NC = "`e[0m"

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"

    # Write to console with colours
    Write-Host $logMessage

    # Strip ANSI codes for log file
    $cleanMessage = $logMessage -replace '\e\[[0-9;]*m', ''

    # Ensure log directory exists
    $logDir = Split-Path -Parent $LogFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Add-Content -Path $LogFile -Value $cleanMessage
}

function Send-Notification {
    param([string]$Message)

    if ($NotifyCmd) {
        try {
            $cmd = "$NotifyCmd '$Message'"
            Invoke-Expression $cmd 2>$null
        }
        catch {
            # Ignore notification errors
        }
    }
}

function Test-Dependencies {
    $missing = @()

    if (-not (Get-Command "claude" -ErrorAction SilentlyContinue)) {
        $missing += "claude"
    }

    if (-not (Get-Command "bd" -ErrorAction SilentlyContinue)) {
        $missing += "bd (beads)"
    }

    if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
        $missing += "gh (GitHub CLI)"
    }

    if ($missing.Count -gt 0) {
        Write-Log "${RED}Error: Missing dependencies: $($missing -join ', ')${NC}"
        exit 1
    }
}

function Invoke-RalphIteration {
    param([int]$Iteration)

    $outputFile = [System.IO.Path]::GetTempFileName()

    Write-Log "${BLUE}========================================${NC}"
    Write-Log "${BLUE}Iteration $Iteration of $MaxIterations${NC}"
    Write-Log "${BLUE}========================================${NC}"
    Write-Log "Running claude (timeout: ${TimeoutMinutes}m)..."
    Write-Log ""

    try {
        # Create a job to run claude with timeout
        $script:CurrentJob = Start-Job -ScriptBlock {
            param($outputPath)

            $output = & claude `
                --dangerously-skip-permissions `
                --output-format stream-json `
                --verbose `
                -p '/ralph-task' 2>&1

            $output | Out-File -FilePath $outputPath -Encoding utf8

            # Stream text output
            $output | ForEach-Object {
                try {
                    $json = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($json.type -eq "assistant" -and $json.message.content) {
                        foreach ($content in $json.message.content) {
                            if ($content.type -eq "text") {
                                Write-Output $content.text
                            }
                        }
                    }
                }
                catch {
                    # Not valid JSON, skip
                }
            }
        } -ArgumentList $outputFile
        $job = $script:CurrentJob

        # Wait with timeout
        $completed = Wait-Job -Job $job -Timeout ($TimeoutMinutes * 60)

        if (-not $completed) {
            # Timeout occurred
            Stop-Job -Job $job
            Remove-Job -Job $job -Force
            $script:CurrentJob = $null
            Write-Log "${YELLOW}Iteration timed out after $TimeoutMinutes minutes${NC}"
            Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
            return 3  # Retry-able
        }

        # Get job output and display
        $textOutput = Receive-Job -Job $job
        if ($textOutput) {
            $textOutput | ForEach-Object { Write-Host $_ }
            # Append to log file
            $textOutput | Add-Content -Path $LogFile
        }
        Remove-Job -Job $job -Force
        $script:CurrentJob = $null

        # Read full output for promise word detection
        $output = Get-Content -Path $outputFile -Raw -ErrorAction SilentlyContinue

        # Check for promise words
        if ($output -match [regex]::Escape($PROMISE_COMPLETE)) {
            Write-Log "${GREEN}Task completed successfully${NC}"
            Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
            return 0  # Continue loop
        }
        elseif ($output -match [regex]::Escape($PROMISE_NO_ISSUES)) {
            Write-Log "${YELLOW}No more issues available${NC}"
            Send-Notification "Ralph: All issues complete!"
            Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
            return 1  # Stop loop - success
        }
        elseif ($output -match [regex]::Escape($PROMISE_BLOCKED)) {
            Write-Log "${RED}Task blocked - human intervention required${NC}"
            Send-Notification "Ralph: BLOCKED! Human needed"
            Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
            return 2  # Stop loop - error
        }
        else {
            Write-Log "${RED}Unexpected output (no promise word found)${NC}"
            Write-Log ""
            Write-Log "--- Last 50 lines of raw output ---"
            $lastLines = Get-Content -Path $outputFile -Tail 50 -ErrorAction SilentlyContinue
            if ($lastLines) {
                $lastLines | ForEach-Object { Write-Host $_ }
                $lastLines | Add-Content -Path $LogFile
            }
            Write-Log "-----------------------------------"
            Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
            return 3  # Retry-able error
        }
    }
    catch {
        Write-Log "${RED}Error during iteration: $_${NC}"
        Remove-Item -Path $outputFile -Force -ErrorAction SilentlyContinue
        return 3  # Retry-able error
    }
}

function Start-Ralph {
    Write-Log "${BLUE}==========================================${NC}"
    Write-Log "${BLUE}Ralph Wiggum - Autonomous Dev Loop${NC}"
    Write-Log "${BLUE}==========================================${NC}"
    Write-Log "Max iterations: $MaxIterations"
    Write-Log "Timeout per iteration: ${TimeoutMinutes}m"
    Write-Log "Max retries per iteration: $MaxRetries"
    Write-Log "Log file: $LogFile"
    Write-Log ""

    Test-Dependencies

    $completed = 0
    $iteration = 1

    while ($iteration -le $MaxIterations) {
        # Check if interrupted
        if ($script:Interrupted) {
            Write-Log "${YELLOW}Stopping due to interrupt...${NC}"
            break
        }

        $retry = 0
        $result = 3  # Start with retry-able state

        # Retry loop for crashes/malformed requests
        while ($result -eq 3 -and $retry -lt $MaxRetries) {
            if ($retry -gt 0) {
                Write-Log "${YELLOW}Retry $retry of $MaxRetries for iteration $iteration${NC}"
                Start-Sleep -Seconds 5
            }

            $result = Invoke-RalphIteration -Iteration $iteration
            $retry++

            # Check if interrupted during iteration
            if ($script:Interrupted) {
                break
            }
        }

        # Check if interrupted
        if ($script:Interrupted) {
            Write-Log "${YELLOW}Stopping due to interrupt...${NC}"
            break
        }

        switch ($result) {
            0 {
                # Success - task completed, continue to next
                $completed++
                $iteration++
                Write-Log ""
                Write-Log "Completed $completed task(s) so far. Continuing..."
                Write-Log ""
                Start-Sleep -Seconds 2
            }
            1 {
                # No more issues - clean exit
                Write-Log ""
                Write-Log "${GREEN}==========================================${NC}"
                Write-Log "${GREEN}Ralph finished - no more issues${NC}"
                Write-Log "${GREEN}Completed: $completed task(s)${NC}"
                Write-Log "${GREEN}==========================================${NC}"
                Send-Notification "Ralph done! Completed $completed tasks"
                exit 0
            }
            3 {
                # Exhausted retries
                Write-Log ""
                Write-Log "${RED}==========================================${NC}"
                Write-Log "${RED}Ralph stopped - exhausted $MaxRetries retries${NC}"
                Write-Log "${RED}Completed before stop: $completed task(s)${NC}"
                Write-Log "${RED}==========================================${NC}"
                Send-Notification "Ralph: Exhausted retries after $completed tasks"
                exit 1
            }
            default {
                # Error/blocked (result=2)
                Write-Log ""
                Write-Log "${RED}==========================================${NC}"
                Write-Log "${RED}Ralph stopped - human intervention needed${NC}"
                Write-Log "${RED}Completed before stop: $completed task(s)${NC}"
                Write-Log "${RED}==========================================${NC}"
                exit 1
            }
        }
    }

    # If we got here via interrupt, show status
    if ($script:Interrupted) {
        Write-Log ""
        Write-Log "${YELLOW}==========================================${NC}"
        Write-Log "${YELLOW}Ralph interrupted by user${NC}"
        Write-Log "${YELLOW}Completed: $completed task(s)${NC}"
        Write-Log "${YELLOW}==========================================${NC}"
        exit 130
    }

    Write-Log ""
    Write-Log "${YELLOW}==========================================${NC}"
    Write-Log "${YELLOW}Max iterations ($MaxIterations) reached${NC}"
    Write-Log "${YELLOW}Completed: $completed task(s)${NC}"
    Write-Log "${YELLOW}==========================================${NC}"
    Send-Notification "Ralph: Max iterations reached ($completed tasks done)"
}

# Track if cleanup has run
$script:CleanupDone = $false

# Cleanup function to kill child processes
function Stop-ChildProcesses {
    param([switch]$IsInterrupt)

    # Only run cleanup once
    if ($script:CleanupDone) {
        return
    }
    $script:CleanupDone = $true

    if ($IsInterrupt) {
        $script:Interrupted = $true
        Write-Log "${YELLOW}Interrupt received - killing child processes...${NC}"
    }

    # Stop the current job if running
    if ($script:CurrentJob) {
        try {
            Stop-Job -Job $script:CurrentJob -ErrorAction SilentlyContinue
            Remove-Job -Job $script:CurrentJob -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore errors during cleanup
        }
        $script:CurrentJob = $null
    }

    # Kill any orphaned claude processes started by this script
    # Get child processes of the current PowerShell process
    $currentPid = $PID
    Get-CimInstance Win32_Process -Filter "ParentProcessId = $currentPid" -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Ignore errors
            }
        }
}

# Handle Ctrl+C gracefully
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-ChildProcesses -IsInterrupt
}

try {
    Start-Ralph
}
catch {
    # Ctrl+C throws a PipelineStoppedException or similar
    Stop-ChildProcesses -IsInterrupt
}
finally {
    # Cleanup (without interrupt message on normal exit)
    Stop-ChildProcesses
    Unregister-Event -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
}
