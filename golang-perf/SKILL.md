---
name: golang-perf
description: Test, benchmark, profile, and troubleshoot Go programs. Use for unit/integration tests, race/deadlock debugging, pprof/trace, benchmark comparison, CI performance checks, and production diagnosis.
license: MIT
---

# Go Testing & Performance

Reproduce first, measure second, change third. Prefer evidence over folklore.

Current stable release line: Go 1.27 (latest patch: [1.27.3](https://go.dev/doc/devel/release), released 2026-10-19). Check the project's `go` directive and toolchain before recommending newer features; do not upgrade a project solely to match the latest release.

## Testing

- Use the standard `testing` package by default; use testify when the project already benefits from it.
- Keep assertions focused on behavior and use `errors.Is`/`errors.As` for wrapped errors.
- Prefer table tests when cases share behavior, but do not force them when individual tests are clearer.
- Run race detection for code whose correctness depends on concurrency.

See `references/testing.md`.

## Benchmarking & Profiling

- Use `b.Loop()` when the project's Go version supports it.
- Compare repeated samples with `benchstat`; choose sample counts based on noise and effect size rather than a fixed magic number.
- Use pprof, execution tracing, and allocation profiles to identify actual bottlenecks.
- Keep benchmark setup outside the measured region when appropriate and prevent accidental dead-code elimination.
- Treat CI regression thresholds as workload-specific and calibrate them from historical variance.

See `references/benchmarking.md`.

## Troubleshooting

- Capture the exact failure, stack/trace, inputs, and environment before changing code.
- Form one falsifiable hypothesis at a time and add a regression test when practical.
- Escalate from logs and targeted tests to race detector, pprof/trace, Delve, and production telemetry as needed.
- For Go 1.27 projects, use the `goroutineleak` pprof profile when investigating permanently blocked goroutines.

See `references/troubleshooting.md`.

## Verification

After a fix, rerun the reproducer and the narrow relevant test/benchmark first, then the broader suite. Report measured before/after results for performance claims.