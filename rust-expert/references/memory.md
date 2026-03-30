# Memory Optimization

Allocation reduction yields the biggest performance ROI in Rust. The allocator is fast but not free — every `Vec`, `String`, and `Box` involves a syscall.

## Core Rules

1. **`with_capacity()`** when size is known or estimable
2. **`SmallVec<[T; N]>`** for usually-small collections (avoids heap for ≤ N items)
3. **`ArrayVec<T, N>`** for bounded-size collections (never allocates)
4. **Box large enum variants** — reduces the size of the entire enum
5. **`Box<[T]>` over `Vec<T>`** when size is fixed after creation
6. **`ThinVec<T>`** for often-empty vectors (1 word vs 3 for Vec)
7. **`clone_from()`** to reuse existing allocations
8. **`clear()` + reuse** collections in loops instead of re-creating
9. **Avoid `format!()`** when string literals or `write!()` work
10. **Arena allocators** (`bumpalo`, `typed-arena`) for batch allocations
11. **Zero-copy** with slices and `bytes::Bytes`
12. **`CompactString`** for small string optimization (inline ≤ 24 bytes)
13. **Smallest integer type** that fits the domain
14. **Assert type sizes** to prevent accidental regressions

## Allocation Avoidance

```rust
// ✗ Allocates every iteration
for item in items {
    let msg = format!("processing {item}"); // heap allocation
    log::info!("{msg}");
}

// ✓ Reuse buffer
let mut buf = String::with_capacity(64);
for item in items {
    buf.clear();
    write!(&mut buf, "processing {item}").unwrap();
    log::info!("{buf}");
}
```

## Collection Reuse

```rust
// ✗ Creates new Vec each iteration
for batch in batches {
    let results: Vec<_> = batch.iter().map(|x| process(x)).collect();
    send(results);
}

// ✓ Reuse allocation
let mut results = Vec::with_capacity(expected_batch_size);
for batch in batches {
    results.clear();
    results.extend(batch.iter().map(|x| process(x)));
    send(&results);
}
```

## Enum Size Optimization

```rust
// ✗ Bad — entire enum is 1024 bytes
enum Message {
    Text(String),
    Binary([u8; 1024]),  // forces all variants to 1024 bytes
}

// ✓ Good — Box the large variant
enum Message {
    Text(String),
    Binary(Box<[u8; 1024]>),  // enum is now ~24 bytes
}
```

## Type Size Assertions

```rust
// Prevent accidental size regressions on hot types
const _: () = assert!(std::mem::size_of::<MyStruct>() <= 64);
```

## SmallVec vs ArrayVec vs Vec

| Type | Heap allocation | Max size | Use when |
| --- | --- | --- | --- |
| `Vec<T>` | Always | Unbounded | General purpose |
| `SmallVec<[T; N]>` | Only if > N | Unbounded | Usually small, occasionally large |
| `ArrayVec<T, N>` | Never | Fixed N | Bounded, stack-only |
| `Box<[T]>` | Once | Fixed | Fixed after creation |
| `ThinVec<T>` | Only if non-empty | Unbounded | Often empty (1-word overhead) |

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `Vec::new()` in hot loop | `Vec::with_capacity(n)` or reuse with `clear()` |
| `format!()` in hot path | `write!()` into reused buffer |
| Large enum variants | `Box` the large variant |
| `Vec<T>` for fixed-size data | `Box<[T]>` after final `collect()` |
| Re-creating collections in loops | `clear()` + `extend()` to reuse |
| No type size assertions | `assert!(size_of::<T>() <= N)` on hot types |
| `String` for small strings | `CompactString` (inline ≤ 24 bytes) |
