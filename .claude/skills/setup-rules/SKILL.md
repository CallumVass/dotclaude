---
name: setup-rules
description: Detect project tech stack and consolidate relevant rules into CLAUDE.md. Use when user says "setup rules", "init rules", "personalise".
arguments:
  - name: stack
    description: Override auto-detection (e.g., "dotnet,typescript")
    required: false
---

# Setup Rules

Consolidate rules from `.claude/rules/` into `CLAUDE.md` based on detected tech stack.

## Constraints

- Never overwrite existing CLAUDE.md content - append to it
- Always include patterns.md (universal rules)
- Delete `.claude/rules/` only after successful consolidation
- Get user confirmation before making changes

## Detection

Scan project root for these indicators:

| Found | Include |
|-------|---------|
| `*.sln` or `*.csproj` | dotnet/core.md |
| `*.cs` files | + dotnet/csharp.md |
| `*.fs` files | + dotnet/fsharp.md |
| `mix.exs` | elixir/setup.md |
| `package.json` or `tsconfig.json` | typescript/core.md |
| `react` in package.json deps or `*.tsx` | + typescript/react.md |
| `vue` in package.json deps or `*.vue` | + typescript/vue.md |
| Always | patterns.md |

If `stack` argument provided, use that instead of auto-detection.

## Process

1. Verify `.claude/rules/` exists. Exit if not.

2. Detect stack (or use provided override).

3. Present findings to user: detected stack, rules to include. Ask for confirmation.

4. Concatenate selected rules into CLAUDE.md:
   - patterns.md first (universal)
   - Then stack-specific rules alphabetically
   - Append if CLAUDE.md exists, create if not

5. Delete `.claude/rules/` directory.

6. Report what was included and where it went.
