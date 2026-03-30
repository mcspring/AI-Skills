# Safety & Concurrency

Rust prevents data races at compile time through the ownership system, `Send`/`Sync` traits, and the borrow checker. `unsafe` grants 5 additional powers — but the programmer must uphold all safety invariants.

## Send & Sync

Two marker traits that form the foundation of Rust's thread safety:

| Trait | Meaning | Example |
| --- | --- | --- |
| `Send` | Ownership can be transferred across threads | `String`, `Vec<T>`, `Arc<T>` |
| `Sync` | `&T` can be shared across threads | `i32`, `Mutex<T>`, `Arc<T>` |
| `!Send` | Cannot be moved to another thread | `Rc<T>`, `*const T` |
| `!Sync` | `&T` cannot be shared across threads | `Cell<T>`, `RefCell<T>`, `Rc<T>` |

**Key insight:** `T: Sync` ⟺ `&T: Send`. If a reference to T can cross threads, T is Sync.

### Auto-derivation

- Most primitive types (`i32`, `bool`, `String`) are both Send and Sync
- Structs/enums are Send/Sync if **all fields** are Send/Sync
- Manual `unsafe impl Send/Sync` is almost never needed — avoid unless FFI requires it

### Thread-Safe Type Mapping

| Single-threaded | Multi-threaded | Why |
| --- | --- | --- |
| `Rc<T>` | `Arc<T>` | Atomic reference counting |
| `RefCell<T>` | `Mutex<T>` | Lock-based interior mutability |
| `RefCell<T>` (read-heavy) | `RwLock<T>` | Multiple readers, exclusive writer |
| `Cell<T>` | `AtomicBool`, `AtomicUsize`, ... | Lock-free atomic operations |

## unsafe — The 5 Superpowers

`unsafe` does NOT disable the borrow checker. It grants exactly 5 additional abilities:

1. **Dereference raw pointers** (`*const T`, `*mut T`)
2. **Call unsafe functions or methods**
3. **Access or modify mutable static variables** (`static mut`)
4. **Implement unsafe traits** (e.g., manual `Send`/`Sync`)
5. **Access union fields**

### Best Practices for unsafe

```rust
// ✓ Good — unsafe wrapped in safe abstraction
pub fn split_at_mut(slice: &mut [i32], mid: usize) -> (&mut [i32], &mut [i32]) {
    assert!(mid <= slice.len()); // safety check BEFORE unsafe
    unsafe {
        let ptr = slice.as_mut_ptr();
        (
            std::slice::from_raw_parts_mut(ptr, mid),
            std::slice::from_raw_parts_mut(ptr.add(mid), slice.len() - mid),
        )
    }
}

// ✗ Bad — unsafe leaking out
pub unsafe fn do_something(ptr: *mut i32) { ... }  // caller burden
```

**Rules:**
- Keep `unsafe` blocks **as small as possible**
- Wrap unsafe in **safe public APIs** — callers shouldn't need `unsafe`
- Document `# Safety` section for all `unsafe fn`
- Every `unsafe` block MUST have a `// SAFETY:` comment explaining the invariant
- Use `#![warn(clippy::undocumented_unsafe_blocks)]`

## Concurrency Patterns

### Shared State with Arc + Mutex

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0));
let mut handles = vec![];

for _ in 0..10 {
    let counter = Arc::clone(&counter);
    handles.push(thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    }));
}

for h in handles { h.join().unwrap(); }
```

### Message Passing with Channels

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();
thread::spawn(move || { tx.send(42).unwrap(); });
let received = rx.recv().unwrap();
```

### Scoped Threads (std::thread::scope)

```rust
let data = vec![1, 2, 3];
std::thread::scope(|s| {
    s.spawn(|| println!("{data:?}")); // borrows data — no Arc needed
});
```

## Mutex Poisoning

When a thread panics while holding a `MutexGuard`, the Mutex becomes "poisoned":

```rust
// Propagate the panic (default behavior)
let data = mutex.lock().unwrap();

// Or recover from poisoning
let data = mutex.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
```

## Data Race vs Race Condition

| | Data Race | Race Condition |
| --- | --- | --- |
| Definition | Concurrent unsynchronized access with at least one write | Logic depends on timing/ordering |
| Rust prevention | **Compile-time** (ownership + Send/Sync) | **Not prevented** — application logic |
| Example | Two threads writing `Vec` simultaneously | Two threads checking-then-updating a counter |
| Fix | Compiler rejects the code | Use atomic ops, locks, or channels |

## Atomics

```rust
use std::sync::atomic::{AtomicUsize, Ordering};

static COUNTER: AtomicUsize = AtomicUsize::new(0);

COUNTER.fetch_add(1, Ordering::SeqCst);
let val = COUNTER.load(Ordering::SeqCst);
```

| Ordering | Guarantee | Use when |
| --- | --- | --- |
| `Relaxed` | No ordering guarantee | Counters where order doesn't matter |
| `Acquire`/`Release` | Happens-before relationship | Producer-consumer patterns |
| `SeqCst` | Total order across all threads | When in doubt (slightly slower) |

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `Rc<T>` across threads | Use `Arc<T>` |
| `RefCell<T>` across threads | Use `Mutex<T>` or `RwLock<T>` |
| Holding `MutexGuard` across `.await` | Scope the guard or use `tokio::sync::Mutex` |
| `unsafe impl Send` without proof | Only when all invariants are manually verified |
| Large `unsafe` blocks | Split into smallest possible scope |
| Missing `// SAFETY:` comment | Document every unsafe block's invariant |
| `static mut` without synchronization | Use `AtomicXxx` or `Mutex` |
| Ignoring Mutex poisoning | Handle `PoisonError` explicitly |
| Manual `Send`/`Sync` impl | Almost never needed — let auto-derive handle it |
