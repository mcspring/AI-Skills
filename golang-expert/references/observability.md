# Observability

Observability is the ability to understand a system's internal state from its external outputs: **logs**, **metrics**, **traces**, **profiles**, and **RUM**.

## Core Rules

1. **Use `log/slog`** for structured logging — JSON in production
2. **Choose the right log level** — Debug/Info/Warn/Error
3. **Log with context** — `slog.InfoContext(ctx, ...)` for trace correlation
4. **Histogram over Summary** for latency — Histograms support server-side aggregation
5. **Keep label cardinality low** — NEVER use unbounded values as Prometheus labels
6. **Every meaningful operation gets a span** — services, DB, APIs
7. **Propagate context everywhere** — context carries trace_id and deadlines
8. **A feature is not done until it is observable**

## The Five Signals

| Signal | Question | Tool | When |
| --- | --- | --- | --- |
| Logs | What happened? | `log/slog` | Events, errors, audit |
| Metrics | How much / how fast? | Prometheus | Aggregates, alerting, SLOs |
| Traces | Where did time go? | OpenTelemetry | Request flow, latency |
| Profiles | Why slow / using memory? | pprof, Pyroscope | CPU, memory, locks |
| RUM | User experience? | PostHog, Segment | Funnels, analytics |

## Structured Logging

```go
// ✓ Good — structured, context-aware
slog.InfoContext(ctx, "order created", "order_id", orderID, "total", total)

// ✗ Bad — unstructured
log.Printf("order created %s %f", orderID, total)
```

### Log Levels

| Level | Use when |
| --- | --- |
| Debug | Development diagnostics |
| Info | Normal operations, state transitions |
| Warn | Degraded but recovering |
| Error | Failures requiring attention |

### Single Handling Rule

```go
// ✗ Bad — log AND return
if err != nil {
    slog.Error("query failed", "error", err)
    return fmt.Errorf("query: %w", err)
}

// ✓ Good — return, log at top level
if err != nil {
    return fmt.Errorf("querying users: %w", err)
}
```

## Metrics

- **Counter**: rate of change (requests, errors)
- **Gauge**: point-in-time snapshot (connections, queue depth)
- **Histogram**: latency distribution (use `histogram_quantile` for P50/P90/P99)

```go
// ✗ Bad — high-cardinality label
httpRequests.WithLabelValues(r.Method, r.URL.Path, userID).Inc()

// ✓ Good — bounded labels
httpRequests.WithLabelValues(r.Method, routePattern).Inc()
```

## Tracing

```go
// Always use context variants
result, err := db.QueryContext(ctx, "SELECT ...")  // ✓
result, err := db.Query("SELECT ...")              // ✗
```

## Correlating Signals

```go
// Logs + Traces: otelslog bridge
logger := otelslog.NewHandler("my-service")
slog.SetDefault(slog.New(logger))
// Every slog call with context includes trace_id, span_id

// Metrics + Traces: exemplars
histogram.WithLabelValues("POST", "/orders").
    (Exemplar(prometheus.Labels{"trace_id": traceID}, duration))
```

## Migrating Legacy Loggers

`slog` is the standard since Go 1.21. Migration path:
1. Add `slog.SetDefault()` with bridge handler
2. Bridge: `samber/slog-zap`, `samber/slog-logrus`, `samber/slog-zerolog`
3. Gradually replace all calls to `slog.Info(...)`
4. Remove bridge and old dependency

## Definition of Done

- [ ] Metrics declared — counters, histograms, gauges with PromQL comments
- [ ] Logging — structured `slog`, context variants, no PII
- [ ] Spans — every service method, DB, API call
- [ ] Dashboards and alerts — wired PromQL, awesome-prometheus-alerts
- [ ] RUM — key events tracked, consent checked

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Log AND return error | Single handling rule — pick one |
| High-cardinality labels | Only bounded values |
| Summary for latency | Histogram (aggregatable) |
| Missing context in DB calls | Always use `*Context` variants |
| No trace correlation in logs | Use `otelslog` bridge |
| Using `fmt.Println` for logging | `slog` for structured output |
