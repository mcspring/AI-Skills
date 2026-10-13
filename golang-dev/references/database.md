# Database Access

Choose the data layer that fits the project. `database/sql`, pgx, sqlx, query generators, and ORMs all have valid use cases; do not replace an established approach without a concrete reason.

## Library Choice

| Choice | Good fit | Trade-off |
|---|---|---|
| `database/sql` | portable, minimal dependencies | manual scanning/helpers |
| pgx | PostgreSQL-specific features and protocol control | PostgreSQL-specific |
| sqlx | light conveniences over SQL | still hand-written SQL |
| query generator | compile-time query/types | generation workflow |
| ORM | domain-heavy CRUD and established ORM projects | abstraction/query behavior must be understood |

Prefer the project's existing data layer unless correctness, performance, or maintainability evidence justifies a change.

## Query Safety

Parameterize values. Do not concatenate untrusted input into SQL.

```go
row := db.QueryRowContext(ctx,
    "SELECT id, name FROM users WHERE email = $1", email)
```

Placeholders do not parameterize identifiers such as table/column names. For dynamic identifiers, map user-facing choices to a small allowlist of known SQL fragments.

## Context and Cancellation

Use context-aware operations for work whose lifetime is scoped to a request/job:

```go
rows, err := db.QueryContext(ctx, query, args...)
```

A library-level operation does not need an arbitrary timeout of its own when the caller already owns the deadline. Propagate the caller's context and define timeout policy at the appropriate boundary.

## Rows and Errors

When using APIs that return `*sql.Rows`:

```go
rows, err := db.QueryContext(ctx, query)
if err != nil { return err }
defer rows.Close()

for rows.Next() {
    // Scan...
}
return rows.Err()
```

Distinguish expected absence from operational failure with `errors.Is(err, sql.ErrNoRows)` when using APIs that expose that sentinel. Driver-specific constraints should be translated at the repository/service boundary when callers need domain meaning.

## Transactions

Keep a transaction focused on one consistency boundary. Check every operation and rollback on failure; a deferred rollback is normally safe because it becomes a no-op after commit.

```go
tx, err := db.BeginTx(ctx, nil)
if err != nil { return err }
defer tx.Rollback()

// operations using tx

return tx.Commit()
```

Choose isolation level, locking (`FOR UPDATE`), and retry behavior from the database's consistency requirements. Retry serialization/deadlock failures only when the whole transaction can be safely replayed.

## NULL and Domain Types

Use pointers, `sql.Null*`, driver-specific nullable types, or domain wrappers according to API semantics. Do not choose a representation solely because it is convenient for JSON; database nullability and public API nullability are separate concerns.

## Connection Pool

Pool values are workload settings, not universal constants. Tune with production metrics:

- open connections versus database/server limits;
- wait count/time;
- request latency and concurrency;
- connection churn and lifetime;
- database-side saturation.

Set `MaxOpenConns`, `MaxIdleConns`, `ConnMaxLifetime`, and `ConnMaxIdleTime` only with an understood operational goal.

## Migrations

Keep migrations explicit, reviewable, reproducible, and tested against representative data. Tools such as golang-migrate, Atlas, Flyway, or project-native migration systems are all reasonable choices.

AI may help draft a migration, but generated DDL still requires normal schema review, rollback/forward strategy, and production-safety validation.

## Verification

For database changes:

1. test not-found and constraint paths;
2. test transaction rollback/commit behavior;
3. verify cancellation/deadline propagation where applicable;
4. inspect generated/executed SQL when abstractions are involved;
5. benchmark or query-plan (`EXPLAIN`) only when performance is part of the task.