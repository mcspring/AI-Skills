# Design Patterns & Idioms

Idiomatic Go patterns for production-ready code. Favor simplicity and explicitness — apply patterns only when they solve a real problem.

## Core Heuristics

1. Use constructors only when initialization, invariants, or dependency injection need them.
2. Functional options are useful for APIs with many optional settings; plain parameters or config structs can be clearer for small APIs.
3. If an option can fail validation, choose an API shape that can surface that error rather than hiding it.
4. Prefer explicit initialization over side-effectful `init()`; keep `init()` for genuinely package-level setup that cannot fail or needs no injection.
5. Design enum-like zero values to be useful when possible; `Unknown`/`Invalid` is one option, not a requirement.
6. Early returns often flatten error-heavy code, but do not contort simple control flow to satisfy a style rule.
7. Panic is generally for programmer errors/invariants rather than expected runtime failures.
8. Acquire and release resources in the smallest clear scope; `defer` is usually the simplest cleanup mechanism.
9. For Go 1.24+, prefer `runtime.AddCleanup` to finalizers when cleanup semantics fit that API.
10. Bound resources that can otherwise grow without limit, based on workload and backpressure needs.
11. Retry loops should respect cancellation/deadlines owned by their caller.

## Functional Options

```go
type Server struct {
    addr        string
    readTimeout time.Duration
    maxConns    int
}

type Option func(*Server)

func WithReadTimeout(d time.Duration) Option {
    return func(s *Server) { s.readTimeout = d }
}

func WithMaxConns(n int) Option {
    return func(s *Server) { s.maxConns = n }
}

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{
        addr:        addr,
        readTimeout: 5 * time.Second,
        maxConns:    100,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
srv := NewServer(":8080", WithReadTimeout(30*time.Second), WithMaxConns(500))
```

## Avoid init() and Mutable Globals

```go
// ✗ Bad — hidden global state
var db *sql.DB
func init() {
    var err error
    db, err = sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil { log.Fatal(err) }
}

// ✓ Good — explicit, injectable
func NewUserRepository(db *sql.DB) *UserRepository {
    return &UserRepository{db: db}
}
```

## Enums

```go
type Status int

const (
    StatusUnknown   Status = iota // 0 = invalid/unset
    StatusActive                  // 1
    StatusInactive                // 2
    StatusSuspended               // 3
)
```

## Error Flow

Handle errors first with early return — keep happy path flat and unindented.

## Resource Management

```go
f, err := os.Open(path)
if err != nil { return err }
defer f.Close() // immediately after open

rows, err := db.QueryContext(ctx, query)
if err != nil { return err }
defer rows.Close()
```

## Resilience

### Deadline Ownership

```go
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
resp, err := httpClient.Do(req.WithContext(ctx))
```

### Retry with Context

Retry logic should stop when the caller's context is done and use a backoff/rate policy appropriate to the dependency. Do not stack arbitrary nested timeouts when an outer boundary already owns the deadline.

## Data Handling

| Type | Default for | Use when |
| --- | --- | --- |
| `string` | Everything | Immutable, safe, UTF-8 |
| `[]byte` | I/O | Writing to `io.Writer`, mutations |
| `[]rune` | Unicode ops | `len()` must mean characters |

Avoid repeated conversions — each allocates. Use iterators (Go 1.23+) for lazy evaluation. Stream large transfers to prevent OOM.

## Static Assets

```go
//go:embed templates/*
var templateFS embed.FS

//go:embed version.txt
var version string
```

## Compiled Patterns

```go
// ✓ Compiled once at package level
var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
```

## Architecture

Core principles regardless of style (clean, hexagonal, DDD, flat):

- **Keep domain pure** — no framework dependencies in domain layer
- **Fail fast** — validate at boundaries, trust internal code
- **Make illegal states unrepresentable** — use types to enforce invariants
- **Design for testability** — accept interfaces, inject dependencies

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `init()` for dependency setup | Explicit constructors with DI |
| Missing timeout on external calls | `context.WithTimeout` on every call |
| Unbounded resource pools | Set explicit limits |
| Retry without context check | Check `ctx.Err()` between attempts |
| Regexp compiled per call | `regexp.MustCompile` at package level |
| `math/rand` for crypto | `crypto/rand` for keys/tokens |
| Large dependencies for small tasks | Inline the logic you need |
