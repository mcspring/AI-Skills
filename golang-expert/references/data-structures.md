# Data Structures

Built-in and standard library data structures: internals, correct usage, and selection guidance.

## Core Rules

1. **Preallocate slices and maps** with `make(T, 0, n)` / `make(map[K]V, n)` when size is known — avoids repeated growth copies and rehashing
2. **Arrays** only for fixed, compile-time-known sizes (hash digests, IPv4, matrix dimensions)
3. **NEVER rely on slice capacity growth timing** — the algorithm changes between Go versions
4. **`container/heap`** for priority queues, **`container/list`** only for frequent middle insertions, **`container/ring`** for circular buffers
5. **`strings.Builder`** for building strings; **`bytes.Buffer`** for bidirectional I/O
6. Generic data structures SHOULD use the **tightest constraint** — `comparable` for keys, `cmp.Ordered` for sorting
7. **`unsafe.Pointer`** MUST only follow the 6 valid spec patterns — NEVER store as `uintptr` across statements
8. **`weak.Pointer[T]`** (Go 1.24+) for caches and canonicalization maps

## Slice Internals

A slice is a 3-word header: pointer, length, capacity. Multiple slices can share a backing array.

### Capacity Growth

- < 256 elements: capacity doubles
- ≥ 256 elements: grows by ~25% (`newcap += (newcap + 3*256) / 4`)
- Each growth copies the entire backing array — O(n)

### Preallocation

```go
// Exact size known
users := make([]User, 0, len(ids))

// Approximate size known
results := make([]Result, 0, estimatedCount)

// Pre-grow before bulk append (Go 1.21+)
s = slices.Grow(s, additionalNeeded)
```

### slices Package (Go 1.21+)

Key functions: `Sort`/`SortFunc`, `BinarySearch`, `Contains`, `Compact`, `Grow`, `Clone`, `Equal`, `DeleteFunc`.

## Map Internals

Hash tables with 8-entry buckets and overflow chains. Reference types — assigning copies the pointer, not the data. Maps never shrink — use `maps.Clone` to create a right-sized copy when needed.

### Preallocation

```go
m := make(map[string]*User, len(users)) // avoids rehashing
```

### maps Package (Go 1.21+)

| Function | Purpose |
| --- | --- |
| `Collect` (1.23+) | Build map from iterator |
| `Insert` (1.23+) | Insert entries from iterator |
| `All` (1.23+) | Iterator over all entries |
| `Keys`, `Values` | Iterators over keys/values |
| `Clone`, `Equal` | Deep copy, comparison |

## Arrays

Fixed-size, value types. Copied entirely on assignment:

```go
type Digest [32]byte           // fixed-size, value type
var grid [3][3]int             // multi-dimensional
cache := map[[2]int]Result{}   // comparable — usable as map keys
```

Prefer slices for everything else.

## container/ Standard Library

| Package | Data Structure | Best For |
| --- | --- | --- |
| `container/list` | Doubly-linked list | LRU caches, frequent middle insertion |
| `container/heap` | Min-heap (priority queue) | Top-K, scheduling, Dijkstra |
| `container/ring` | Circular buffer | Rolling windows, round-robin |
| `bufio` | Buffered reader/writer | Efficient I/O with small reads/writes |

Container types use `any` — consider generic wrappers for type safety.

## strings.Builder vs bytes.Buffer

| | `strings.Builder` | `bytes.Buffer` |
| --- | --- | --- |
| Purpose | String concatenation | Bidirectional I/O |
| `String()` | Zero-copy | Copies bytes |
| Implements | `io.Writer` | `io.Reader` + `io.Writer` |
| Preallocate | `Grow(n)` | `Grow(n)` |

## Generic Collections (Go 1.18+)

Use the tightest constraint:

```go
type Set[T comparable] map[T]struct{}

func (s Set[T]) Add(v T)          { s[v] = struct{}{} }
func (s Set[T]) Contains(v T) bool { _, ok := s[v]; return ok }
```

## Pointer Types

| Type | Use Case | Notes |
| --- | --- | --- |
| `*T` | Normal indirection, mutation, optional values | Zero value: `nil` |
| `unsafe.Pointer` | FFI, low-level memory layout | 6 valid spec patterns only |
| `weak.Pointer[T]` (1.24+) | Caches, canonicalization | Allows GC to reclaim |

## Copy Semantics

| Type | Copy Behavior | Independence |
| --- | --- | --- |
| `int`, `float`, `bool`, `string` | Value (deep) | Fully independent |
| `array`, `struct` | Value (deep) | Fully independent |
| `slice` | Header copied, backing shared | Use `slices.Clone` |
| `map` | Reference copied | Use `maps.Clone` |
| `channel` | Reference copied | Same channel |
| `*T` | Address copied | Same underlying value |

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Growing slice in loop without prealloc | `make([]T, 0, n)` or `slices.Grow` |
| `container/list` when slice suffices | Poor cache locality; benchmark first |
| `bytes.Buffer` for pure string building | `strings.Builder` avoids copy on `String()` |
| `unsafe.Pointer` stored as `uintptr` | GC can move object — dangling reference |
| Large struct values in maps | Use `map[K]*V` to avoid copy overhead |
| Not preallocating maps | `make(map[K]V, n)` avoids rehashing |
