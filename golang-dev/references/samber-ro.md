# samber/ro — Reactive Streams

ReactiveX for Go. Generics-first, type-safe, composable pipelines for async data streams. 150+ operators, 5 subject types, 40+ plugins.

- [github.com/samber/ro](https://github.com/samber/ro)
- [pkg.go.dev/github.com/samber/ro](https://pkg.go.dev/github.com/samber/ro)

## When to Use ro vs lo

| Scenario | Tool | Why |
| --- | --- | --- |
| Transform a finite slice | `samber/lo` | Synchronous, eager, no stream overhead |
| Simple goroutine fan-out | `errgroup` | Lightweight, sufficient for bounded concurrency |
| Infinite event stream | `samber/ro` | Backpressure, retry, timeout, combine |
| Multiple async sources | `samber/ro` | CombineLatest/Zip without manual select |
| Pub/sub with shared source | `samber/ro` | Hot observables handle multicast |

## Core Concepts

1. **Observable** — emits values over time. Cold by default (each subscriber gets independent execution)
2. **Observer** — consumes: `onNext(T)`, `onError(error)`, `onComplete()`
3. **Operator** — transforms observable → observable, chained via `Pipe`
4. **Subscription** — `.Wait()` to block, `.Unsubscribe()` to cancel

```go
observable := ro.Pipe2(
    ro.RangeWithInterval(0, 5, 1*time.Second),
    ro.Filter(func(x int) bool { return x%2 == 0 }),
    ro.Map(func(x int) string { return fmt.Sprintf("even-%d", x) }),
)

observable.Subscribe(ro.NewObserver(
    func(s string) { fmt.Println(s) },
    func(err error) { log.Println(err) },
    func() { fmt.Println("Done!") },
))

// Or collect synchronously:
values, err := ro.Collect(observable)
```

## Cold vs Hot

| | Cold (default) | Hot |
| --- | --- | --- |
| Execution | Per subscriber | Shared |
| Use when | Default, predictable | Expensive source, multicast |
| Convert | — | `Share()`, `ShareReplay(n)`, `Connectable()` |

### Subject Types

| Subject | Replay | Use case |
| --- | --- | --- |
| `PublishSubject` | None | Real-time events |
| `BehaviorSubject` | Last value | Current state + updates |
| `ReplaySubject` | Last N values | Late subscribers need history |
| `AsyncSubject` | Last value on complete | Single final result |
| `UnicastSubject` | All (single subscriber) | Dedicated consumer |

## Operator Quick Reference

| Category | Key operators |
| --- | --- |
| Creation | `Just`, `FromSlice`, `FromChannel`, `Range`, `Interval`, `Defer`, `Future` |
| Transform | `Map`, `MapErr`, `FlatMap`, `Scan`, `Reduce`, `GroupBy` |
| Filter | `Filter`, `Take`, `TakeLast`, `Skip`, `Distinct`, `First`, `Last` |
| Combine | `Merge`, `Concat`, `Zip2`–`Zip6`, `CombineLatest2`–`CombineLatest5`, `Race` |
| Error | `Catch`, `OnErrorReturn`, `OnErrorResumeNextWith`, `Retry`, `RetryWithConfig` |
| Timing | `Delay`, `Timeout`, `ThrottleTime`, `SampleTime`, `BufferWithTime` |
| Side effect | `Tap`/`Do`, `TapOnNext`, `TapOnError`, `TapOnComplete` |
| Terminal | `Collect`, `ToSlice`, `ToChannel`, `ToMap` |

Use typed `Pipe2`–`Pipe25` for compile-time type safety.

## Plugin Ecosystem (40+)

| Category | Plugins |
| --- | --- |
| Encoding | JSON, CSV, Base64, Gob |
| Network | HTTP, I/O, FSNotify |
| Scheduling | Cron, ICS |
| Observability | Zap, Slog, Zerolog, Sentry |
| Rate limiting | Native, Ulule |
| Data | Bytes, Strings, Sort, Regexp |
| System | Process, Signal |

## Best Practices

1. **Always handle all 3 events** — `NewObserver(onNext, onError, onComplete)`. Unhandled errors = silent data loss
2. **`Collect()` for synchronous consumption** — blocks until complete, returns `[]T`
3. **Typed Pipe functions** — `Pipe2`–`Pipe25` catch type mismatches at compile time
4. **Bound infinite streams** — `Take(n)`, `TakeUntil`, `Timeout`, or context cancellation
5. **`Tap`/`Do` for observability** — log/trace without altering the stream
6. **Prefer `lo` for simple transforms** — use `ro` only when data arrives over time

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `ro.OnNext()` without error handler | Silent error loss — use `NewObserver` with all 3 |
| Untyped `Pipe()` | Loses type safety — use `Pipe2`–`Pipe25` |
| No `Unsubscribe()` on infinite streams | Goroutine leak — use `TakeUntil` or context |
| `Share()` when cold is sufficient | Unnecessary complexity |
| `ro` for finite slice transforms | Use `lo` — simpler and faster |
| Missing context propagation | Streams ignore shutdown — chain `ContextWithTimeout` |
