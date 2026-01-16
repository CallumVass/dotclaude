# TypeScript React Rules

## Mandatory Constraints

```
╔═══════════════════════════════════════════════════════════════╗
║  These rules ALWAYS apply to ALL code, regardless of what     ║
║  acceptance criteria says. AC defines WHAT to build, these    ║
║  rules define HOW to build it.                                ║
╚═══════════════════════════════════════════════════════════════╝
```

1. **No `any` types** - Use `unknown` with type guards if needed.

2. **Tailwind only** - NEVER write custom CSS, inline styles, or `<style>` blocks.

3. **Semantic tokens** - Use design system tokens (`bg-surface`, `text-foreground`, etc.), not raw Tailwind values.

4. **Tests required** - Every feature MUST include boundary tests. A feature is NOT complete without them.

5. **Only mock external I/O** - Mock third-party APIs, not your own code.

---

## Core Principles

### DRY, YAGNI, KISS

- Single source of truth for constants and configuration
- Build only what's needed for the current task
- Prefer explicit over clever
- "Duplication is far cheaper than the wrong abstraction" - Sandi Metz

### TypeScript Fundamentals

- No `any` types - use `unknown` and type guards if needed
- Prefer `type` for unions, `interface` for objects
- Use `readonly` for immutable data
- Use strict null checks - handle undefined explicitly
- Avoid type assertions (`as`) - prefer type guards

---

## Project Structure

```
src/
├── types/           # Shared type definitions
│   ├── index.ts     # Barrel export
│   ├── base.ts      # Branded IDs, utility types
│   └── [domain].ts  # Domain-specific types
├── constants/       # Const values that define types
├── utils/           # Pure utility functions
├── services/        # Business logic, API calls
├── components/      # Shared components
└── [feature]/       # Feature-specific code
```

---

## "Make Impossible States Impossible"

### Const Assertions for Domain Values

```typescript
export const STATUSES = ['pending', 'active', 'completed'] as const
export type Status = typeof STATUSES[number]

function getStatusColor(status: Status): string {
  switch (status) {
    case 'pending': return 'yellow'
    case 'active': return 'blue'
    case 'completed': return 'green'
  }
}
```

### Branded Types for IDs

```typescript
export type UserId = number & { readonly __brand: 'UserId' }
export type OrderId = number & { readonly __brand: 'OrderId' }

export const UserId = (id: number) => id as UserId
export const OrderId = (id: number) => id as OrderId
```

### Discriminated Unions

```typescript
type AppState =
  | { status: 'loading' }
  | { status: 'error'; message: string }
  | { status: 'ready'; data: Data }
```

### Result Type

```typescript
type Result<T, E = string> =
  | { success: true; data: T }
  | { success: false; error: E }
```

---

## React Component Structure

- Use function components with TypeScript
- Define props as interface/type above component
- Destructure props in function signature

```tsx
interface UserCardProps {
  user: User
  onEdit?: (user: User) => void
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <article className="bg-surface rounded border border-border p-4">
      <h2 className="text-lg font-semibold">{user.name}</h2>
      {onEdit && (
        <button
          className="bg-accent text-white rounded px-4 py-2"
          onClick={() => onEdit(user)}
        >
          Edit
        </button>
      )}
    </article>
  )
}
```

---

## Hooks Rules

- Always call hooks at the top level
- Custom hooks must start with `use`
- Extract complex logic into custom hooks

```tsx
function useUser(id: string) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchUser(id)
      .then(setUser)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false))
  }, [id])

  return { user, loading, error }
}
```

---

## State Management

| Pattern | When to Use |
|---------|------------|
| `useState` | Local component state |
| `useReducer` | Complex local state with many updates |
| `useContext` | Shared state across tree (theme, auth) |
| Zustand/Jotai | Global state with many consumers |
| React Query/SWR | Server state (caching, revalidation) |

---

## Next.js (App Router)

- Use Server Components by default
- Add `'use client'` only when needed (hooks, events)
- Use `loading.tsx` and `error.tsx` for states
- Prefer Server Actions for mutations

```tsx
// Server Component (default)
async function UserPage({ params }: { params: { id: string } }) {
  const user = await fetchUser(params.id)
  return <UserCard user={user} />
}

// Client Component
'use client'
function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

---

## Styling: Tailwind Only

```
╔═══════════════════════════════════════════════════════════════╗
║  NEVER write custom CSS, inline styles, or <style> blocks     ║
║  ALWAYS use Tailwind utility classes                          ║
║  EXTEND the config for custom values, don't hardcode          ║
╚═══════════════════════════════════════════════════════════════╝
```

### Semantic Tokens

Use semantic tokens, not raw Tailwind values:

| NEVER | INSTEAD |
|-------|---------|
| `className="text-gray-500"` | `className="text-foreground-muted"` |
| `className="bg-white"` | `className="bg-surface"` |
| `className="border-gray-200"` | `className="border-border"` |
| `style={{ color: '#64748b' }}` | `className="text-foreground-muted"` |

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

## Accessibility

- Use semantic HTML (`button`, `nav`, `article`, etc.)
- Add `aria-label` for icon-only buttons
- Ensure keyboard navigation works

```tsx
<button aria-label="Close dialog" onClick={onClose}>
  <XIcon />
</button>
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

### API Integration Tests

```typescript
import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { faker } from '@faker-js/faker'
import { app } from '~/app'

describe('Users API', () => {
  it('GET /users returns all users', async () => {
    const response = await request(app).get('/api/users')
    expect(response.status).toBe(200)
  })

  it('POST /users creates user', async () => {
    const userData = {
      email: faker.internet.email(),
      name: faker.person.fullName(),
    }
    const response = await request(app).post('/api/users').send(userData)
    expect(response.status).toBe(201)
  })
})
```

### Mock External APIs with MSW

```typescript
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'

const server = setupServer(
  http.post('https://api.stripe.com/v1/charges', () => {
    return HttpResponse.json({ id: 'ch_123', status: 'succeeded' })
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Mocking Rules

```
ONLY mock external I/O:
  - Third-party APIs (payment, email, SMS)
  - File system, network, time

NEVER mock your own code:
  - Services, repositories, validators
```
