# Go Concurrency and Context

Use this reference for goroutine lifetime, cancellation, channels, synchronization, and request-scoped context.

## Goroutine Ownership

Every goroutine needs a reason to exist and a way to stop.

Define:

- who starts it;
- what input it consumes;
- how it terminates;
- how errors are surfaced;
- whether shutdown waits for it.

A goroutine without an ownership/lifetime story is a common leak source.

## Context

Use `context.Context` for cancellation, deadlines, and request-scoped metadata that crosses API/process boundaries.

Conventional Go APIs place `ctx context.Context` first when the operation is context-aware. Preserve existing public API conventions rather than rewriting solely for style.

Guidance:

- do not pass `nil`; use an appropriate real context;
- propagate caller context through request-scoped work;
- call the returned cancel function when creating cancellable/deadline contexts so associated resources are released;
- use `context.WithoutCancel` deliberately for work that must outlive caller cancellation while retaining context values;
- use context values sparingly for cross-cutting request metadata, not ordinary required parameters.

Storing context in a long-lived struct is usually a design smell, but some framework/request wrapper types can legitimately carry it. Judge by lifetime semantics rather than a blanket ban.

## Cancellation in Loops

Long-running workers should observe cancellation at meaningful boundaries. A `select` on `ctx.Done()` is useful when waiting on channels/timers; CPU loops can check `ctx.Err()` between batches.

Do not add cancellation checks to trivial operations where no useful interruption is possible.

## Channels vs Mutexes

Use channels when transferring ownership/coordinating streams of events naturally expresses the problem.

Use mutexes/atomics when several goroutines share short-lived mutable state and synchronous access is clearer.

“Share memory by communicating” is guidance, not a prohibition on mutexes.

## Channel Ownership

The code responsible for producing a stream should normally decide when no more values will be sent and close the channel when receivers rely on closure.

Receivers should not close a channel just to stop a producer; cancellation or a separate control signal is usually clearer.

Never send on a closed channel. Nil channels intentionally block and can be useful in select state machines, but should be obvious from the code.

## Bounded Concurrency

Bound concurrency when input size, resource usage, or downstream limits can grow.

Options include:

- `errgroup.Group` with `SetLimit` for fallible groups;
- semaphores when permits model a resource;
- worker pools when jobs are a long-lived stream;
- application-specific rate limiters for external services.

Do not build a worker pool for a small fixed number of independent operations when `errgroup`/`WaitGroup` is clearer.

## `sync.WaitGroup`

For modules targeting Go 1.25+, `WaitGroup.Go` can combine starting/tracking goroutines and reduce `Add`/`Done` bookkeeping.

Use classic `Add` + goroutine when compatibility or control requires it. Ensure `Add` happens before a concurrent `Wait` can observe zero for newly started work.

## Locks

Keep critical sections small and protect one clear invariant.

- use `Mutex` by default for shared state;
- use `RWMutex` only when measured/read-heavy access benefits;
- avoid copying structs containing mutexes after first use;
- do not call unknown/slow external code while holding a lock when it can cause contention or deadlock.

## Atomics

Use atomics for small, well-defined lock-free state where the memory/invariant model remains obvious. If several fields must change consistently, a mutex is often safer and clearer.

## Timers

Avoid repeatedly allocating timers in hot loops when a reusable timer/ticker expresses the lifecycle better. Stop/drain/reset according to the current timer API semantics and target Go version.

## Leaks and Diagnostics

Investigate suspected leaks with goroutine profiles, traces, and lifecycle tests.

Go 1.27 adds the `goroutineleak` pprof profile for a class of permanently blocked unreachable goroutines. It is a useful signal, not a complete leak detector.

## Common Failures

- goroutine waits forever because no cancellation/close path exists;
- unbounded goroutine-per-item fan-out;
- channel send blocked after consumer exits;
- request work starts from a fresh background context and ignores cancellation accidentally;
- lock held while making network/disk/callback calls;
- copying a mutex-containing value;
- using channels for simple shared counters/maps where a lock is clearer.

## Verification

Run focused tests and `go test -race` for concurrency-sensitive changes. For leaks/contention/performance, use pprof/trace with representative workloads rather than relying only on code inspection.
