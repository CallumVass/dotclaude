# Experiment: Todo API

A simple REST API for task management. Tests the full dotclaude workflow.

## Project Spec

Build a TypeScript REST API with:
- Express.js server
- In-memory storage (no database)
- CRUD operations for todos
- Input validation
- Error handling with Result types

## Pre-seeded Beads

Create these issues before starting:

```bash
bd create --title="Set up Express server with TypeScript" --type=task --priority=1
bd create --title="Implement GET /todos endpoint" --type=task --priority=2
bd create --title="Implement POST /todos endpoint" --type=task --priority=2
bd create --title="Implement PUT /todos/:id endpoint" --type=task --priority=2
bd create --title="Implement DELETE /todos/:id endpoint" --type=task --priority=2
bd create --title="Add input validation" --type=task --priority=3
bd create --title="Add API tests" --type=task --priority=3
```

## Success Criteria

- [ ] All beads completed via /next-feature
- [ ] Tests pass (`npm test`)
- [ ] Server runs (`npm start`)
- [ ] All CRUD operations work

## Convention Checks

After completion, verify:

1. **TypeScript Core**
   - [ ] Uses `type` for unions, `interface` for objects
   - [ ] No `any` types
   - [ ] Result types for fallible operations
   - [ ] Branded IDs (TodoId)
   - [ ] Const assertions for status values

2. **Patterns**
   - [ ] Layer separation (routes/services/types)
   - [ ] Tests at API boundaries (supertest)
   - [ ] No over-engineering

3. **Testing**
   - [ ] Uses vitest + supertest
   - [ ] Uses @faker-js/faker for test data
   - [ ] Tests all endpoints

## Stack

```json
{
  "runtime": "node",
  "language": "typescript",
  "framework": "express",
  "testing": "vitest"
}
```
