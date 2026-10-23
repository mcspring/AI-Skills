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
- Prefer channel communication when it clarifies ownership; sending pointers is valid when shared ownership and synchronization are explicit
- The code coordinating all sends should close a channel when closure signals completion; specify channel direction where it improves API clarity (`chan<-`, `<-chan`)
- Observe cancellation in blocking or long-running work; include `ctx.Done()` in `select` when cancellation must interrupt that wait, and avoid repeated timer allocation in hot loops
- Put `ctx context.Context` first in context-aware APIs and propagate it through request-scoped work where cancellation/deadlines should apply
- Avoid storing request contexts in long-lived structs; call cancellation functions to release resources, commonly with `defer` when the scope matches the function lifetime
- Bound concurrency when workload or resource limits require it; choose `errgroup.SetLimit`, semaphores, or worker pools to fit the task
- Prefer `sync.Mutex` for shared state, channels for ownership transfer
- Always run `go test -race ./...` in CI

### 2. Error Handling (CRITICAL)

- Handle returned errors deliberately; explicitly ignore only when failure is intentionally irrelevant or best-effort
- Add context with `fmt.Errorf("...: %w", err)` when callers benefit from operation detail and error identity must be preserved
- Prefer lowercase error text without terminal punctuation for errors intended to be wrapped; user-facing messages follow product conventions
- Avoid duplicate logging at multiple layers; log and return the same error when each action adds distinct diagnostic or boundary value
- Use `errors.Is`/`errors.As` for wrapped or semantic matching; direct comparison is appropriate for unwrapped sentinels when that is the contract
- Use sentinel errors for expected conditions, custom types for carrying data
- Never panic for expected errors — reserve for truly unrecoverable states
- Use `slog` (Go 1.21+) for structured error logging

### 3. Safety & Defensive Coding (CRITICAL)

- Use comma-ok for type assertions when the value may not have the asserted type; a direct assertion is appropriate when a mismatch is an invariant violation
- Typed nil pointer in interface is NOT `== nil` — return explicit `nil`
- Writing to a nil map panics — initialize it before writing; nil maps remain valid for reads
- `append` may reuse a slice's backing array; use `slices.Clone` or `make` + `copy` when an independent copy is required (`s[:len(s):len(s)]` limits append capacity but does not copy)
- `defer` runs at function exit, not loop iteration — extract to function
- Integer conversions truncate silently — check bounds before converting
- Return defensive copies of slices/maps when callers must not mutate internal state or share mutable backing storage
- Design useful zero values; use `sync.Once` for lazy init

### 4. Type Design (HIGH)

- Keep interfaces focused on one coherent capability; small interfaces are often easier to compose, but method count is not a hard limit
- Define interfaces where consumed, not where implemented
- Accept the narrowest useful interface at boundaries and return concrete types by default; return an interface when hiding the implementation is an intentional API contract
- Introduce interfaces when a consumer needs substitution, testing isolation, or a meaningful abstraction—not only because a type exists or a second implementation has appeared
- Use compile-time checks: `var _ Interface = (*Type)(nil)`
- Comma-ok for type assertions; type switches for dynamic dispatch
- Keep receiver choices consistent where practical, but use pointer/value receivers according to mutation, size, identity, and method-set requirements
- Add serialization tags when the target format's defaults do not match the intended wire contract; tags are not required on every exported field

### 5. Design Patterns (HIGH)

- Use functional options when there are several independent optional settings; simpler constructors or config structs are often clearer
- Prefer explicit initialization when it improves clarity; `init()` and meaningful zero values are valid when their semantics suit the package
- Error cases handled first with early return — keep happy path flat
- Defer cleanup after acquiring a resource when the surrounding scope matches its lifetime; apply deadlines/timeouts to external calls according to caller context and service-level requirements
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

- Follow Go naming conventions (MixedCaps for identifiers); use underscores only where a tool, generated-code convention, or external format requires them
- Package names: lowercase, single word, no plurals; avoid `util`/`helper`
- Don't stutter: `http.Client` not `http.HTTPClient`
- No `Get` prefix on getters; `Is`/`Has`/`Can` for boolean methods
- Constructor: `New()` for single type, `NewTypeName()` for multi-type packages
- Error vars: `ErrNotFound`; error types: `PathError`; strings: lowercase
- Enum zero = `StatusUnknown`; acronyms: all caps or all lower (`URL`, `xmlParser`)
- Use short receiver names (often 1–2 letters) and keep them consistent within a type

### 8. Performance (MEDIUM)

- Profile before optimizing — intuition is wrong ~80% of the time
- Allocation reduction yields the biggest ROI — GC is fast but not free
- Use `make([]T, 0, n)` or `make(map[K]V, n)` when a useful capacity estimate is known
- Rule out external bottlenecks first (DB, API) before optimizing Go code
- Tune `GOMEMLIMIT` against the container limit and other memory consumers using representative workloads; 80–90% is only a possible starting point, not a universal safe value
- Iterative cycle: define metric → benchmark → diagnose → improve → compare
- Document optimizations with benchmark numbers; one change at a time
- Use `reflect.DeepEqual` only when its semantics are appropriate; prefer domain-specific equality or `cmp` where clearer, and benchmark before making performance claims

### 9. Observability (MEDIUM)

- Use `log/slog` for structured logging — JSON in production
- Histogram over Summary for latency; keep label cardinality low
- Instrument important boundaries (such as service calls, database operations, and external APIs) with spans when tracing is enabled and useful
- Propagate context through request-scoped work where cancellation, deadlines, or request metadata matter; use `slog.InfoContext` when a context is available and relevant
- Correlate signals: trace_id in logs, exemplars on metrics
- Add observability proportional to operational risk and the feature's production support needs
- Prefer a consistent structured-logging approach; migrate legacy loggers when there is a concrete maintenance or integration benefit
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

- Preallocate slices and maps when a useful size estimate is available: `make([]T, 0, n)`, `make(map[K]V, n)`
- Use `slices` and `maps` packages (Go 1.21+) for Sort, Clone, Equal
- `strings.Builder` for concatenation; `bytes.Buffer` for bidirectional I/O
- Use `container/heap` for priority queues; choose `container/list` only when its node-based insertion/removal and allocation trade-offs fit the workload
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
