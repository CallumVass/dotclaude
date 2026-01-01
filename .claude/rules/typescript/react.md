---
paths: ["**/*.tsx", "**/*.jsx", "**/next.config.*"]
---

# React/Next.js Rules

Applies to React projects with TypeScript.

## Component Structure

- Use function components with TypeScript
- Define props as interface/type above component
- Destructure props in function signature
- Export component as default or named consistently

```tsx
interface UserCardProps {
  user: User
  onEdit?: (user: User) => void
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <article className="p-4 border rounded">
      <h2>{user.name}</h2>
      {onEdit && (
        <button onClick={() => onEdit(user)}>Edit</button>
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
- Memoize expensive computations

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

## Next.js Specific

### App Router (Next.js 13+)

- Use Server Components by default
- Add `'use client'` only when needed (hooks, events)
- Use `loading.tsx` and `error.tsx` for states
- Prefer Server Actions for mutations

```tsx
// Server Component (default)
async function UserPage({ params }: { params: { id: string } }) {
  const user = await fetchUser(params.id) // Runs on server
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

## Accessibility

- Use semantic HTML (`button`, `nav`, `article`, etc.)
- Add `aria-label` for icon-only buttons
- Ensure keyboard navigation works

```tsx
<button
  aria-label="Close dialog"
  onClick={onClose}
>
  <XIcon />
</button>
```
