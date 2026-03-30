# Modernization

Keep Go codebases current with the latest language features and standard library improvements. Scope: Go 1.21 through Go 1.26 (2023–2026).

## Workflow

1. Check `go.mod` / `go.work` for current Go version
2. Check latest release at https://go.dev/dl/
3. Scan for modernization opportunities based on target version
4. Run `golangci-lint` with `modernize` linter (v2.6.0+)
5. Prioritize by impact: safety → readability → gradual improvement

## Go Version Changelogs

| Version | Release | Changelog |
| --- | --- | --- |
| Go 1.21 | Aug 2023 | https://go.dev/doc/go1.21 |
| Go 1.22 | Feb 2024 | https://go.dev/doc/go1.22 |
| Go 1.23 | Aug 2024 | https://go.dev/doc/go1.23 |
| Go 1.24 | Feb 2025 | https://go.dev/doc/go1.24 |
| Go 1.25 | Aug 2025 | https://go.dev/doc/go1.25 |
| Go 1.26 | Feb 2026 | https://go.dev/doc/go1.26 |

## Deprecated Packages

| Deprecated | Replacement | Since |
| --- | --- | --- |
| `math/rand` | `math/rand/v2` | Go 1.22 |
| `crypto/elliptic` (most) | `crypto/ecdh` | Go 1.21 |
| `reflect.SliceHeader` | `unsafe.Slice`, `unsafe.String` | Go 1.21 |
| `runtime.SetFinalizer` | `runtime.AddCleanup` | Go 1.24 |
| `golang.org/x/crypto/sha3` | `crypto/sha3` | Go 1.24 |
| `golang.org/x/crypto/hkdf` | `crypto/hkdf` | Go 1.24 |
| `golang.org/x/crypto/pbkdf2` | `crypto/pbkdf2` | Go 1.24 |
| `testing/synctest.Run` | `testing/synctest.Test` | Go 1.25 |
| `crypto.EncryptPKCS1v15` | OAEP encryption | Go 1.26 |
| `ReverseProxy.Director` | `ReverseProxy.Rewrite` | Go 1.26 |

## Migration Priority

### High Priority (safety & correctness)

1. Remove loop variable shadow copies — Go 1.22+
2. Replace `math/rand` with `math/rand/v2` — Go 1.22+
3. Use `os.Root` for user-supplied paths — Go 1.24+
4. Run `govulncheck` — Go 1.22+
5. Use `errors.Is`/`errors.As` instead of direct comparison
6. Migrate deprecated crypto packages — Go 1.24+

### Medium Priority (readability)

7. Replace `interface{}` with `any` — Go 1.18+
8. Use `min`/`max` builtins — Go 1.21+
9. Use `range` over int — Go 1.22+
10. Use `slices` and `maps` packages — Go 1.21+
11. Use `cmp.Or` for default values — Go 1.22+
12. Use `sync.OnceValue`/`sync.OnceFunc` — Go 1.21+
13. Use `sync.WaitGroup.Go` — Go 1.25+
14. Use `t.Context()` in tests — Go 1.24+
15. Use `b.Loop()` in benchmarks — Go 1.24+

### Lower Priority (gradual)

16. Migrate to `slog` — Go 1.21+
17. Adopt iterators — Go 1.23+
18. Replace `sort.Slice` with `slices.SortFunc` — Go 1.21+
19. Use `strings.SplitSeq` — Go 1.24+
20. Tool deps to `go.mod` tool directives — Go 1.24+
21. Enable PGO — Go 1.21+
22. Upgrade to golangci-lint v2 with `modernize` — v2.6.0+
23. Add `govulncheck` to CI
24. Evaluate `encoding/json/v2` — Go 1.25+

## Key Modernizations by Version

### Go 1.21+
- `min()`, `max()` builtins
- `slices`, `maps`, `cmp` packages
- `log/slog` structured logging
- `sync.OnceFunc`, `sync.OnceValue`, `sync.OnceValues`
- `context.WithoutCancel`

### Go 1.22+
- Loop variable per-iteration scoping (no more shadow copies)
- `range` over integers: `for i := range 10`
- `math/rand/v2`
- `cmp.Or` for default values

### Go 1.23+
- Range-over-func iterators (`iter.Seq`, `iter.Seq2`)
- `slices.All`, `slices.Values`, `maps.Keys`, `maps.Values`
- `structs.HostLayout` for cgo

### Go 1.24+
- `os.Root` for path-safe file access
- `t.Context()` — test context auto-cancelled on cleanup
- `b.Loop()` — benchmark loop with compiler optimization prevention
- `runtime.AddCleanup` replaces `SetFinalizer`
- `strings.SplitSeq`, `strings.FieldsSeq`
- `go.mod` tool directives

### Go 1.25+
- `sync.WaitGroup.Go` — spawn and track goroutines
- `testing/synctest.Test` replaces `synctest.Run`
- `encoding/json/v2` (experimental)

### Go 1.26+
- Rewritten `go fix` with modernize analyzers
- `ReverseProxy.Rewrite` replaces `Director`

## Tooling

```bash
# Modernize linter (golangci-lint v2)
golangci-lint run --enable modernize

# Vulnerability check
govulncheck ./...

# Go fix with modernize (Go 1.26+)
go fix -fix modernize ./...
```
