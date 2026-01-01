# Architecture Patterns

Universal patterns applicable across all tech stacks.

---

## Core Principles

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

These principles exist in tension - dogmatic application of one violates another:

- Aggressive DRY creates complex abstractions that violate KISS
- "Duplication is far cheaper than the wrong abstraction" - Sandi Metz
- When in doubt: simple duplicated code > premature abstraction

---

## Layer Architecture

```
┌─────────────────────────────────────┐
│            PRESENTATION             │
│  UI Components / Views / Pages      │
│  - Render UI, handle user input     │
│  - Call application layer           │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│            APPLICATION              │
│  State Management / Services        │
│  - Business logic orchestration     │
│  - Coordinate domain + persistence  │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│              DOMAIN                 │
│  Core Business Logic / Models       │
│  - Pure functions preferred         │
│  - No side effects where possible   │
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

For operations that can fail, use explicit Result types instead of throwing:

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
    public bool IsSuccess { get; init; }
    public T? Value { get; init; }
    public string? Error { get; init; }

    public static Result<T> Success(T value) => new() { IsSuccess = true, Value = value };
    public static Result<T> Failure(string error) => new() { IsSuccess = false, Error = error };
}
```

**F#:**
```fsharp
type Result<'T, 'E> = Ok of 'T | Error of 'E  // Built-in!
```

**Elixir:**
```elixir
{:ok, user} = Users.get(id)
{:error, :not_found} = Users.get(invalid_id)
```

---

## Discriminated Unions / Tagged Unions

Type-safe handling of variant data:

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

---

## Testing Requirements

### The Rule

```
╔═══════════════════════════════════════════════════════════════╗
║  EVERY feature implementation MUST include tests.             ║
║  A feature is NOT complete without them.                      ║
║  This is enforced by the tests_before_review gate.            ║
╚═══════════════════════════════════════════════════════════════╝
```

### What Must Be Tested

```
REQUIRE test_for_boundary:
  
  | When you change...        | You MUST test...              |
  |---------------------------|-------------------------------|
  | API endpoint / Controller | Request → response behavior   |
  | View / Page / LiveView    | User interactions, renders    |
  | Context module            | New public functions          |
  | CLI command               | Input → output behavior       |

VALID justification for no tests:
  - "Changed private helper, covered by existing test at [path]"
  - "Configuration-only change, no behavior to test"

INVALID justification:
  - "It's a small change"
  - "It's obvious it works"
  - "I tested it manually"
```

### Boundary Testing Philosophy

Test at boundaries where users interact - APIs, Views, LiveViews. Use real implementations internally, only mock external services.

```
┌─────────────────────────────────────────────────────────────┐
│                    TEST BOUNDARY                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  HTTP Request / View Render                           │  │
│  │         ↓                                             │  │
│  │  Controller / LiveView                                │  │
│  │         ↓                                             │  │
│  │  Service Layer            ← All REAL implementations  │  │
│  │         ↓                                             │  │
│  │  Repository / Context                                 │  │
│  └───────────────────────────────────────────────────────┘  │
│                       ↓                                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Database / External APIs   ← Mock ONLY here          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Why this approach:**
- Tests don't break when you refactor internals
- Tests verify actual user-facing behavior
- Less mocking = less test maintenance
- Higher confidence the system works

### What NOT to Test Separately

```
DO NOT create isolated unit tests for internal collaborators:

  UserService      ← tested via API endpoint
  UserRepository   ← tested via API endpoint  
  UserValidator    ← tested via API endpoint

DO test at the boundary:

  GET /users       ← tests the full vertical slice
```

### Mocking Rules

```
ONLY mock external I/O:
  - Database connections (or use in-memory/container)
  - Third-party APIs (payment, email, SMS)
  - File system, network, time

NEVER mock your own code:
  - Services, repositories, validators
  - If you're mocking it, you're testing implementation not behavior
```

### Test Data

```
REQUIRE generated test data:
  
  | Stack      | Library              |
  |------------|----------------------|
  | .NET       | AutoFixture, Bogus   |
  | TypeScript | @faker-js/faker      |
  | Elixir     | ExMachina            |

DO NOT hand-craft test data - use factories/generators
```

### Test Structure

```
Arrange: Set up test data (via factories), configure test server
Act:     Make HTTP request / render view / trigger event  
Assert:  Verify response status, body, side effects
```

---

## Code Organization

```
PREFER feature-based over layer-based:

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

  # Layer-based (avoid)
  components/
    UserCard.vue
    OrderList.vue
  services/
    UserService.ts
    OrderService.ts
```
