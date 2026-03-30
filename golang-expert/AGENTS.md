---
name: golang-expert
description: >
  Comprehensive Go coding guidelines across 11 categories. Use when writing,
  reviewing, or refactoring Go code. Covers concurrency, error handling, safety,
  type design, design patterns, security, naming, performance, observability,
  modernization, and data structures. Invoke with /golang-expert.
license: MIT
metadata:
  version: "1.0.0"
  sources:
    - Effective Go
    - Go Proverbs
    - Go Standard Library
    - samber/cc-skills-golang
---

# Go Best Practices

Comprehensive guide for writing high-quality, idiomatic, and production-ready Go code. Organized into 11 categories, prioritized by impact.

## When to Apply

Reference these guidelines when:
- Writing new Go functions, types, or packages
- Implementing concurrent code with goroutines and channels
- Designing APIs and public interfaces
- Handling errors and defensive coding
- Reviewing code for safety, security, and performance
- Refactoring or modernizing existing Go code

## Categories by Priority

| Priority | Category | Impact | Reference |
|----------|----------|--------|-----------|
| 1 | Concurrency & Context | CRITICAL | [concurrency.md](references/concurrency.md) |
| 2 | Error Handling | CRITICAL | [error-handling.md](references/error-handling.md) |
| 3 | Safety & Defensive Coding | CRITICAL | [safety.md](references/safety.md) |
| 4 | Type Design | HIGH | [type-design.md](references/type-design.md) |
| 5 | Design Patterns | HIGH | [design-patterns.md](references/design-patterns.md) |
| 6 | Security | HIGH | [security.md](references/security.md) |
| 7 | Naming Conventions | MEDIUM | [naming.md](references/naming.md) |
| 8 | Performance | MEDIUM | [performance.md](references/performance.md) |
| 9 | Observability | MEDIUM | [observability.md](references/observability.md) |
| 10 | Modernization | MEDIUM | [modernization.md](references/modernization.md) |
| 11 | Data Structures | MEDIUM | [data-structures.md](references/data-structures.md) |

---

## Quick Reference

### 1. Concurrency & Context (CRITICAL)

- Every goroutine MUST have a clear exit mechanism (context, done channel, WaitGroup)
- Share memory by communicating — send copies, not pointers on channels
- Only the sender closes a channel; specify direction (`chan<-`, `<-chan`)
- Always include `ctx.Done()` in `select`; never use `time.After` in loops
- `ctx` MUST be the first parameter; propagate through entire call chain
- Never store context in a struct; `cancel()` MUST be deferred immediately
- Use `errgroup.SetLimit(n)` for bounded concurrency, not hand-rolled worker pools
- Prefer `sync.Mutex` for shared state, channels for ownership transfer
- Always run `go test -race ./...` in CI

### 2. Error Handling (CRITICAL)

- Returned errors MUST always be checked — never discard with `_`
- Wrap with context: `fmt.Errorf("{context}: %w", err)`
- Error strings MUST be lowercase, no trailing punctuation
- Errors MUST be either logged OR returned, NEVER both (single handling rule)
- Use `errors.Is`/`errors.As`, not direct comparison or type assertion
- Use sentinel errors for expected conditions, custom types for carrying data
- Never panic for expected errors — reserve for truly unrecoverable states
- Use `slog` (Go 1.21+) for structured error logging

### 3. Safety & Defensive Coding (CRITICAL)

- Always use comma-ok for type assertions: `v, ok := x.(T)`
- Typed nil pointer in interface is NOT `== nil` — return explicit `nil`
- Writing to nil map panics — always initialize before use
- `append` may reuse backing array — use `s[:len(s):len(s)]` to force copy
- `defer` runs at function exit, not loop iteration — extract to function
- Integer conversions truncate silently — check bounds before converting
- Return defensive copies of slices/maps from exported functions
- Design useful zero values; use `sync.Once` for lazy init

### 4. Type Design (HIGH)

- Interfaces SHOULD have 1–3 methods; compose larger from smaller
- Define interfaces where consumed, not where implemented
- Accept interfaces, return concrete structs — never return interfaces from constructors
- Don't create interfaces prematurely — wait for 2+ implementations
- Use compile-time checks: `var _ Interface = (*Type)(nil)`
- Comma-ok for type assertions; type switches for dynamic dispatch
- Receiver type MUST be consistent: if one method uses pointer, all should
- Exported serialized fields MUST have struct tags

### 5. Design Patterns (HIGH)

- Constructors SHOULD use functional options (`With*` pattern)
- Avoid `init()` — use explicit constructors; enum zero = Unknown/Invalid
- Error cases handled first with early return — keep happy path flat
- `defer Close()` immediately after opening; timeout every external call
- Retry MUST check `ctx.Err()` between attempts; limit all resource pools
- Compile regexp once at package level; use `//go:embed` for static assets
- `string` for display/keys, `[]byte` for mutation/I/O; avoid repeated conversions
- Minimize dependencies — a little recode > a big dependency

### 6. Security (HIGH)

- Parameterized queries for SQL — never concatenate user input
- `exec.Command` with separate args — never shell concatenation
- `html/template` for user data — auto-escaping prevents XSS
- `os.Root` (Go 1.24+) for user-supplied paths; `crypto/rand` for tokens
- `crypto/subtle.ConstantTimeCompare` for secret comparison
- Never expose technical errors to users; never hardcode secrets
- Run `govulncheck ./...` and `go test -race ./...` in CI
- Apply STRIDE at trust boundaries; score with DREAD

### 7. Naming Conventions (MEDIUM)

- All identifiers use MixedCaps — NEVER underscores (except test subcases)
- Package names: lowercase, single word, no plurals; avoid `util`/`helper`
- Don't stutter: `http.Client` not `http.HTTPClient`
- No `Get` prefix on getters; `Is`/`Has`/`Can` for boolean methods
- Constructor: `New()` for single type, `NewTypeName()` for multi-type packages
- Error vars: `ErrNotFound`; error types: `PathError`; strings: lowercase
- Enum zero = `StatusUnknown`; acronyms: all caps or all lower (`URL`, `xmlParser`)
- Receiver: 1–2 letter abbreviation, consistent across all methods

### 8. Performance (MEDIUM)

- Profile before optimizing — intuition is wrong ~80% of the time
- Allocation reduction yields the biggest ROI — GC is fast but not free
- Use `with_capacity` / `make([]T, 0, n)` when size is known
- Rule out external bottlenecks first (DB, API) before optimizing Go code
- Set `GOMEMLIMIT` to 80–90% of container memory to prevent OOM
- Iterative cycle: define metric → benchmark → diagnose → improve → compare
- Document optimizations with benchmark numbers; one change at a time
- Avoid `reflect.DeepEqual` in production (50–200x slower)

### 9. Observability (MEDIUM)

- Use `log/slog` for structured logging — JSON in production
- Histogram over Summary for latency; keep label cardinality low
- Every meaningful operation gets a span (service methods, DB, APIs)
- Propagate context everywhere — `slog.InfoContext(ctx, ...)` for correlation
- Correlate signals: trace_id in logs, exemplars on metrics
- A feature is not done until it is observable
- Migrate legacy loggers (zap/logrus/zerolog) to `slog`
- Use awesome-prometheus-alerts as starting point for alerting

### 10. Modernization (MEDIUM)

- Check `go.mod` version; upgrade to latest stable Go release
- Remove loop variable shadow copies (Go 1.22+)
- Replace `math/rand` with `math/rand/v2` (Go 1.22+)
- Use `min`/`max` builtins (Go 1.21+), `range` over int (Go 1.22+)
- Use `slices`, `maps`, `cmp` packages (Go 1.21+)
- Use `os.Root` for user-supplied paths (Go 1.24+)
- Use `sync.WaitGroup.Go` (Go 1.25+), `t.Context()` (Go 1.24+)
- Run `golangci-lint` with `modernize` linter (v2.6.0+)

### 11. Data Structures (MEDIUM)

- Preallocate slices and maps: `make([]T, 0, n)`, `make(map[K]V, n)`
- Use `slices` and `maps` packages (Go 1.21+) for Sort, Clone, Equal
- `strings.Builder` for concatenation; `bytes.Buffer` for bidirectional I/O
- `container/heap` for priority queues; `container/list` only for middle insertions
- Generic collections: use tightest constraint (`comparable`, `cmp.Ordered`)
- Slice copy shares backing array — use `slices.Clone` for independence
- `weak.Pointer[T]` (Go 1.24+) for GC-safe caches
- Never rely on slice capacity growth timing — algorithm changes between versions

---

## Category Selection by Task

| Task | Primary Categories |
|------|-------------------|
| New function/method | Concurrency, Error Handling, Naming |
| New struct/API | Type Design, Design Patterns, Naming |
| Concurrent code | Concurrency, Safety |
| Error handling | Error Handling, Safety |
| Performance tuning | Performance, Data Structures, Concurrency |
| Security review | Security, Safety |
| Code review | Safety, Naming, Modernization |
| Production readiness | Observability, Security, Performance |
| Choosing data structures | Data Structures, Performance |

---

## Sources

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Proverbs](https://go-proverbs.github.io/)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Go Security Best Practices](https://go.dev/doc/security/best-practices)
- [Go Performance Book](https://tip.golang.org/doc/gc-guide)
- Community conventions (2024–2026)
