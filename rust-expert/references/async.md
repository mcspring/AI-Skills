# Async/Await

Tokio is the de facto async runtime for production Rust. Async code runs on a thread pool — tasks yield at `.await` points, allowing the runtime to schedule other work.

## Core Rules

1. **Tokio for production** — `#[tokio::main]` or `Runtime::new()`
2. **Never hold `Mutex`/`RwLock` across `.await`** — blocks the entire runtime thread
3. **`spawn_blocking` for CPU-intensive work** — keeps async threads free for I/O
4. **`tokio::fs` not `std::fs`** — std::fs blocks the async thread
5. **`CancellationToken` for graceful shutdown** — cooperative cancellation
6. **`tokio::join!` for parallel operations** — runs futures concurrently
7. **`tokio::try_join!` for fallible parallel** — short-circuits on first error
8. **`tokio::select!` for racing/timeouts** — first-to-complete wins
9. **Clone data before await, release locks** — avoid Send issues

## Channel Selection

| Channel | Pattern | Use when |
| --- | --- | --- |
| `mpsc` (bounded) | N→1 work queue | Backpressure needed, worker pools |
| `mpsc` (unbounded) | N→1 fire-and-forget | Logging, metrics (careful: OOM risk) |
| `broadcast` | N→N pub/sub | Multiple consumers, same events |
| `watch` | 1→N latest-value | Config updates, state changes |
| `oneshot` | 1→1 single response | Request/response, task result |

```rust
// Bounded channel with backpressure
let (tx, mut rx) = tokio::sync::mpsc::channel(100);

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        process(msg).await;
    }
});
```

## Structured Concurrency with JoinSet

```rust
let mut set = tokio::task::JoinSet::new();

for url in urls {
    set.spawn(async move { fetch(url).await });
}

while let Some(result) = set.join_next().await {
    match result {
        Ok(response) => handle(response),
        Err(e) => log::error!("task panicked: {e}"),
    }
}
```

## Graceful Shutdown

```rust
let token = CancellationToken::new();
let child_token = token.child_token();

tokio::spawn(async move {
    tokio::select! {
        _ = child_token.cancelled() => { /* cleanup */ }
        _ = do_work() => {}
    }
});

// On shutdown signal:
token.cancel();
```

## Select with Timeout

```rust
tokio::select! {
    result = operation() => handle(result),
    _ = tokio::time::sleep(Duration::from_secs(5)) => {
        return Err(anyhow!("operation timed out"));
    }
}
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `std::sync::Mutex` across `.await` | Use `tokio::sync::Mutex` or scope the guard |
| `std::fs::read` in async context | `tokio::fs::read` |
| Unbounded channel without backpressure | Use bounded `mpsc::channel(n)` |
| No cancellation support | `CancellationToken` + `select!` |
| `spawn` without `join`/`JoinSet` | Structured concurrency — track all tasks |
| CPU work on async thread | `spawn_blocking` |
| Missing `Send` bounds on spawned futures | Clone data before the async block |
