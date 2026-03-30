---
name: golang-dev
description: >
  Go development libraries and patterns. Covers database access (sqlx/pgx),
  gRPC services, and samber ecosystem (lo, mo, ro). Use when writing database
  queries, gRPC servers/clients, functional transforms, monadic types, or
  reactive streams in Go. Invoke with /golang-dev.
license: MIT
metadata:
  version: "1.0.0"
  sources:
    - database/sql
    - google.golang.org/grpc
    - samber/lo, samber/mo, samber/ro
---

# Go Development Libraries

Practical guidance for database access, gRPC services, and the samber functional programming ecosystem.

## When to Apply

- Writing or reviewing database queries (sqlx, pgx)
- Implementing gRPC servers, clients, or interceptors
- Using samber/lo for functional collection transforms
- Using samber/mo for monadic types (Option, Result, Either)
- Building reactive pipelines with samber/ro

## Categories

| Priority | Category | Impact | Reference |
|----------|----------|--------|-----------|
| 1 | Database Access | HIGH | [database.md](references/database.md) |
| 2 | gRPC Services | HIGH | [grpc.md](references/grpc.md) |
| 3 | samber/lo — Functional Transforms | MEDIUM | [samber-lo.md](references/samber-lo.md) |
| 4 | samber/mo — Monadic Types | MEDIUM | [samber-mo.md](references/samber-mo.md) |
| 5 | samber/ro — Reactive Streams | MEDIUM | [samber-ro.md](references/samber-ro.md) |

---

## Quick Reference

### 1. Database Access (HIGH)

- Use sqlx or pgx, NOT ORMs — ORMs hide SQL and generate unpredictable queries
- Parameterized queries ONLY — never concatenate user input into SQL
- Pass `ctx` to all DB operations — use `*Context` method variants
- Handle `sql.ErrNoRows` explicitly — distinguish "not found" from real errors
- `defer rows.Close()` immediately after `QueryContext`
- Use `db.Exec` for non-returning statements — `db.Query` leaks connections if rows aren't closed
- Configure connection pool: `SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime`
- Use external migration tools (golang-migrate, Atlas) — never AI-generated schema SQL

### 2. gRPC Services (HIGH)

- Always return `status.Errorf` with specific codes — raw errors become `codes.Unknown`
- Set deadlines on every client call with `context.WithTimeout`
- Reuse connections — gRPC multiplexes RPCs on a single HTTP/2 connection
- Use interceptors for cross-cutting concerns (logging, auth, recovery)
- Implement `grpc_health_v1` health check — Kubernetes needs it for readiness
- Use `GracefulStop()` with timeout fallback to `Stop()`
- Disable reflection in production — prevents API discovery by attackers
- Use `bufconn` for testing the full gRPC stack in-memory

### 3. samber/lo — Functional Transforms (MEDIUM)

- Prefer stdlib (`slices.Contains`, `slices.Sort`, `maps.Keys`) when available
- Use `lo.Map`, `lo.Filter`, `lo.Reduce`, `lo.GroupBy` for transforms stdlib lacks
- `lo.MapErr` for error-aware transforms — stops on first error
- `lop` for CPU-bound parallelism (1000+ items), NOT for I/O — use `errgroup` for I/O
- `lom` for in-place mutation — only when allocation pressure is profiled
- `loi` for lazy iterators (Go 1.23+) — avoids intermediate allocations in chains
- `lo.Must` only in tests and init — panics in production code

### 4. samber/mo — Monadic Types (MEDIUM)

- `Option[T]` for nullable values — eliminates nil pointer risks at the type level
- `Result[T]` for error handling as values — `TupleToResult` wraps Go's `(T, error)`
- `Either[L, R]` for two valid alternatives — not for errors (use Result)
- Use sub-package pipes (`result.Pipe2`) for type-changing transforms
- `mo.Do` for imperative style with monadic safety — catches `MustGet()` panics
- Option implements `json.Marshaler` and `sql.Scanner` — use directly in structs

### 5. samber/ro — Reactive Streams (MEDIUM)

- Use for infinite/async event streams — NOT for finite slice transforms (use lo)
- Always handle all 3 events: `onNext`, `onError`, `onComplete`
- Bound infinite streams with `Take(n)`, `TakeUntil`, `Timeout`, or context
- Use typed `Pipe2`–`Pipe25` — untyped `Pipe` loses compile-time safety
- Cold observables by default — use `Share()` only for multicast scenarios
- 40+ plugins for HTTP, cron, fsnotify, JSON, logging, rate limiting

---

## Category Selection by Task

| Task | Primary Categories |
|------|-------------------|
| Database queries / CRUD | Database |
| Transaction management | Database |
| gRPC server/client | gRPC |
| Proto file organization | gRPC |
| Slice/map transforms | samber/lo |
| Nullable values / Option | samber/mo |
| Error pipelines / Result | samber/mo |
| Event streams / realtime | samber/ro |
| WebSocket fan-out | samber/ro |
