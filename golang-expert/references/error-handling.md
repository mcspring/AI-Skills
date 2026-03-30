# Error Handling

Go's error handling is explicit — every error is a value that must be checked, wrapped with context, and handled exactly once.

## Core Rules

1. **Returned errors MUST always be checked** — NEVER discard with `_`
2. **Errors MUST be wrapped with context** using `fmt.Errorf("{context}: %w", err)`
3. **Error strings MUST be lowercase**, without trailing punctuation
4. **Use `%w` internally, `%v` at system boundaries** to control error chain exposure
5. **MUST use `errors.Is` and `errors.As`** instead of direct comparison or type assertion
6. **Use `errors.Join`** (Go 1.20+) to combine independent errors
7. **Errors MUST be either logged OR returned, NEVER both** (single handling rule)
8. **Use sentinel errors** for expected conditions, custom types for carrying data
9. **NEVER use `panic` for expected error conditions** — reserve for truly unrecoverable states
10. **Use `slog`** (Go 1.21+) for structured error logging
11. **Keep error messages low-cardinality** — don't interpolate variable data into error strings; attach as structured attributes
12. **Never expose technical errors to users** — translate to user-friendly messages

## Error Creation

### Sentinel Errors

Preallocated package-level errors for expected conditions:

```go
var (
    ErrNotFound   = errors.New("user: not found")
    ErrConflict   = errors.New("user: already exists")
    ErrValidation = errors.New("user: invalid input")
)
```

### Custom Error Types

For carrying rich context:

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s %s", e.Field, e.Message)
}
```

### When to Use Which

| Condition | Use | Why |
| --- | --- | --- |
| Caller checks for specific condition | Sentinel (`ErrNotFound`) | Simple equality check with `errors.Is` |
| Caller needs data from the error | Custom type | `errors.As` extracts structured fields |
| Internal wrapping only | `fmt.Errorf` | No matching needed, just context |

## Error Wrapping

```go
// ✓ Good — wraps with context, preserves chain
return fmt.Errorf("querying user %s: %w", userID, err)

// ✗ Bad — loses the error chain
return fmt.Errorf("querying user: %v", err)  // at boundaries only

// ✓ Good — combining independent errors
return errors.Join(validateName(u), validateEmail(u), validateAge(u))
```

## Error Inspection

```go
// ✓ Good — works through wrapped chains
if errors.Is(err, ErrNotFound) { ... }

var valErr *ValidationError
if errors.As(err, &valErr) {
    log.Printf("field: %s", valErr.Field)
}

// ✗ Bad — breaks on wrapped errors
if err == ErrNotFound { ... }   // direct comparison fails
if e, ok := err.(*ValidationError); ok { ... }  // type assertion fails
```

## Single Handling Rule

Errors MUST be handled at exactly one point — either log or return, never both:

```go
// ✗ Bad — logged AND returned (duplicate logs up the chain)
if err != nil {
    slog.Error("query failed", "error", err)
    return fmt.Errorf("query: %w", err)
}

// ✓ Good — return with context, log once at the top level
if err != nil {
    return fmt.Errorf("querying users: %w", err)
}
```

## Panic vs Error

| Situation | Use |
| --- | --- |
| Network failure, invalid input, file not found | Return `error` |
| Violated invariant, impossible nil, `Must*` init-time constructors | `panic` |
| `.Close()` errors | Acceptable to ignore via `defer f.Close()` |

## Structured Logging with slog

```go
// ✓ Good — structured, context-aware
slog.ErrorContext(ctx, "payment failed",
    "order_id", orderID,
    "error", err,
)

// ✗ Bad — unstructured, no context
log.Printf("payment failed for order %s: %v", orderID, err)
```

### Log Levels

| Level | Use when |
| --- | --- |
| Debug | Development diagnostics, verbose tracing |
| Info | Normal operations, state transitions |
| Warn | Degraded but recovering (retries, fallbacks) |
| Error | Failures requiring attention |

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Discarding errors with `_` | Always check returned errors |
| Log AND return | Pick one — single handling rule |
| `err == ErrNotFound` direct comparison | `errors.Is(err, ErrNotFound)` |
| Uppercase error strings | Lowercase, no punctuation |
| Interpolating IDs in error messages | Attach as structured `slog` attributes |
| `panic` for expected conditions | Return `error` |
| `fmt.Println` for error logging | Use `slog` for structured output |
