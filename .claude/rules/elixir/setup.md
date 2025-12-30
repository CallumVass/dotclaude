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

## Testing

Test at boundaries - LiveViews, Controllers, and CLI commands. Use real contexts and services with database isolation via Ecto Sandbox.

### Dependencies

```elixir
# mix.exs
defp deps do
  [
    {:ex_machina, "~> 2.8", only: :test},
    {:mox, "~> 1.0", only: :test}
  ]
end
```

### LiveView Tests

```elixir
defmodule MyAppWeb.UsersLiveTest do
  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import MyApp.AccountsFixtures

  describe "Index" do
    test "lists all users", %{conn: conn} do
      user = user_fixture()

      {:ok, _view, html} = live(conn, ~p"/users")

      assert html =~ user.email
    end

    test "creates user with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/new")

      view
      |> form("#user-form", user: %{email: "test@example.com", name: "Test"})
      |> render_submit()

      assert_redirect(view, ~p"/users")
    end
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
      name: Faker.Person.name(),
      inserted_at: DateTime.utc_now()
    }
  end

  def admin_factory do
    struct!(user_factory(), role: :admin)
  end
end

# Usage in tests
import MyApp.Factory

user = insert(:user)
admin = insert(:admin)
users = insert_list(3, :user)
```

### Mock External Services with Mox

```elixir
# test/support/mocks.ex
Mox.defmock(MyApp.PaymentsMock, for: MyApp.Payments.Behaviour)

# config/test.exs
config :my_app, :payments_client, MyApp.PaymentsMock

# In test
import Mox

expect(MyApp.PaymentsMock, :charge, fn _amount, _token ->
  {:ok, %{id: "ch_123", status: "succeeded"}}
end)
```

### Test Organization

```
test/
├── my_app/              # Context tests (if needed for complex logic)
├── my_app_web/
│   ├── live/
│   │   ├── users_live_test.exs
│   │   └── orders_live_test.exs
│   └── controllers/
│       └── api/
│           └── users_controller_test.exs
└── support/
    ├── factory.ex
    ├── fixtures/
    └── mocks.ex
```

## Why This Approach?

1. **No stale rules**: `usage_rules` syncs from actual dependency versions
2. **Ecosystem alignment**: Uses tools the Elixir community maintains
3. **Project-specific**: AGENTS.md and CLAUDE.md capture what's unique
4. **Composable**: Igniter lets generators call other generators intelligently
5. **Context-efficient**: Linking to deps folder keeps CLAUDE.md lean
