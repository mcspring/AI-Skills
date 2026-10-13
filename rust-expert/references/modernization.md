# Rust Modernization

Use this reference when updating an existing crate/workspace to a newer Rust compiler, edition, standard library, or Cargo behavior.

## Start With Compatibility

Record before changing code:

- `rust-version` / MSRV policy;
- edition for each crate;
- stable/beta/nightly requirements;
- feature flags and target platforms;
- public API and serialization/FFI compatibility constraints.

A newer stable compiler is not automatically the project's new MSRV.

## Workflow

1. Build/test on the current MSRV.
2. Update toolchain locally without changing `rust-version` first.
3. Review compiler/Clippy suggestions.
4. Apply behavior-preserving modernizations separately from edition/MSRV bumps.
5. Test supported targets/features.
6. Change MSRV/edition only when project policy allows it.

Use `cargo fix` and Clippy as candidate generators, not as authority for API design.

## Rust 2024 Edition

Rust 2024 is the current edition. Edition migration is designed to be largely machine-assisted, but it can change lint behavior and source interpretation.

Prefer:

```sh
cargo fix --edition
cargo test --workspace --all-features
cargo clippy --workspace --all-targets --all-features
```

Review generated changes, especially around unsafe operations, match ergonomics, temporary lifetimes, and macro behavior relevant to the workspace.

Do not combine an edition migration with unrelated refactors in one reviewable change.

## Rust 1.99

Rust 1.99.0 is the current stable release (2026-10-01).

### C-ABI variadic definitions

Stable Rust can define `extern "C"` and `extern "C-unwind"` variadic functions. This is primarily relevant to FFI/system code.

Treat variadic bodies as unsafe-boundary code:

- document caller ABI/type requirements;
- keep `VaList` access narrow;
- add platform/ABI tests where practical;
- do not introduce C variadics into ordinary Rust APIs.

### Raw-pointer layout APIs

Rust 1.99 stabilizes raw-value layout/size/alignment APIs such as `Layout::for_value_raw`, `size_of_val_raw`, and `align_of_val_raw`.

Use them only where raw-pointer metadata is genuinely required. Their stabilization does not make arbitrary raw-pointer dereference safe.

### `Box::leak` guidance

Current standard-library guidance recommends against “unleaking” memory by reconstructing ownership after `Box::leak`. Prefer ownership-preserving raw/non-null conversion APIs such as `Box::into_raw` or `Box::into_non_null` when memory will later be reclaimed.

Audit older unsafe code that leaks temporarily and reconstructs a box later.

### Newly stabilized library APIs

Rust 1.99 also adds APIs including `Vec::into_parts`/`from_parts`, boxed-array iterator support, `VecDeque::retain_back`, and owned lossy UTF-8 conversion helpers.

Adopt these when they replace bespoke unsafe/helper code or clearly improve intent; do not raise MSRV only for cosmetic use.

## Dependency Modernization

- prefer workspace-wide dependency policies for related crates;
- inspect semver-breaking transitive changes with `cargo tree`;
- test minimal/default/all-feature combinations that matter to published crates;
- avoid broad `cargo update` in a focused code change when lockfile churn obscures review.

For libraries, dependency features and MSRV are part of the user-facing compatibility surface.

## Clippy and Lints

Use workspace-level lint configuration where possible. Prioritize correctness, suspicious code, unsafe invariants, and API misuse over stylistic churn.

Rust 1.99 adds/extends diagnostics around unsafe/raw borrowing and unconditional panic cases. Treat newly surfaced warnings as prompts to inspect the invariant, not merely silence them.

## Unsafe Modernization

When new safe APIs replace older unsafe patterns, prefer the safe API if it preserves semantics and MSRV allows it.

Keep unsafe changes small and verify:

- pointer provenance/lifetime;
- initialization;
- aliasing;
- layout/alignment;
- ownership reconstruction;
- panic/unwind behavior across FFI.

See `safety-concurrency.md` and `memory.md`.

## Verification

Typical sequence:

```sh
cargo fmt --check
cargo check --workspace --all-targets
cargo clippy --workspace --all-targets --all-features
cargo test --workspace --all-features
```

Add Miri, sanitizers, fuzzing, cross-target builds, or benchmarks only when the changed code warrants them.

## Avoid

- bumping MSRV because CI happens to use latest stable;
- edition migration plus architecture refactor in one change;
- applying every Clippy suggestion mechanically;
- replacing clear stable code with a new API only for novelty;
- treating stabilized raw-pointer APIs as a relaxation of unsafe invariants.
