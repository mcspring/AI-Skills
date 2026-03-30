---
name: rust-expert
description: >
  Comprehensive Rust coding guidelines across 10 categories. Use when writing,
  reviewing, or refactoring Rust code. Covers ownership, error handling, safety,
  concurrency, memory optimization, API design, async patterns, performance,
  testing, and project structure. Invoke with /rust-expert.
license: MIT
metadata:
  version: "2.0.0"
  sources:
    - Rust API Guidelines
    - Rust Performance Book
    - Rust 圣经 (course.rs)
    - The Rustonomicon
    - ripgrep, tokio, serde, polars codebases
---

# Rust Best Practices

Comprehensive guide for writing high-quality, idiomatic, and highly optimized Rust code. Organized into 10 categories, prioritized by impact.

## When to Apply

Reference these guidelines when:
- Writing new Rust functions, structs, or modules
- Implementing error handling or async code
- Designing public APIs for libraries
- Reviewing code for ownership/borrowing issues
- Writing concurrent or unsafe code
- Optimizing memory usage or reducing allocations
- Tuning performance for hot paths
- Refactoring existing Rust code

## Categories by Priority

| Priority | Category | Impact | Reference |
|----------|----------|--------|-----------|
| 1 | Ownership & Borrowing | CRITICAL | [ownership.md](references/ownership.md) |
| 2 | Error Handling | CRITICAL | [error-handling.md](references/error-handling.md) |
| 3 | Safety & Concurrency | CRITICAL | [safety-concurrency.md](references/safety-concurrency.md) |
| 4 | Memory Optimization | HIGH | [memory.md](references/memory.md) |
| 5 | API Design & Type Safety | HIGH | [api-design.md](references/api-design.md) |
| 6 | Async/Await | HIGH | [async.md](references/async.md) |
| 7 | Performance & Compiler | MEDIUM | [performance.md](references/performance.md) |
| 8 | Naming & Documentation | MEDIUM | [naming-docs.md](references/naming-docs.md) |
| 9 | Testing | MEDIUM | [testing.md](references/testing.md) |
| 10 | Project & Tooling | LOW | [project-tooling.md](references/project-tooling.md) |

---

## Quick Reference

### 1. Ownership & Borrowing (CRITICAL)

- Prefer `&T` borrowing over `.clone()` — cloning is explicit cost
- Accept `&[T]` not `&Vec<T>`, `&str` not `&String` — borrow the slice
- Use `Cow<'a, T>` for conditional ownership — clone only when needed
- `Arc<T>` for thread-safe sharing; `Rc<T>` for single-threaded
- `RefCell<T>` for single-thread interior mutability; `Mutex<T>` for multi-thread
- Derive `Copy` for small trivial types; make `Clone` explicit
- Move large data instead of cloning; rely on lifetime elision when possible
- `RwLock<T>` when reads dominate writes

### 2. Error Handling (CRITICAL)

- `thiserror` for library error types; `anyhow` for application errors
- Return `Result`, don't panic on expected errors
- Add context with `.context()` / `.with_context()`
- Never `.unwrap()` in production; `.expect()` only for programming errors
- Use `?` for clean error propagation; `#[from]` for auto-conversion
- `#[source]` chains underlying errors; messages: lowercase, no punctuation
- Document errors with `# Errors` section; create custom types over `Box<dyn Error>`

### 3. Safety & Concurrency (CRITICAL)

- `Send` = ownership can move across threads; `Sync` = `&T` can be shared across threads
- Most types auto-derive Send/Sync; manual impl is `unsafe` — avoid unless necessary
- `Rc` → `Arc`, `RefCell` → `Mutex`/`RwLock`, `Cell` → `AtomicXxx` for thread safety
- Wrap `unsafe` in safe abstractions; keep `unsafe` blocks minimal
- 5 unsafe superpowers: raw pointer deref, unsafe fn, static mut, unsafe trait impl, union access
- Never hold `MutexGuard` across `.await` — use scoping or Tokio's async Mutex
- Compiler prevents data races; race conditions need application-level handling
- Handle `Mutex` poisoning — `.lock().unwrap()` panics if holder panicked

### 4. Memory Optimization (HIGH)

- `with_capacity()` when size is known; `SmallVec` for usually-small collections
- `ArrayVec` for bounded-size; `Box<[T]>` instead of `Vec<T>` when fixed
- Box large enum variants to reduce type size; `ThinVec` for often-empty vectors
- `clone_from()` to reuse allocations; `clear()` + reuse in loops
- Avoid `format!()` when literals work; `write!()` over `format!()`
- Arena allocators for batch allocations; zero-copy with slices and `Bytes`
- `CompactString` for small string optimization; smallest integer type that fits
- Assert hot type sizes to prevent regressions

### 5. API Design & Type Safety (HIGH)

- Builder pattern for complex construction; `#[must_use]` on builders and Results
- Newtypes for type-safe IDs and validated data; typestate for compile-time state machines
- Sealed traits prevent external impl; extension traits add methods to foreign types
- Parse at boundaries, don't validate — make illegal states unrepresentable
- `impl Into<T>` for flexible inputs; `impl AsRef<T>` for borrowed inputs
- `From` not `Into` (auto-derived); `Default` for sensible defaults
- `Debug`, `Clone`, `PartialEq` eagerly; gate `Serialize`/`Deserialize` behind feature
- `#[non_exhaustive]` for future-proof enums; `PhantomData<T>` for type markers
- Use enums for mutually exclusive states; `#[repr(transparent)]` for FFI newtypes

### 6. Async/Await (HIGH)

- Tokio for production async runtime; never hold locks across `.await`
- `spawn_blocking` for CPU-intensive work; `tokio::fs` not `std::fs`
- `CancellationToken` for graceful shutdown; `tokio::join!` for parallel ops
- `tokio::try_join!` for fallible parallel; `tokio::select!` for racing/timeouts
- Bounded channels for backpressure; `mpsc` for work queues
- `broadcast` for pub/sub; `watch` for latest-value; `oneshot` for request/response
- `JoinSet` for dynamic task groups; clone data before await, release locks

### 7. Performance & Compiler (MEDIUM)

- Profile before optimizing — `cargo flamegraph`, `criterion`
- Iterators over indexing — avoids bounds checks, enables fusion
- Keep iterators lazy; `collect()` only when needed; `entry()` for map ops
- `drain()` to reuse allocations; `extend()` for batch insertions
- `#[inline]` for small hot functions; `#[cold]` for error paths
- LTO + `codegen-units = 1` in release; PGO for production builds
- `target-cpu=native` for local; portable SIMD for data-parallel ops
- Cache-friendly SoA layouts; `black_box()` in benchmarks

### 8. Naming & Documentation (MEDIUM)

- `UpperCamelCase` types/traits; `snake_case` functions; `SCREAMING_SNAKE_CASE` constants
- `as_` (free ref), `to_` (expensive), `into_` (ownership); no `get_` prefix
- `is_`/`has_`/`can_` for booleans; `iter`/`iter_mut`/`into_iter` for iterators
- Acronyms as words: `Uuid` not `UUID`; crate names: no `-rs` suffix
- Document all public items with `///`; `//!` for module-level
- `# Examples` with runnable code; `# Errors`, `# Panics`, `# Safety` sections
- `?` in doc examples, not `.unwrap()`; intra-doc links: `[Vec]`

### 9. Testing (MEDIUM)

- `#[cfg(test)] mod tests` with `use super::*;`
- Integration tests in `tests/`; descriptive names; arrange/act/assert
- `proptest` for property-based; `mockall` for trait mocking
- Traits for dependencies enable mocking; RAII (`Drop`) for test cleanup
- `#[tokio::test]` for async; `#[should_panic]` for panic tests
- `criterion` for benchmarks; doc examples as executable tests

### 10. Project & Tooling (LOW)

- `main.rs` minimal, logic in `lib.rs`; organize modules by feature
- `pub(crate)` for internal APIs; `pub use` for clean public API
- `prelude` module for common imports; workspaces for large projects
- `#![deny(clippy::correctness)]`; `#![warn(clippy::suspicious, style, complexity, perf)]`
- `#![warn(missing_docs)]`; pedantic selectively; workspace-level lints
- `cargo fmt --check` in CI; `clippy::cargo` for published crates

---

## Recommended Cargo.toml Settings

```toml
[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"
strip = true

[profile.bench]
inherits = "release"
debug = true
strip = false

[profile.dev]
opt-level = 0
debug = true

[profile.dev.package."*"]
opt-level = 3  # Optimize dependencies in dev
```

---

## Category Selection by Task

| Task | Primary Categories |
|------|-------------------|
| New function | Ownership, Error Handling, Naming |
| New struct/API | API Design, Naming, Documentation |
| Async code | Async, Safety & Concurrency |
| Error handling | Error Handling, API Design |
| Concurrent / unsafe code | Safety & Concurrency, Ownership |
| Memory optimization | Memory, Performance |
| Performance tuning | Performance, Memory |
| Code review | Safety, Naming, Testing |
| New project setup | Project & Tooling |

---

## Sources

- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Rust Design Patterns](https://rust-unofficial.github.io/patterns/)
- [Rust 圣经](https://course.rs/) — Send/Sync, unsafe, concurrency
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/) — unsafe Rust
- Production codebases: ripgrep, tokio, serde, polars, axum, deno
