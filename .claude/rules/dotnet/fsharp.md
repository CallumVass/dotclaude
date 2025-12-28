---
paths: ["**/*.fs", "**/*.fsx", "**/*.fsproj"]
---

# F# Specific Rules

Applies to F# files in .NET projects.

## Core Principles

- Prefer immutability by default
- Use discriminated unions for domain modeling
- Leverage the type system to prevent invalid states
- Compose small functions into larger ones
- Prefer explicit over implicit (no nulls, use Option)

---

## Type System

### Discriminated Unions

Model domain with explicit states:

```fsharp
type OrderStatus =
    | Pending
    | Confirmed of confirmedAt: DateTime
    | Shipped of trackingNumber: string * shippedAt: DateTime
    | Delivered of deliveredAt: DateTime
    | Cancelled of reason: string

// Handle exhaustively
let getStatusMessage status =
    match status with
    | Pending -> "Order is pending"
    | Confirmed date -> $"Confirmed on {date}"
    | Shipped (tracking, date) -> $"Shipped: {tracking} on {date}"
    | Delivered date -> $"Delivered on {date}"
    | Cancelled reason -> $"Cancelled: {reason}"
```

### Single-Case Unions for Type Safety

Wrap primitives to prevent mixing:

```fsharp
type UserId = UserId of int
type OrderId = OrderId of int
type Email = Email of string

// Now these won't mix!
let getUser (UserId id) = // ...
let getOrder (OrderId id) = // ...

// Create with validation
module Email =
    let create (value: string) =
        if value.Contains("@")
        then Some (Email value)
        else None
```

### Records for Data

```fsharp
type User = {
    Id: UserId
    Email: Email
    Name: string
    CreatedAt: DateTime
}

// With default values
let defaultUser = {
    Id = UserId 0
    Email = Email "default@example.com"
    Name = "Default"
    CreatedAt = DateTime.UtcNow
}

// Update with copy
let updatedUser = { existingUser with Name = "New Name" }
```

---

## Result Type

Use built-in Result for error handling:

```fsharp
type UserError =
    | NotFound
    | ValidationFailed of errors: string list
    | DatabaseError of message: string

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

Never use null, use Option:

```fsharp
type User = {
    Name: string
    Nickname: string option  // Explicit nullable
}

// Handle Option explicitly
let getDisplayName user =
    user.Nickname
    |> Option.defaultValue user.Name

// Pattern matching
match user.Nickname with
| Some nick -> $"Hey {nick}!"
| None -> $"Hello {user.Name}"
```

---

## Composition

### Pipe Operator

```fsharp
// Left to right data flow
let processUsers users =
    users
    |> Seq.filter (fun u -> u.IsActive)
    |> Seq.sortBy (fun u -> u.Name)
    |> Seq.map toDto
    |> Seq.toList
```

### Function Composition

```fsharp
let validate = validateEmail >> validateName >> validateAge
let process = fetchUser >> validate >> save

// Equivalent to:
let process' user =
    user |> fetchUser |> validate |> save
```

---

## Async Workflows

Use `Async` or `task` CE:

```fsharp
// Async (F# native)
let getUserAsync id = async {
    let! user = db.Users.FindAsync(id) |> Async.AwaitTask
    return user
}

// Task (for interop with C#)
let getUserTask id = task {
    let! user = db.Users.FindAsync(id)
    return user
}

// Parallel execution
let! results =
    [1; 2; 3]
    |> List.map getUserAsync
    |> Async.Parallel
```

---

## Module Organization

```fsharp
// Domain.fs
module Domain

type UserId = UserId of int
type Email = Email of string

type User = {
    Id: UserId
    Email: Email
    Name: string
}

// Operations in submodule
module User =
    let create email name =
        { Id = UserId 0; Email = email; Name = name }

    let updateName name user =
        { user with Name = name }
```

---

## ASP.NET Integration

### Minimal API with F#

```fsharp
open Microsoft.AspNetCore.Builder

let configureApp (app: WebApplication) =
    app.MapGet("/users/{id}", Func<int, IUserService, Task<IResult>>(fun id service ->
        task {
            match! service.GetUserAsync(UserId id) with
            | Ok user -> return Results.Ok(user)
            | Error NotFound -> return Results.NotFound()
            | Error (ValidationFailed errors) -> return Results.BadRequest(errors)
        }
    )) |> ignore

    app
```

### Giraffe (F#-first web framework)

```fsharp
open Giraffe

let getUserHandler (id: int) : HttpHandler =
    fun next ctx -> task {
        match! userService.GetUser(UserId id) with
        | Ok user -> return! json user next ctx
        | Error NotFound -> return! RequestErrors.NOT_FOUND "User not found" next ctx
    }

let webApp =
    choose [
        GET >=> route "/users" >=> getAllUsersHandler
        GET >=> routef "/users/%i" getUserHandler
        POST >=> route "/users" >=> createUserHandler
    ]
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

    testAsync "getUserAsync returns user when exists" {
        let! result = userService.GetUserAsync(UserId 1)
        match result with
        | Ok user -> Expect.equal user.Name "Expected Name" "Name should match"
        | Error _ -> failtest "Expected Ok but got Error"
    }
]
```
