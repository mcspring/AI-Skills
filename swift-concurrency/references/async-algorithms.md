# Async Algorithms and Stream Composition

Use this reference when an asynchronous stream needs composition such as debounce, throttle, merge, combine-latest behavior, chunking, or channels. Basic sequence construction belongs in `async-sequences.md`.

## Prefer Semantics Over Operator Names

Before choosing an operator, define what should happen when values arrive faster or slower than expected:

- preserve every value;
- keep only the latest;
- delay until input becomes quiet;
- rate-limit output;
- interleave several sources;
- emit only after every source has a current value;
- batch values by count/time;
- provide a bounded producer/consumer handoff.

The same product requirement can map to different operators depending on cancellation and buffering semantics.

## Debounce

Use debounce when an action should occur only after input has been quiet for a period, such as search-as-you-type.

Key decisions:

- whether the first value should ever emit immediately;
- which clock/tolerance the project uses;
- cancellation when the owning task/view disappears;
- whether a new value cancels in-flight downstream work or only delays the next start.

Prefer an established operator over a hand-built “cancel previous sleep task” utility when this behavior is reused.

## Throttle

Use throttle when output should be limited to a maximum rate while input may continue rapidly.

Decide whether each interval emits the first or latest value. That choice is user-visible; do not assume one default fits scroll, telemetry, logging, and network updates equally.

## Merge

Merge interleaves values from multiple sources as they arrive. It does not pair values or guarantee source ordering relative to one another.

Use when all sources produce the same conceptual event stream and source identity can be included in the payload when needed.

## Combine Latest

Use combine-latest semantics when downstream work needs the current value from several independent sources and should rerun whenever any source changes after all have produced at least one value.

For simple UI state already represented by Observation, derive state directly instead of creating a stream graph only to mirror properties.

## Zip

Zip pairs values by position/order. It waits for one value from each input for every output.

Use when elements are logically paired. Do not use zip when “latest state” is intended, because one faster source will queue values while waiting for the slower source.

## Chunking / Batching

Batch when per-element overhead is significant or downstream systems accept groups more efficiently.

Bound both batch size and waiting time if latency matters. An infinite “wait until N values” batch can stall sparse streams indefinitely.

## Channels

Use an async channel when producers and consumers need explicit asynchronous handoff and backpressure semantics.

Choose bounded capacity when unbounded producer lead would cause memory growth. Define what cancellation/closure means for both sides.

A channel is not automatically a broadcast mechanism; use a broadcast/latest-value abstraction when that is the requirement.

## Clocks and Testing

Time-based operators should use injectable/testable clock semantics when the framework/library supports them. Avoid tests that depend on wall-clock sleeps and scheduler luck.

Assert emitted values and ordering with deterministic clocks or controlled sources.

## Error and Completion Semantics

For composed streams, decide:

- whether one source error terminates the entire composition;
- whether source completion should end output immediately or only when all sources finish;
- whether cancellation should propagate to every upstream producer.

Do not swallow errors just to keep an operator chain convenient.

## Isolation and Sendability

Operator closures can execute across isolation boundaries depending on the sequence/library. Capture Sendable immutable values where possible and keep actor-owned mutable state within its actor.

Do not add `@unchecked Sendable` to make an operator compile before identifying what value is actually crossing the boundary.

## When Not to Use Async Algorithms

Prefer simpler primitives when:

- there is one async result → async function;
- SwiftUI Observation already expresses state dependencies;
- a plain `for await` loop is clearer;
- a task group models finite parallel work better;
- an existing Combine/Rx pipeline is stable and migration adds no concrete value.

## Common Failures

- using debounce when throttle is required, or vice versa;
- reimplementing operators with nested unstructured tasks;
- unbounded merge/channel buffering;
- assuming merge preserves source ordering;
- using zip for current-state semantics;
- wall-clock sleeps in tests;
- forgetting upstream cancellation on downstream termination.

## Verification

Test empty input, first value, bursts, sparse input, simultaneous sources, upstream error, normal completion, downstream cancellation, and slow consumers. For high-rate pipelines, measure latency and buffer growth.
