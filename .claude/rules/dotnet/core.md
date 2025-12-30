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
│   └── [ProjectName].Tests.csproj
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
| Constants | PascalCase | `MaxRetries` |
| Async methods | Suffix with Async | `GetUserAsync` |

---

## Dependency Injection

Register services in `Program.cs` or extension methods:

```csharp
// Program.cs
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<ICacheService, RedisCacheService>();
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();

// Or use extension method
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IOrderService, OrderService>();
        return services;
    }
}

// Usage
builder.Services.AddApplicationServices();
```

---

## Result Pattern

Avoid throwing exceptions for expected failures:

```csharp
public record Result<T>
{
    public bool IsSuccess { get; init; }
    public T? Value { get; init; }
    public string? Error { get; init; }

    public static Result<T> Success(T value) => new() { IsSuccess = true, Value = value };
    public static Result<T> Failure(string error) => new() { IsSuccess = false, Error = error };
}

// Usage
public async Task<Result<User>> GetUserAsync(int id)
{
    var user = await _dbContext.Users.FindAsync(id);
    if (user is null)
        return Result<User>.Failure("User not found");

    return Result<User>.Success(user);
}

// Handling
var result = await _userService.GetUserAsync(id);
if (!result.IsSuccess)
    return NotFound(result.Error);

return Ok(result.Value);
```

---

## Async/Await

- Always use `async`/`await` for I/O operations
- Suffix async methods with `Async`
- Don't mix sync and async (avoid `.Result`, `.Wait()`)
- **ConfigureAwait(false)**: Not needed in ASP.NET Core apps (no SynchronizationContext exists). Only use in library code that may be consumed by UI apps or legacy ASP.NET

```csharp
// Good
public async Task<User> GetUserAsync(int id)
{
    return await _dbContext.Users.FindAsync(id);
}

// Avoid
public User GetUser(int id)
{
    return _dbContext.Users.FindAsync(id).Result; // Deadlock risk!
}
```

---

## Nullable Reference Types

Enable in `.csproj`:

```xml
<PropertyGroup>
    <Nullable>enable</Nullable>
</PropertyGroup>
```

Use nullable annotations:

```csharp
public class User
{
    public required string Name { get; init; }      // Non-null, required
    public string? Nickname { get; set; }           // Nullable
    public IList<Order> Orders { get; } = [];       // Non-null collection
}

// Handle nullable values explicitly
public string GetDisplayName(User? user)
{
    return user?.Nickname ?? user?.Name ?? "Unknown";
}
```

---

## Records for DTOs

Use records for immutable data transfer objects:

```csharp
// Request/Response DTOs
public record CreateUserRequest(string Email, string Name);
public record UserResponse(int Id, string Email, string Name, DateTime CreatedAt);

// Domain events
public record UserCreatedEvent(int UserId, DateTime OccurredAt);

// Value objects
public record Money(decimal Amount, string Currency);
```

---

## Minimal APIs vs Controllers

**Minimal APIs** - Simple endpoints, microservices:

```csharp
app.MapGet("/users/{id}", async (int id, IUserService userService) =>
{
    var result = await userService.GetUserAsync(id);
    return result.IsSuccess
        ? Results.Ok(result.Value)
        : Results.NotFound(result.Error);
});
```

**Controllers** - Complex APIs, OpenAPI generation:

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("{id}")]
    [ProducesResponseType<UserResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetUser(int id)
    {
        var result = await _userService.GetUserAsync(id);
        return result.IsSuccess
            ? Ok(result.Value)
            : NotFound(result.Error);
    }
}
```

---

## Testing

Test at API boundaries using `WebApplicationFactory`. Use real services and repositories - only mock the database or external APIs.

### Test Project Setup

```xml
<!-- [ProjectName].Tests.csproj -->
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="9.0.0" />
<PackageReference Include="AutoFixture" Version="4.18.0" />
<PackageReference Include="Bogus" Version="35.0.0" />
<PackageReference Include="Testcontainers.PostgreSql" Version="4.0.0" />
```

### API Integration Tests

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
                // Replace database with test container or in-memory
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase("TestDb"));
            });
        });
    }

    [Fact]
    public async Task GetUsers_ReturnsAllUsers()
    {
        // Arrange
        var client = _factory.CreateClient();
        await SeedUsers(3);

        // Act
        var response = await client.GetAsync("/api/users");

        // Assert
        response.EnsureSuccessStatusCode();
        var users = await response.Content.ReadFromJsonAsync<List<UserResponse>>();
        Assert.Equal(3, users!.Count);
    }

    [Fact]
    public async Task CreateUser_WithValidData_ReturnsCreated()
    {
        // Arrange
        var client = _factory.CreateClient();
        var request = _fixture.Create<CreateUserRequest>();

        // Act
        var response = await client.PostAsJsonAsync("/api/users", request);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task CreateUser_WithInvalidEmail_ReturnsBadRequest()
    {
        // Arrange
        var client = _factory.CreateClient();
        var request = new CreateUserRequest("not-an-email", "Test User");

        // Act
        var response = await client.PostAsJsonAsync("/api/users", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
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
        RuleFor(u => u.CreatedAt, f => f.Date.Past());
    }
}

// Usage
var users = new UserFaker().Generate(10);
```

### Using Testcontainers (Real Database)

```csharp
public class DatabaseFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .Build();

    public string ConnectionString => _postgres.GetConnectionString();

    public async Task InitializeAsync() => await _postgres.StartAsync();
    public async Task DisposeAsync() => await _postgres.DisposeAsync();
}
```

### Test Organization

```
src/
├── [ProjectName]/
└── [ProjectName].Tests/
    ├── ApiTests/
    │   ├── UsersApiTests.cs
    │   └── OrdersApiTests.cs
    ├── Fakers/
    │   ├── UserFaker.cs
    │   └── OrderFaker.cs
    └── Fixtures/
        └── DatabaseFixture.cs
```
