# Experiment: TypeScript Todo API

A simple REST API for task management, built with TypeScript and Express.

## Project Spec

**Name:** TodoApi

**Overview:** A RESTful API for managing todo items with CRUD operations.

**Vision:** Demonstrate idiomatic TypeScript patterns in an Express API context.

**Problem:** Need a clean example of TypeScript API conventions with Result types, branded IDs, and boundary testing.

**Users:** Developers learning TypeScript API patterns.

**Stack:**
| Layer | Choice | Rationale |
|-------|--------|-----------|
| Runtime | Node.js 20 | Latest LTS |
| Language | TypeScript | Type safety |
| Framework | Express | Lightweight, widely used |
| Testing | Vitest + Supertest | Fast, native ESM |

**Key Commands:**
```bash
npm run dev         # Development
npm test            # Test
npm run build       # Build
```

**Data Model:**

### Todo
- id: TodoId (branded number)
- title: string
- completed: boolean
- createdAt: Date

### TodoStatus (const assertion)
```typescript
const STATUSES = ['pending', 'in_progress', 'done'] as const
type TodoStatus = typeof STATUSES[number]
```

**Architecture:**
- types/: Type definitions, branded IDs
- services/: Business logic with Result types
- routes/: Express route handlers
- app.ts: Express app setup
- index.ts: Server entry point

**Conventions:**
- Use Result<T, E> for fallible operations
- Branded IDs for type safety (TodoId, not number)
- Const assertions for enum-like values
- Tests at API boundary (supertest)
- No any types

## Pre-seeded Beads

```bash
bd create --title="Set up Express server with TypeScript" --type=task --priority=1
bd create --title="Define domain types (Todo, TodoId, Result)" --type=task --priority=1
bd create --title="Implement GET /todos endpoint" --type=task --priority=2
bd create --title="Implement POST /todos endpoint" --type=task --priority=2
bd create --title="Implement PUT /todos/:id endpoint" --type=task --priority=2
bd create --title="Implement DELETE /todos/:id endpoint" --type=task --priority=2
bd create --title="Add API integration tests" --type=task --priority=3
```

## Success Criteria

- [ ] Project builds with `npm run build`
- [ ] All 7 beads completed
- [ ] Tests pass with `npm test`
- [ ] API endpoints return correct responses
- [ ] No TypeScript errors

## Convention Checks

After completion, verify TypeScript conventions:

1. **Type Definitions (types/)**
   - [ ] TodoId is branded type, not raw number
   - [ ] Result<T, E> type defined and used
   - [ ] Const assertions for status values
   - [ ] No `any` types

2. **Services**
   - [ ] Functions return Result<T, E>
   - [ ] Error handling without exceptions
   - [ ] Pure functions where possible

3. **Route Handlers**
   - [ ] Pattern matching on Result (if/switch)
   - [ ] Appropriate HTTP status codes
   - [ ] Input validation

4. **Testing**
   - [ ] Tests at API boundary (supertest)
   - [ ] @faker-js/faker for test data
   - [ ] All CRUD operations tested

5. **General TypeScript Style**
   - [ ] Strict mode enabled
   - [ ] No implicit any
   - [ ] Prefer `type` for unions, `interface` for objects

## Stack

```json
{
  "runtime": "node",
  "language": "typescript",
  "framework": "express",
  "testing": "vitest"
}
```

## Expected File Structure

```
todo-api/
├── package.json
├── tsconfig.json
├── src/
│   ├── types/
│   │   ├── index.ts      # Exports
│   │   ├── todo.ts       # Todo, TodoId
│   │   └── result.ts     # Result type
│   ├── services/
│   │   └── todoService.ts
│   ├── routes/
│   │   └── todos.ts
│   ├── app.ts
│   └── index.ts
└── tests/
    └── todos.test.ts     # API integration tests
```
