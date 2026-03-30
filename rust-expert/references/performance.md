# Performance & Compiler Optimization

Profile before optimizing. Combine idiomatic iterator patterns with compiler hints to achieve maximum throughput.

## Methodology

1. **Profile first** — `cargo flamegraph`, `perf`, or `samply`
2. **Benchmark** — `criterion` for statistical rigor
3. **Diagnose** — identify hot path (CPU? allocation? I/O?)
4. **Optimize** — apply the right pattern
5. **Compare** — benchmark before vs after

## Iterator Patterns

```rust
// ✓ Iterator — no bounds checks, enables SIMD fusion
let sum: i32 = items.iter().filter(|x| x.is_valid()).map(|x| x.value).sum();

// ✗ Manual indexing — bounds checks on every access
let mut sum = 0;
for i in 0..items.len() {
    if items[i].is_valid() { sum += items[i].value; }
}
```

**Rules:**
- Prefer iterators over manual indexing — avoids bounds checks
- Keep iterators lazy — `collect()` only at the end
- Don't `collect()` intermediate iterators — chain operations
- Use `entry()` API for map insert-or-update
- `drain()` to reuse allocations; `extend()` for batch insertions
- Avoid `chain()` in hot loops — may inhibit optimization

## Compiler Hints

| Annotation | Effect | Use when |
| --- | --- | --- |
| `#[inline]` | Suggest inlining | Small functions called from other crates |
| `#[inline(always)]` | Force inlining | Profiling proves benefit (rare) |
| `#[inline(never)]` | Prevent inlining | Cold error paths, reduce code size |
| `#[cold]` | Mark as unlikely | Error handling, panic paths |
| `likely()`/`unlikely()` | Branch prediction hints | Hot conditionals with skewed probability |

```rust
#[cold]
#[inline(never)]
fn handle_error(e: Error) -> ! {
    eprintln!("fatal: {e}");
    std::process::exit(1);
}
```

## Release Profile

```toml
[profile.release]
opt-level = 3          # maximum optimization
lto = "fat"            # link-time optimization across all crates
codegen-units = 1      # single codegen unit for max LLVM optimization
panic = "abort"        # smaller binary, no unwind tables
strip = true           # remove debug symbols

[profile.bench]
inherits = "release"
debug = true           # flamegraph needs debug info
strip = false
```

## Advanced Optimization

- **PGO (Profile-Guided Optimization)** — compile, profile on real workload, recompile
- **`target-cpu=native`** — use all local CPU features (not portable)
- **Portable SIMD** — `std::simd` for data-parallel operations
- **SoA (Struct of Arrays)** — cache-friendly layout for hot data

```rust
// AoS — poor cache locality for single-field access
struct Particle { x: f32, y: f32, z: f32, mass: f32 }
let particles: Vec<Particle> = ...;

// SoA — excellent cache locality
struct Particles { x: Vec<f32>, y: Vec<f32>, z: Vec<f32>, mass: Vec<f32> }
```

## Benchmarking

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_sort(c: &mut Criterion) {
    c.bench_function("sort_1000", |b| {
        b.iter(|| {
            let mut data = black_box(generate_data(1000));
            data.sort();
        })
    });
}

criterion_group!(benches, bench_sort);
criterion_main!(benches);
```

Use `black_box()` to prevent the compiler from optimizing away benchmark code.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Optimizing without profiling | `cargo flamegraph` first |
| Manual indexing in hot loops | Iterators avoid bounds checks |
| `collect()` between iterator steps | Chain operations, collect once |
| `#[inline(always)]` everywhere | Profile to prove benefit |
| `format!()` in hot path | `write!()` into reused buffer |
| Missing `lto` in release | `lto = "fat"` for max optimization |
