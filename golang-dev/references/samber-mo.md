# samber/mo — Monadic Types

Type-safe monadic types for Go 1.18+. Zero dependencies. Makes impossible states unrepresentable.

- [github.com/samber/mo](https://github.com/samber/mo)
- [pkg.go.dev/github.com/samber/mo](https://pkg.go.dev/github.com/samber/mo)

## Core Types

| Type | Purpose | Analogy |
| --- | --- | --- |
| `Option[T]` | Value that may be absent | Rust `Option`, Java `Optional` |
| `Result[T]` | Operation that may fail | Rust `Result<T, E>` |
| `Either[L, R]` | Value of one of two types | Scala `Either` |
| `Future[T]` | Async value not yet available | JS `Promise` |
| `IO[T]` | Lazy synchronous side effect | Haskell `IO` |
| `Task[T]` | Lazy async computation | fp-ts `Task` |
| `State[S, A]` | Stateful computation | Haskell `State` |

## Option[T]

Represents present (`Some`) or absent (`None`). Eliminates nil pointer risks:

```go
name := mo.Some("Alice")
empty := mo.None[string]()
fromPtr := mo.PointerToOption(ptr) // nil → None

name.OrElse("Anonymous")   // "Alice"
empty.OrElse("Anonymous")  // "Anonymous"

upper := name.Map(func(s string) (string, bool) {
    return strings.ToUpper(s), true
})
```

**Key methods:** `Some`, `None`, `Get`, `MustGet`, `OrElse`, `OrEmpty`, `Map`, `FlatMap`, `Match`, `IsPresent`, `IsAbsent`, `ToPointer`.

Implements `json.Marshaler/Unmarshaler` and `sql.Scanner/driver.Valuer`.

## Result[T]

Success (`Ok`) or failure (`Err`):

```go
result := mo.TupleToResult(os.ReadFile("config.yaml"))

upper := mo.Ok("hello").Map(func(s string) (string, error) {
    return strings.ToUpper(s), nil
})

val := upper.OrElse("default")
```

### Type-Changing Pipelines

Direct methods can't change type params. Use sub-package pipes:

```go
import "github.com/samber/mo/result"

parsed := result.Pipe2(
    mo.TupleToResult(os.ReadFile("config.yaml")),
    result.Map(func(data []byte) Config { return parseConfig(data) }),
    result.FlatMap(func(cfg Config) mo.Result[ValidConfig] { return validate(cfg) }),
)
```

**Key methods:** `Ok`, `Err`, `Errf`, `TupleToResult`, `Try`, `Get`, `MustGet`, `OrElse`, `Map`, `FlatMap`, `MapErr`, `Match`, `IsOk`, `IsError`.

## Either[L, R]

Two valid alternatives (not error vs success — use Result for that):

```go
func fetchUser(id string) mo.Either[CachedUser, FreshUser] {
    if cached, ok := cache.Get(id); ok {
        return mo.Left[CachedUser, FreshUser](cached)
    }
    return mo.Right[CachedUser, FreshUser](db.Fetch(id))
}
```

`Either3`, `Either4`, `Either5` extend to more variants.

## Do Notation

Imperative style with monadic safety — catches `MustGet()` panics:

```go
result := mo.Do(func() int {
    a := mo.Some(21).MustGet()
    b := mo.Ok(2).MustGet()
    return a * b // 42
})
// Ok(42) — or Err if any MustGet panics
```

## Common Patterns

```go
// JSON with optional fields
type UserResponse struct {
    Name     string            `json:"name"`
    Nickname mo.Option[string] `json:"nickname"`
}

// Database nullable columns
type User struct {
    ID    int
    Phone mo.Option[string] // implements sql.Scanner
}

// Fold — uniform extraction across Option/Result/Either
str := mo.Fold[error, int, string](
    mo.Ok(42),
    func(v int) string { return fmt.Sprintf("got %d", v) },
    func(err error) string { return "failed" },
)
```

## Best Practices

1. **`OrElse` over `MustGet`** — `MustGet` panics; use only inside `mo.Do`
2. **`TupleToResult` at boundaries** — convert Go's `(T, error)` then chain
3. **`Result[T]` for errors, `Either[L, R]` for alternatives**
4. **`Option` for nullable, not zero values** — distinguishes absent from empty
5. **Sub-package pipes for type changes** — `result.Pipe2(...)` when types differ

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `MustGet` in production handlers | Use `OrElse` or check `IsPresent` |
| `Either` for error handling | Use `Result[T]` — specialized for errors |
| `Option[string]` when empty is valid | Use plain `string` |
| Nested if/else instead of chaining | `.Map().FlatMap().OrElse()` |
