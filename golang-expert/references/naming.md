# Naming Conventions

Go favors short, readable names. Capitalization controls visibility — uppercase exported, lowercase unexported. All identifiers MUST use MixedCaps, NEVER underscores.

> "Clear is better than clever." — Go Proverbs

## Quick Reference

| Element | Convention | Example |
| --- | --- | --- |
| Package | lowercase, single word | `json`, `http`, `tabwriter` |
| File | lowercase, underscores OK | `user_handler.go` |
| Exported name | UpperCamelCase | `ReadAll`, `HTTPClient` |
| Unexported | lowerCamelCase | `parseToken`, `userCount` |
| Interface | method name + `-er` | `Reader`, `Closer`, `Stringer` |
| Struct | MixedCaps noun | `Request`, `FileHeader` |
| Constant | MixedCaps (not ALL_CAPS) | `MaxRetries`, `defaultTimeout` |
| Receiver | 1–2 letter abbreviation | `func (s *Server)`, `func (b *Buffer)` |
| Error variable | `Err` prefix | `ErrNotFound`, `ErrTimeout` |
| Error type | `Error` suffix | `PathError`, `SyntaxError` |
| Constructor | `New` or `NewTypeName` | `ring.New`, `http.NewRequest` |
| Boolean field | `is`, `has`, `can` prefix | `isReady`, `IsConnected()` |
| Test function | `Test` + function name | `TestParseToken` |
| Acronym | all caps or all lower | `URL`, `HTTPServer`, `xmlParser` |
| Option func | `With` + field name | `WithPort()`, `WithLogger()` |
| Enum (iota) | type prefix, zero = unknown | `StatusUnknown` at 0 |
| Error string | lowercase, no punctuation | `"image: unknown format"` |

## MixedCaps

All identifiers use `MixedCaps` — NEVER underscores. Only exceptions: test subcases, generated code, cgo.

```go
// ✓ Good
MaxPacketSize
userCount
parseHTTPResponse

// ✗ Bad
MAX_PACKET_SIZE   // C/Python style
max_packet_size   // snake_case
kMaxBufferSize    // Hungarian notation
```

## Avoid Stuttering

Package name is always at call site — don't repeat it:

```go
http.Client       // not http.HTTPClient
json.Decoder      // not json.JSONDecoder
user.New()        // not user.NewUser()
config.Parse()    // not config.ParseConfig()
```

## Key Conventions

**Constructors:** Single primary type → `New()`. Multiple types → `NewTypeName()`.

**Boolean fields:** Unexported booleans use `is`/`has`/`can` prefix: `isConnected`, `hasPermission`. Exported getter keeps prefix: `IsConnected() bool`.

**Error strings:** Fully lowercase including acronyms: `"invalid message id"` not `"invalid message ID"`. Sentinel errors include package name: `errors.New("apiclient: not found")`.

**Enum zero values:** Always `Unknown`/`Invalid` at iota 0. `StatusUnknown` catches uninitialized.

**Getters:** No `Get` prefix — `user.Name()` not `user.GetName()`. Keep `Is`/`Has`/`Can` for booleans.

**Receivers:** 1–2 letter abbreviation, consistent across all methods of a type. Never `this` or `self`.

**Subtest names:** Lowercase descriptive phrases: `"valid id"`, `"empty input"`.

**Scope-based length:** Short scopes → short names (`i` for 3-line loop). Long scopes → descriptive names.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| `ALL_CAPS` constants | MixedCaps (`MaxRetries`) |
| `GetName()` getter | `Name()` — omit Get |
| `Url`, `Http` acronyms | All caps: `URL`, `HTTP` |
| `this`/`self` receiver | 1–2 letter abbreviation |
| `util`/`helper` packages | Specific names describing content |
| `http.HTTPClient` stuttering | `http.Client` |
| `user.NewUser()` constructor | `user.New()` for single type |
| `connected bool` field | `isConnected` |
| `"invalid message ID"` error | `"invalid message id"` — lowercase |
| `StatusReady` at iota 0 | `StatusUnknown` at 0 |
| `snake_case` identifiers | `mixedCaps` |
| Unnecessary import aliases | Only alias on collision |
