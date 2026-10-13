---
name: golang-expert
description: Write, review, and modernize idiomatic Go. Use for concurrency, errors, APIs, types, security, performance, observability, modernization, and production-readiness reviews.
license: MIT
---

# Go Expert

Favor simple, explicit Go that follows the standard library and the project's existing conventions. Treat guidance as context-dependent unless it protects correctness or security.

## Start Here

1. Check `go.mod` for the declared Go version and existing dependencies.
2. Load only the reference files relevant to the task.
3. Preserve public behavior unless the user asks for an API change.
4. Prefer standard-library capabilities before adding dependencies.

Current stable line: Go 1.27. Use newer APIs only when the module's `go` directive permits them.

## Core Guidance

- Concurrency: every goroutine needs an ownership/lifetime story; propagate cancellation where work is request-scoped; use channels for coordination and mutexes/atomics for shared state when they are clearer.
- Errors: return useful context, preserve wrapped errors with `%w` when callers need matching, and use `errors.Is`/`errors.As` across wrapped chains.
- APIs: prefer small concrete APIs, useful zero values, interfaces at consumption boundaries, and compatibility-conscious exported types.
- Safety/security: parameterize queries, avoid shell-string construction for untrusted input, use `crypto/rand` for secrets, and validate path/file boundaries.
- Performance: measure first; use benchmarks, profiles, traces, and allocation data before changing code for speed.
- Observability: use structured logs/metrics/traces where the service needs them; keep cardinality and sensitive data under control.
- Modernization: prefer current stdlib facilities when they simplify code without forcing an unsupported minimum Go version.

## Go 1.27 Notes

When the project targets Go 1.27, consider generic methods, `encoding/json/v2`/`encoding/json/jsontext`, the `goroutineleak` profile, newer `go fix` modernizers, and current testing/vet behavior when they materially simplify the task. Do not migrate solely for novelty.

## Reference Router

| Need | Reference |
|---|---|
| Concurrency/context | `references/concurrency.md` |
| Error handling | `references/error-handling.md` |
| Defensive coding | `references/safety.md` |
| API/type design | `references/type-design.md` |
| Common patterns | `references/design-patterns.md` |
| Security | `references/security.md` |
| Naming | `references/naming.md` |
| Performance | `references/performance.md` |
| Observability | `references/observability.md` |
| Version modernization | `references/modernization.md` |
| Collections/data structures | `references/data-structures.md` |

## Verification

Run the narrowest relevant checks first, then expand as needed: `gofmt`, `go test`, `go vet`, race tests for concurrent code, `govulncheck` for security-sensitive dependency work, and benchmarks/profiles for performance claims.