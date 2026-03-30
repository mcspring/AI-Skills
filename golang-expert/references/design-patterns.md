# Design Patterns & Idioms

Idiomatic Go patterns for production-ready code. Favor simplicity and explicitness — apply patterns only when they solve a real problem.

## Core Rules

1. Constructors SHOULD use **functional options** — scale as APIs evolve, no breaking changes
2. Functional options MUST **return error** if validation can fail
3. **Avoid `init()`** — runs implicitly, cannot return errors, makes testing unpredictable
4. Enums SHOULD **start at 1** (or Unknown sentinel at 0) — zero value catches uninitialized
5. Error cases MUST be **handled first** with early return — keep happy path flat
6. **Panic is for bugs, not expected errors**
7. **`defer Close()` immediately** after opening
8. **`runtime.AddCleanup`** over `runtime.SetFinalizer` (Go 1.24+)
9. Every external call SHOULD **have a timeout**
10. **Limit everything** — pool sizes, queue depths, buffers
11. Retry logic MUST **check `ctx.Err()`** between attempts
12. **Compile regexp once** at package level
13. **Minimize dependencies** — a little recode > a big dependency

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

### Timeout Every External Call

```go
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
resp, err := httpClient.Do(req.WithContext(ctx))
```

### Retry with Context

Retry logic MUST check `ctx.Err()` between attempts and use exponential/linear backoff via `select` on `ctx.Done()`.

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
