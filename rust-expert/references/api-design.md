# API Design & Type Safety

Leverage Rust's type system to make illegal states unrepresentable. Design APIs that guide users toward correct usage through types, not documentation.

## Builder Pattern

```rust
#[must_use]
pub struct ServerBuilder {
    port: u16,
    max_connections: Option<usize>,
}

impl ServerBuilder {
    pub fn new(port: u16) -> Self { Self { port, max_connections: None } }
    pub fn max_connections(mut self, n: usize) -> Self { self.max_connections = Some(n); self }
    pub fn build(self) -> Result<Server, BuildError> { /* validate and construct */ }
}
```

`#[must_use]` on builder types prevents discarding the builder without calling `.build()`.

## Newtypes

```rust
// ✓ Type-safe IDs
struct UserId(u64);
struct OrderId(u64);

fn get_user(id: UserId) -> User { ... }  // can't pass OrderId by accident

// ✓ Validated data — parse at boundaries
struct Email(String);

impl Email {
    pub fn parse(s: &str) -> Result<Self, ValidationError> {
        if s.contains('@') { Ok(Self(s.to_string())) }
        else { Err(ValidationError::InvalidEmail) }
    }
}
```

## Typestate Pattern

```rust
struct Draft;
struct Published;

struct Post<State> {
    content: String,
    _state: PhantomData<State>,
}

impl Post<Draft> {
    pub fn publish(self) -> Post<Published> { /* transition */ }
}

impl Post<Published> {
    pub fn view(&self) -> &str { &self.content }
}
// Post<Draft> cannot call .view() — compiler enforces state machine
```

## Flexible Input Types

```rust
// Accept broad inputs, convert internally
fn connect(addr: impl Into<SocketAddr>) -> Result<Connection> { ... }
fn read_file(path: impl AsRef<Path>) -> Result<String> { ... }
```

| Accept | When | Cost |
| --- | --- | --- |
| `impl Into<T>` | Caller may own or borrow | May allocate |
| `impl AsRef<T>` | Only need borrowed view | Zero-cost |
| `&str` / `&[T]` | Only need reference | Zero-cost |

## Standard Trait Implementations

Implement eagerly for public types:

| Trait | Why |
| --- | --- |
| `Debug` | Required for error messages and debugging |
| `Clone` | Allows duplication when needed |
| `PartialEq` / `Eq` | Enables comparison and testing |
| `Hash` | Enables use as HashMap key |
| `Default` | Sensible zero-configuration construction |
| `Display` | User-facing string representation |
| `From<T>` | Idiomatic conversions (auto-provides `Into`) |

## Key API Patterns

- **`From` not `Into`** — implement `From`, the compiler provides `Into` for free
- **`#[non_exhaustive]`** on public enums/structs — allows adding variants without breaking changes
- **Sealed traits** — prevent external implementations when needed
- **Extension traits** — add methods to foreign types
- **Gate `Serialize`/`Deserialize` behind features** — avoid forcing serde on all users
- **`PhantomData<T>`** for type-level markers without runtime cost
- **`#[repr(transparent)]`** for FFI-safe newtypes

## Enums for States

```rust
// ✗ Stringly-typed
fn set_status(status: &str) { ... }

// ✓ Type-safe enum
enum Status { Active, Inactive, Suspended }
fn set_status(status: Status) { ... }  // compiler catches typos
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Stringly-typed APIs | Use enums or newtypes |
| Missing `Debug` on public types | Derive `Debug` eagerly |
| `Into` impl instead of `From` | Implement `From` — `Into` is auto-derived |
| Missing `#[must_use]` on Results | Add to all Result-returning functions |
| Exhaustive public enums | `#[non_exhaustive]` for future evolution |
| `Box<dyn Error>` as library error | Custom enum with `thiserror` |
| serde always on | Gate behind `serde` feature flag |
| Accepting `&String` / `&Vec<T>` | Accept `&str` / `&[T]` |
