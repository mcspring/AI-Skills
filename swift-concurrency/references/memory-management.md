# Swift Concurrency Memory and Lifetime

Use this reference when tasks, actors, streams, or callbacks keep objects alive longer than intended or cleanup depends on async lifetime.

## Separate Leak From Intentional Lifetime

A task retaining an owner is not automatically a leak. First define when the owner is expected to deallocate and who owns the task.

A real lifetime bug usually has one of these forms:

- an unbounded task strongly retains its owner;
- owner retains task and task awaits a source that never finishes;
- callback/stream registration is never removed;
- continuation is retained after terminal completion;
- detached work outlives resources it captures.

## Task Captures

`Task {}` closures capture referenced values like other closures.

Do not add `[weak self]` mechanically. Weak capture is useful when the task should not extend owner lifetime, but it can also cause work to disappear unexpectedly.

Decide explicitly:

- owner should live until task finishes → strong capture can be correct;
- task should stop when owner disappears → weak capture plus cancellation/lifetime linkage may be appropriate;
- task represents independent application work → move ownership out of the UI/object entirely.

## Long-Lived Tasks

For listeners, polling loops, and streams:

- retain a task handle when the owner is responsible for cancellation;
- cancel it during explicit teardown/deinit when that contract is reliable;
- make the producer stop on cancellation;
- avoid loops that catch cancellation and continue forever.

Prefer explicit `start`/`stop` or lifecycle-scoped APIs when teardown is important enough that relying on deinit is ambiguous.

## SwiftUI

Use `.task` for work tied to a view's lifetime. SwiftUI cancels that task when the relevant view lifetime ends.

Avoid starting permanent listener tasks from `onAppear` without matching ownership/termination; repeated appearances can create duplicate subscriptions.

## AsyncStream Lifetime

An `AsyncStream` bridge often creates a retention triangle among owner, producer callback, and continuation.

Use `onTermination` to unregister the underlying callback/observer and release retained resources. Finish the continuation exactly once for terminal producer states.

See `async-sequences.md`.

## Continuations

Checked continuations must resume exactly once. A continuation that is never resumed can leave the awaiting task and captured object graph alive indefinitely.

For cancellation-aware bridges, define how cancellation reaches the underlying operation rather than merely abandoning the awaiting task.

## Actors

Actors can participate in cycles just like classes. Isolation prevents data races, not reference cycles.

Avoid storing closures/tasks on an actor that strongly capture that same actor unless a deliberate termination event breaks the cycle.

## Isolated Deinitialization

Modern Swift supports isolated deinitialization for types whose teardown needs isolated state. Use it for small, reliable cleanup.

If cleanup can suspend or fail significantly, prefer an explicit async shutdown API where callers can await and handle errors.

Swift 6.4 permits `await` in `defer` and provides cancellation shields, which can make async cleanup more reliable. Keep shielded cleanup narrow so cancellation still works for normal operations.

## Async Cleanup

When a resource needs async cleanup:

- expose an explicit async close/shutdown API;
- use `defer` with async cleanup on Swift 6.4+ where it fits lexical ownership;
- shield only cleanup that must preserve an invariant;
- make repeated cleanup safe when possible.

Do not depend on deinit to perform arbitrary asynchronous network/file work.

## Weak References

Weak capture is a lifetime policy, not a concurrency safety mechanism.

A common safe pattern for long-running owner-bound loops is to reacquire `self` only for short operations rather than holding a strong reference across an indefinite suspension.

But if the task's purpose requires the owner to remain alive, weak capture is the wrong semantics.

## Diagnostics

Use:

- Xcode Memory Graph;
- Instruments Allocations/Leaks;
- explicit deinit logging/signposts during investigation;
- deterministic lifetime tests with weak references;
- task/stream termination instrumentation.

Do not diagnose leaks solely from “deinit did not run immediately”; pending tasks/autorelease/framework caches can extend lifetime legitimately.

## Common Failures

- blanket `[weak self]` everywhere;
- owner-held task with no cancellation path;
- `AsyncStream` observer never unregistered;
- continuation never resumed;
- cancellation swallowed in an infinite loop;
- detached task capturing UI/controller objects;
- attempting substantial async work from deinit without explicit ownership.

## Verification

Exercise normal completion, cancellation, error, owner release, repeated start/stop, and stream termination. Confirm expected objects deallocate after the owning work has actually finished, not at an arbitrary scheduler moment.
