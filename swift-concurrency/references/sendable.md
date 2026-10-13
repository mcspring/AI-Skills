# Sendable and Isolation Transfer

Use this reference when values cross actor/task boundaries or the compiler reports potential data races.

## Core Idea

`Sendable` expresses that a value can safely cross concurrency isolation domains. It is not a marker for “thread-safe enough” and should not be added solely to silence diagnostics.

Before adding conformance, ask whether the value needs to cross the boundary at all.

## Prefer These in Order

1. Keep the value inside one isolation domain.
2. Transfer an immutable value representation.
3. Make the type structurally `Sendable` when its members support that safely.
4. Put mutable shared state behind an actor/lock and transfer only safe handles or snapshots.
5. Use `@unchecked Sendable` only when an external invariant proves safety.

## Value Types

Structs and enums are natural Sendable candidates when all stored payloads are Sendable and mutation is not shared across isolation domains.

Public/frozen/generic types may need explicit constraints because the compiler cannot infer safety across all clients.

Copy-on-write does not automatically make every wrapper safe: the implementation still has to preserve value semantics under concurrent use.

## Reference Types

A class is safe to send only when its mutation model is safe across domains.

Common safe designs:

- immutable final class whose stored values are Sendable;
- globally/actor-isolated class where mutation remains behind that isolation;
- internally synchronized class with a documented invariant.

Do not declare an ordinary mutable class `Sendable` because accesses “usually happen on one queue.”

## `@Sendable` Closures

A `@Sendable` closure must capture values safely for transfer.

If a mutable local capture causes a diagnostic, prefer:

- immutable snapshots;
- moving state behind an actor/lock;
- redesigning the closure boundary.

Avoid papering over mutable captures with unsafe annotations.

## Region-Based Isolation and `sending`

Modern Swift can prove some transfers safe without requiring a globally Sendable type when ownership moves between isolated regions.

Treat `sending` and region-based isolation as ownership-transfer tools: after transfer, the original isolation domain must not continue using the transferred value in ways that violate the compiler's model.

Prefer these language-supported transfers over broad `@unchecked Sendable` when they model the actual lifetime.

## `@unchecked Sendable`

Use only when all of these are true:

- the type genuinely crosses isolation domains;
- the implementation already guarantees safe access through immutability or synchronization;
- the compiler cannot express/prove that guarantee;
- the invariant is documented next to the conformance;
- focused tests exercise concurrent access where practical.

If the safety story depends on callers remembering an undocumented rule, the type is not a good `@unchecked Sendable` candidate.

## Global State

Global mutable state should have an explicit owner:

- global actor;
- actor instance;
- lock-protected storage;
- immutable Sendable value.

`nonisolated(unsafe)` suppresses checking and should be a last-resort compatibility bridge, not a design pattern.

## Locks and Sendability

A lock-protected class can be Sendable if every access to mutable state consistently uses the same synchronization invariant. Never expose references that let callers bypass the lock.

Do not hold synchronous locks across suspension points.

## Common Diagnostics

### “Sending ... risks causing data races”

Find the boundary being crossed. Prefer moving a safe snapshot or keeping the original object isolated.

### Captured mutable variable in concurrently executing code

Replace shared mutable capture with immutable input, actor-owned state, or another explicit synchronization boundary.

### Protocol/conformance isolation mismatch

Do not solve this by weakening isolation first. Determine whether the conformance itself should be isolated; see `actors.md`.

## Avoid

- mass-adding `Sendable` during migration;
- `@unchecked Sendable` around framework objects with unknown mutation semantics;
- assuming value type means automatically race-safe;
- using locks inconsistently across methods;
- treating compiler diagnostics as false positives before identifying the transfer boundary.

## Verification

Compile in the project's real concurrency mode, test concurrent callers where the invariant matters, and use Thread Sanitizer/runtime diagnostics when legacy synchronization remains involved.
