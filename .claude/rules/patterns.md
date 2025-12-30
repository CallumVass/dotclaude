# Architecture Patterns

Universal patterns applicable across all tech stacks.

## Guiding Principles

### DRY (Don't Repeat Yourself)

- Single source of truth for constants and configuration
- Derive types/schemas from data, not the other way around
- Extract repeated logic into shared utilities

### YAGNI (You Aren't Gonna Need It)

- Build only what's needed for the current task
- Avoid premature abstractions
- Add complexity only when proven necessary

### KISS (Keep It Simple, Stupid)

- Prefer explicit over clever
- Flat is better than nested
- If a function needs extensive comments, it's too complex

### Balancing These Principles

These principles exist in tension - dogmatic application of one can violate another:

- Aggressive DRY can create complex abstractions that violate KISS
- "Duplication is far cheaper than the wrong abstraction" - Sandi Metz
- When in doubt, prefer simple duplicated code over a premature abstraction

---

## Layer Architecture

```
┌─────────────────────────────────────┐
│            PRESENTATION             │
│  UI Components / Views / Pages      │
│  - Render UI, handle user input     │
│  - Call application layer           │
│  - Use presentation utilities       │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│            APPLICATION              │
│  State Management / Services        │
│  - Reactive state (if applicable)   │
│  - Business logic orchestration     │
│  - Coordinate domain + persistence  │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│              DOMAIN                 │
│  Core Business Logic / Models       │
│  - Pure functions preferred         │
│  - No side effects where possible   │
│  - Deterministic behavior           │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│           PERSISTENCE               │
│  Database / External APIs           │
│  - CRUD operations only             │
│  - No business logic                │
└─────────────────────────────────────┘
```

---

## Result Type Pattern

For operations that can fail, use explicit Result types instead of throwing/raising:

**TypeScript:**
```typescript
type Result<T, E = string> =
  | { success: true; data: T }
  | { success: false; error: E }
```

**C#:**
```csharp
public record Result<T>
{
    public bool Success { get; init; }
    public T? Data { get; init; }
    public string? Error { get; init; }

    public static Result<T> Ok(T data) => new() { Success = true, Data = data };
    public static Result<T> Fail(string error) => new() { Success = false, Error = error };
}
```

**F#:**
```fsharp
type Result<'T, 'E> = Ok of 'T | Error of 'E
// Built-in! Use it.
```

**Elixir:**
```elixir
# Use {:ok, data} | {:error, reason} tuples - it's idiomatic!
{:ok, user} = Users.get(id)
{:error, :not_found} = Users.get(invalid_id)
```

---

## Discriminated Unions / Tagged Unions

Use these for type-safe handling of variant data:

**TypeScript:**
```typescript
type Event =
  | { type: 'user_created'; userId: string }
  | { type: 'order_placed'; orderId: string; amount: number }
  | { type: 'payment_failed'; reason: string }
```

**F#:**
```fsharp
type Event =
    | UserCreated of userId: string
    | OrderPlaced of orderId: string * amount: decimal
    | PaymentFailed of reason: string
```

**Elixir:**
```elixir
# Use tagged tuples or structs with type field
defmodule Event do
  defstruct [:type, :payload]
end

# Or pattern match on tuple shapes
{:user_created, user_id}
{:order_placed, order_id, amount}
```

---

## Constants Define Types

Define domain values as constants, derive types from them:

**TypeScript:**
```typescript
export const ROLES = ['admin', 'user', 'guest'] as const
export type Role = typeof ROLES[number]
```

**C#:**
```csharp
public enum Role { Admin, User, Guest }
```

**F#:**
```fsharp
type Role = Admin | User | Guest
```

**Elixir:**
```elixir
@roles [:admin, :user, :guest]
def valid_role?(role), do: role in @roles
```

---

## Testing Patterns

### Core Philosophy: Boundary Testing

Test at the boundaries where users interact with your system - APIs, Views, LiveViews. Use real implementations internally, only mocking external services.

```
┌─────────────────────────────────────────────────────────┐
│                    TEST BOUNDARY                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │  HTTP Request / View Render                       │  │
│  │         ↓                                         │  │
│  │  Controller / LiveView                            │  │
│  │         ↓                                         │  │
│  │  Service Layer            ← All real              │  │
│  │         ↓                   implementations       │  │
│  │  Repository / Context                             │  │
│  │         ↓                                         │  │
│  └───────────────────────────────────────────────────┘  │
│                       ↓                                 │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Database / External APIs   ← Mock/fake here only │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Why this approach:**
- Tests don't break when you refactor internals
- Tests verify actual user-facing behavior
- Less mocking = less test maintenance
- Higher confidence the system actually works

### What to Test

| Boundary | What to Test | Mock Only |
|----------|--------------|-----------|
| API endpoints | HTTP request → response | Database, external APIs |
| Views/Pages | User interactions, renders | Database, external APIs |
| LiveViews | Real-time updates, events | Database, external APIs |
| CLI commands | Input → output | File system, network |

### What NOT to Test Separately

Don't create isolated unit tests for internal collaborators:

```
# Don't test these in isolation:
UserService        ← tested via API endpoint
UserRepository     ← tested via API endpoint
UserValidator      ← tested via API endpoint

# Do test at the boundary:
GET /users         ← tests the full vertical slice
```

### Test Data: Use Generators

Don't hand-craft test data. Use generators/factories:

| Stack | Library | Purpose |
|-------|---------|---------|
| .NET | AutoFixture, Bogus | Generate realistic test data |
| TypeScript | @faker-js/faker | Generate realistic test data |
| Elixir | ExMachina | Factory-based test data |

### Test Structure (Arrange-Act-Assert)

```
Arrange: Set up test data (via factories), configure test server
Act:     Make HTTP request / render view / trigger event
Assert:  Verify response status, body, side effects
```

### When to Mock

**Only mock external I/O:**
- Database connections (or use in-memory/container)
- Third-party APIs (payment, email, SMS)
- File system, network, time

**Never mock your own code:**
- Services, repositories, validators
- If you're mocking it, you're testing implementation not behavior

---

## Code Organization

Prefer feature-based over layer-based organization:

```
# Feature-based (preferred)
features/
  users/
    components/
    services/
    types/
  orders/
    components/
    services/
    types/

# Over layer-based
components/
  UserCard.vue
  OrderList.vue
services/
  UserService.ts
  OrderService.ts
```
