# Project Structure & Tooling

Organize Rust projects for clarity. Use Clippy and rustfmt for consistent quality.

## Project Layout

```
my_project/
├── Cargo.toml
├── src/
│   ├── main.rs        # minimal — parse args, call lib
│   ├── lib.rs         # all business logic
│   ├── config.rs      # organize by feature
│   ├── server/
│   │   ├── mod.rs
│   │   ├── handler.rs
│   │   └── middleware.rs
│   └── bin/
│       ├── cli.rs     # additional binaries
│       └── worker.rs
├── tests/
│   └── integration.rs # integration tests
└── benches/
    └── benchmark.rs   # criterion benchmarks
```

## Key Rules

1. **`main.rs` minimal, logic in `lib.rs`** — enables integration testing and library reuse
2. **Organize by feature, not type** — `server/`, `auth/`, not `models/`, `handlers/`
3. **Keep small projects flat** — one `lib.rs` is fine until 500+ lines
4. **`pub(crate)` for internal APIs** — expose only what's needed
5. **`pub(super)` for parent-only** — restrict to parent module
6. **`pub use` for clean public API** — re-export from `lib.rs`
7. **`prelude` module** for common imports
8. **Workspaces for large projects** — share dependencies, unified CI

## Visibility

```rust
pub fn external_api() { ... }        // visible to all
pub(crate) fn internal_api() { ... } // visible within crate
pub(super) fn parent_only() { ... }  // visible to parent module
fn private() { ... }                  // module-only

// Re-export for clean public API
pub use self::config::AppConfig;
pub use self::server::Server;
```

## Workspaces

```toml
# Cargo.toml (root)
[workspace]
members = ["crates/*"]

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }

[workspace.lints.clippy]
correctness = { level = "deny" }
suspicious = { level = "warn" }
style = { level = "warn" }
```

```toml
# crates/my-lib/Cargo.toml
[dependencies]
tokio = { workspace = true }
serde = { workspace = true }

[lints]
workspace = true
```

## Clippy Configuration

```rust
// lib.rs or main.rs
#![deny(clippy::correctness)]          // must fix — actual bugs
#![warn(clippy::suspicious)]           // likely bugs
#![warn(clippy::style)]                // idiomatic style
#![warn(clippy::complexity)]           // unnecessary complexity
#![warn(clippy::perf)]                 // performance issues
#![warn(missing_docs)]                 // enforce documentation
#![warn(clippy::undocumented_unsafe_blocks)]  // require // SAFETY: comments
```

### Pedantic — Enable Selectively

```rust
#![warn(clippy::pedantic)]
#![allow(clippy::module_name_repetitions)]  // too noisy for most projects
#![allow(clippy::must_use_candidate)]       // too many false positives
```

## CI Essentials

```yaml
# GitHub Actions
- run: cargo fmt --check          # formatting
- run: cargo clippy -- -D warnings  # linting
- run: cargo test                 # unit + integration + doc tests
- run: cargo test -- --ignored    # slow/integration tests
```

For published crates, also add `#![warn(clippy::cargo)]` to check `Cargo.toml` metadata.

## Cargo.toml Metadata

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2024"
description = "Short, compelling description"
license = "MIT"
repository = "https://github.com/user/repo"
keywords = ["keyword1", "keyword2"]
categories = ["category"]
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| All logic in `main.rs` | Move to `lib.rs` — testable and reusable |
| `pub` on everything | `pub(crate)` for internal APIs |
| Modules organized by type | Organize by feature/domain |
| No workspace for multi-crate | `[workspace]` with dependency inheritance |
| Clippy not in CI | `cargo clippy -- -D warnings` |
| No `rustfmt` in CI | `cargo fmt --check` |
| Inconsistent lint config | Workspace-level `[lints]` |
