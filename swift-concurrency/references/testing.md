# Testing Swift Concurrency

Use this reference for deterministic tests of async functions, actors, cancellation, streams, and lifetime behavior.

## Prefer Behavior Over Scheduling

Tests should assert observable results and invariants, not which thread ran a task or how many scheduler turns occurred.

Avoid wall-clock sleeps as synchronization. They make tests slow and flaky and do not prove the intended state transition happened.

## Swift Testing vs XCTest

Use the test framework already adopted by the project.

Swift Testing is a strong default for new Swift packages/apps on supported toolchains; XCTest remains appropriate for existing suites, UI tests, and APIs that still integrate around XCTest.

Do not migrate a stable suite solely to modernize syntax.

## Async Tests

Async test functions can `await` production APIs directly. Keep setup/teardown lifetime explicit and avoid spawning untracked child tasks that can escape the test.

When a test creates long-lived work, cancel and await its termination before the test ends.

## Callbacks and Confirmations

For callback-based behavior, use the framework's expectation/confirmation mechanisms rather than sleeping until a callback “probably” fired.

Assert:

- exact/allowed number of callbacks;
- payload/order when behavior requires it;
- no callback after cancellation or teardown when that is part of the contract.

Checked continuations are useful for bridging a one-shot callback in test helpers, but ensure exactly one resume.

## Actors

Test actor state through the actor's public isolated API. Avoid adding `nonisolated` test-only escape hatches just to inspect internals.

For reentrancy-sensitive code, create controlled suspension points/dependencies so the test can deliberately interleave operations.

Do not rely on task sleeps to manufacture an actor race.

## Cancellation

A useful cancellation test controls when work starts, then cancels, then observes cleanup/result.

Verify the contract rather than only checking `Task.isCancelled`:

- underlying request/producer cancelled if promised;
- no stale state committed after cancellation;
- required cleanup still completed;
- cancellation error propagated or intentionally translated.

Swift 6.4 cancellation shields and async cleanup should be tested at their semantic boundary: shield only the essential cleanup, then verify normal work still respects cancellation.

## AsyncSequence

Test streams with controlled producers.

Cover:

- first and repeated values;
- normal finish;
- producer error;
- consumer cancellation;
- buffering/slow-consumer behavior when relevant.

Avoid infinite production in tests. Bound the stream and terminate explicitly.

## Main Actor

Annotate a test `@MainActor` only when the tested API is genuinely main-actor isolated. Do not apply it globally to make isolation diagnostics disappear.

If production code performs expensive off-main work and returns to main actor, assert the resulting state rather than thread identity.

## Deterministic Time

For debounce, throttle, timeout, and retry behavior, prefer injectable clocks/test clocks supported by the implementation/library.

Wall-clock sleeps should be a last resort for integration behavior that cannot expose a controllable time source.

## Lifetime and Leaks

When task lifetime is part of correctness:

- hold the owner weakly;
- release strong references;
- cancel/finish external streams;
- wait using deterministic completion signals;
- assert deallocation.

A task retaining its owner is not automatically a leak if that lifetime is intentional; the test should express the intended ownership contract.

## Concurrency Stress

Use repeated/concurrent execution when testing synchronization invariants, but do not confuse a stress test with a proof of race freedom.

Compiler isolation, Thread Sanitizer/runtime tooling, and invariant-focused tests complement each other.

## Serial Execution

Only force serial test execution when shared external state truly requires it. Prefer isolating test fixtures/state so tests can run independently.

A global serial executor can change scheduling enough to hide bugs; use deterministic dependencies rather than relying on it as a general fix for flaky concurrency tests.

## Common Failures

- `Task.sleep` used as synchronization;
- asserting exact thread IDs;
- tests leaving unstructured tasks alive;
- blanket `@MainActor` on the suite;
- expectations that can fulfill after test teardown;
- forgetting cancellation/error paths;
- testing implementation scheduling instead of public behavior.

## Verification Checklist

1. Does the test deterministically know when the operation reached the state it needs?
2. Does it cover success, failure, and cancellation where applicable?
3. Are spawned tasks/streams cleaned up?
4. Does it avoid scheduler timing assumptions?
5. Does actor isolation match production behavior?
6. For lifetime-sensitive code, is deallocation/termination actually asserted?
