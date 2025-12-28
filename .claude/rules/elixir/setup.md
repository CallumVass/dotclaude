# Elixir Project Setup

For Elixir projects, defer to ecosystem tooling rather than prescriptive rules.

## First-Time Setup

When working with an Elixir project for the first time:

### 1. Check for AGENTS.md

Phoenix 1.8+ generates an `AGENTS.md` file with project-specific guidance:

```bash
# Look for it
ls AGENTS.md
```

If it exists, read it and follow its conventions.

### 2. Install Igniter (if not present)

[Igniter](https://github.com/ash-project/igniter) provides smart code generation and project modification:

```elixir
# In mix.exs deps
{:igniter, "~> 0.6", only: [:dev, :test]}
```

Then use `mix igniter.install <package>` for smarter dependency setup.

### 3. Install usage_rules via Igniter

[usage_rules](https://hexdocs.pm/usage_rules) syncs documentation from dependencies:

```bash
mix deps.get
mix igniter.install usage_rules
```

### 4. Sync Dependency Rules

```bash
mix usage_rules.sync --all
```

This creates consolidated documentation from all dependencies that provide usage rules.

### 5. Update CLAUDE.md (if needed)

If the project has a `CLAUDE.md`, add any project-specific patterns discovered. If not, consider creating one with:

- Key architectural decisions
- Project-specific conventions
- Important context from AGENTS.md

## Ongoing Development

### Before Starting Work

```bash
# Ensure rules are current
mix usage_rules.sync --all
```

### Using mix Tasks

Prefer Igniter-powered tasks when available:

```bash
mix igniter.install <dep>     # Smart dependency installation
mix igniter.upgrade           # Upgrade with code modifications
```

### Documentation Lookup

Use `mix usage_rules.search_docs` to search hexdocs:

```bash
mix usage_rules.search_docs phoenix "live view"
```

## Why This Approach?

1. **No stale rules**: `usage_rules` syncs from actual dependency versions
2. **Ecosystem alignment**: Uses tools the Elixir community maintains
3. **Project-specific**: AGENTS.md and CLAUDE.md capture what's unique
4. **Composable**: Igniter lets generators call other generators intelligently
