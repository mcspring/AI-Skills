# Core Data and Swift Concurrency

Use this reference when Core Data contexts, managed objects, actors, or Sendable diagnostics interact.

## Core Rule

`NSManagedObject` instances are tied to their managed-object context and are not general-purpose Sendable values.

Do not pass live managed objects between actors/contexts. Cross boundaries with:

- `NSManagedObjectID`;
- immutable Sendable DTO/value snapshots;
- stable domain identifiers that can be re-fetched in the destination context.

## Context Ownership

Treat each managed-object context as an isolation domain with a clear owner.

Use Core Data's context APIs to perform work on the context's expected executor/queue. Do not access managed object properties from arbitrary tasks because the compiler cannot make Core Data's queue confinement disappear.

## Main-Queue Context

A view context used directly by UI is naturally main-actor adjacent. Keep UI-facing mutations/read observation there when that matches the app architecture.

Do not put expensive import/transform work on the main context just because the final UI update is main-actor owned.

## Background Work

For imports, batch updates, or expensive persistence work:

1. create/use a background context according to the persistent container architecture;
2. pass Sendable input values or object IDs into the operation;
3. fetch/create managed objects inside that context;
4. save there;
5. merge/observe changes through the container/context mechanisms already used by the app.

Never transfer the newly fetched managed object back to another actor as the result. Return an ID or value snapshot.

## `perform` / Async APIs

Use the context's async-capable `perform` APIs where available instead of manually dispatching to queues around Core Data.

Keep the closure focused on context-bound work. Do not suspend arbitrarily while holding assumptions about mutable managed-object state unless the API/context model supports it and you revalidate afterward.

## Actors Around Persistence

An actor can own a persistence service, but it does not make a managed object Sendable.

A good persistence actor/service exposes Sendable inputs/outputs and keeps context/object access internal.

Example API shape:

```swift
actor Store {
    func loadUser(id: UUID) async throws -> UserSnapshot
    func save(_ draft: UserDraft) async throws
}
```

The internal context can be created/used according to Core Data requirements without leaking `NSManagedObject` across the API boundary.

## Custom Executors

Advanced integrations can align actor execution with an existing context/queue using custom executors. Use this only when there is a concrete architecture need and you understand both Core Data confinement and Swift executor semantics.

A simpler service that calls context `perform` is usually easier to maintain.

## SwiftUI

When SwiftUI observes Core Data directly through framework integrations, preserve the framework's lifecycle rather than wrapping each managed object in extra task/actor layers.

For asynchronous work triggered by a view:

- capture stable IDs/value inputs;
- perform persistence work behind the persistence boundary;
- update UI state with returned Sendable values or let Core Data observation publish changes.

## Faults and Snapshots

Reading a managed object's property can fire a fault, so converting to a DTO is context-bound work. Build the snapshot while on the correct context, then transfer the snapshot.

Do not hold a managed object merely as a “read-only DTO”; its relationship/fault behavior still belongs to the context.

## Batch Operations

Batch insert/update/delete APIs can bypass ordinary managed-object lifecycle hooks. Their concurrency advantage does not remove merge/consistency requirements.

Use them when dataset size justifies the trade-off and verify how changes become visible to active contexts.

## Cancellation

Long imports should check Swift task cancellation between meaningful batches. Core Data operations already submitted to a context may not be individually cancellable, so define the boundary at which work can safely stop.

Avoid leaving partially applied in-memory state without either saving intentionally or rolling back/resetting according to the transaction design.

## Common Diagnostics

### Non-Sendable managed object crossing actor boundary

Do not add `@unchecked Sendable` to the managed-object subclass. Pass `objectID` or a value snapshot.

### Main-actor isolation around a context

Decide whether the context is truly UI-owned. If persistence work is background, move the persistence boundary rather than marking the whole store `@MainActor`.

### Legacy queue-based service mixed with actors

Choose one clear ownership boundary. An actor service may internally call legacy context APIs, but callers should not need to understand both actor and dispatch-queue rules.

## Common Failures

- `@unchecked Sendable` on `NSManagedObject`;
- returning managed objects from background actor APIs;
- using `Task.detached` with a captured managed object/context;
- assuming read-only access is safe on any executor;
- doing large imports on the view/main context;
- adding actors on top of contexts without clarifying which one owns mutation.

## Verification

Test fetch/save on the intended contexts, UI merge/observation, background imports, cancellation/partial failure, and object deletion/reset scenarios. Enable Core Data concurrency debugging during development when investigating confinement violations.
