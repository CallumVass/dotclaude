#!/usr/bin/env bash
#
# quality-checks.sh - Detect project type and run appropriate quality checks
#
# Exit codes:
#   0 - All checks passed
#   1 - Checks failed
#   2 - Unknown project type
#

set -euo pipefail

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "$1"
}

detect_project_type() {
    local types=()

    # .NET
    if compgen -G "*.sln" > /dev/null 2>&1 || compgen -G "*.csproj" > /dev/null 2>&1; then
        types+=("dotnet")
    fi

    # Elixir
    if [[ -f "mix.exs" ]]; then
        types+=("elixir")
    fi

    # Node.js/TypeScript
    if [[ -f "package.json" ]]; then
        types+=("node")
    fi

    # Python
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        types+=("python")
    fi

    # Rust
    if [[ -f "Cargo.toml" ]]; then
        types+=("rust")
    fi

    # Go
    if [[ -f "go.mod" ]]; then
        types+=("go")
    fi

    if [[ ${#types[@]} -eq 0 ]]; then
        echo "unknown"
    else
        echo "${types[@]}"
    fi
}

run_dotnet_checks() {
    log "${YELLOW}Running .NET quality checks...${NC}"

    # Restore dependencies
    if ! dotnet restore; then
        log "${RED}dotnet restore failed${NC}"
        return 1
    fi

    # Build
    if ! dotnet build --no-restore; then
        log "${RED}dotnet build failed${NC}"
        return 1
    fi

    # Test
    if ! dotnet test --no-build --verbosity normal; then
        log "${RED}dotnet test failed${NC}"
        return 1
    fi

    # Format check (if dotnet-format available)
    if command -v dotnet-format &> /dev/null; then
        if ! dotnet format --verify-no-changes; then
            log "${YELLOW}Format issues found (non-blocking)${NC}"
        fi
    fi

    log "${GREEN}.NET checks passed${NC}"
    return 0
}

run_elixir_checks() {
    log "${YELLOW}Running Elixir quality checks...${NC}"

    # Get dependencies
    if ! mix deps.get; then
        log "${RED}mix deps.get failed${NC}"
        return 1
    fi

    # Compile
    if ! mix compile --warnings-as-errors; then
        log "${RED}mix compile failed${NC}"
        return 1
    fi

    # Test
    if ! mix test; then
        log "${RED}mix test failed${NC}"
        return 1
    fi

    # Format check
    if ! mix format --check-formatted; then
        log "${RED}mix format check failed${NC}"
        return 1
    fi

    # Credo (if available)
    if mix help credo &> /dev/null; then
        if ! mix credo --strict; then
            log "${YELLOW}Credo issues found (non-blocking)${NC}"
        fi
    fi

    log "${GREEN}Elixir checks passed${NC}"
    return 0
}

run_node_checks() {
    log "${YELLOW}Running Node.js quality checks...${NC}"

    # Determine package manager
    local pm="npm"
    if [[ -f "pnpm-lock.yaml" ]]; then
        pm="pnpm"
    elif [[ -f "yarn.lock" ]]; then
        pm="yarn"
    fi

    # Install dependencies
    if ! $pm install; then
        log "${RED}$pm install failed${NC}"
        return 1
    fi

    # TypeScript type check (if applicable)
    if [[ -f "tsconfig.json" ]]; then
        if command -v npx &> /dev/null; then
            if ! npx tsc --noEmit 2>/dev/null; then
                log "${RED}TypeScript type check failed${NC}"
                return 1
            fi
        fi
    fi

    # Lint (if script exists)
    if grep -q '"lint"' package.json 2>/dev/null; then
        if ! $pm run lint; then
            log "${RED}Lint failed${NC}"
            return 1
        fi
    fi

    # Test
    if grep -q '"test"' package.json 2>/dev/null; then
        if ! $pm test; then
            log "${RED}Tests failed${NC}"
            return 1
        fi
    else
        log "${YELLOW}No test script found${NC}"
    fi

    log "${GREEN}Node.js checks passed${NC}"
    return 0
}

run_python_checks() {
    log "${YELLOW}Running Python quality checks...${NC}"

    # Install dependencies
    if [[ -f "pyproject.toml" ]]; then
        pip install -e ".[dev]" 2>/dev/null || pip install -e . 2>/dev/null || true
    elif [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt 2>/dev/null || true
    fi

    # Pytest
    if command -v pytest &> /dev/null; then
        if ! pytest; then
            log "${RED}pytest failed${NC}"
            return 1
        fi
    fi

    # Ruff (if available)
    if command -v ruff &> /dev/null; then
        if ! ruff check .; then
            log "${RED}ruff check failed${NC}"
            return 1
        fi
    fi

    log "${GREEN}Python checks passed${NC}"
    return 0
}

run_rust_checks() {
    log "${YELLOW}Running Rust quality checks...${NC}"

    # Build
    if ! cargo build; then
        log "${RED}cargo build failed${NC}"
        return 1
    fi

    # Test
    if ! cargo test; then
        log "${RED}cargo test failed${NC}"
        return 1
    fi

    # Clippy
    if ! cargo clippy -- -D warnings; then
        log "${RED}cargo clippy failed${NC}"
        return 1
    fi

    # Format check
    if ! cargo fmt -- --check; then
        log "${RED}cargo fmt check failed${NC}"
        return 1
    fi

    log "${GREEN}Rust checks passed${NC}"
    return 0
}

run_go_checks() {
    log "${YELLOW}Running Go quality checks...${NC}"

    # Build
    if ! go build ./...; then
        log "${RED}go build failed${NC}"
        return 1
    fi

    # Test
    if ! go test ./...; then
        log "${RED}go test failed${NC}"
        return 1
    fi

    # Vet
    if ! go vet ./...; then
        log "${RED}go vet failed${NC}"
        return 1
    fi

    # Format check
    if [[ -n "$(gofmt -l . 2>/dev/null)" ]]; then
        log "${RED}go fmt check failed${NC}"
        return 1
    fi

    log "${GREEN}Go checks passed${NC}"
    return 0
}

main() {
    log "=========================================="
    log "Quality Checks"
    log "=========================================="

    local project_types
    project_types=$(detect_project_type)

    log "Detected project types: $project_types"

    if [[ "$project_types" == "unknown" ]]; then
        log "${RED}Could not detect project type${NC}"
        exit 2
    fi

    local failed=0

    for ptype in $project_types; do
        case $ptype in
            dotnet)
                run_dotnet_checks || failed=1
                ;;
            elixir)
                run_elixir_checks || failed=1
                ;;
            node)
                run_node_checks || failed=1
                ;;
            python)
                run_python_checks || failed=1
                ;;
            rust)
                run_rust_checks || failed=1
                ;;
            go)
                run_go_checks || failed=1
                ;;
        esac
    done

    if [[ $failed -eq 0 ]]; then
        log "${GREEN}All quality checks passed${NC}"
        exit 0
    else
        log "${RED}Some quality checks failed${NC}"
        exit 1
    fi
}

main "$@"
