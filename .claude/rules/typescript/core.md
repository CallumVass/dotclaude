# TypeScript Core Rules

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

---

## Testing

Test at API boundaries using Supertest. Use real services - only mock external APIs with MSW.

### Dependencies

```json
{
  "devDependencies": {
    "vitest": "^2.0.0",
    "supertest": "^7.0.0",
    "@faker-js/faker": "^9.0.0",
    "msw": "^2.0.0"
  }
}
```

### API Integration Tests

```typescript
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import request from 'supertest'
import { faker } from '@faker-js/faker'
import { app } from '~/app'
import { db } from '~/db'

describe('Users API', () => {
  beforeAll(async () => {
    await db.migrate.latest()
  })

  afterAll(async () => {
    await db.destroy()
  })

  it('GET /users returns all users', async () => {
    // Arrange
    await seedUsers(3)

    // Act
    const response = await request(app).get('/api/users')

    // Assert
    expect(response.status).toBe(200)
    expect(response.body).toHaveLength(3)
  })

  it('POST /users creates user with valid data', async () => {
    // Arrange
    const userData = {
      email: faker.internet.email(),
      name: faker.person.fullName(),
    }

    // Act
    const response = await request(app)
      .post('/api/users')
      .send(userData)

    // Assert
    expect(response.status).toBe(201)
    expect(response.body.email).toBe(userData.email)
  })

  it('POST /users rejects invalid email', async () => {
    // Arrange
    const userData = { email: 'not-an-email', name: 'Test' }

    // Act
    const response = await request(app)
      .post('/api/users')
      .send(userData)

    // Assert
    expect(response.status).toBe(400)
  })
})
```

### Test Data with Faker

```typescript
import { faker } from '@faker-js/faker'

function createUser(overrides?: Partial<User>): User {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    createdAt: faker.date.past(),
    ...overrides,
  }
}

// Usage
const users = Array.from({ length: 10 }, () => createUser())
const admin = createUser({ role: 'admin' })
```

### Mock External APIs with MSW

```typescript
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'

const server = setupServer(
  // Mock Stripe API
  http.post('https://api.stripe.com/v1/charges', () => {
    return HttpResponse.json({ id: 'ch_123', status: 'succeeded' })
  }),

  // Mock email service
  http.post('https://api.sendgrid.com/v3/mail/send', () => {
    return new HttpResponse(null, { status: 202 })
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Test Organization

```
src/
├── api/
│   └── users/
│       └── route.ts
└── __tests__/
    ├── api/
    │   ├── users.test.ts
    │   └── orders.test.ts
    ├── factories/
    │   └── user.ts
    └── mocks/
        └── handlers.ts
```
