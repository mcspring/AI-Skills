---
name: rust-expert
description: Write, review, and modernize idiomatic Rust. Use for ownership, error handling, async/concurrency, unsafe code, APIs, performance, testing, Cargo, and project structure.
license: MIT
---

# Rust Expert

Favor safe, explicit, idiomatic Rust and the project's existing ecosystem. Optimize for clarity first; optimize memory/layout/runtime only with evidence.

## Start Here

1. Check `Cargo.toml` for edition, MSRV/rust-version, enabled features, runtime choices, and workspace lints.
2. Load only the references relevant to the task.
3. Preserve public API and MSRV unless the user asks to change them.
4. Prefer std/core capabilities before adding crates.

Current stable release line: Rust 1.99 (latest patch: [1.99.1](https://blog.rust-lang.org/2026/10/15/Rust-1.99.1/) as of 2026-10-23). Rust 2024 is the current edition, but existing crates may intentionally target older editions or MSRVs.

## Core Guidance

- Ownership: borrow when it expresses the lifetime naturally; clone when ownership semantics justify the cost. Avoid lifetime cleverness that makes APIs harder to use.
- Errors: use `Result` for recoverable failures, preserve useful context, and choose typed library errors versus application-level aggregation according to the project.
- Types/APIs: make invalid states difficult to represent, use newtypes/enums where they clarify invariants, and keep public APIs evolution-friendly.
- Concurrency: prefer structured ownership of tasks and state; choose threads, async runtimes, channels, locks, or atomics based on workload rather than defaulting to one runtime.
- Unsafe: keep unsafe blocks small, document invariants, and expose safe abstractions around them.
- Async: avoid blocking executors and holding synchronous guards across `.await`; use the runtime already selected by the project unless there is a concrete reason to change it.
- Performance: measure with benchmarks/profiles before introducing allocation tricks, custom containers, inlining, LTO, PGO, or layout changes.
- Testing/tooling: use `cargo fmt`, Clippy, tests, doctests, and targeted property/fuzz tests where they add confidence.

## Modern Rust Notes

For projects that can target recent stable Rust, consider Rust 2024 semantics and newer stable language/library features such as let chains, `if let` guards, and `cfg_select!` when they simplify code. New compiler features are options, not migration goals by themselves.

## Reference Router

| Need | Reference |
|---|---|
| Ownership/borrowing | `references/ownership.md` |
| Error handling | `references/error-handling.md` |
| Safety/concurrency | `references/safety-concurrency.md` |
| Memory/layout | `references/memory.md` |
| API/type design | `references/api-design.md` |
| Async | `references/async.md` |
| Performance | `references/performance.md` |
| Naming/docs | `references/naming-docs.md` |
| Testing | `references/testing.md` |
| Cargo/project tooling | `references/project-tooling.md` |
| Edition/MSRV/version modernization | `references/modernization.md` |

## Verification

Run the narrowest relevant checks first, then expand: `cargo fmt --check`, `cargo check`, `cargo clippy`, `cargo test`, plus sanitizer/Miri/fuzz/bench workflows when the task justifies them.