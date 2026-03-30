# Troubleshooting & Debugging

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.** Symptom fixes create new bugs and waste time — especially under time pressure.

## Quick Decision Tree

```
WHAT ARE YOU SEEING?

"Build won't compile"
  → go build ./... 2>&1, go vet ./...

"Wrong output / logic bug"
  → Write a failing test → Check error handling, nil, off-by-one

"Random crashes / panics"
  → GOTRACEBACK=all ./app → go test -race ./...

"Sometimes works, sometimes fails"
  → go test -race ./...

"Program hangs / frozen"
  → curl localhost:6060/debug/pprof/goroutine?debug=2

"High CPU usage"
  → pprof CPU profiling

"Memory growing over time"
  → pprof heap profiling (inuse_space)

"Slow / high latency / p99 spikes"
  → CPU + mutex + block profiles
```

## The Golden Rules

### 1. Read the Error Message First

Go error messages are precise:
- **File and line number** → go directly there
- **Type mismatch** → check function signatures, interface satisfaction
- **"undefined"** → check imports, exported names, build tags
- **"cannot use X as Y"** → check concrete types vs interfaces

### 2. Reproduce Before You Fix

NEVER debug by guessing:
- Write a failing test that captures the bug
- Make it deterministic
- Isolate the minimal failing example
- Use `git bisect` to find the breaking commit

### 3. Measure, Don't Guess

- **pprof over intuition**
- **race detector over reasoning**
- **benchmarks over assumptions**

### 4. One Hypothesis at a Time

Change one thing, measure, confirm. Multiple simultaneous changes teach nothing.

### 5. Find the Root Cause

A band-aid that masks the symptom IS NOT ACCEPTABLE. When stuck:
- Trace data flow backwards from symptom
- Question your assumptions — the code you trust might be wrong
- Ask "why" five times

### 6. Research the Codebase

Before flagging a bug, trace callers and check upstream validation. A function that looks broken in isolation may be correct in context.

### 7. Start Simple

`fmt.Println` IS the right tool for local debugging. Escalate only when needed. Use `slog` in production.

## Red Flags: You're Debugging Wrong

- **"Quick fix for now"** — There is no "later". Find root cause.
- **Multiple simultaneous changes** — One hypothesis at a time.
- **Proposing fixes without understanding** — "Maybe add a nil check?" is guessing.
- **Each fix reveals new problems** — You're treating symptoms.
- **3+ fix attempts** — Wrong mental model. Re-read code from scratch.
- **"Works on my machine"** — Haven't isolated environmental difference.

## Common Go Bugs

| Bug | Symptom | Fix |
| --- | --- | --- |
| Nil pointer dereference | Panic with nil pointer | Check nil before dereference |
| Interface nil trap | `err != nil` true for typed nil | Return explicit `nil` |
| Variable shadowing | Wrong value in outer scope | Use `=` not `:=` for existing vars |
| Slice append aliasing | Silent data corruption | Full slice expression `s[:len:len]` |
| defer in loop | Resource accumulation | Extract to function |
| Unchecked errors | Silent failures | Always check returned errors |
| Missing context cancel | Goroutine/resource leak | `defer cancel()` after `WithTimeout` |
| Concurrent map access | Hard crash | `sync.Mutex` or `sync.Map` |
| JSON unexported fields | Fields silently ignored | Export and add `json` tags |

## Debugging Tools

### Race Detector

```bash
go test -race ./...       # must be in CI
go build -race ./cmd/app  # for manual testing
```

### Full Stack Traces

```bash
GOTRACEBACK=all ./app     # all goroutine stacks on panic
```

### pprof on Running Services

```go
import _ "net/http/pprof"
go http.ListenAndServe("localhost:6060", nil)
```

```bash
# Goroutine dump (find hangs/deadlocks)
curl localhost:6060/debug/pprof/goroutine?debug=2

# CPU profile (30 seconds)
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Heap profile
go tool pprof http://localhost:6060/debug/pprof/heap
```

### Delve Debugger

```bash
dlv debug ./cmd/app       # start with debugger
dlv test ./pkg/parser     # debug tests
dlv attach <pid>          # attach to running process
```

### GODEBUG

```bash
GODEBUG=gctrace=1 ./app          # GC logging
GODEBUG=schedtrace=1000 ./app    # scheduler every 1s
GODEBUG=http2debug=1 ./app       # HTTP/2 frame logging
```

### Compiler Analysis

```bash
go build -gcflags="-m" ./...     # escape analysis
go build -gcflags="-m -m" ./...  # verbose escape analysis
go build -gcflags="-l" ./...     # disable inlining
```

## Production Debugging Checklist

- [ ] Structured logging with `slog` — searchable, correlated
- [ ] pprof endpoints protected with auth, localhost-only
- [ ] `GOTRACEBACK=crash` to get core dumps on panic
- [ ] Goroutine leak detection with monitoring (goroutine count metric)
- [ ] Race detector run in CI on every PR
