#Requires -Version 5.1
<#
.SYNOPSIS
    Ralph Wiggum - Autonomous Claude Code loop runner

.DESCRIPTION
    Loops claude CLI calls until promise word signals completion.

    Promise words:
      - <promise>COMPLETE</promise>: Task complete, continue to next
      - <promise>NO_ISSUES</promise>: No more issues, exit success
      - <promise>BLOCKED</promise>: Needs human, exit with error

.PARAMETER MaxIterations
    Maximum number of iterations (default: 10)

.PARAMETER LogFile
    Path to log file (default: .\ralph.log)

.PARAMETER Notify
    Enable Windows toast notifications

.EXAMPLE
    .\ralph.ps1 -MaxIterations 5

.EXAMPLE
    .\ralph.ps1 -Notify

.EXAMPLE
    .\ralph.ps1 -MaxIterations 20 -Notify -LogFile "C:\logs\ralph.log"
#>

[CmdletBinding()]
param(
    [int]$MaxIterations = 10,
    [string]$LogFile = ".\ralph.log",
    [switch]$Notify
)

$ErrorActionPreference = "Continue"

# Promise words
$PROMISE_COMPLETE = "<promise>COMPLETE</promise>"
$PROMISE_NO_ISSUES = "<promise>NO_ISSUES</promise>"
$PROMISE_BLOCKED = "<promise>BLOCKED</promise>"

function Write-Log {
    param(
        [string]$Message,
        [string]$Colour = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"

    Write-Host $logMessage -ForegroundColor $Colour
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
}

function Send-Notification {
    param(
        [string]$Title,
        [string]$Message
    )

    if (-not $Notify) { return }

    try {
        # Windows toast notification using BurntToast if available
        if (Get-Command "New-BurntToastNotification" -ErrorAction SilentlyContinue) {
            New-BurntToastNotification -Text $Title, $Message
        }
        else {
            # Fallback to basic notification
            [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
            $balloon = New-Object System.Windows.Forms.NotifyIcon
            $balloon.Icon = [System.Drawing.SystemIcons]::Information
            $balloon.BalloonTipTitle = $Title
            $balloon.BalloonTipText = $Message
            $balloon.Visible = $true
            $balloon.ShowBalloonTip(5000)
            Start-Sleep -Seconds 1
            $balloon.Dispose()
        }
    }
    catch {
        Write-Log "Notification failed: $_" -Colour Yellow
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
        Write-Log "Error: Missing dependencies: $($missing -join ', ')" -Colour Red
        exit 1
    }
}

function Invoke-RalphIteration {
    param([int]$Iteration)

    Write-Log "==========================================" -Colour Cyan
    Write-Log "Iteration $Iteration of $MaxIterations" -Colour Cyan
    Write-Log "==========================================" -Colour Cyan

    $tempFile = [System.IO.Path]::GetTempFileName()

    try {
        # Run claude with ralph-task skill
        # --permission-mode acceptEdits allows autonomous operation
        # Tee-Object streams to console AND captures to file
        & claude --permission-mode acceptEdits -p "/ralph-task" 2>&1 | Tee-Object -FilePath $tempFile | Write-Host

        $output = Get-Content -Path $tempFile -Raw -ErrorAction SilentlyContinue

        if (-not $output) {
            Write-Log "No output from claude" -Colour Red
            return @{ Continue = $false; Completed = $false; Status = "error" }
        }

        # Check for promise words
        if ($output -match [regex]::Escape($PROMISE_COMPLETE)) {
            Write-Log "Task completed successfully" -Colour Green
            return @{ Continue = $true; Completed = $true; Status = "complete" }
        }
        elseif ($output -match [regex]::Escape($PROMISE_NO_ISSUES)) {
            Write-Log "No more issues available" -Colour Yellow
            Send-Notification "Ralph" "All issues complete!"
            return @{ Continue = $false; Completed = $false; Status = "done" }
        }
        elseif ($output -match [regex]::Escape($PROMISE_BLOCKED)) {
            Write-Log "Task blocked - human intervention required" -Colour Red
            Send-Notification "Ralph" "BLOCKED! Human needed"
            Write-Host ""
            Write-Host "--- Blocked Output ---" -ForegroundColor Red
            Write-Host $output
            Write-Host "----------------------" -ForegroundColor Red
            return @{ Continue = $false; Completed = $false; Status = "blocked" }
        }
        else {
            Write-Log "Unexpected output (no promise word found)" -Colour Red
            Write-Host ""
            Write-Host "--- Unexpected Output (last 50 lines) ---" -ForegroundColor Red
            $output -split "`n" | Select-Object -Last 50 | ForEach-Object { Write-Host $_ }
            Write-Host "------------------------------------------" -ForegroundColor Red
            return @{ Continue = $false; Completed = $false; Status = "error" }
        }
    }
    catch {
        Write-Log "Error running claude: $_" -Colour Red
        return @{ Continue = $false; Completed = $false; Status = "error" }
    }
    finally {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
}

# Main execution
Write-Log "==========================================" -Colour Cyan
Write-Log "Ralph Wiggum - Autonomous Dev Loop" -Colour Cyan
Write-Log "==========================================" -Colour Cyan
Write-Log "Max iterations: $MaxIterations"
Write-Log "Log file: $LogFile"
Write-Log ""

Test-Dependencies

$completed = 0
$iteration = 1

while ($iteration -le $MaxIterations) {
    $result = Invoke-RalphIteration -Iteration $iteration

    if ($result.Completed) {
        $completed++
    }

    if ($result.Status -eq "complete") {
        # Task completed, continue to next
        $iteration++
        Write-Log ""
        Write-Log "Completed $completed task(s) so far. Continuing..."
        Write-Log ""
        Start-Sleep -Seconds 2
    }
    elseif ($result.Status -eq "done") {
        # No more issues - clean exit
        Write-Log ""
        Write-Log "==========================================" -Colour Green
        Write-Log "Ralph finished - no more issues" -Colour Green
        Write-Log "Completed: $completed task(s)" -Colour Green
        Write-Log "==========================================" -Colour Green
        Send-Notification "Ralph" "Done! Completed $completed tasks"
        exit 0
    }
    else {
        # Error or blocked
        Write-Log ""
        Write-Log "==========================================" -Colour Red
        Write-Log "Ralph stopped - human intervention needed" -Colour Red
        Write-Log "Completed before stop: $completed task(s)" -Colour Red
        Write-Log "==========================================" -Colour Red
        exit 1
    }
}

Write-Log ""
Write-Log "==========================================" -Colour Yellow
Write-Log "Max iterations ($MaxIterations) reached" -Colour Yellow
Write-Log "Completed: $completed task(s)" -Colour Yellow
Write-Log "==========================================" -Colour Yellow
Send-Notification "Ralph" "Max iterations reached ($completed tasks done)"
