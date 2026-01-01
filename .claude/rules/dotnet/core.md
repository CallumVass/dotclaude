# .NET Core Rules

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

## Async/Await

- Always use `async`/`await` for I/O operations
- Suffix async methods with `Async`
- Don't mix sync and async (avoid `.Result`, `.Wait()`)

---

## Testing

Test at API boundaries using `WebApplicationFactory`:

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
