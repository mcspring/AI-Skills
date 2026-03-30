# Testing

Rust's built-in test framework is powerful. Use it with `proptest` for property-based testing, `mockall` for mocking, and `criterion` for benchmarks.

## Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_valid_input() {
        // Arrange
        let input = "42";

        // Act
        let result = parse(input);

        // Assert
        assert_eq!(result.unwrap(), 42);
    }

    #[test]
    #[should_panic(expected = "out of bounds")]
    fn panics_on_invalid_index() {
        get_item(&[], 0);
    }
}
```

**Structure**: `#[cfg(test)] mod tests` with `use super::*;`. Follow arrange/act/assert.

## Descriptive Names

```rust
#[test]
fn user_with_expired_token_gets_unauthorized() { ... }

#[test]
fn empty_input_returns_default_config() { ... }
```

Use `snake_case` that reads as a behavior specification.

## Integration Tests

Place in `tests/` directory — each file is a separate crate:

```
src/lib.rs
tests/
  integration_test.rs
  common/
    mod.rs       # shared helpers
```

## Async Tests

```rust
#[tokio::test]
async fn fetches_user_from_database() {
    let pool = setup_test_db().await;
    let user = get_user(&pool, "alice").await.unwrap();
    assert_eq!(user.name, "Alice");
}
```

## Property-Based Testing

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn parse_roundtrip(s in "[a-zA-Z0-9]+") {
        let parsed = parse(&s).unwrap();
        let serialized = parsed.to_string();
        assert_eq!(s, serialized);
    }
}
```

## Mocking with mockall

```rust
// Define trait for dependency
pub trait Database {
    fn get_user(&self, id: u64) -> Option<User>;
}

#[cfg(test)]
mod tests {
    use mockall::mock;
    use super::*;

    mock! {
        pub Db {}
        impl Database for Db {
            fn get_user(&self, id: u64) -> Option<User>;
        }
    }

    #[test]
    fn returns_none_for_missing_user() {
        let mut db = MockDb::new();
        db.expect_get_user()
            .with(eq(42))
            .returning(|_| None);

        let result = find_user(&db, 42);
        assert!(result.is_none());
    }
}
```

**Key principle**: Use traits for dependencies — enables mocking without runtime cost.

## Test Cleanup with RAII

```rust
struct TempDir(PathBuf);

impl TempDir {
    fn new() -> Self {
        let path = std::env::temp_dir().join(uuid::Uuid::new_v4().to_string());
        std::fs::create_dir_all(&path).unwrap();
        Self(path)
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        std::fs::remove_dir_all(&self.0).ok();
    }
}
```

## Doc Tests

```rust
/// Adds two numbers.
///
/// ```
/// assert_eq!(my_crate::add(2, 3), 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 { a + b }
```

Doc examples run with `cargo test` — keep them correct and current.

## Benchmarking with criterion

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench(c: &mut Criterion) {
    c.bench_function("sort_vec", |b| {
        b.iter(|| {
            let mut v = black_box(vec![3, 1, 2]);
            v.sort();
        })
    });
}

criterion_group!(benches, bench);
criterion_main!(benches);
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Tests without `#[cfg(test)]` | Compile-time gated test module |
| Meaningless test names | Describe behavior: `empty_input_returns_error` |
| No cleanup for temp files | RAII with `Drop` |
| Mocking without traits | Define trait interfaces for dependencies |
| Missing property-based tests | `proptest` for roundtrip and invariant testing |
| Benchmarks without `black_box` | Use `black_box` to prevent dead code elimination |
