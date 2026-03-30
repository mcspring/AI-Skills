---
name: golang-perf
description: >
  Go testing, benchmarking, and troubleshooting. Use when writing tests with
  testify, benchmarking with pprof/benchstat, debugging crashes/deadlocks/races,
  or setting up CI regression detection. Covers stretchr/testify (assert/require/
  mock/suite), benchmark methodology, profiling, Delve debugger, race detection,
  and production debugging. Invoke with /golang-perf.
license: MIT
metadata:
  version: "1.0.0"
  sources:
    - Go testing package
    - stretchr/testify
    - samber/cc-skills-golang
---

# Go Testing, Benchmarking & Troubleshooting

Testing, measurement, and debugging — the three pillars of reliable Go code. Write tests to constrain behavior, benchmark to prove performance, and debug systematically to find root causes.

## When to Apply

- Writing or reviewing tests with `stretchr/testify`
- Benchmarking functions with `b.Loop()` / pprof / benchstat
- Debugging crashes, deadlocks, races, or unexpected behavior
- Setting up CI benchmark regression detection
- Profiling production services

## Categories

| Priority | Category | Impact | Reference |
|----------|----------|--------|-----------|
| 1 | Testing (testify) | HIGH | [testing.md](references/testing.md) |
| 2 | Benchmarking & Profiling | HIGH | [benchmarking.md](references/benchmarking.md) |
| 3 | Troubleshooting & Debugging | HIGH | [troubleshooting.md](references/troubleshooting.md) |

---

## Quick Reference

### 1. Testing with testify (HIGH)

- `require` for preconditions (stop on failure), `assert` for verifications (continue)
- Argument order: always `(expected, actual)`
- Use `is.ErrorIs` not `is.Equal` for error comparison — walks wrapped chains
- Mock: embed `mock.Mock`, implement with `m.Called()`, verify with `AssertExpectations(t)`
- Suite: `SetupSuite` → `SetupTest` → `TestXxx` → `TearDownTest` → `TearDownSuite`
- Always include `suite.Run(t, new(MySuite))` launcher — without it, zero tests run

### 2. Benchmarking & Profiling (HIGH)

- Use `b.Loop()` (Go 1.24+) — prevents compiler dead code elimination
- Always `-count=10` minimum for statistical significance
- Compare with `benchstat old.txt new.txt` — never eyeball single runs
- Profile from benchmarks: `-cpuprofile`, `-memprofile`, `-trace`
- `alloc_objects` for GC churn, `inuse_space` for leaks
- Track regressions in CI with benchdiff/cob/gobenchdata

### 3. Troubleshooting (HIGH)

- **NO FIXES WITHOUT ROOT CAUSE** — symptom fixes create new bugs
- Reproduce before you fix — write a failing test first
- One hypothesis at a time — change one thing, measure, confirm
- Always run `go test -race ./...` for concurrency bugs
- Escalate tools incrementally: `fmt.Println` → `slog` → pprof → Delve
- `GOTRACEBACK=all` for full stack traces on panics

---

## Category Selection by Task

| Task | Primary Categories |
|------|-------------------|
| Writing unit tests | Testing |
| Creating mocks | Testing |
| Measuring performance | Benchmarking |
| CI regression detection | Benchmarking |
| Crash / panic debugging | Troubleshooting |
| Memory leak investigation | Benchmarking, Troubleshooting |
| Race condition debugging | Troubleshooting |
| Production latency spike | Benchmarking, Troubleshooting |
