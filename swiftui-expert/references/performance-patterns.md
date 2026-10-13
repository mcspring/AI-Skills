# SwiftUI Performance Patterns

Use this reference when there is evidence of excessive invalidation, main-thread work, memory growth, layout churn, or slow scrolling.

## Measure First

Use SwiftUI update diagnostics, Instruments, Time Profiler, Allocations, and signposts to confirm where time or memory is spent. Do not treat every large view body or every recomputation as a performance bug.

## Reduce Invalidation Scope

A view should depend only on the values it renders.

- pass narrow values instead of broad models when only a small subset is needed;
- keep frequently changing state close to the smallest affected subtree;
- split views when doing so creates useful invalidation boundaries, not merely to reduce line count;
- avoid environment dependencies that cause unrelated subtrees to observe broad state.

Observation can track property-level dependencies more precisely than older `ObservableObject` publishing, but broad computed properties can still make many values appear dependent.

## Keep `body` Cheap

`body` may be evaluated often. Avoid work whose cost or side effects matter:

- network/disk I/O;
- decoding large payloads;
- expensive sorting/filtering repeatedly;
- image decoding/downsampling;
- constructing heavyweight reference objects;
- synchronous database access.

Precompute or move expensive work to a model/task/cache with explicit invalidation.

Cheap formatting and small derived values are normally fine; profile before introducing caches that add complexity.

## Stable Identity

List/grid performance depends on stable semantic identity.

- identify items by stable IDs, not transient offsets when content can mutate;
- avoid regenerating IDs in `body`;
- do not replace a whole collection when a smaller state mutation expresses the change;
- keep each item view's dependencies narrow.

See `list-patterns.md` for identity details.

## Lazy Containers

Use lazy stacks/grids for large or expensive collections where eager construction is measurable.

Do not assume lazy is always faster: small static layouts can be simpler and cheaper eagerly.

Modern SwiftUI improves nested lazy-container loading and prefetching behavior across recent SDKs, including the 2027 generation. Prefer framework behavior before building custom virtualization.

## Images

Large images are frequent scrolling bottlenecks.

- request/decode images near display size when possible;
- avoid repeatedly decoding `Data` in `body`;
- cache according to app/network semantics;
- use `AsyncImage` for simple remote images when its policy fits.

In the 2027 SDK generation, `AsyncImage` participates in standard HTTP caching by default. Use custom requests/session/cache policy only when the app needs different behavior.

See `image-optimization.md`.

## Tasks and Cancellation

Tie asynchronous work to view lifetime with `.task` / `.task(id:)` where appropriate.

Cancel or replace stale searches, image requests, and background preparation when their inputs change. Avoid detached tasks that outlive the view unless that lifetime is intentional.

## Main Actor

State mutation used by SwiftUI is generally main-actor owned, but expensive computation should not occupy the main actor unnecessarily.

Move genuinely expensive CPU work behind an appropriate concurrency boundary, return a compact result, then update UI state. Do not move trivial work off-main merely to satisfy a rule.

## Equatable Optimization

Use explicit equatability only when profiling shows diffing/invalidation work is significant and the equality relation accurately represents rendering dependencies.

Do not add `EquatableView`/custom equality to every component: incorrect equality can suppress legitimate updates and maintenance cost can exceed savings.

## Layout

Repeated geometry feedback can create layout loops or churn.

Prefer native adaptive containers and layout APIs before chains of `GeometryReader` + preference updates. Cache layout measurements only when they are truly stable and expensive.

See `layout-best-practices.md`.

## Scrolling

For smooth scrolling:

- keep row construction cheap;
- avoid global state mutations from every scroll tick;
- keep images appropriately sized;
- avoid synchronous work in appearance callbacks;
- use current scroll APIs instead of geometry-preference polling where possible.

See `scroll-patterns.md`.

## Common Failures

- creating formatter/model/image objects repeatedly in `body` when construction is expensive;
- filtering large arrays inline for every update;
- broad environment/observable dependencies invalidating a large subtree;
- unstable IDs causing row recreation;
- task-per-row work with no cancellation/backpressure;
- custom caching without a measured bottleneck;
- declaring something a performance fix without before/after data.

## Review Checklist

1. Is there a measured user-visible or resource problem?
2. Which views are invalidating and why?
3. Is expensive work happening during render/layout?
4. Are identity and lifetime stable?
5. Are stale async operations cancelled?
6. Are images/data sized appropriately?
7. Did the change improve the measured workload without breaking semantics?
