# dotclaude

This is a dotfiles repository for Claude Code configuration. It is not a project to build or run.

## Purpose

Contains reusable skills and rules that get symlinked or cloned to `~/.claude` for use across projects.

## Structure

- `.claude/rules/` - Stack-specific coding standards (dotnet, elixir, typescript, windows)
- `.claude/skills/` - Workflow automation (next-feature, brainstorm, review-loop, etc.)
- `.claude/settings.local.json` - Default permissions

## Usage

See README.md for setup instructions.

## Windows

**CRITICAL: Avoid `>nul` and `2>nul` redirections** - they create literal files instead of redirecting to the NUL device. Use dedicated tools (Grep, Glob, Read) instead of piped bash commands.
