# Elixir Phoenix Rules

## Mandatory Constraints

```
╔═══════════════════════════════════════════════════════════════╗
║  These rules ALWAYS apply to ALL code, regardless of what     ║
║  acceptance criteria says. AC defines WHAT to build, these    ║
║  rules define HOW to build it.                                ║
╚═══════════════════════════════════════════════════════════════╝
```

1. **Tailwind + daisyUI only** - NEVER write custom CSS or `<style>` blocks. Use daisyUI components where appropriate.

2. **Tests required** - Every feature MUST include boundary tests (LiveView, Controller). A feature is NOT complete without them.

3. **Only mock external I/O** - Use Mox for third-party APIs, not your own contexts.

---

## Core Principles

### DRY, YAGNI, KISS

- Single source of truth for constants and configuration
- Build only what's needed for the current task
- Prefer explicit over clever
- "Duplication is far cheaper than the wrong abstraction" - Sandi Metz

### Elixir Fundamentals

- Prefer immutability and pure functions
- Use pattern matching extensively
- Let processes crash and supervise them
- Prefer pipelines for data transformation

---

## First-Time Setup

### Check for AGENTS.md

Phoenix 1.8+ generates an `AGENTS.md` file with project-specific guidance:

```bash
ls AGENTS.md
```

If it exists, read it and follow its conventions.

### Install the Claude Package (Recommended)

```bash
mix igniter.install claude
```

This automatically:
- Adds `usage_rules` dependency
- Creates/updates `CLAUDE.md` with links to dependency rules
- Syncs rules from all dependencies to `deps/` folder

### Manual usage_rules Setup (Alternative)

```bash
mix igniter.install usage_rules
mix usage_rules.sync --all
```

## Ongoing Development

```bash
# Ensure rules are current
mix usage_rules.sync CLAUDE.md --all --link-to-folder deps

# Search docs
mix usage_rules.search_docs phoenix "live view"
```

---

## Result Type

```elixir
{:ok, user} = Users.get(id)
{:error, :not_found} = Users.get(invalid_id)

# Pipeline with with
with {:ok, user} <- Users.get(id),
     {:ok, _} <- Users.validate(user),
     {:ok, updated} <- Users.update(user, params) do
  {:ok, updated}
end
```

---

## LiveView Styling: Tailwind Only

```
╔═══════════════════════════════════════════════════════════════╗
║  NEVER write custom CSS or <style> blocks                     ║
║  ALWAYS use Tailwind utility classes                          ║
║  EXTEND the config for custom values, don't hardcode          ║
╚═══════════════════════════════════════════════════════════════╝
```

### Semantic Tokens

Use semantic tokens, not raw Tailwind values:

| NEVER | INSTEAD |
|-------|---------|
| `class="text-gray-500"` | `class="text-foreground-muted"` |
| `class="bg-white"` | `class="bg-surface"` |
| `class="border-gray-200"` | `class="border-border"` |

### Token Reference

```
bg-surface / bg-surface-muted / bg-surface-subtle
border-border / border-border-subtle
text-foreground / text-foreground-muted / text-foreground-faint
bg-accent / bg-accent-hover / text-accent
text-success / text-warning / text-error
```

### Typography

```
text-2xl font-semibold tracking-tight  // Page titles
text-lg font-semibold tracking-tight   // Section headings
text-sm text-foreground                // Primary body
text-sm text-foreground-muted          // Secondary text
font-mono tabular-nums                 // Numeric data
```

### Spacing (4px Grid)

| Class | Value | Use |
|-------|-------|-----|
| `p-2` / `gap-2` | 8px | Tight spacing |
| `p-4` / `gap-4` | 16px | Standard spacing |
| `p-6` / `gap-6` | 24px | Generous spacing |

---

## Testing

### The Rule

```
╔═══════════════════════════════════════════════════════════════╗
║  EVERY feature implementation MUST include tests.             ║
║  A feature is NOT complete without them.                      ║
╚═══════════════════════════════════════════════════════════════╝
```

### Boundary Testing

Test at boundaries - LiveViews, Controllers. Use real contexts with Ecto Sandbox.

### LiveView Tests

```elixir
defmodule MyAppWeb.UsersLiveTest do
  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "lists all users", %{conn: conn} do
    user = user_fixture()
    {:ok, _view, html} = live(conn, ~p"/users")
    assert html =~ user.email
  end

  test "creates new user", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/users/new")

    view
    |> form("#user-form", user: %{email: "test@example.com"})
    |> render_submit()

    assert_redirect(view, ~p"/users")
  end
end
```

### Factories with ExMachina

```elixir
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo

  def user_factory do
    %MyApp.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      name: Faker.Person.name()
    }
  end
end
```

### Mock External Services with Mox

```elixir
Mox.defmock(MyApp.PaymentsMock, for: MyApp.Payments.Behaviour)

expect(MyApp.PaymentsMock, :charge, fn _amount, _token ->
  {:ok, %{id: "ch_123", status: "succeeded"}}
end)
```

### Mocking Rules

```
ONLY mock external I/O:
  - Third-party APIs (payment, email, SMS)
  - HTTP clients, external services

NEVER mock your own code:
  - Contexts, schemas, internal modules
  - If you're mocking it, you're testing implementation not behavior
```

---

## Why This Approach?

1. **No stale rules**: `usage_rules` syncs from actual dependency versions
2. **Ecosystem alignment**: Uses tools the Elixir community maintains
3. **Context-efficient**: Linking to deps folder keeps CLAUDE.md lean
