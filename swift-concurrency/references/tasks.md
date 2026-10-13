# Tasks and Cancellation

Use this reference for task ownership, structured concurrency, cancellation, priorities, and cleanup.

## Choose the Smallest Tool

| Need | Prefer |
|---|---|
| sequential async work | ordinary `async`/`await` |
| fixed independent child operations | `async let` |
| dynamic child operations | task group |
| attach work to SwiftUI view lifetime | `.task` / `.task(id:)` |
| bridge sync caller into async work | `Task {}` with explicit ownership |
| intentionally independent executor/context | `Task.detached` only with a concrete reason |

Structured child tasks should be the default because lifetime, errors, and cancellation remain tied to the parent scope.

## Task Ownership

Every unstructured task should answer:

- Who creates it?
- Who retains the handle, if anyone?
- What cancels it?
- Can it outlive the owner safely?
- What happens to errors?

A fire-and-forget `Task {}` is acceptable only when losing its result/error and allowing its lifetime are deliberate.

## Cancellation

Cancellation is cooperative. APIs should propagate it rather than silently replacing it.

Check cancellation:

- before expensive batches;
- inside long loops;
- before committing expensive or irreversible work when cancellation still matters;
- after suspension points when downstream work would otherwise continue unnecessarily.

Use `Task.checkCancellation()` when cancellation should throw; use `Task.isCancelled` when local cleanup/control flow is clearer.

Child tasks inherit parent cancellation. Cancelling a task group should prevent unnecessary new work and allow existing children to finish or observe cancellation promptly.

## Cancellation Handlers

Use cancellation handlers to cancel or detach underlying legacy work that does not automatically follow Swift task cancellation. Keep cleanup idempotent because cancellation can race with normal completion.

## Swift 6.4 Cleanup

Swift 6.4 allows asynchronous work in `defer`. This is useful when cleanup itself must suspend.

Use `withTaskCancellationShield` when essential cleanup must complete even after the enclosing task is cancelled. Keep shields narrow: they should protect cleanup/invariants, not hide ordinary work from cancellation.

## Task Groups

Use task groups when child count is dynamic.

Guidance:

- add only independent work that can safely run concurrently;
- collect results in the parent unless shared mutation is separately isolated;
- stop adding work when cancellation/error means the remaining work is useless;
- use throwing groups when failures should propagate;
- use bounded concurrency when input size can be large or downstream services have limits.

Do not create a task per item for an unbounded collection without considering memory, executor pressure, and external rate limits.

## `async let` vs Task Group

Use `async let` when the number and shape of child operations are known lexically. Use a task group when children are created from runtime data or need iterative result consumption.

## Detached Tasks

`Task.detached` does not inherit actor isolation in the same way as an ordinary task and weakens structured lifetime relationships. It is not the default way to do background work.

Use it only when independence from the current actor/task context is itself required and the captured values are safe to transfer.

## Priorities

Treat priority as a scheduling hint, not correctness control.

- inherit priority when that represents the user-visible operation;
- avoid manually assigning priorities unless work has a real service-level distinction;
- never rely on priority for ordering.

## Sleeping, Yielding, Debounce

- `Task.sleep` suspends for time; use it when time is part of the behavior and preserve cancellation.
- `Task.yield` only offers other work a scheduling opportunity; it is not a delay or synchronization primitive.
- For reusable debounce/throttle/merge behavior, prefer an appropriate async-sequence operator/library over hand-built sleeping-task state machines.

## SwiftUI

`.task` is normally preferable to `onAppear { Task { ... } }` because SwiftUI owns and cancels the task with the view lifetime.

Use `.task(id:)` when the operation should restart as a specific input changes.

Do not assume a view disappearing means every nested unstructured task is cancelled; only tasks in the relevant structured/lifecycle relationship are.

## Timeouts

A timeout is cancellation policy around useful work. Prefer APIs that race the operation against a clock while cancelling the loser. Preserve the underlying operation's own deadline semantics when available rather than layering arbitrary nested timeouts.

## Common Failures

- storing a `Task` only to leak it beyond owner lifetime;
- spawning unbounded children;
- swallowing task errors unintentionally;
- using detached tasks to avoid actor diagnostics;
- sleeping to coordinate tests or production state;
- forgetting cancellation in CPU-heavy loops;
- shielding too much work from cancellation.

## Verification

Test normal completion, error propagation, parent cancellation, owner deallocation, and repeated cancellation. Use Instruments when task volume or executor scheduling is the performance concern.
