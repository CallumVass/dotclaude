# Experiment: F# Minimal API

A minimal REST API for a reading list tracker, built with F# and ASP.NET Core.

## Project Spec

**Name:** ReadingList

**Overview:** A simple API to track books you want to read, are reading, or have read.

**Vision:** Demonstrate idiomatic F# patterns in a web API context.

**Problem:** Need a clean example of F# API conventions with Result types, discriminated unions, and Railway-oriented programming.

**Users:** Developers learning F# API patterns.

**Stack:**
| Layer | Choice | Rationale |
|-------|--------|-----------|
| Runtime | .NET 8 | Latest LTS |
| Language | F# | Functional-first, strong typing |
| Framework | ASP.NET Core Minimal API | Lightweight, F#-friendly |
| Testing | xUnit + FsUnit | F# testing conventions |

**Key Commands:**
```bash
dotnet run          # Development
dotnet test         # Test
dotnet build        # Build
```

**Data Model:**

### Book
- Id: BookId (branded int)
- Title: string
- Author: string
- Status: ReadingStatus (ToRead | Reading | Finished)
- AddedAt: DateTimeOffset

### ReadingStatus (Discriminated Union)
- ToRead
- Reading of startedAt: DateTimeOffset
- Finished of finishedAt: DateTimeOffset

**Architecture:**
- Domain.fs: Types, branded IDs, DUs
- Services.fs: Business logic with Result types
- Handlers.fs: HTTP handlers
- Program.fs: App setup and routing

**Conventions:**
- Use Result<'T, 'E> for all fallible operations
- Branded IDs for type safety (BookId, not int)
- Discriminated unions for state
- Railway-oriented programming with Result.bind
- No exceptions for expected errors

## Pre-seeded Beads

```bash
bd create --title="Set up F# Minimal API project structure" --type=task --priority=1
bd create --title="Define domain types (Book, BookId, ReadingStatus)" --type=task --priority=1
bd create --title="Implement in-memory book repository" --type=task --priority=2
bd create --title="Add GET /books endpoint" --type=task --priority=2
bd create --title="Add POST /books endpoint" --type=task --priority=2
bd create --title="Add PUT /books/:id/status endpoint" --type=task --priority=2
bd create --title="Add API integration tests" --type=task --priority=3
```

## Success Criteria

- [ ] Project builds with `dotnet build`
- [ ] All 7 beads completed
- [ ] Tests pass with `dotnet test`
- [ ] API endpoints return correct responses
- [ ] No compiler warnings

## Convention Checks

After completion, verify F# conventions:

1. **Domain Types (Domain.fs)**
   - [ ] BookId is a branded/wrapped type, not raw int
   - [ ] ReadingStatus is a discriminated union
   - [ ] Types are immutable (no mutable fields)

2. **Result Pattern (Services.fs)**
   - [ ] Functions return Result<'T, 'Error>
   - [ ] Error type is a discriminated union
   - [ ] No exceptions thrown for expected failures
   - [ ] Railway-oriented composition with bind/map

3. **API Handlers (Handlers.fs)**
   - [ ] Pattern matching on Result
   - [ ] Appropriate HTTP status codes
   - [ ] No null checks (use Option instead)

4. **Testing**
   - [ ] Tests at API boundary (WebApplicationFactory)
   - [ ] FsUnit or similar F# test assertions
   - [ ] Test data generation (not hardcoded)

5. **General F# Style**
   - [ ] Pipeline operators (|>) for data flow
   - [ ] Function composition where appropriate
   - [ ] Module organization (not classes where avoidable)
   - [ ] Type inference utilized (minimal annotations)

## Stack

```json
{
  "runtime": "dotnet",
  "language": "fsharp",
  "framework": "aspnetcore-minimal",
  "testing": "xunit"
}
```

## Expected File Structure

```
ReadingList/
├── ReadingList.fsproj
├── Domain.fs           # Types, branded IDs, DUs
├── Services.fs         # Business logic
├── Handlers.fs         # HTTP handlers
├── Program.fs          # App entry point
└── ReadingList.Tests/
    ├── ReadingList.Tests.fsproj
    └── ApiTests.fs     # Integration tests
```
