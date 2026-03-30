# Safety & Defensive Coding

Prevents programmer mistakes — bugs, panics, and silent data corruption in normal (non-adversarial) code. Security handles attackers; safety handles ourselves.

## Core Rules

1. **Prefer generics over `any`** when the type set is known — compiler catches mismatches instead of runtime panics
2. **Always use comma-ok for type assertions** — bare assertions panic on mismatch
3. **Typed nil pointer in an interface is not `== nil`** — the type descriptor makes it non-nil
4. **Writing to a nil map panics** — always initialize before use
5. **`append` may reuse the backing array** — both slices share memory if capacity allows
6. **Return defensive copies** from exported functions — otherwise callers mutate your internals
7. **`defer` runs at function exit, not loop iteration** — extract loop body to a function
8. **Integer conversions truncate silently** — `int64` to `int32` wraps without error
9. **Float arithmetic is not exact** — use epsilon comparison or `math/big`
10. **Design useful zero values** — nil map fields panic on first write; use lazy init
11. **Use `sync.Once` for lazy init** — guarantees exactly-once even under concurrency

## Nil Safety

### The nil interface trap

Interfaces store (type, value). An interface is `nil` only when both are nil:

```go
// ✗ Dangerous — interface{type: *MyHandler, value: nil} != nil
func getHandler() http.Handler {
    var h *MyHandler
    if !enabled {
        return h // non-nil interface!
    }
    return h
}

// ✓ Good — return nil explicitly
func getHandler() http.Handler {
    if !enabled {
        return nil // interface{type: nil, value: nil} == nil
    }
    return &MyHandler{}
}
```

### Nil map, slice, and channel behavior

| Type | Read from nil | Write to nil | Len/Cap of nil | Range over nil |
| --- | --- | --- | --- | --- |
| Map | Zero value | **panic** | 0 | 0 iterations |
| Slice | **panic** (index) | **panic** (index) | 0 | 0 iterations |
| Channel | Blocks forever | Blocks forever | 0 | Blocks forever |

```go
// ✓ Lazy-init pattern for maps
func (r *Registry) Add(name string, val int) {
    if r.items == nil { r.items = make(map[string]int) }
    r.items[name] = val
}
```

## Slice & Map Safety

### Slice aliasing — the append trap

```go
// ✗ Dangerous — a and b share backing array
a := make([]int, 3, 5)
b := append(a, 4)
b[0] = 99 // also modifies a[0]

// ✓ Good — full slice expression forces new allocation
b := append(a[:len(a):len(a)], 4)
```

### Defensive copies

```go
// ✓ Good — unexported field with accessor returning a copy
type Config struct {
    hosts []string
}

func (c *Config) Hosts() []string {
    return slices.Clone(c.hosts)
}
```

## Numeric Safety

### Integer overflow

```go
// ✗ Bad — silently wraps (3B → -1.29B)
var val int64 = 3_000_000_000
i32 := int32(val)

// ✓ Good — check before converting
if val > math.MaxInt32 || val < math.MinInt32 {
    return fmt.Errorf("value %d overflows int32", val)
}
i32 := int32(val)
```

### Float comparison

```go
// ✗ Bad — 0.1+0.2 == 0.3 is false
// ✓ Good — epsilon comparison
const epsilon = 1e-9
math.Abs((0.1+0.2)-0.3) < epsilon
```

### Division by zero

Integer division by zero panics. Float division produces `+Inf`/`-Inf`/`NaN`. Always guard with `if divisor == 0`.

## Resource Safety

### defer in loops

```go
// ✗ Bad — all files stay open until function returns
for _, path := range paths {
    f, _ := os.Open(path)
    defer f.Close()
    process(f)
}

// ✓ Good — extract to function so defer runs per iteration
for _, path := range paths {
    if err := processOne(path); err != nil { return err }
}

func processOne(path string) error {
    f, err := os.Open(path)
    if err != nil { return err }
    defer f.Close()
    return process(f)
}
```

## Zero-Value Design

```go
var mu sync.Mutex    // ✓ usable at zero value
var buf bytes.Buffer // ✓ usable at zero value

// ✗ Bad — nil map panics on write
type Cache struct { data map[string]any }

// ✓ Good — sync.Once for lazy init
type DB struct {
    once sync.Once
    conn *sql.DB
}

func (db *DB) connection() *sql.DB {
    db.once.Do(func() {
        db.conn, _ = sql.Open("postgres", connStr)
    })
    return db.conn
}
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Bare type assertion `v := x.(T)` | Use `v, ok := x.(T)` |
| Returning typed nil in interface | Return explicit `nil` |
| Writing to nil map | Initialize with `make()` or lazy-init |
| Assuming `append` always copies | Use `s[:len(s):len(s)]` to force copy |
| `defer` in a loop | Extract body to separate function |
| `int64` to `int32` without bounds check | Check `math.MaxInt32`/`math.MinInt32` |
| Comparing floats with `==` | Use `math.Abs(a-b) < epsilon` |
| Integer division without zero check | Guard with `if divisor == 0` |
| Returning internal slice/map reference | Return `slices.Clone()` / `maps.Clone()` |
| Blocking forever on nil channel | Always initialize before use |
