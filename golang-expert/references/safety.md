# Safety & Defensive Coding

Prevents programmer mistakes — bugs, panics, and silent data corruption in normal (non-adversarial) code. Security handles attackers; safety handles ourselves.

## Core Rules

1. Prefer static types/generics when they make invariants clearer; use `any` when dynamic values are genuinely part of the API.
2. Use comma-ok type assertions when mismatch is an expected runtime possibility. A direct assertion is appropriate when mismatch represents a programmer invariant and panic is intentional.
3. Remember that an interface containing a typed nil pointer is itself non-nil.
4. Nil maps can be read but panic on writes; initialize before a write path that may see nil.
5. `append` may reuse a backing array, so reason explicitly about aliasing when slices escape or are shared.
6. Return defensive copies when callers must not mutate internal state; avoid copies when sharing/mutation is part of the contract.
7. `defer` runs when the surrounding function returns, not at each loop iteration.
8. Integer conversions can truncate/wrap; validate bounds when the source value is not already constrained.
9. Floating-point equality depends on domain semantics; use tolerances, exact integer/fixed-point units, or `math/big` as the problem requires.
10. Favor useful zero values and deliberate initialization. Use `sync.Once` only when exactly-once concurrent initialization is actually needed.

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
// Choose tolerance from the domain/scale; one global epsilon is rarely universal.
diff := math.Abs(got - want)
ok := diff <= absTol || diff <= relTol*math.Max(math.Abs(got), math.Abs(want))
```

### Division by zero

Integer division by zero panics. Float division produces `+Inf`/`-Inf`/`NaN`. Guard when zero is possible from the API/input domain; a redundant check is unnecessary when an invariant already proves nonzero.

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
