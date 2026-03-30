# samber/lo — Functional Utilities

Lodash-inspired, generics-first utility library with 500+ type-safe helpers. Zero dependencies. Immutable by default.

- [github.com/samber/lo](https://github.com/samber/lo)
- [pkg.go.dev/github.com/samber/lo](https://pkg.go.dev/github.com/samber/lo)

## Package Selection

| Package | Import alias | Use when | Go version |
| --- | --- | --- | --- |
| `lo` (core) | `lo` | Default for all transforms | 1.18+ |
| `lo/parallel` | `lop` | CPU-bound work on 1000+ items | 1.18+ |
| `lo/mutable` | `lom` | Hot path confirmed by pprof | 1.18+ |
| `lo/it` | `loi` | Chained transforms on large data (lazy) | 1.23+ |
| `lo/exp/simd` | — | Numeric bulk ops (experimental) | 1.25+ |

**Key rules:**
- `lop` is for CPU parallelism, NOT I/O — use `errgroup` for I/O fan-out
- `lom` breaks immutability — only when allocation pressure is measured
- `loi` eliminates intermediate allocations in chains like `Map → Filter → Take`
- Prefer stdlib when available: `slices.Contains`, `slices.Sort`, `maps.Keys` (Go 1.21+)

## Core Functions

| Function | What it does |
| --- | --- |
| `lo.Map` | Transform each element |
| `lo.Filter` / `lo.Reject` | Keep / remove matching elements |
| `lo.Reduce` | Fold into single value |
| `lo.ForEach` | Side-effect iteration |
| `lo.GroupBy` | Group by key |
| `lo.Chunk` | Split into fixed-size batches |
| `lo.Flatten` | Flatten nested slices |
| `lo.Uniq` / `lo.UniqBy` | Remove duplicates |
| `lo.Find` / `lo.FindOrElse` | First match or default |
| `lo.Contains` / `lo.Every` / `lo.Some` | Membership tests |
| `lo.Keys` / `lo.Values` | Map key/value extraction |
| `lo.PickBy` / `lo.OmitBy` | Filter map entries |
| `lo.Zip2` / `lo.Unzip2` | Pair/unpair slices |
| `lo.Ternary` / `lo.If` | Inline conditionals |
| `lo.ToPtr` / `lo.FromPtr` | Pointer helpers |
| `lo.Must` / `lo.Try` | Panic-on-error / recover-as-bool |
| `lo.MapErr` / `lo.FilterErr` | Error-aware variants |

## Core Patterns

```go
// Transform
names := lo.Map(users, func(u User, _ int) string { return u.Name })

// Filter + Reduce
total := lo.Reduce(
    lo.Filter(orders, func(o Order, _ int) bool { return o.Status == "paid" }),
    func(sum float64, o Order, _ int) float64 { return sum + o.Amount },
    0,
)

// GroupBy
byStatus := lo.GroupBy(tasks, func(t Task, _ int) string { return t.Status })

// Error variant — stops on first error
results, err := lo.MapErr(urls, func(url string, _ int) (Response, error) {
    return http.Get(url)
})
```

## Best Practices

1. **Prefer stdlib when available** — `slices.Contains`, `slices.Sort` carry no dependency
2. **Compose lo functions** — chain `Filter → Map → GroupBy` instead of nested loops
3. **Profile before optimizing** — switch to `lom`/`lop` only after pprof confirms bottleneck
4. **Use error variants** — `lo.MapErr` over manual error collection
5. **`lo.Must` only in tests and init** — panics in production code

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `lo.Contains` when `slices.Contains` exists | Prefer stdlib |
| `lop.Map` on 10 items | Use `lo.Map` — goroutine overhead exceeds benefit |
| Assuming `lo.Filter` mutates input | `lo` is immutable — returns new slice |
| `lo.Must` in request handlers | Handle errors explicitly |
| Many eager chains on large data | Use `loi` for lazy evaluation |
