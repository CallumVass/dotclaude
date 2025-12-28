# TypeScript Core Rules

## Activation

These rules apply when working with TypeScript projects. Enable by adding to project's `.claude/settings.local.json`:

```json
{
  "rules": {
    "include": [".claude/rules/typescript/core.md"]
  }
}
```

---

## Core Principles

- No `any` types - use `unknown` and type guards if needed
- Prefer `type` for unions, `interface` for objects
- Use `readonly` for immutable data
- Use strict null checks - handle undefined explicitly
- Avoid type assertions (`as`) - prefer type guards
- Use generics for reusable utility types

---

## "Make Impossible States Impossible"

### Const Assertions for Domain Values

Define domain values as const arrays, derive types from them:

```typescript
// Single source of truth - type derived from data
export const STATUSES = ['pending', 'active', 'completed'] as const
export type Status = typeof STATUSES[number]

// Exhaustive - compiler ensures all cases handled
function getStatusColor(status: Status): string {
  switch (status) {
    case 'pending': return 'yellow'
    case 'active': return 'blue'
    case 'completed': return 'green'
  } // No default needed - TypeScript knows this is exhaustive
}
```

### Branded Types for IDs

Prevent accidental ID mixing:

```typescript
export type UserId = number & { readonly __brand: 'UserId' }
export type OrderId = number & { readonly __brand: 'OrderId' }

// Helper to create branded IDs
export const UserId = (id: number) => id as UserId
export const OrderId = (id: number) => id as OrderId

// Type-safe
function getUser(id: UserId): User { /* ... */ }
getUser(userId)  // Works
getUser(orderId) // Error: OrderId not assignable to UserId
```

### Discriminated Unions for Events/States

```typescript
type AppState =
  | { status: 'loading' }
  | { status: 'error'; message: string }
  | { status: 'ready'; data: Data }

// Impossible to have 'ready' without data
// Impossible to have 'error' without message
```

### The `satisfies` Operator

Validate object structure while preserving literal types:

```typescript
const CONFIG = {
  api: 'https://api.example.com',
  timeout: 5000,
} as const satisfies Record<string, string | number>

// TypeScript knows CONFIG.api is exactly 'https://api.example.com'
```

### Exhaustive Checks with `never`

```typescript
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${x}`)
}

function handleStatus(status: Status) {
  switch (status) {
    case 'pending': return 'Waiting...'
    case 'active': return 'In progress'
    case 'completed': return 'Done!'
    default: return assertNever(status) // Compile error if case missing
  }
}
```

---

## Project Structure

```
src/
├── types/           # Shared type definitions
│   ├── index.ts     # Barrel export
│   ├── base.ts      # Branded IDs, utility types
│   └── [domain].ts  # Domain-specific types
├── constants/       # Const values that define types
│   └── index.ts
├── utils/           # Pure utility functions
├── services/        # Business logic, API calls
└── [feature]/       # Feature-specific code
```

---

## Imports

- Use absolute imports with path aliases (`~/`, `@/`)
- Barrel exports for public APIs (`index.ts`)
- Avoid circular dependencies

```typescript
// Good
import { User } from '~/types'
import { formatDate } from '~/utils'

// Avoid
import { User } from '../../../types/user'
```

---

## Async/Await

- Always handle errors explicitly
- Use Result types for expected failures
- Use try/catch only for unexpected errors

```typescript
// For expected failures
async function fetchUser(id: UserId): Promise<Result<User, 'not_found' | 'network_error'>> {
  try {
    const response = await api.get(`/users/${id}`)
    if (response.status === 404) {
      return { success: false, error: 'not_found' }
    }
    return { success: true, data: response.data }
  } catch {
    return { success: false, error: 'network_error' }
  }
}
```
