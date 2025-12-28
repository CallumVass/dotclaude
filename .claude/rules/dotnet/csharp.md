---
paths: ["**/*.cs", "**/*.csproj"]
---

# C# Specific Rules

Applies to C# files in .NET projects.

## Modern C# Features (C# 12+)

### Primary Constructors

```csharp
// Modern - Primary constructor
public class UserService(IUserRepository repository, ILogger<UserService> logger)
{
    public async Task<User?> GetUserAsync(int id)
    {
        logger.LogInformation("Getting user {Id}", id);
        return await repository.GetByIdAsync(id);
    }
}

// Traditional (still valid)
public class UserService
{
    private readonly IUserRepository _repository;

    public UserService(IUserRepository repository)
    {
        _repository = repository;
    }
}
```

### Collection Expressions

```csharp
// Modern
List<int> numbers = [1, 2, 3, 4, 5];
int[] array = [1, 2, 3];
HashSet<string> set = ["a", "b", "c"];

// Spread
int[] combined = [..array, 6, 7, 8];
```

### Pattern Matching

```csharp
// Type patterns
if (obj is User { Name: var name, Age: > 18 } user)
{
    Console.WriteLine($"Adult user: {name}");
}

// Switch expressions
var description = status switch
{
    Status.Pending => "Waiting for approval",
    Status.Active => "In progress",
    Status.Completed => "Done",
    _ => throw new ArgumentOutOfRangeException(nameof(status))
};

// List patterns
int[] numbers = [1, 2, 3];
var result = numbers switch
{
    [1, 2, 3] => "Exact match",
    [1, ..] => "Starts with 1",
    [.., 3] => "Ends with 3",
    [] => "Empty",
    _ => "Other"
};
```

---

## LINQ Best Practices

```csharp
// Good - Readable chain
var activeUsers = users
    .Where(u => u.IsActive)
    .OrderBy(u => u.Name)
    .Select(u => new UserDto(u.Id, u.Name))
    .ToList();

// Good - Query syntax for complex joins
var ordersWithUsers = from o in orders
                      join u in users on o.UserId equals u.Id
                      where o.Total > 100
                      select new { Order = o, User = u };

// Avoid - Nested queries
var bad = users.Where(u => orders.Any(o => o.UserId == u.Id)); // N+1 risk!

// Better - Explicit join or Include
var better = users.Include(u => u.Orders).Where(u => u.Orders.Any());
```

---

## Entity Framework Core

### DbContext Setup

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

### Entity Configuration

```csharp
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Email).HasMaxLength(256).IsRequired();
        builder.HasIndex(u => u.Email).IsUnique();
        builder.HasMany(u => u.Orders).WithOne(o => o.User);
    }
}
```

### Repository Pattern (Optional)

```csharp
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id);
    Task<IReadOnlyList<T>> GetAllAsync();
    Task AddAsync(T entity);
    void Update(T entity);
    void Remove(T entity);
}

public class Repository<T>(AppDbContext context) : IRepository<T> where T : class
{
    protected readonly DbSet<T> _dbSet = context.Set<T>();

    public virtual async Task<T?> GetByIdAsync(int id) => await _dbSet.FindAsync(id);
    public virtual async Task<IReadOnlyList<T>> GetAllAsync() => await _dbSet.ToListAsync();
    public virtual async Task AddAsync(T entity) => await _dbSet.AddAsync(entity);
    public virtual void Update(T entity) => _dbSet.Update(entity);
    public virtual void Remove(T entity) => _dbSet.Remove(entity);
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
        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .MaximumLength(256);

        RuleFor(x => x.Name)
            .NotEmpty()
            .MaximumLength(100);
    }
}
```

Or Data Annotations for simple cases:

```csharp
public record CreateUserRequest(
    [Required, EmailAddress, MaxLength(256)] string Email,
    [Required, MaxLength(100)] string Name
);
```

---

## Error Handling

Use middleware for global error handling:

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
        catch (NotFoundException ex)
        {
            context.Response.StatusCode = 404;
            await context.Response.WriteAsJsonAsync(new { error = ex.Message });
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
