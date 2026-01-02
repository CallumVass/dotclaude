# Elixir Project Setup

For Elixir projects, defer to ecosystem tooling rather than prescriptive rules.

## First-Time Setup

### 1. Check for AGENTS.md

Phoenix 1.8+ generates an `AGENTS.md` file with project-specific guidance:

```bash
ls AGENTS.md
```

If it exists, read it and follow its conventions.

### 2. Install the Claude Package (Recommended)

```bash
mix igniter.install claude
```

This automatically:
- Adds `usage_rules` dependency
- Creates/updates `CLAUDE.md` with links to dependency rules
- Syncs rules from all dependencies to `deps/` folder

### 3. Manual usage_rules Setup (Alternative)

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

## Testing

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

## Why This Approach?

1. **No stale rules**: `usage_rules` syncs from actual dependency versions
2. **Ecosystem alignment**: Uses tools the Elixir community maintains
3. **Context-efficient**: Linking to deps folder keeps CLAUDE.md lean
