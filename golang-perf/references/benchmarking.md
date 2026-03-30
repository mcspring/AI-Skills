# Benchmarking & Profiling

Performance improvement does not exist without measurement — if you can measure it, you can improve it.

## Writing Benchmarks

### b.Loop() (Go 1.24+) — preferred

Prevents compiler dead code elimination and auto-excludes setup from timing:

```go
func BenchmarkParse(b *testing.B) {
    data := loadFixture("large.json") // setup — excluded from timing
    for b.Loop() {
        Parse(data)  // compiler cannot eliminate this
    }
}
```

Existing `for range b.N` benchmarks still work but should migrate to `b.Loop()`.

### Memory tracking

```go
func BenchmarkAlloc(b *testing.B) {
    b.ReportAllocs() // or run with -benchmem flag
    for b.Loop() {
        _ = make([]byte, 1024)
    }
}

// Custom metrics
b.ReportMetric(float64(totalBytes)/b.Elapsed().Seconds(), "bytes/s")
```

### Sub-benchmarks

```go
func BenchmarkEncode(b *testing.B) {
    for _, size := range []int{64, 256, 4096} {
        b.Run(fmt.Sprintf("size=%d", size), func(b *testing.B) {
            data := make([]byte, size)
            for b.Loop() {
                Encode(data)
            }
        })
    }
}
```

## Running Benchmarks

```bash
go test -bench=BenchmarkEncode -benchmem -count=10 ./pkg/... | tee bench.txt
```

| Flag | Purpose |
| --- | --- |
| `-bench=.` | Run all benchmarks (regexp) |
| `-benchmem` | Report allocations (B/op, allocs/op) |
| `-count=10` | Run 10 times for statistical significance |
| `-benchtime=3s` | Minimum time per benchmark |
| `-cpu=1,2,4` | Run with different GOMAXPROCS |
| `-cpuprofile=cpu.prof` | Write CPU profile |
| `-memprofile=mem.prof` | Write memory profile |
| `-trace=trace.out` | Write execution trace |

**Output**: `BenchmarkEncode/size=64-8  5000000  230.5 ns/op  128 B/op  2 allocs/op`

## Profiling from Benchmarks

```bash
# CPU profile
go test -bench=BenchmarkParse -cpuprofile=cpu.prof ./pkg/parser
go tool pprof cpu.prof

# Memory profile
go test -bench=BenchmarkParse -memprofile=mem.prof ./pkg/parser
go tool pprof -alloc_objects mem.prof  # GC churn
go tool pprof -inuse_space mem.prof    # leaks

# Execution trace
go test -bench=BenchmarkParse -trace=trace.out ./pkg/parser
go tool trace trace.out
```

## Statistical Comparison with benchstat

Never eyeball single runs. Always compare with statistical rigor:

```bash
# Before optimization
go test -bench=BenchmarkParse -benchmem -count=10 ./... | tee /tmp/report-1.txt

# After optimization
go test -bench=BenchmarkParse -benchmem -count=10 ./... | tee /tmp/report-2.txt

# Compare
benchstat /tmp/report-1.txt /tmp/report-2.txt
```

A change is meaningful only when benchstat shows a low p-value (< 0.05).

## pprof Profile Types

| Profile | Purpose | Key metric |
| --- | --- | --- |
| CPU | Where CPU time goes | Flat vs cumulative time |
| Heap (alloc_objects) | GC churn | Allocation count |
| Heap (inuse_space) | Memory leaks | Live heap size |
| Goroutine | Hanging goroutines | Stack traces of blocked goroutines |
| Mutex | Lock contention | Mutex wait time |
| Block | Blocking operations | Channel/IO wait time |

### pprof Commands

```bash
go tool pprof cpu.prof
(pprof) top 20           # top functions by CPU
(pprof) list FuncName    # source-level annotation
(pprof) web              # flamegraph in browser
(pprof) disasm FuncName  # assembly view
```

## CI Regression Detection

| Tool | Use case |
| --- | --- |
| `benchdiff` | Quick PR comparison |
| `cob` | Strict threshold-based gating |
| `gobenchdata` | Long-term trend dashboards |

Cloud CI benchmarks vary 5–10% — use self-hosted runners for reproducible results.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Single benchmark run | `-count=10` minimum, compare with benchstat |
| `for range b.N` without sink | Migrate to `b.Loop()` (Go 1.24+) |
| Setup code inside benchmark loop | Move before `b.Loop()` or use `b.ResetTimer()` |
| Eyeballing ns/op diffs | Use `benchstat` for statistical significance |
| Profiling without benchmarks | Generate profiles from benchmark runs |
| Ignoring alloc_objects | Allocation count matters more than bytes for GC |
