---
paths: ["**/*.cs", "**/*.csproj"]
---

# C# Specific Rules

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

## Error Handling Middleware

```csharp
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (ValidationException ex)
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(new { errors = ex.Errors });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Unhandled exception");
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new { error = "An error occurred" });
        }
    }
}
```
