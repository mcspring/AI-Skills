# Ownership & Borrowing

Rust's ownership system ensures memory safety without a garbage collector. Every value has exactly one owner; when the owner goes out of scope, the value is dropped.

## Core Rules

1. **Prefer `&T` borrowing over `.clone()`** — cloning is an explicit cost; borrow when you only need to read
2. **Accept `&[T]` not `&Vec<T>`, `&str` not `&String`** — borrow the slice, not the container
3. **Use `Cow<'a, T>` for conditional ownership** — clone only when mutation is actually needed
4. **`Arc<T>` for thread-safe shared ownership** — atomic reference counting for cross-thread sharing
5. **`Rc<T>` for single-threaded sharing** — cheaper than Arc, no atomic overhead
6. **`RefCell<T>` for single-thread interior mutability** — runtime borrow checking
7. **`Mutex<T>` for multi-thread interior mutability** — lock-based protection
8. **`RwLock<T>` when reads dominate writes** — multiple readers, exclusive writer
9. **Derive `Copy` for small, trivial types** — implicit bitwise copy (< 64 bytes, no heap)
10. **Make `Clone` explicit** — `.clone()` signals intentional allocation
11. **Move large data instead of cloning** — transfer ownership to avoid duplication
12. **Rely on lifetime elision when possible** — let the compiler infer lifetimes

## Smart Pointer Selection

| Type | Thread-safe | Interior mutability | Cost | Use when |
| --- | --- | --- | --- | --- |
| `Box<T>` | Yes (if T: Send) | No | Heap allocation | Single owner, heap-allocated |
| `Rc<T>` | No | No | Reference count | Multiple owners, single-thread |
| `Arc<T>` | Yes | No | Atomic ref count | Multiple owners, multi-thread |
| `RefCell<T>` | No | Yes (runtime checks) | Borrow tracking | Interior mutability, single-thread |
| `Mutex<T>` | Yes | Yes (lock) | Lock contention | Interior mutability, multi-thread |
| `RwLock<T>` | Yes | Yes (lock) | Lock contention | Read-heavy multi-thread |
| `Cell<T>` | No | Yes (copy) | Zero overhead | Copy types, single-thread |

## Cow — Clone-on-Write

```rust
use std::borrow::Cow;

fn process(input: &str) -> Cow<'_, str> {
    if input.contains(' ') {
        Cow::Owned(input.replace(' ', "_"))  // allocates only when needed
    } else {
        Cow::Borrowed(input)  // zero-cost pass-through
    }
}
```

## Lifetime Elision Rules

The compiler infers lifetimes following these rules:
1. Each reference parameter gets its own lifetime
2. If exactly one input lifetime, output gets that lifetime
3. If `&self`/`&mut self`, output gets self's lifetime

When elision doesn't apply, annotate explicitly:

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() > b.len() { a } else { b }
}
```

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `.clone()` to satisfy borrow checker | Restructure code to borrow instead |
| `fn foo(v: &Vec<T>)` | `fn foo(v: &[T])` — accept slice |
| `fn bar(s: &String)` | `fn bar(s: &str)` — accept string slice |
| `Rc<T>` in multi-threaded code | Use `Arc<T>` — Rc is not Send |
| `RefCell<T>` in multi-threaded code | Use `Mutex<T>` or `RwLock<T>` |
| Deriving `Copy` for large structs | Only for small types (< 64 bytes) |
| Unnecessary lifetime annotations | Let elision rules handle it |
| Cloning `Arc<T>` contents instead of Arc | Clone the Arc itself: `Arc::clone(&x)` |
