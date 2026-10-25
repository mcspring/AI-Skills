---
name: swift-concurrency
description: Diagnose and design Swift concurrency code. Use for async/await, tasks, actors, Sendable, isolation, data races, callback migration, Swift 6 migration, and concurrency performance or testing.
---

# Swift Concurrency

Reason from isolation and ownership, not threads. Make the smallest safe change that matches the project's Swift language mode and concurrency settings.

## Start Here

1. Check Swift version/language mode, deployment targets, default actor isolation, strict-concurrency settings, and enabled upcoming features.
2. Capture the exact diagnostic or behavioral failure.
3. Identify the isolation boundary and the value crossing it.
4. Load only the matching reference file.

Current Swift stable line is [6.4](https://www.swift.org/blog/swift-6.4-released/) (released 2026-09-15). Do not assume a project uses its defaults or newest concurrency behavior.

## Core Guidance

- Prefer structured concurrency (`async let`, task groups) over detached or untracked work.
- Use `@MainActor` for genuinely UI/main-actor-owned state, not as a blanket compiler-error fix.
- Keep mutable shared state behind a clear isolation mechanism: actor, global actor, lock, or another deliberately chosen owner.
- Prefer immutable/Sendable values across isolation boundaries.
- Treat `@unchecked Sendable`, `@preconcurrency`, and unsafe isolation escape hatches as compatibility tools that require a documented invariant.
- Preserve cancellation: propagate it through async APIs and check it in long-running work.
- Do not reason about correctness from `Thread.current`; actor isolation and task semantics are the relevant model.
- Avoid blocking waits, semaphores, synchronous I/O, and long CPU work in async executor-bound code.
- Measure task/executor performance with Instruments before restructuring concurrency for speed.

## Common Routing

| Problem | Reference |
|---|---|
| async/await basics and bridging | `references/async-await-basics.md` |
| Task lifetime, groups, cancellation | `references/tasks.md` |
| Actors, global actors, isolation | `references/actors.md` |
| Sendable / region transfer | `references/sendable.md` |
| Execution and threading model | `references/threading.md` |
| AsyncSequence / AsyncStream | `references/async-sequences.md` |
| Async Algorithms | `references/async-algorithms.md` |
| Migration / diagnostics / linting | `references/migration.md` |
| Tests | `references/testing.md` |
| Performance | `references/performance.md` |
| Memory/lifetime | `references/memory-management.md` |
| Core Data | `references/core-data.md` |
| Terminology | `references/glossary.md` |

## Diagnostic Heuristics

- Actor-isolation error: first ask which actor should own the operation; move the caller or data boundary rather than adding arbitrary hops.
- Non-Sendable transfer: keep it isolated, make the transferred representation immutable/Sendable, or redesign the boundary.
- Callback migration: preserve cancellation, ordering, and single-resume guarantees when introducing continuations.
- Background CPU work: use the mechanism appropriate to the project's current Swift version and executor model; do not assume `Task.detached` is required.

## Verification

Build after each isolation-category change, then run concurrency-sensitive tests. Verify cancellation and object lifetime for long-lived tasks; use Instruments or runtime diagnostics for performance and scheduling claims.