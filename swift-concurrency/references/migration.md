# Swift 6 Concurrency Migration

Use this reference for project-wide migration strategy and compiler diagnostics. Detailed semantics live in `actors.md`, `sendable.md`, `tasks.md`, and `threading.md`.

## Before Changing Code

Record the settings that affect diagnostics:

- Swift language mode and compiler version.
- Deployment targets.
- Strict concurrency checking level.
- Default actor isolation.
- Enabled upcoming features.
- Dependency modules that are not yet concurrency-safe.

Do not infer language mode from `swift-tools-version` alone.

## Migration Order

1. Build the existing project and capture diagnostics.
2. Update dependencies that already publish concurrency-safe APIs.
3. Migrate one module or feature boundary at a time.
4. Fix ownership/isolation before adding escape hatches.
5. Add `Sendable` only when the value actually crosses isolation domains.
6. Enable stricter language/concurrency modes after local issues are understood.
7. Build and test after each category of change.

Avoid architecture rewrites during compiler migration unless the existing boundary is the cause of the error.

## Diagnostic Routing

| Diagnostic shape | First question | Reference |
|---|---|---|
| actor-isolated member from nonisolated context | Which actor should own this operation? | `actors.md` |
| non-Sendable value crossing boundary | Can the value remain isolated or become a Sendable representation? | `sendable.md` |
| task/cancellation/lifetime issue | Who owns this task and how does it end? | `tasks.md` |
| execution behavior differs by Swift mode | Which isolation/upcoming features are active? | `threading.md` |
| callback-to-async bridge | Can completion happen exactly once and preserve cancellation? | `async-await-basics.md` |
| tests fail or become flaky | Is the test asserting behavior or scheduler timing? | `testing.md` |

## Compatibility Tools

### `@preconcurrency`

Use at an import or conformance boundary when consuming code whose concurrency annotations lag reality. Treat it as migration debt: document why it is safe and remove it when the dependency catches up.

### `@unchecked Sendable`

Use only when synchronization or immutability already guarantees safety but the compiler cannot prove it. Document the invariant next to the conformance. See `sendable.md`.

### Unsafe nonisolation

`nonisolated(unsafe)` or similar escape hatches suppress compiler protection. Prefer redesigning the ownership boundary; use only with an explicit invariant and focused tests.

## Default Actor Isolation

Newer Swift toolchains can change default isolation behavior. Before adding `@MainActor` or `nonisolated`, inspect the target's actual default. UI-heavy application targets may intentionally use main-actor defaults while libraries often remain nonisolated.

Do not copy migration advice between targets without checking settings.

## Approachable Concurrency

Swift 6.2+ introduced language modes/features that reduce accidental executor hopping and make isolation defaults easier to reason about. Swift 6.4 builds on this model. Prefer the project's active behavior rather than manually emulating older execution assumptions.

See `threading.md` for `nonisolated`, `@concurrent`, and isolation inheritance.

## Swift 6.4 Notes

Swift 6.4 adds concurrency-relevant capabilities including:

- `await` inside `defer`, useful for asynchronous cleanup.
- `withTaskCancellationShield`, which protects essential cleanup from inherited cancellation.
- broader Swift Testing interoperability and tooling improvements.

Adopt these only when the project's compiler/toolchain supports them. Task ownership, cancellation, and cleanup patterns belong in `tasks.md` rather than being duplicated here.

## Callback Migration

When replacing callbacks with async APIs:

- Preserve whether completion is one-shot or streaming.
- Resume checked continuations exactly once.
- Preserve cancellation when the underlying operation supports it.
- Preserve ordering and actor requirements.
- Use `AsyncSequence` for multi-value streams rather than forcing them into a one-shot continuation.

See `async-await-basics.md` and `async-sequences.md`.

## Combine / Rx Migration

Do not mechanically replace every publisher with `AsyncSequence`.

Choose based on semantics:

- one result → async function;
- sequence of values → `AsyncSequence` / `AsyncStream`;
- state observed by SwiftUI → Observation where appropriate;
- rich operator graph already maintained by a reactive framework → keep it unless migration has clear value.

For debounce/merge/combine operators, see `async-algorithms.md`.

## Notifications

Prefer typed, concurrency-safe notification APIs when the deployment target and framework provide them. Keep notification-specific details out of migration strategy; the key rule is to preserve isolation and lifetime of observers/streams.

## Linting

A linter warning is not a reason to add fake `await`, actor hops, or annotations.

- Remove unnecessary `async` when the signature does not require it.
- Keep `async` when required by a protocol/override/API contract.
- Suppress narrowly when a tool cannot model a valid language pattern.
- Prefer compiler diagnostics over style-lint heuristics for concurrency safety.

## Verification Loop

After each migration step:

1. Rebuild the affected target.
2. Run focused tests.
3. Check cancellation and lifetime behavior for long-lived tasks.
4. Run the broader suite before changing language mode or default isolation.
5. Use Instruments/runtime diagnostics for performance claims.

## Avoid

- adding `@MainActor` everywhere to silence diagnostics;
- marking whole object graphs `@unchecked Sendable`;
- wrapping synchronous work in unstructured `Task` merely to satisfy isolation;
- assuming Swift 6.2, 6.3, and 6.4 use identical project settings;
- mixing migration with unrelated architectural modernization.
