# Naming & Documentation

Rust has strong conventions for naming and documentation. Following them makes code feel idiomatic and integrates well with `cargo doc`.

## Naming Conventions

| Item | Convention | Example |
| --- | --- | --- |
| Types, traits, enums | `UpperCamelCase` | `HttpClient`, `Iterator` |
| Enum variants | `UpperCamelCase` | `Status::NotFound` |
| Functions, methods | `snake_case` | `read_to_string()` |
| Modules, crates | `snake_case` | `my_crate`, `mod utils` |
| Constants, statics | `SCREAMING_SNAKE_CASE` | `MAX_CONNECTIONS` |
| Type parameters | Single uppercase | `T`, `E`, `K`, `V` |
| Lifetimes | Short lowercase | `'a`, `'de`, `'src` |

## Method Naming Conventions

| Prefix | Meaning | Cost | Example |
| --- | --- | --- | --- |
| `as_` | Free reference conversion | O(1), no copy | `as_str()`, `as_bytes()` |
| `to_` | Expensive conversion | Allocates | `to_string()`, `to_vec()` |
| `into_` | Ownership transfer | Consumes self | `into_inner()`, `into_bytes()` |
| (no prefix) | Simple getter | O(1) | `len()`, `is_empty()` |
| `is_`/`has_`/`can_` | Boolean query | O(1) | `is_valid()`, `has_key()` |

**No `get_` prefix** for simple getters — `connection.port()` not `connection.get_port()`.

## Iterator Naming

| Method | Returns | Consumes? |
| --- | --- | --- |
| `iter()` | `Iterator<Item = &T>` | No |
| `iter_mut()` | `Iterator<Item = &mut T>` | No |
| `into_iter()` | `Iterator<Item = T>` | Yes |

Iterator type names should match: `fn iter(&self) -> Iter<'_, T>`.

## Other Conventions

- **Acronyms as words**: `Uuid` not `UUID`, `HttpClient` not `HTTPClient`
- **Crate names**: no `-rs` suffix — `serde` not `serde-rs`
- **Conversion traits**: implement `From`, not `Into` (auto-derived)

## Documentation

### Required Sections

```rust
/// Short one-line summary.
///
/// Detailed description with more context.
///
/// # Examples
///
/// ```
/// let result = my_crate::parse("input")?;
/// assert_eq!(result.value, 42);
/// # Ok::<(), my_crate::Error>(())  // hidden setup
/// ```
///
/// # Errors
///
/// Returns `ParseError::InvalidInput` if the input is malformed.
///
/// # Panics
///
/// Panics if `index` is out of bounds.
///
/// # Safety
///
/// The caller must ensure `ptr` is valid and properly aligned.
pub fn parse(input: &str) -> Result<Parsed, ParseError> { ... }
```

| Section | Required when |
| --- | --- |
| `# Examples` | All public items |
| `# Errors` | Functions returning `Result` |
| `# Panics` | Functions that can panic |
| `# Safety` | `unsafe fn` |

### Module Documentation

```rust
//! # My Module
//!
//! This module provides utilities for processing user data.
//! See [`UserProcessor`] for the main entry point.
```

### Best Practices

- **Document all public items** with `///`
- **`?` in doc examples**, not `.unwrap()` — teaches correct error handling
- **Hide setup** with `# ` prefix — keeps examples focused
- **Intra-doc links**: `[Vec]`, `[Self::method]` — auto-resolves across crate
- **Fill `Cargo.toml` metadata** — description, license, repository, keywords
- **Doc examples are tests** — they run with `cargo test`, keep them correct

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `get_foo()` getter | Just `foo()` |
| `UUID` all-caps | `Uuid` — treat as word |
| `.unwrap()` in doc examples | Use `?` with hidden error type |
| Missing `# Errors` section | Document all error conditions |
| No module-level docs | `//!` at top of file |
| Uppercase error messages | Lowercase, no punctuation |
