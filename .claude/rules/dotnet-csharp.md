# .NET C# Rules

## Mandatory Constraints

```
╔═══════════════════════════════════════════════════════════════╗
║  These rules ALWAYS apply to ALL code, regardless of what     ║
║  acceptance criteria says. AC defines WHAT to build, these    ║
║  rules define HOW to build it.                                ║
╚═══════════════════════════════════════════════════════════════╝
```

1. **No sync over async** - NEVER use `.Result` or `.Wait()`. Always `await`.

2. **Tests required** - Every feature MUST include boundary tests (API/Controller). A feature is NOT complete without them.

3. **Only mock external I/O** - Mock third-party APIs, not your own services.

---

## Core Principles

### DRY, YAGNI, KISS

- Single source of truth for constants and configuration
- Build only what's needed for the current task
- Prefer explicit over clever
- "Duplication is far cheaper than the wrong abstraction" - Sandi Metz

### Layer Architecture

```
┌─────────────────────────────────────┐
│            PRESENTATION             │
│  API Controllers / UI               │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│            APPLICATION              │
│  Services / Use Cases               │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│              DOMAIN                 │
│  Entities / Business Logic          │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│           PERSISTENCE               │
│  DbContext / Repositories           │
└─────────────────────────────────────┘
```

---

## Project Structure

```
src/
├── [ProjectName].sln
├── [ProjectName]/              # Main application
│   ├── [ProjectName].csproj
│   ├── Program.cs
│   ├── Domain/                 # Domain models, entities
│   ├── Application/            # Use cases, services
│   ├── Infrastructure/         # External concerns (DB, APIs)
│   └── Presentation/           # API controllers, UI
├── [ProjectName].Tests/        # Test project
└── [ProjectName].Shared/       # Shared types (optional)
```

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `UserService` |
| Interfaces | IPascalCase | `IUserRepository` |
| Methods | PascalCase | `GetUserById` |
| Properties | PascalCase | `FirstName` |
| Private fields | _camelCase | `_userRepository` |
| Parameters | camelCase | `userId` |
| Async methods | Suffix with Async | `GetUserAsync` |

---

## Modern C# Features (C# 12+)

### Primary Constructors

```csharp
public class UserService(IUserRepository repository, ILogger<UserService> logger)
{
    public async Task<User?> GetUserAsync(int id)
    {
        logger.LogInformation("Getting user {Id}", id);
        return await repository.GetByIdAsync(id);
    }
}
```

### Collection Expressions

```csharp
List<int> numbers = [1, 2, 3, 4, 5];
int[] combined = [..array, 6, 7, 8];
```

### Pattern Matching

```csharp
var description = status switch
{
    Status.Pending => "Waiting",
    Status.Active => "In progress",
    Status.Completed => "Done",
    _ => throw new ArgumentOutOfRangeException(nameof(status))
};
```

---

## Dependency Injection

```csharp
// Program.cs
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<ICacheService, RedisCacheService>();

// Extension method pattern
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();
        return services;
    }
}
```

---

## Result Pattern

```csharp
public record Result<T>
{
    public bool IsSuccess { get; init; }
    public T? Value { get; init; }
    public string? Error { get; init; }

    public static Result<T> Success(T value) => new() { IsSuccess = true, Value = value };
    public static Result<T> Failure(string error) => new() { IsSuccess = false, Error = error };
}
```

---

## Entity Framework Core

```csharp
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
```

---

## Validation

Use FluentValidation:

```csharp
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
    }
}
```

---

## Async/Await

- Always use `async`/`await` for I/O operations
- Suffix async methods with `Async`
- Don't mix sync and async (avoid `.Result`, `.Wait()`)

---

## Testing

### The Rule

```
╔═══════════════════════════════════════════════════════════════╗
║  EVERY feature implementation MUST include tests.             ║
║  A feature is NOT complete without them.                      ║
╚═══════════════════════════════════════════════════════════════╝
```

### Boundary Testing

Test at API boundaries using `WebApplicationFactory`. Use real implementations internally, only mock external services.

```csharp
public class UsersApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly Fixture _fixture = new();

    public UsersApiTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb"));
            });
        });
    }

    [Fact]
    public async Task GetUsers_ReturnsAllUsers()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/users");
        response.EnsureSuccessStatusCode();
    }
}
```

### Test Data with Bogus

```csharp
public class UserFaker : Faker<User>
{
    public UserFaker()
    {
        RuleFor(u => u.Id, f => f.IndexFaker + 1);
        RuleFor(u => u.Email, f => f.Internet.Email());
        RuleFor(u => u.Name, f => f.Name.FullName());
    }
}
```

### Mocking Rules

```
ONLY mock external I/O:
  - Third-party APIs (payment, email, SMS)
  - File system, network, time

NEVER mock your own code:
  - Services, repositories, validators
  - If you're mocking it, you're testing implementation not behavior
```
