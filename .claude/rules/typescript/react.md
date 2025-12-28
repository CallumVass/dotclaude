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
// Custom hook
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

// Usage
function UserProfile({ id }: { id: string }) {
  const { user, loading, error } = useUser(id)

  if (loading) return <Spinner />
  if (error) return <Error message={error} />
  if (!user) return <NotFound />

  return <UserCard user={user} />
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

### Context Pattern

```tsx
interface AuthContextValue {
  user: User | null
  login: (creds: Credentials) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)

  const login = async (creds: Credentials) => {
    const user = await AuthService.login(creds)
    setUser(user)
  }

  const logout = () => setUser(null)

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}
```

---

## Performance

```tsx
// Memoize expensive computations
const sortedItems = useMemo(
  () => items.sort((a, b) => a.name.localeCompare(b.name)),
  [items]
)

// Memoize callbacks passed to children
const handleClick = useCallback(
  (id: string) => onItemClick(id),
  [onItemClick]
)

// Memoize components that receive object/array props
const MemoizedList = memo(function List({ items }: { items: Item[] }) {
  return items.map(item => <Item key={item.id} {...item} />)
})
```

---

## Styling

Prefer utility-first CSS (Tailwind) or CSS Modules:

```tsx
// Tailwind (preferred)
<div className="flex items-center gap-4 p-4 bg-gray-100 rounded-lg">

// CSS Modules
import styles from './Card.module.css'
<div className={styles.card}>

// Avoid inline styles for static values
// Use them only for dynamic values
<div style={{ height: `${dynamicHeight}px` }}>
```

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

### Data Fetching

```tsx
// Server Component - direct fetch
async function Page() {
  const data = await fetch('https://api.example.com/data')
  return <Component data={data} />
}

// Client Component - React Query or SWR
'use client'
function Page() {
  const { data, isLoading } = useQuery({
    queryKey: ['data'],
    queryFn: () => fetch('/api/data').then(r => r.json())
  })
  // ...
}
```

---

## Accessibility

- Use semantic HTML (`button`, `nav`, `article`, etc.)
- Add `aria-label` for icon-only buttons
- Ensure keyboard navigation works
- Use `role` attributes when semantic HTML isn't enough

```tsx
<button
  aria-label="Close dialog"
  onClick={onClose}
>
  <XIcon />
</button>
```
