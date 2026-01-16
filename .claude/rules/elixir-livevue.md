# Elixir Phoenix + LiveVue Rules

## Mandatory Constraints

```
╔═══════════════════════════════════════════════════════════════╗
║  These rules ALWAYS apply to ALL code, regardless of what     ║
║  acceptance criteria says. AC defines WHAT to build, these    ║
║  rules define HOW to build it.                                ║
╚═══════════════════════════════════════════════════════════════╝
```

1. **All UI is Vue components** - NEVER use Phoenix function components (`<.input>`, `<.button>`, `<.form>`, `<.header>`, `<.table>`, etc.). LiveViews render Vue via `<.vue>`.

2. **Tailwind only** - NEVER write custom CSS, inline styles, or `<style>` blocks in Vue components.

3. **Semantic tokens** - Use design system tokens (`bg-surface`, `text-foreground`, etc.), not raw Tailwind values.

4. **Tests required** - Every feature MUST include boundary tests (LiveView). A feature is NOT complete without them.

5. **Only mock external I/O** - Use Mox for third-party APIs, not your own contexts.

---

## First-Time Setup

### Check for AGENTS.md

Phoenix 1.8+ generates an `AGENTS.md` file with project-specific guidance. If it exists, read it and follow its conventions.

---

## Core Principles

### Elixir Fundamentals

- Prefer immutability and pure functions
- Use pattern matching extensively
- Let processes crash and supervise them
- Prefer pipelines for data transformation

### Vue Fundamentals

- Use `<script setup lang="ts">` for all components
- Define props with `defineProps<{}>()` TypeScript syntax
- Keep components focused - one responsibility per component

---

## LiveVue Pattern

LiveViews handle state and events, Vue handles rendering:

```elixir
defmodule MyAppWeb.UsersLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.vue
      v-component="UserList"
      users={@users}
      v-on:delete="handle_delete"
    />
    """
  end

  def handle_event("handle_delete", %{"id" => id}, socket) do
    Users.delete(id)
    {:noreply, assign(socket, :users, Users.list())}
  end
end
```

```vue
<!-- assets/vue/UserList.vue -->
<script setup lang="ts">
interface Props {
  users: User[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  delete: [id: string]
}>()
</script>

<template>
  <ul class="space-y-2">
    <li
      v-for="user in users"
      :key="user.id"
      class="bg-surface border border-border rounded p-4 flex justify-between"
    >
      <span class="text-foreground">{{ user.name }}</span>
      <button
        class="text-error hover:text-error/80"
        @click="emit('delete', user.id)"
      >
        Delete
      </button>
    </li>
  </ul>
</template>
```

---

## Styling: Tailwind + Semantic Tokens

```
╔═══════════════════════════════════════════════════════════════╗
║  NEVER write custom CSS, inline styles, or <style> blocks     ║
║  ALWAYS use Tailwind utility classes                          ║
║  ALWAYS use semantic tokens, not raw Tailwind values          ║
╚═══════════════════════════════════════════════════════════════╝
```

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

### LiveView Tests

Test at the LiveView boundary - Vue components are tested through LiveView interaction:

```elixir
defmodule MyAppWeb.UsersLiveTest do
  use MyAppWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "lists all users", %{conn: conn} do
    user = user_fixture()
    {:ok, _view, html} = live(conn, ~p"/users")
    assert html =~ user.name
  end

  test "deletes user", %{conn: conn} do
    user = user_fixture()
    {:ok, view, _html} = live(conn, ~p"/users")

    view
    |> element("button", "Delete")
    |> render_click()

    refute render(view) =~ user.name
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

### Mocking Rules

```
ONLY mock external I/O:
  - Third-party APIs (payment, email, SMS)
  - HTTP clients, external services

NEVER mock your own code:
  - Contexts, schemas, internal modules
  - If you're mocking it, you're testing implementation not behavior
```
