# Go Error Handling

Use this reference for designing, wrapping, matching, logging, and aggregating Go errors.

## Return Errors for Expected Failure

Use errors for failures callers can reasonably handle or report. Reserve panic for broken invariants or initialization/programmer failures where continuing is not meaningful.

Do not turn every exceptional condition into a custom error type; choose the representation based on what callers need to inspect.

## Add Context Without Destroying Identity

Wrap an underlying error with `%w` when callers may need `errors.Is`/`errors.As` through the chain:

```go
return fmt.Errorf("load user %q: %w", id, err)
```

Add context that helps identify the failed operation/resource. Avoid redundant stack-like narration at every layer.

Not every returned error must be wrapped: returning a well-defined domain/sentinel error directly can be clearer when no additional context is needed.

## Matching

Use `errors.Is` for sentinel/semantic matching across wrappers and `errors.As` for typed errors.

Direct equality can still be appropriate for an unwrapped local sentinel when that is explicitly the API contract, but `errors.Is` is the safer boundary when wrapping is allowed.

Do not inspect error strings for control flow.

## Sentinel vs Typed Errors

Use a sentinel when callers only need one stable condition, for example `ErrNotFound`.

Use a typed error when callers need structured details such as path, field, retry metadata, or an underlying cause.

Avoid exporting error internals that lock the package into implementation details unnecessarily.

## Error Strings

For errors that will be wrapped into larger messages, idiomatic Go typically uses lowercase text without terminal punctuation. User-facing/UI messages are a different layer and can follow product writing conventions.

## Logging Boundary

Avoid automatically logging every error at the point it is returned; this creates duplicate logs when higher layers also report it.

Choose an observation boundary where the application has enough request/user context to log or convert the error.

Logging and returning the same error can be legitimate when the log captures unique diagnostic evidence or when crossing process boundaries. Treat “log or return, never both” as a useful anti-duplication heuristic, not an absolute rule.

## Ignored Errors

Do not discard an error accidentally. Explicitly ignoring one can be correct when failure has no useful action, such as best-effort cleanup; document or structure that intent when it is not obvious.

Cleanup errors can matter. Decide whether to return, join, log, or intentionally ignore them based on the operation contract.

## Multiple Errors

Use `errors.Join` when several independent failures should remain inspectable through `errors.Is`/`errors.As`.

Do not join merely to avoid choosing a primary failure when ordering/priority matters to callers.

## Deferred Cleanup

A deferred close can overwrite or augment a named return error when close failure matters, especially for writers/transactions.

For read-only resources where close errors have no actionable meaning, best-effort close may be reasonable.

## Boundary Translation

Translate errors at architectural boundaries:

- storage → domain conditions;
- domain → HTTP/gRPC status;
- internal diagnostic → safe user message.

Preserve useful causes internally while avoiding leakage of secrets, SQL, paths, or implementation detail to untrusted clients.

## Retries

An error being non-nil does not imply retryability. Classify retry based on operation semantics, idempotency, status/code, and context cancellation/deadline.

Respect `ctx.Err()` and stop retrying when the caller no longer wants the work.

## Common Failures

- matching `err.Error()` text;
- wrapping with `%v` and losing chain identity when callers need matching;
- logging the same error at many layers;
- converting every failure into one generic sentinel and losing actionable detail;
- panicking for normal I/O/validation failures;
- retrying cancellation/deadline or non-idempotent operations blindly;
- leaking internal error text to clients.

## Verification

Test the behavior callers depend on: `errors.Is`/`errors.As`, boundary status mapping, joined/cleanup errors, and retry classification. Avoid tests that require exact full error strings unless wording itself is the public contract.
