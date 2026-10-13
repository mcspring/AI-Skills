# Go Modernization

Use this reference when updating an existing module to newer language or standard-library capabilities. Start from the `go` directive in `go.mod`; do not assume the newest compiler is an acceptable minimum version.

## Workflow

1. Record the current `go` directive and supported deployment/tooling constraints.
2. Run tests and static analysis before changing behavior.
3. Prefer automated `go fix`/modernize rewrites when they preserve semantics.
4. Upgrade one compatibility boundary at a time.
5. Re-run tests, vet, race/security checks as relevant.

Modernization is optional unless an older API is unsafe, deprecated, unsupported, or materially complicates the code.

## Version Landmarks

| Go | Notable capabilities useful during modernization |
|---|---|
| 1.21 | `slices`, `maps`, `cmp`, `min`/`max`, PGO, `sync.OnceFunc/OnceValue` |
| 1.22 | per-iteration loop variables, range-over-int, `math/rand/v2` |
| 1.23 | range-over-function iterators and iterator ecosystem improvements |
| 1.24 | `os.Root`, `runtime.AddCleanup`, `b.Loop`, tool directives, newer stdlib crypto packages |
| 1.25 | `sync.WaitGroup.Go`, continued synctest/testing improvements |
| 1.26 | `go fix` modernizers and additional stdlib/security migrations |
| 1.27 | generic methods, `encoding/json/v2`, `encoding/json/jsontext`, `goroutineleak` profile |

Check official release notes for exact API availability before editing code.

## Go 1.27

### Generic methods

Methods may declare their own type parameters in Go 1.27. Consider them when the generic operation naturally belongs to a type's API and improves discoverability.

Do not convert package-level generic functions mechanically. Interface methods still cannot declare type parameters, and compatibility/API stability may favor the existing form.

### `encoding/json/v2`

Go 1.27 ships `encoding/json/v2` and `encoding/json/jsontext`.

Use v2 deliberately when stricter semantics, streaming/text-level APIs, options, or performance benefits matter. Important differences include stricter handling of malformed UTF-8 and duplicate object names.

The existing `encoding/json` API remains supported. Do not force migration merely because v2 exists; serialization behavior is a compatibility boundary and should have tests before changing implementation.

### Goroutine leak profile

`runtime/pprof` and `net/http/pprof` expose the `goroutineleak` profile for a useful class of permanently blocked goroutines.

Use it as a diagnostic aid, not as proof that no leak exists: reachability-based detection cannot identify every possible goroutine leak.

## High-Value Modernizations

### Safety/security

- use `os.Root` for filesystem operations scoped to an untrusted/user-selected root where supported;
- migrate obsolete crypto APIs when the replacement improves security guarantees;
- run `govulncheck` when dependency/security changes are in scope;
- replace unsafe slice/string-header manipulation with supported unsafe helpers only when unsafe code is actually required.

### Readability

- use `slices`, `maps`, and `cmp` when they make intent clearer than local helpers;
- remove loop-variable compatibility copies when the module targets Go 1.22+;
- use range-over-int or iterators when they improve the code, not simply because they are newer;
- prefer `WaitGroup.Go` when it matches task lifetime and the module target supports it.

### Testing/performance

- use `b.Loop()` on supported versions for benchmarks;
- use `t.Context()` where it cleanly connects test lifetime to request-scoped APIs;
- evaluate PGO only with representative profiles;
- use current pprof/trace diagnostics before rewriting performance-sensitive code.

## Dependency Modernization

Prefer removing dependencies when the standard library now provides the same capability clearly and migration cost is low. Keep a dependency when it still provides important semantics, ecosystem integration, or compatibility.

Do not replace established libraries with stdlib equivalents without checking behavior, operational tooling, and API surface.

## API Compatibility

For public packages:

- preserve exported names and behavior unless a breaking release is intended;
- avoid raising the minimum Go version for a minor cleanup unless project policy allows it;
- treat JSON/text formats and error matching as compatibility surfaces;
- document minimum-version changes explicitly.

## Tooling

Useful checks include:

```sh
gofmt -w .
go test ./...
go vet ./...
govulncheck ./...
```

Use race tests and benchmarks when the touched code justifies them. `golangci-lint` modernize rules can surface candidates, but review each suggestion against the module's minimum Go version and behavior.

## Avoid

- “upgrade to latest Go” as an unconditional code-review requirement;
- replacing every helper with a newly added stdlib API when readability is unchanged;
- changing JSON implementation without compatibility tests;
- introducing generic methods merely to demonstrate a Go 1.27 feature;
- trusting automated rewrites without running the affected tests.
