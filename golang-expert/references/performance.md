# Performance

## Core Philosophy

1. **Profile before optimizing** — intuition about bottlenecks is wrong ~80% of the time
2. **Allocation reduction yields the biggest ROI** — Go's GC is fast but not free
3. **Document optimizations** — add comments explaining why, with benchmark numbers

## Rule Out External Bottlenecks First

Before optimizing Go code, verify the bottleneck is in your process:
- `fgprof` — captures on-CPU and off-CPU time; if off-CPU dominates, bottleneck is external
- `go tool pprof` (goroutine profile) — many goroutines in `net.Read` = external wait
- Distributed tracing — span breakdown shows which upstream is slow

## Iterative Methodology

1. **Define metric** — latency, throughput, memory, or CPU?
2. **Benchmark** — `go test -bench=BenchmarkX -benchmem -count=6 ./... | tee /tmp/report-1.txt`
3. **Diagnose** — pprof CPU, heap, goroutine, mutex profiles
4. **Improve** — ONE optimization at a time with explanatory comment
5. **Compare** — `benchstat /tmp/report-1.txt /tmp/report-2.txt`
6. **Repeat**

## Decision Tree

| Bottleneck | Signal (pprof) | Action |
| --- | --- | --- |
| Too many allocations | `alloc_objects` high | Reduce allocations: prealloc, sync.Pool, avoid format! |
| CPU-bound hot loop | CPU profile dominant | Inlining, cache locality, avoid reflection |
| GC pauses / OOM | High GC%, container limits | Set GOMEMLIMIT, reduce live heap |
| Network / I/O latency | Goroutines blocked | Optimize upstream, connection pools, caching |
| Repeated expensive work | Same computation | Singleflight, memoization, compiled patterns |
| Lock contention | Mutex/block profile hot | Reduce critical section, shard, atomics |

## Memory Optimization

- **Preallocate**: `make([]T, 0, n)` when size known
- **sync.Pool**: reuse temporary objects; always `Reset()` before `Put()`
- **Avoid `format!()`** in hot paths — allocates even when log level disabled
- **Struct alignment**: order fields large-to-small to reduce padding
- **`strings.Builder`**: for concatenation in loops
- **`slices.Clone`**: when you need a copy, not shared backing array

## CPU Optimization

- Iterators over manual indexing — avoids bounds checks
- Use `slog.LogAttrs` in hot loops — `slog.Info` prevents inlining
- Avoid `reflect.DeepEqual` (50–200x slower) — use typed comparison
- `unsafe` only with benchmark proof of >10% improvement

## Runtime Tuning

- **GOMEMLIMIT**: Set to 80–90% of container memory to prevent OOM kills
- **GOGC**: Default 100. Lower = more frequent GC, less memory. Higher = less GC, more memory
- **GOMAXPROCS**: Defaults to CPU count. In containers, use `go.uber.org/automaxprocs`
- **PGO**: Profile-guided optimization (Go 1.21+) — 2–7% improvement

## I/O & Networking

- `http.Transport.MaxIdleConnsPerHost` defaults to 2 — set to match concurrency
- Stream large responses — don't buffer entire body
- Use `json.NewDecoder`/`json.NewEncoder` for streaming JSON
- Batch DB operations — reduce round trips

## Caching

- `sync.Once` / `sync.OnceValue` — one-time init
- `singleflight` — deduplicate concurrent identical requests
- Compiled regex at package level — `regexp.MustCompile`
- Precomputed lookup tables

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Optimizing without profiling | Profile with pprof first |
| Default `http.Client` Transport | Set `MaxIdleConnsPerHost` |
| Logging in hot loops | Use `slog.LogAttrs` |
| `panic`/`recover` as control flow | Error returns |
| `unsafe` without benchmark | Only with >10% proven improvement |
| No GC tuning in containers | Set `GOMEMLIMIT` |
| `reflect.DeepEqual` in production | `slices.Equal`, `maps.Equal` |
