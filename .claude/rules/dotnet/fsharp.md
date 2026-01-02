---
paths: ["**/*.fs", "**/*.fsx", "**/*.fsproj"]
---

# F# Specific Rules

## Core Principles

- Prefer immutability by default
- Use discriminated unions for domain modeling
- Leverage the type system to prevent invalid states
- Compose small functions into larger ones
- Prefer explicit over implicit (no nulls, use Option)

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

## Testing with Expecto

```fsharp
open Expecto

let userTests = testList "User" [
    test "create sets correct email" {
        let user = User.create (Email "test@example.com") "Test"
        Expect.equal user.Email (Email "test@example.com") "Email should match"
    }
]
```
