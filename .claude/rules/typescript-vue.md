# TypeScript Vue Rules

## Mandatory Constraints

```
╔═══════════════════════════════════════════════════════════════╗
║  These rules ALWAYS apply to ALL code, regardless of what     ║
║  acceptance criteria says. AC defines WHAT to build, these    ║
║  rules define HOW to build it.                                ║
╚═══════════════════════════════════════════════════════════════╝
```

1. **No `any` types** - Use `unknown` with type guards if needed.

2. **Tailwind/UnoCSS only** - NEVER write custom CSS, inline styles, or `<style>` blocks.

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
├── constants/       # Const values that define types
├── utils/           # Pure utility functions
├── composables/     # Reusable composition functions
├── stores/          # Pinia stores
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
```

### Branded Types for IDs

```typescript
export type UserId = number & { readonly __brand: 'UserId' }
export type OrderId = number & { readonly __brand: 'OrderId' }
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

## Script Setup

Use `<script setup lang="ts">` for all components:

```vue
<script setup lang="ts">
interface Props {
  title: string
  count?: number
}

const props = withDefaults(defineProps<Props>(), {
  count: 0,
})

const emit = defineEmits<{
  update: [value: number]
}>()
</script>
```

---

## Composables vs Stores vs Services

| Layer | Purpose | Statefulness | Example |
|-------|---------|--------------|---------|
| **Composable** | Reusable UI logic | Stateless or local | `useFormatDate()` |
| **Store** | Shared reactive state | Stateful, reactive | `useUserStore` |
| **Service** | Business operations | Stateless | `AuthService` |

### Composables

```typescript
// Stateless utility
export function useFormatCurrency() {
  const format = (amount: number) => `$${amount.toLocaleString()}`
  return { format }
}

// Local reactive state
export function useSearch() {
  const query = ref('')
  const results = computed(() => /* ... */)
  return { query, results }
}
```

### Stores

```typescript
export const useUserStore = defineStore('user', () => {
  const currentUser = ref<User | null>(null)
  const isAuthenticated = computed(() => !!currentUser.value)

  async function login(credentials: Credentials) { /* ... */ }
  async function logout() { /* ... */ }

  return { currentUser, isAuthenticated, login, logout }
})
```

### Services

```typescript
export const AuthService = {
  async login(email: string, password: string): Promise<Result<User>> {
    const response = await api.post('/auth/login', { email, password })
    return { success: true, data: response.data }
  }
}
```

---

## Template Rules

- Keep components focused - one responsibility per component
- Use semantic HTML elements
- Add aria labels for accessibility
- Prefer `v-if` over `v-show` unless toggling frequently
- Use `key` attribute with `v-for`

```vue
<template>
  <article class="bg-surface rounded border border-border p-4">
    <header>
      <h2 class="text-lg font-semibold">{{ user.name }}</h2>
    </header>
    <ul class="space-y-2">
      <li v-for="item in items" :key="item.id">
        {{ item.label }}
      </li>
    </ul>
    <button
      v-if="canEdit"
      aria-label="Edit user profile"
      class="bg-accent text-white rounded px-4 py-2"
      @click="emit('edit')"
    >
      Edit
    </button>
  </article>
</template>
```

---

## Nuxt-Specific

- Use `useState` for SSR-safe shared state
- Use `useFetch`/`useAsyncData` for data fetching
- Prefer auto-imports (components, composables, utils)
- Use `~/` alias for imports from project root

---

## Styling: Tailwind/UnoCSS Only

```
╔═══════════════════════════════════════════════════════════════╗
║  NEVER write custom CSS, inline styles, or <style> blocks     ║
║  ALWAYS use Tailwind/UnoCSS utility classes                   ║
║  EXTEND the config for custom values, don't hardcode          ║
╚═══════════════════════════════════════════════════════════════╝
```

### Semantic Tokens

Use semantic tokens, not raw Tailwind values:

| NEVER | INSTEAD |
|-------|---------|
| `class="text-gray-500"` | `class="text-foreground-muted"` |
| `class="bg-white"` | `class="bg-surface"` |
| `class="border-gray-200"` | `class="border-border"` |
| `:style="{ color: '#64748b' }"` | `class="text-foreground-muted"` |

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

### Component Tests

Test components at the boundary - mount, interact, assert:

```typescript
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import UserCard from './UserCard.vue'

describe('UserCard', () => {
  it('renders user name', () => {
    const wrapper = mount(UserCard, {
      props: { user: { name: 'John Doe' } }
    })
    expect(wrapper.text()).toContain('John Doe')
  })

  it('emits edit event on button click', async () => {
    const wrapper = mount(UserCard, {
      props: { user: { name: 'John' }, canEdit: true }
    })
    await wrapper.find('button').trigger('click')
    expect(wrapper.emitted('edit')).toBeTruthy()
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
  - Services, composables, stores
```
