# Database Access

Go's `database/sql` provides a solid foundation. Use `sqlx` or `pgx` on top — never an ORM.

## Library Choice

| Library | Best for | Struct scanning | PostgreSQL-specific |
| --- | --- | --- | --- |
| `database/sql` | Portability | Manual `Scan` | No |
| `sqlx` | Multi-database | `StructScan` | No |
| `pgx` | PostgreSQL (30–50% faster) | `pgx.RowToStructByName` | Yes (COPY, LISTEN) |
| GORM/ent | **Avoid** | Magic | Abstracted away |

## Parameterized Queries

```go
// ✗ SQL injection
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)

// ✓ Parameterized (PostgreSQL)
err := db.GetContext(ctx, &user, "SELECT id, name FROM users WHERE email = $1", email)

// ✓ Parameterized (MySQL)
err := db.GetContext(ctx, &user, "SELECT id, name FROM users WHERE email = ?", email)
```

### Dynamic IN Clauses

```go
query, args, err := sqlx.In("SELECT * FROM users WHERE id IN (?)", ids)
query = db.Rebind(query)
err = db.SelectContext(ctx, &users, query, args...)
```

### Dynamic Column Names

Never interpolate from user input — use allowlist:

```go
allowed := map[string]bool{"name": true, "email": true, "created_at": true}
if !allowed[sortCol] {
    return fmt.Errorf("invalid sort column: %s", sortCol)
}
```

## Error Handling

```go
err := db.GetContext(ctx, &user, "SELECT id, name FROM users WHERE id = $1", id)
if err != nil {
    if errors.Is(err, sql.ErrNoRows) {
        return nil, ErrUserNotFound // domain error
    }
    return nil, fmt.Errorf("querying user %s: %w", id, err)
}
```

### Always Close Rows

```go
rows, err := db.QueryContext(ctx, "SELECT id, name FROM users")
if err != nil { return fmt.Errorf("querying: %w", err) }
defer rows.Close()

for rows.Next() { /* scan */ }
if err := rows.Err(); err != nil { return fmt.Errorf("iterating: %w", err) }
```

### Error Patterns

| Error | Detection | Action |
| --- | --- | --- |
| Not found | `errors.Is(err, sql.ErrNoRows)` | Return domain error |
| Unique constraint | Driver-specific error code | Return conflict error |
| Connection refused | `db.PingContext` fails | Fail fast, retry with backoff |
| Serialization failure | PostgreSQL `40001` | Retry entire transaction |
| Context canceled | `errors.Is(err, context.Canceled)` | Stop, propagate |

## NULLable Columns

Use pointer fields (`*string`, `*time.Time`) — works with scanning and JSON:

```go
type User struct {
    ID    int        `db:"id"    json:"id"`
    Name  string     `db:"name"  json:"name"`
    Phone *string    `db:"phone" json:"phone,omitempty"`
}
```

## Transactions

```go
tx, err := db.BeginTxx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
if err != nil { return err }
defer tx.Rollback() // no-op if committed

if _, err := tx.ExecContext(ctx, "UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, from); err != nil {
    return fmt.Errorf("debit: %w", err)
}
if _, err := tx.ExecContext(ctx, "UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, to); err != nil {
    return fmt.Errorf("credit: %w", err)
}
return tx.Commit()
```

Use `SELECT ... FOR UPDATE` when reading data you intend to modify.

## Connection Pool

```go
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(10)
db.SetConnMaxLifetime(5 * time.Minute)
db.SetConnMaxIdleTime(1 * time.Minute)
```

## Context Propagation

Always use `*Context` variants — queries respect cancellation and timeouts:

```go
db.QueryContext(ctx, "SELECT ...")  // ✓
db.Query("SELECT ...")              // ✗ runs until completion
```

## Migrations

Use external tools — never AI-generated schema SQL:
- [golang-migrate](https://github.com/golang-migrate/migrate)
- [Atlas](https://atlasgo.io/)
- [Flyway](https://flywaydb.org/)

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| SQL string concatenation | Parameterized queries |
| Missing `rows.Close()` | `defer rows.Close()` immediately |
| `db.Query` for non-returning SQL | Use `db.Exec` — Query leaks connections |
| Ignoring `sql.ErrNoRows` | Check with `errors.Is` |
| No context on DB calls | Always `*Context` variants |
| No connection pool config | Set `MaxOpenConns`, `MaxIdleConns`, `ConnMaxLifetime` |
| ORM for database access | Use sqlx or pgx directly |
