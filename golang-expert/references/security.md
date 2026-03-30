# Security

Security follows defense in depth: protect at multiple layers, validate all inputs, use secure defaults.

## Security Thinking Model

Before writing or reviewing code, ask:
1. **What are the trust boundaries?** — Where does untrusted data enter?
2. **What can an attacker control?** — Which inputs flow into sensitive operations?
3. **What is the blast radius?** — If this defense fails, what's the worst outcome?

## Quick Reference

| Severity | Vulnerability | Defense | Standard Library |
| --- | --- | --- | --- |
| Critical | SQL Injection | Parameterized queries | `database/sql` with `?` placeholders |
| Critical | Command Injection | Separate args, no shell | `exec.Command` with separate args |
| High | XSS | Auto-escaping templates | `html/template` |
| High | Path Traversal | Scope to root dir | `os.Root` (Go 1.24+), `filepath.Clean` |
| Medium | Timing Attacks | Constant-time compare | `crypto/subtle.ConstantTimeCompare` |
| High | Crypto Issues | Vetted algorithms only | `crypto/aes` GCM, `crypto/rand` |
| Medium | Rate Limiting | Prevent brute-force | `golang.org/x/time/rate`, server timeouts |
| High | Race Conditions | Protect shared state | `sync.Mutex`, channels |

## Injection Prevention

```go
// ✗ Critical — SQL injection
db.Query("SELECT * FROM users WHERE id = '" + id + "'")

// ✓ Good — parameterized
db.QueryContext(ctx, "SELECT * FROM users WHERE id = $1", id)

// ✗ Critical — command injection
exec.Command("bash", "-c", "echo " + userInput)

// ✓ Good — separate args
exec.Command("echo", userInput)
```

## Cryptography

- Use `crypto/rand` for tokens/keys — `math/rand` is predictable
- AES with GCM mode — ECB/CBC lack authentication
- Argon2id or bcrypt for passwords — never MD5/SHA1
- Never roll your own crypto

## Filesystem

- `os.Root` (Go 1.24+) for user-supplied paths — prevents `../` escapes
- Validate file sizes before reading — zip bomb prevention
- Set restrictive permissions: `0600` for secrets, `0644` for config

## Network Security

- Always use TLS; configure `MinVersion: tls.VersionTLS12`
- Security headers: HSTS, CSP, X-Frame-Options
- Validate redirect URLs against allowlist — prevent open redirects
- Bind to specific interface, not `0.0.0.0`

## Secrets Management

- NEVER hardcode secrets in source code
- Use environment variables or secret managers (Vault, AWS SM)
- Per-environment secrets — staging breach must not compromise production

## Threat Modeling (STRIDE)

Apply at every trust boundary: **S**poofing, **T**ampering, **R**epudiation, **I**nformation Disclosure, **D**enial of Service, **E**levation of Privilege. Score with DREAD (Damage, Reproducibility, Exploitability, Affected users, Discoverability).

## Tooling

```bash
# SAST
gosec ./...

# Vulnerability scanner
govulncheck ./...

# Race detector
go test -race ./...

# Fuzz testing
go test -fuzz=Fuzz
```

## Common Mistakes

| Severity | Mistake | Fix |
| --- | --- | --- |
| High | `math/rand` for tokens | Use `crypto/rand` |
| Critical | SQL string concatenation | Parameterized queries |
| Critical | `exec.Command("bash -c")` | Separate args |
| Critical | Hardcoded secrets | Env vars or secret managers |
| Medium | `==` for secret comparison | `crypto/subtle.ConstantTimeCompare` |
| High | MD5/SHA1 for passwords | Argon2id or bcrypt |
| High | AES without GCM | GCM provides encrypt + authenticate |
| Medium | Binding to `0.0.0.0` | Bind to specific interface |
| High | Ignoring `-race` findings | Fix all races |
| Critical | Rolling your own crypto | Use standard library |

## Anti-Patterns

| Anti-Pattern | Fix |
| --- | --- |
| Security through obscurity | Authentication + authorization on all endpoints |
| Trusting client headers | Server-side identity verification |
| Client-side authorization | Server-side permission checks |
| Shared secrets across envs | Per-environment via secret manager |
| Ignoring crypto errors | Always check — fail closed |
