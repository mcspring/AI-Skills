# Error Handling

Rust makes errors explicit through `Result<T, E>`. Every fallible operation returns a Result — no hidden exceptions.

## Library vs Application Errors

| Context | Crate | Why |
| --- | --- | --- |
| Library | typed errors (optionally `thiserror`) | stable matchable API and sources |
| Application | contextual aggregation (optionally `anyhow`) | convenient error chains at application boundaries |

## Core Rules

1. Return `Result` for recoverable failures; panic for violated invariants or unrecoverable programmer errors.
2. Use `?` when propagation is clearer than an explicit `match`; handle locally when recovery or translation belongs there.
3. Avoid `unwrap()` on input/runtime failure paths. It is reasonable in tests or where a nearby invariant makes failure impossible and that invariant is obvious.
4. Use `expect()` when the message usefully documents such an invariant.
5. Add context at boundaries where it helps diagnose what operation failed; avoid repeating the same context at every layer.
6. Preserve underlying sources when callers or diagnostics benefit from the chain.
7. Use typed errors for library contracts that callers need to inspect; dynamic aggregation can be appropriate in applications.
8. Document public error conditions when they are part of the API contract.

## thiserror (Libraries)

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("config not found: {path}")]
    ConfigNotFound { path: String },

    #[error("parse failed")]
    Parse(#[from] serde_json::Error),

    #[error("database error")]
    Database(#[source] sqlx::Error),
}
```

## anyhow (Applications)

```rust
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let data = std::fs::read_to_string(path)
        .with_context(|| format!("reading config from {path}"))?;
    let config: Config = serde_json::from_str(&data)
        .context("parsing config JSON")?;
    Ok(config)
}
```

## The `?` Operator

```rust
// ✗ Verbose
let file = match File::open(path) {
    Ok(f) => f,
    Err(e) => return Err(e.into()),
};

// ✓ Clean
let file = File::open(path)?;
```

## When to Panic

| Situation | Use |
| --- | --- |
| Invalid user input | `Result` |
| File not found | `Result` |
| Network timeout | `Result` |
| Out-of-bounds index (compile-time known) | `panic!` / `unreachable!` |
| Violated invariant / impossible state | `.expect("invariant: ...")` |
| Test assertions | `unwrap()`, `expect()` |

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `.unwrap()` in production | Use `?` or `.context()` |
| `.expect()` for recoverable errors | Return `Result` |
| `Box<dyn Error>` as library error | Custom enum with `thiserror` |
| Missing error context in chains | `.context()` / `.with_context()` |
| Uppercase error messages | Lowercase, no punctuation |
| Ignoring errors silently | Check every `Result` |
| `panic!` for expected conditions | Return `Err(...)` |
