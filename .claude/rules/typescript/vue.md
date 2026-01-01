---
paths: ["**/*.vue", "**/nuxt.config.ts", "**/vite.config.ts"]
---

# Vue/Nuxt Rules

Applies to Vue 3 projects with Composition API.

## Script Setup

- Use `<script setup lang="ts">` for all components
- Define props with `defineProps<{}>()` TypeScript syntax
- Define emits with `defineEmits<{}>()` TypeScript syntax
- Extract complex logic into composables
- Keep template expressions simple

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

### When to Use Each

**Composables** (`composables/`):
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

**Stores** (`stores/`):
```typescript
export const useUserStore = defineStore('user', () => {
  const currentUser = ref<User | null>(null)
  const isAuthenticated = computed(() => !!currentUser.value)

  async function login(credentials: Credentials) { /* ... */ }
  async function logout() { /* ... */ }

  return { currentUser, isAuthenticated, login, logout }
})
```

**Services** (`services/`):
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
  <article class="user-card">
    <header>
      <h2>{{ user.name }}</h2>
    </header>
    <ul>
      <li v-for="item in items" :key="item.id">
        {{ item.label }}
      </li>
    </ul>
    <button
      v-if="canEdit"
      aria-label="Edit user profile"
      @click="emit('edit')"
    >
      Edit
    </button>
  </article>
</template>
```

---

## Styling

Prefer utility-first CSS (Tailwind, UnoCSS) over scoped styles:

```vue
<!-- Good -->
<template>
  <div class="p-4 bg-gray-100 rounded-lg">
    <h1 class="text-xl font-bold mb-2">{{ title }}</h1>
  </div>
</template>
```

---

## Nuxt-Specific

When using Nuxt:

- Use `useState` for SSR-safe shared state
- Use `useFetch`/`useAsyncData` for data fetching
- Prefer auto-imports (components, composables, utils)
- Use `~/` alias for imports from project root
