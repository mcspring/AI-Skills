# Swift Concurrency Execution Model

Use this reference when reasoning about where async code executes, isolation inheritance, `nonisolated`, `@concurrent`, or why thread-based debugging is misleading.

## Think in Isolation Domains

Swift concurrency schedules tasks on executors. Actor isolation determines which executor owns protected work; it does not promise a permanent OS thread.

For correctness, ask:

- Which actor/isolation domain owns this state?
- Does this operation inherit caller isolation or cross a boundary?
- Where can suspension occur?
- Is any synchronous work blocking an executor for too long?

Do not use `Thread.current` as the primary concurrency model.

## Suspension Is Not a Thread Hop Contract

`await` means the current task may suspend. It does not mean “dispatch to a background thread,” and resumption need not occur on the same underlying thread.

An async function can execute substantial synchronous work before its first suspension. Keep expensive CPU or blocking I/O out of latency-sensitive actor executors.

## Actor Isolation

Actor-isolated code executes through that actor's executor. `@MainActor` represents main-actor ownership and is appropriate for UI/main-actor state.

Crossing actor boundaries can suspend. Within the same isolation domain, the compiler/runtime may avoid unnecessary executor hops.

See `actors.md` for ownership and reentrancy.

## `Task {}`

An ordinary task can inherit actor context from where it is created. Creating `Task {}` inside main-actor code does not automatically move the work off the main actor.

Use a task to establish asynchronous lifetime, not as a generic “background thread” API.

## `Task.detached`

A detached task intentionally separates work from surrounding task/actor context. That also weakens structured cancellation, priority, and isolation inheritance.

Use only when this independence is required. Captures must be safe to transfer.

## `nonisolated`

`nonisolated` removes actor isolation from a declaration when it does not need isolated state.

Its execution semantics depend on the active Swift language mode and concurrency features. Do not copy advice based solely on a historical Swift version; inspect project settings.

## `@concurrent`

Use `@concurrent` when an async operation intentionally needs concurrent execution separate from caller isolation under toolchains that support it.

It is not a synonym for “make this faster.” Use it for a real execution/ownership requirement, especially CPU work that should not monopolize a caller actor.

## Approachable Concurrency

Swift 6.2 introduced the modern approachable-concurrency model and related default-isolation behavior; Swift 6.4 continues this model.

The practical rule is version-aware rather than version-hardcoded:

1. inspect language mode/default isolation/upcoming features;
2. reason from the actual caller and declaration isolation;
3. choose `nonisolated` or `@concurrent` only when the semantic boundary requires it.

## Blocking Work

Avoid blocking waits, semaphores, and synchronous I/O in async code when they can occupy scarce executor threads.

For CPU-heavy work, choose an explicit concurrent execution boundary. For blocking legacy APIs, isolate/block them in an integration layer rather than spreading blocking calls through actor code.

## Main Actor

Main actor protects UI state; it should not become an application-wide serialization queue.

Keep main-actor critical sections focused on UI/state coordination. Prepare expensive values elsewhere when safe, then apply compact state changes on the main actor.

## Custom Executors

Use custom executors for real integration requirements such as affinity with an existing event loop/queue or specialized scheduling. They are advanced infrastructure, not a standard optimization.

## Debugging

Prefer:

- compiler isolation diagnostics;
- task/actor views in Instruments;
- signposts around expensive operations;
- actor/task names where supported;
- runtime concurrency diagnostics.

Thread IDs are useful for low-level investigation but should not drive source-level correctness assumptions.

## Common Failures

- assuming async means background;
- wrapping heavy work in `Task {}` while still inheriting the busy actor;
- using `Task.detached` to silence isolation errors;
- dispatching manually to queues while also using actor isolation, creating two competing ownership models;
- adding `MainActor.run` hops without deciding who should own the state;
- relying on pre-Swift-6.2 execution folklore without checking project settings.

## Verification

Build with the target's real concurrency settings. Use Instruments to confirm actor/executor behavior when performance matters, and test invariants rather than asserting exact thread identities.
