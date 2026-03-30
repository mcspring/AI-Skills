# Error Handling

Rust makes errors explicit through `Result<T, E>`. Every fallible operation returns a Result — no hidden exceptions.

## Library vs Application Errors

| Context | Crate | Why |
| --- | --- | --- |
| Library | `thiserror` | Derive custom error types with `#[error]`, `#[from]`, `#[source]` |
| Application | `anyhow` | Dynamic error type with `.context()` for rich error chains |

## Core Rules

1. **Return `Result`, don't panic** — `panic!` is for bugs, not expected errors
2. **Use `?` for clean propagation** — replaces verbose `match` chains
3. **Never `.unwrap()` in production** — panics with no context
4. **`.expect()` only for programming errors** — invariants that should never fail
5. **Add context**: `.context("parsing config")` or `.with_context(|| format!(...))`
6. **Error messages: lowercase, no trailing punctuation** — composable in chains
7. **`#[from]` for automatic conversion** — eliminates manual `impl From<E>`
8. **`#[source]` chains underlying errors** — enables `source()` traversal
9. **Document with `# Errors`** — list all error conditions
10. **Custom types over `Box<dyn Error>`** — callers can match on variants

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
