# Swift Concurrency Performance

Use this reference only when there is measured latency, responsiveness, throughput, or executor contention to investigate.

## Principle

Concurrency is a correctness and responsiveness model first. More tasks, actors, or suspension points do not automatically make code faster.

Measure before restructuring.

## Start With Instruments

Use the Swift Concurrency and Time Profiler instruments to answer:

- Is the main actor blocked?
- Are tasks spending time runnable, running, or suspended?
- Is an actor a contention hotspot?
- Are too many tiny tasks being created?
- Is the actual bottleneck CPU, I/O, lock contention, allocation, or an external service?

Do not infer these from source shape alone.

## Main-Actor Responsiveness

A UI hang is usually caused by synchronous work that occupies the main actor too long.

Fix the ownership/work boundary rather than wrapping everything in `Task`:

- keep UI state updates main-actor isolated;
- move genuinely expensive CPU work to an appropriate concurrent execution boundary;
- use async I/O APIs instead of blocking I/O;
- batch tiny state updates when doing so preserves behavior.

## Actor Contention

Actors are useful ownership boundaries but can become hot serialization points.

Investigate:

- unrelated state sharing one actor;
- long synchronous actor methods;
- work performed inside the actor that could use an immutable snapshot elsewhere;
- repeated actor hops in tight loops.

Split actors only when state invariants permit independent ownership. Do not shard an actor merely to reduce an `await` count.

## Suspension Points

Suspension itself has overhead, but the larger concern is semantic: suspension allows other work to run and actor state to change.

Reduce suspension when:

- an async helper does no asynchronous work;
- several same-actor operations can be expressed as one isolated operation;
- a hot loop repeatedly hops actors for tiny reads/writes.

Do not remove suspension that is required for I/O, fairness, or correct ownership.

## Parallelism

Parallelize when work is independent and expensive enough to outweigh task/scheduling overhead.

Poor candidates include:

- tiny transformations;
- workloads constrained by one downstream resource;
- memory-bandwidth-bound work that already saturates hardware;
- operations whose ordering/invariants force serialization anyway.

Use bounded concurrency for large input sets or rate-limited external systems.

## Task Volume

High task counts can increase allocation, scheduling, and bookkeeping overhead.

Prefer coarse useful units of work. For large streams, use batching or bounded groups instead of unbounded task-per-element fan-out.

## Cancellation and Wasted Work

Responsiveness improves when obsolete work stops promptly.

- cancel replaced searches/loads;
- check cancellation in CPU-heavy loops;
- avoid starting children after failure/cancellation makes them irrelevant;
- keep cancellation shields limited to required cleanup.

## Data Movement

Cross-isolation copies can dominate costs for large values. Prefer immutable snapshots sized to what the consumer actually needs.

Swift 6.4 adds safer non-copying/value-ownership facilities in the broader language/runtime, but adopt them only where profiling shows copy cost matters and the project's platform/toolchain supports them.

## UX Over Throughput

For app code, optimize user-perceived responsiveness before benchmark throughput:

- keep scrolling and animation responsive;
- show progressive results when useful;
- prioritize current user intent over obsolete background work;
- avoid parallel work that increases memory pressure enough to harm UI responsiveness.

## Avoid

- `Task.detached` as a generic performance fix;
- actors around pure immutable data;
- parallelizing every loop;
- manually tuning task priority without evidence;
- replacing clear async code with locks solely to remove `await`;
- claiming performance improvement without before/after measurement.

## Verification

Capture the same workload before and after the change. Report wall time or latency distribution plus relevant task/actor evidence. Re-test on representative hardware, not only simulator/debug builds.
