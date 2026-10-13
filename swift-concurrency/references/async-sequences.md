# AsyncSequence and AsyncStream

Use this reference for asynchronous streams of values. For one-shot work, prefer an async function. For stream operators such as debounce/merge/combine, use `async-algorithms.md`.

## Choose a Stream Only When the Data Is a Stream

Good fits:

- notifications/events over time;
- sensor/location/socket updates;
- producer/consumer pipelines;
- adapting callback APIs that emit multiple values;
- values that end through completion, error, or cancellation.

Do not turn a single response into an `AsyncStream` just to use `for await`.

## Consuming a Sequence

`for await` / `for try await` expresses sequential consumption with natural suspension between elements.

Keep the loop cancellation-aware and avoid heavy synchronous processing that monopolizes the consumer's actor/executor.

If each item can be processed independently and parallelism matters, add bounded concurrency explicitly rather than spawning an unbounded task for every element.

## `AsyncStream` vs `AsyncThrowingStream`

Use:

- `AsyncStream<Element>` when termination is normal/cancellation-only;
- `AsyncThrowingStream<Element, Error>` when producer failure is part of the API contract.

Keep error semantics faithful to the underlying source; do not convert operational errors into silent completion.

## Bridging Callback/Delegate APIs

When adapting a multi-event source:

1. create the stream and install the callback/delegate;
2. yield each event exactly once;
3. finish on terminal completion/error;
4. use `onTermination` to unregister/cancel the underlying source;
5. avoid a retain cycle between continuation, owner, and callback source.

If the source emits only once, use a checked continuation instead; see `async-await-basics.md`.

## Continuation Lifetime

The stream continuation may outlive the call that created it. Give it a clear owner and cleanup path.

Do not assume deallocation alone will unregister an external observer. Explicit termination is easier to reason about.

## Buffering and Backpressure

Choose buffering from source semantics:

- newest/current-state updates → small newest-value buffer may be appropriate;
- every event is significant → preserve events or apply explicit producer backpressure;
- high-rate telemetry/UI updates → coalesce/drop only when the product semantics allow it.

An unlimited buffer can turn a slow consumer into unbounded memory growth.

## Cancellation

Stopping iteration cancels the consumer task but does not automatically stop every external producer. Use termination handling to detach observers, close sockets, cancel requests, or release other resources.

For long-running sources, test both explicit cancellation and natural completion.

## Multiple Consumers

An `AsyncSequence` does not automatically mean broadcast/multicast. Some sequences are single-consumer or recreate work per iterator.

If several consumers need the same live source, decide explicitly whether semantics are:

- independent subscriptions;
- shared broadcast;
- latest-value state;
- work queue where each element is consumed once.

Choose a primitive/library that represents that behavior instead of sharing one iterator accidentally.

## Actor Isolation

Values crossing from producer to consumer may cross isolation domains. Prefer Sendable value payloads or keep non-Sendable framework objects inside one actor and emit safe representations.

Do not invoke arbitrary consumer callbacks while holding a lock or mutable producer invariant.

## SwiftUI

Consume long-lived sequences from `.task` when the subscription belongs to view lifetime. Let cancellation stop the loop and clean up the underlying source.

Avoid launching a permanent stream task from `onAppear` without owning/cancelling it.

## Async Algorithms

Use Swift Async Algorithms or another project-approved library when operators materially simplify stream logic, especially debounce, throttle, merge, combine-latest style composition, chunks, or channels.

Do not reimplement operator state machines with ad hoc tasks/timers unless the required semantics differ.

See `async-algorithms.md`.

## Common Failures

- using a stream for one-shot work;
- continuation retained forever after consumer cancellation;
- unbounded buffering;
- assuming one sequence is safely multicast;
- emitting mutable non-Sendable framework objects across actors;
- swallowing producer errors as completion;
- creating nested tasks for every event without bounds.

## Verification

Test first value, repeated values, normal completion, producer error, consumer cancellation, slow consumer behavior, and owner deallocation. For high-volume streams, measure buffer growth and latency under representative load.
