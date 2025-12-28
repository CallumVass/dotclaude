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

### 2. Install the Claude Package (Recommended)

The [claude](https://hexdocs.pm/claude) package provides Claude Code-specific integration:

```bash
mix igniter.install claude
```

This automatically:
- Adds `usage_rules` dependency
- Creates/updates `CLAUDE.md` with links to dependency rules
- Syncs rules from all dependencies to `deps/` folder

The installer runs:
```bash
mix usage_rules.sync CLAUDE.md --all --link-to-folder deps
```

This keeps the root `CLAUDE.md` lean by linking to rules in `deps/` rather than inlining everything, reducing context window usage.

### Alternative: Manual usage_rules Setup

If you prefer not to use the `claude` package, install [usage_rules](https://hexdocs.pm/usage_rules) directly:

```bash
mix igniter.install usage_rules
mix usage_rules.sync --all
```

### 3. Nested CLAUDE.md Files (Optional)

For larger projects, create context-specific `CLAUDE.md` files in subdirectories:

```
lib/
├── my_app_web/
│   └── CLAUDE.md    # Web-specific guidance
└── my_app/
    └── accounts/
        └── CLAUDE.md  # Accounts context guidance
```

Rules in nested files are inlined for focused context when working in those directories.

### 4. Update CLAUDE.md (if needed)

Add project-specific patterns:

- Key architectural decisions
- Project-specific conventions
- Important context from AGENTS.md

## Ongoing Development

### Before Starting Work

```bash
# Ensure rules are current (if using claude package)
mix usage_rules.sync CLAUDE.md --all --link-to-folder deps

# Or if using usage_rules directly
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

## Sub-Agent Usage Rules

When spawning sub-agents, you can reference specific usage rules via the `usage_rules` field:

```elixir
# Load main rules file from a package
usage_rules: [:phoenix]

# Load all rules from a package
usage_rules: ["phoenix:all"]

# Load specific rule from a package
usage_rules: ["phoenix:live_view"]
```

This allows sub-agents to have focused context for their specific tasks.

## Why This Approach?

1. **No stale rules**: `usage_rules` syncs from actual dependency versions
2. **Ecosystem alignment**: Uses tools the Elixir community maintains
3. **Project-specific**: AGENTS.md and CLAUDE.md capture what's unique
4. **Composable**: Igniter lets generators call other generators intelligently
5. **Context-efficient**: Linking to deps folder keeps CLAUDE.md lean
