# .NET F# Rules

## Mandatory Constraints

```
╔═══════════════════════════════════════════════════════════════╗
║  These rules ALWAYS apply to ALL code, regardless of what     ║
║  acceptance criteria says. AC defines WHAT to build, these    ║
║  rules define HOW to build it.                                ║
╚═══════════════════════════════════════════════════════════════╝
```

1. **No nulls** - Use `Option` for missing values. Leverage the type system.

2. **Tests required** - Every feature MUST include boundary tests. A feature is NOT complete without them.

3. **Only mock external I/O** - Mock third-party APIs, not your own modules.

---

## Core Principles

- Prefer immutability by default
- Use discriminated unions for domain modeling
- Leverage the type system to prevent invalid states
- Compose small functions into larger ones
- Prefer explicit over implicit (no nulls, use Option)

### Layer Architecture

```
┌─────────────────────────────────────┐
│            PRESENTATION             │
│  API Controllers / UI               │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│            APPLICATION              │
│  Services / Use Cases               │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│              DOMAIN                 │
│  Types / Business Logic             │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│           PERSISTENCE               │
│  Database / External APIs           │
└─────────────────────────────────────┘
```

---

## Project Structure

```
src/
├── [ProjectName].sln
├── [ProjectName]/              # Main application
│   ├── [ProjectName].fsproj
│   ├── Program.fs
│   ├── Domain.fs               # Types, discriminated unions
│   ├── Application.fs          # Use cases, workflows
│   └── Infrastructure.fs       # External concerns
├── [ProjectName].Tests/        # Test project
└── [ProjectName].Shared/       # Shared types (optional)
```

---

## Discriminated Unions

```fsharp
type OrderStatus =
    | Pending
    | Confirmed of confirmedAt: DateTime
    | Shipped of trackingNumber: string * shippedAt: DateTime
    | Delivered of deliveredAt: DateTime
    | Cancelled of reason: string
```

---

## Single-Case Unions for Type Safety

```fsharp
type UserId = UserId of int
type OrderId = OrderId of int
type Email = Email of string

// Now these won't mix!
let getUser (UserId id) = // ...
let getOrder (OrderId id) = // ...
```

---

## Result Type

```fsharp
type UserError =
    | NotFound
    | ValidationFailed of errors: string list

let getUser (UserId id) : Result<User, UserError> =
    if id < 1 then Error (ValidationFailed ["Invalid ID"])
    else
        match findInDb id with
        | Some user -> Ok user
        | None -> Error NotFound

// Railway-oriented programming
let result =
    getUser (UserId 1)
    |> Result.bind validateUser
    |> Result.map transformToDto
```

---

## Option for Missing Values

```fsharp
type User = {
    Name: string
    Nickname: string option
}

let getDisplayName user =
    user.Nickname |> Option.defaultValue user.Name
```

---

## Pipe Operator

```fsharp
let processUsers users =
    users
    |> Seq.filter (fun u -> u.IsActive)
    |> Seq.sortBy (fun u -> u.Name)
    |> Seq.map toDto
    |> Seq.toList
```

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

Test at API boundaries. Use real implementations internally, only mock external services.

### Testing with Expecto

```fsharp
open Expecto

let userTests = testList "User" [
    test "create sets correct email" {
        let user = User.create (Email "test@example.com") "Test"
        Expect.equal user.Email (Email "test@example.com") "Email should match"
    }
]
```

### Mocking Rules

```
ONLY mock external I/O:
  - Third-party APIs (payment, email, SMS)
  - File system, network, time

NEVER mock your own code:
  - If you're mocking it, you're testing implementation not behavior
```
