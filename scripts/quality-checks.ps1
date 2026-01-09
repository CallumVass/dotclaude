#Requires -Version 5.1
<#
.SYNOPSIS
    Detect project type and run appropriate quality checks

.DESCRIPTION
    Automatically detects the project type (dotnet, node, elixir, etc.)
    and runs the appropriate build, test, and lint commands.

.EXAMPLE
    .\quality-checks.ps1

.NOTES
    Exit codes:
      0 - All checks passed
      1 - Checks failed
      2 - Unknown project type
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [string]$Message,
        [string]$Colour = "White"
    )
    Write-Host $Message -ForegroundColor $Colour
}

function Get-ProjectTypes {
    $types = @()

    # .NET
    if ((Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue) -or
        (Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue)) {
        $types += "dotnet"
    }

    # Node.js
    if (Test-Path "package.json") {
        $types += "node"
    }

    # Elixir
    if (Test-Path "mix.exs") {
        $types += "elixir"
    }

    # Python
    if ((Test-Path "pyproject.toml") -or (Test-Path "setup.py") -or (Test-Path "requirements.txt")) {
        $types += "python"
    }

    # Rust
    if (Test-Path "Cargo.toml") {
        $types += "rust"
    }

    # Go
    if (Test-Path "go.mod") {
        $types += "go"
    }

    if ($types.Count -eq 0) {
        $types += "unknown"
    }

    return $types
}

function Test-DotNet {
    Write-Status "Running .NET quality checks..." -Colour Yellow

    # Restore
    dotnet restore
    if ($LASTEXITCODE -ne 0) {
        Write-Status "dotnet restore failed" -Colour Red
        return $false
    }

    # Build
    dotnet build --no-restore
    if ($LASTEXITCODE -ne 0) {
        Write-Status "dotnet build failed" -Colour Red
        return $false
    }

    # Test
    dotnet test --no-build --verbosity normal
    if ($LASTEXITCODE -ne 0) {
        Write-Status "dotnet test failed" -Colour Red
        return $false
    }

    Write-Status ".NET checks passed" -Colour Green
    return $true
}

function Test-Node {
    Write-Status "Running Node.js quality checks..." -Colour Yellow

    # Determine package manager
    $pm = "npm"
    if (Test-Path "pnpm-lock.yaml") { $pm = "pnpm" }
    elseif (Test-Path "yarn.lock") { $pm = "yarn" }

    # Install
    & $pm install
    if ($LASTEXITCODE -ne 0) {
        Write-Status "$pm install failed" -Colour Red
        return $false
    }

    # TypeScript type check
    if (Test-Path "tsconfig.json") {
        npx tsc --noEmit 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Status "TypeScript type check failed" -Colour Red
            return $false
        }
    }

    # Read package.json
    $pkg = Get-Content "package.json" | ConvertFrom-Json

    # Lint (if exists)
    if ($pkg.scripts.lint) {
        & $pm run lint
        if ($LASTEXITCODE -ne 0) {
            Write-Status "Lint failed" -Colour Red
            return $false
        }
    }

    # Test (if exists)
    if ($pkg.scripts.test) {
        & $pm test
        if ($LASTEXITCODE -ne 0) {
            Write-Status "Tests failed" -Colour Red
            return $false
        }
    }
    else {
        Write-Status "No test script found" -Colour Yellow
    }

    Write-Status "Node.js checks passed" -Colour Green
    return $true
}

function Test-Elixir {
    Write-Status "Running Elixir quality checks..." -Colour Yellow

    mix deps.get
    if ($LASTEXITCODE -ne 0) { return $false }

    mix compile --warnings-as-errors
    if ($LASTEXITCODE -ne 0) { return $false }

    mix test
    if ($LASTEXITCODE -ne 0) { return $false }

    mix format --check-formatted
    if ($LASTEXITCODE -ne 0) { return $false }

    Write-Status "Elixir checks passed" -Colour Green
    return $true
}

function Test-Python {
    Write-Status "Running Python quality checks..." -Colour Yellow

    if (Test-Path "pyproject.toml") {
        pip install -e ".[dev]" 2>$null
        if ($LASTEXITCODE -ne 0) { pip install -e . 2>$null }
    }
    elseif (Test-Path "requirements.txt") {
        pip install -r requirements.txt 2>$null
    }

    if (Get-Command pytest -ErrorAction SilentlyContinue) {
        pytest
        if ($LASTEXITCODE -ne 0) { return $false }
    }

    if (Get-Command ruff -ErrorAction SilentlyContinue) {
        ruff check .
        if ($LASTEXITCODE -ne 0) { return $false }
    }

    Write-Status "Python checks passed" -Colour Green
    return $true
}

function Test-Rust {
    Write-Status "Running Rust quality checks..." -Colour Yellow

    cargo build
    if ($LASTEXITCODE -ne 0) { return $false }

    cargo test
    if ($LASTEXITCODE -ne 0) { return $false }

    cargo clippy -- -D warnings
    if ($LASTEXITCODE -ne 0) { return $false }

    cargo fmt -- --check
    if ($LASTEXITCODE -ne 0) { return $false }

    Write-Status "Rust checks passed" -Colour Green
    return $true
}

function Test-Go {
    Write-Status "Running Go quality checks..." -Colour Yellow

    go build ./...
    if ($LASTEXITCODE -ne 0) { return $false }

    go test ./...
    if ($LASTEXITCODE -ne 0) { return $false }

    go vet ./...
    if ($LASTEXITCODE -ne 0) { return $false }

    Write-Status "Go checks passed" -Colour Green
    return $true
}

# Main
Write-Status "==========================================" -Colour Cyan
Write-Status "Quality Checks" -Colour Cyan
Write-Status "==========================================" -Colour Cyan

$projectTypes = Get-ProjectTypes
Write-Status "Detected project types: $($projectTypes -join ', ')"

if ($projectTypes -contains "unknown") {
    Write-Status "Could not detect project type" -Colour Red
    exit 2
}

$allPassed = $true

foreach ($ptype in $projectTypes) {
    $result = switch ($ptype) {
        "dotnet" { Test-DotNet }
        "node" { Test-Node }
        "elixir" { Test-Elixir }
        "python" { Test-Python }
        "rust" { Test-Rust }
        "go" { Test-Go }
    }

    if (-not $result) {
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Status "All quality checks passed" -Colour Green
    exit 0
}
else {
    Write-Status "Some quality checks failed" -Colour Red
    exit 1
}
