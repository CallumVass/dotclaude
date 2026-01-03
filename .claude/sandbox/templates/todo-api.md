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

**API Endpoints:**
- GET /todos - List all todos
- POST /todos - Create a todo
- PUT /todos/:id - Update a todo
- DELETE /todos/:id - Delete a todo

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

## Decisions (Use These When Asked)

If asked about any of these, use the provided answer:

| Question | Answer |
|----------|--------|
| Authentication? | None - out of scope |
| Database? | In-memory Map |
| Validation library? | Manual with Result type |
| Architecture approach? | Pick **pragmatic** option |
| Project structure? | src/ with types/, services/, routes/ |
| Logging? | console.log only |
| Error format? | JSON { success: false, error: string } |

## Expected Scope

Init-project should identify approximately these tasks:
1. Project setup (Express + TypeScript)
2. Type definitions (Todo, TodoId, Result)
3. In-memory storage service
4. GET /todos endpoint
5. POST /todos endpoint
6. PUT /todos/:id endpoint
7. DELETE /todos/:id endpoint
8. API integration tests

The exact breakdown may vary.

## Success Criteria

- [ ] Project builds with `npm run build`
- [ ] Tests pass with `npm test`
- [ ] API endpoints work correctly
- [ ] No TypeScript errors
- [ ] Beads created and completed

## Convention Checks

1. **Type Definitions**
   - [ ] TodoId is branded type
   - [ ] Result<T, E> defined and used
   - [ ] Const assertions for status
   - [ ] No `any` types

2. **Services**
   - [ ] Functions return Result<T, E>
   - [ ] No thrown exceptions for expected errors

3. **Route Handlers**
   - [ ] Proper HTTP status codes
   - [ ] Input validation

4. **Testing**
   - [ ] Tests at API boundary (supertest)
   - [ ] @faker-js/faker for test data

## Stack

```json
{
  "runtime": "node",
  "language": "typescript",
  "framework": "express",
  "testing": "vitest"
}
```
