# Type Design (Structs & Interfaces)

## Interface Design

### Keep Interfaces Small

> "The bigger the interface, the weaker the abstraction." — Go Proverbs

Interfaces SHOULD have 1–3 methods. Compose larger contracts from small interfaces:

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type ReadWriter interface { Reader; Writer }
```

### Define Where Consumed

Interfaces MUST be defined where consumed, not where implemented:

```go
// package notification — defines only what it needs
type Sender interface {
    Send(to, body string) error
}

type Service struct { sender Sender }
```

### Accept Interfaces, Return Structs

```go
// ✓ Good — accepts interface, returns concrete
func NewService(store UserStore) *Service { ... }

// ✗ Bad — NEVER return interfaces from constructors
func NewService(store UserStore) ServiceInterface { ... }
```

### Don't Create Prematurely

> "Don't design with interfaces, discover them."

Wait for 2+ implementations or a testability requirement before extracting an interface.

## Key Standard Library Interfaces

| Interface | Package | Method |
| --- | --- | --- |
| `Reader` | `io` | `Read(p []byte) (n int, err error)` |
| `Writer` | `io` | `Write(p []byte) (n int, err error)` |
| `Closer` | `io` | `Close() error` |
| `Stringer` | `fmt` | `String() string` |
| `error` | builtin | `Error() string` |
| `Handler` | `net/http` | `ServeHTTP(ResponseWriter, *Request)` |

Honor canonical signatures — don't invent `ToString()` or `ReadData()`.

## Compile-Time Interface Check

```go
var _ io.ReadWriter = (*MyBuffer)(nil)
```

Zero cost at runtime. Catches broken implementations at build time.

## Type Assertions & Type Switches

```go
// ✓ Safe — comma-ok form
s, ok := val.(string)
if !ok { /* handle */ }

// ✗ Bad — panics on mismatch
s := val.(string)

// Type switch for dynamic dispatch
switch v := val.(type) {
case string:  fmt.Println(v)
case int:     fmt.Println(v * 2)
default:      fmt.Printf("unexpected type %T\n", v)
}
```

### Optional Behavior

```go
if f, ok := w.(Flusher); ok {
    return f.Flush()
}
```

## Struct Embedding

Embedding promotes inner type's methods — composition, not inheritance:

```go
// Embed — Server exposes all http.Handler methods
type Server struct { http.Handler }

// Named field — only uses store internally
type Server struct { store *DataStore }
```

| Use | When |
| --- | --- |
| **Embed** | Full API promotion — outer type "is a" enhanced version |
| **Named field** | Internal dependency — outer type "has a" dependency |

## Dependency Injection

```go
type UserStore interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

type UserService struct { store UserStore }

func NewUserService(store UserStore) *UserService {
    return &UserService{store: store}
}
```

## Struct Field Tags

Exported fields in serialized structs MUST have tags:

```go
type Order struct {
    ID        string    `json:"id"         db:"id"`
    UserID    string    `json:"user_id"    db:"user_id"`
    Total     float64   `json:"total"      db:"total"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
    Internal  string    `json:"-"          db:"-"`
}
```

## Pointer vs Value Receivers

| Pointer `(s *Server)` | Value `(s Server)` |
| --- | --- |
| Modifies receiver | Small, immutable receiver |
| Contains `sync.Mutex` | Basic type (int, string) |
| Large struct | Read-only accessor |
| Consistency: if any uses pointer, all should | Map/function values (reference types) |

## Preventing Struct Copies with noCopy

```go
type noCopy struct{}
func (*noCopy) Lock()   {}
func (*noCopy) Unlock() {}

type ConnPool struct {
    noCopy noCopy
    mu     sync.Mutex
    conns  []*Conn
}
// go vet reports error if ConnPool is copied
```

## Avoid `any` When Specific Types Work

```go
// ✗ Bad — loses type safety
func Contains(slice []any, target any) bool { ... }

// ✓ Good — generic, type-safe (Go 1.18+)
func Contains[T comparable](slice []T, target T) bool { ... }
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Large interfaces (5+ methods) | Split into 1–3 method interfaces, compose |
| Defining interfaces in implementor package | Define where consumed |
| Returning interfaces from constructors | Return concrete types |
| Bare type assertions | Always use comma-ok |
| Embedding when you only need a few methods | Use named field, delegate |
| Missing field tags on serialized structs | Tag all exported fields |
| Mixing pointer and value receivers | Pick one, be consistent |
| Using `any` for type-safe operations | Use generics |
| Premature interface with single implementation | Start concrete, extract later |
