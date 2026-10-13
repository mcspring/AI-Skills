---
name: golang-dev
description: Practical Go guidance for database access, gRPC, and the samber ecosystem. Use when working with SQL/pgx/sqlx, gRPC services, lo/mo/ro, or choosing between these libraries and the standard library.
license: MIT
---

# Go Development Libraries

Use project conventions first. Prefer the standard library when it is sufficient, and introduce a library only when it clearly improves the implementation.

## Database

- Use parameterized SQL and context-aware calls for request-scoped work.
- Choose `database/sql`, pgx, sqlx, query generators, or an ORM based on project needs; do not replace an established data layer without a concrete reason.
- Distinguish not-found from operational errors and close/consume rows correctly.
- Configure pooling from workload measurements rather than fixed defaults.
- Keep schema migrations explicit, reviewable, and reproducible.

See `references/database.md`.

## gRPC

- Map domain failures to deliberate gRPC status codes at service boundaries.
- Propagate cancellation and deadlines from callers; do not invent arbitrary timeouts deep in reusable libraries.
- Reuse client connections/channels and use interceptors for genuinely cross-cutting behavior.
- Support health checks, graceful shutdown, observability, and reflection according to deployment/security requirements.
- Test handlers and transport behavior at the narrowest useful layer.

See `references/grpc.md`.

## samber

Use stdlib `slices`, `maps`, iterators, and ordinary `(T, error)` patterns when they are clearer. Reach for samber when the project already uses it or its abstractions materially simplify the code.

- `lo`: collection transforms not expressed as clearly with stdlib. See `references/samber-lo.md`.
- `mo`: Option/Result/Either when value-oriented composition is a project convention. See `references/samber-mo.md`.
- `ro`: asynchronous/reactive streams where an observable model is a better fit than channels or iterators. See `references/samber-ro.md`.

## Version Awareness

Check `go.mod` before recommending APIs. Go 1.27 adds generic methods and broader standard-library capabilities, so re-evaluate helper-library usage when modernizing a project rather than assuming older trade-offs still apply.