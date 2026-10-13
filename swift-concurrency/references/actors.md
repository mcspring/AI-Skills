# Actors and Isolation

Use this reference for actor ownership, `@MainActor`, global actors, isolated parameters, reentrancy, and choosing actors versus locks.

## Mental Model

An actor protects mutable state by serializing access through its isolation domain. Correctness comes from ownership/isolation, not from assuming a particular thread.

Crossing an actor boundary may require `await` because the caller can suspend before the actor runs the operation.

## `@MainActor`

Use `@MainActor` when the state or operation is genuinely owned by the UI/main actor.

Good fits:

- UI-facing observable state;
- APIs that require main-actor access;
- coordination whose invariant is explicitly tied to main-actor serialization.

Do not add `@MainActor` merely to silence a Sendable/isolation error. That can hide an incorrect boundary and serialize unrelated work.

## Custom Global Actors

A custom global actor is useful when many otherwise unrelated types share one logical serialization domain. Avoid introducing one just to create a convenient queue-like abstraction.

## `isolated` Parameters

Use an isolated actor parameter when a function should execute in the caller-supplied actor's isolation domain and perform multiple synchronous accesses without repeated hops.

This can be clearer than moving a helper into the actor type when the helper conceptually belongs elsewhere.

## `nonisolated`

Mark a member `nonisolated` only when it does not depend on actor-isolated mutable state.

Typical examples:

- immutable metadata;
- protocol requirements that are safe without actor state;
- pure helpers.

Do not use `nonisolated` to bypass ownership rules.

## Protocol Conformance

Before changing isolation to satisfy a protocol, ask whether the protocol requirement itself should run on the actor.

Modern Swift supports isolated conformances in situations where the conformance is intentionally bound to a global actor. Prefer that over making unsafe members nonisolated.

## Isolated Deinitialization

Recent Swift versions support actor-isolated deinitialization patterns. Use them when cleanup genuinely must access isolated state during teardown. Keep heavy or fallible cleanup out of `deinit` when an explicit lifetime API would be clearer.

## Reentrancy

Actors are serial but reentrant: when an actor-isolated function suspends, other work can enter the actor before the original function resumes.

Therefore, state read before `await` may no longer be valid after it.

Mitigations:

- validate state again after suspension;
- perform state mutation before suspension when semantics allow;
- split operations into explicit phases;
- pass immutable snapshots to nonisolated work;
- avoid holding conceptual transactions open across arbitrary suspension points.

## Tasks Created from Actor Context

`Task {}` can inherit actor context. Do not assume creating a task automatically moves work off the actor.

If work is CPU-heavy or intentionally concurrent, choose an API/execution boundary based on the active Swift language mode. See `threading.md`.

## Custom Executors

Use custom executors only when integration/performance requirements justify controlling where actor jobs execute. They add operational complexity and should not be a default architecture choice.

## Actor vs Lock

Choose an actor when:

- async callers naturally cross the boundary;
- state has a clear asynchronous owner;
- serialization should participate in Swift isolation checking.

Choose a lock/mutex when:

- access is short and synchronous;
- the protected state must be used from synchronous code;
- introducing suspension would make the API worse.

Never hold a synchronous lock across an `await`.

## `MainActor.assumeIsolated`

Use only when an external runtime guarantee proves execution is on the main actor but the compiler cannot see it. It is an assertion, not a hop to the main actor.

## Common Failures

- blanket `@MainActor` annotations;
- reading state, awaiting, then committing based on stale assumptions;
- adding actors around immutable data;
- using `nonisolated` as an escape hatch;
- assuming actor = dedicated thread;
- replacing a cheap synchronous lock with async actor hops without benefit.

## Verification

Test invariants across suspension points, cancellation, concurrent callers, and teardown. For performance concerns, inspect actor contention and executor activity with Instruments rather than counting `await` syntactically.
