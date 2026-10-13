# Go gRPC

Use this reference for service boundaries, status mapping, deadlines/cancellation, connection lifecycle, interceptors, health, and tests.

## Service Boundary

Keep protobuf transport types at the transport boundary when the application has a separate domain model. Thin services typically:

1. validate/normalize transport input;
2. call domain/application logic;
3. translate domain failures to gRPC status;
4. build the response.

Do not spread `status.Error` construction through domain code unless the domain itself is intentionally gRPC-specific.

## Status Codes

Return deliberate status codes for conditions callers can act on, for example invalid input, not found, permission denied, conflict/precondition, resource exhaustion, unavailable, or deadline exceeded.

Unknown internal errors should normally become `codes.Internal`/an appropriate safe status while detailed diagnostics stay in server logs/traces.

Avoid exposing raw internal error strings to untrusted clients.

## Context, Deadlines, Cancellation

Server handlers receive a context tied to the RPC. Propagate it into request-scoped DB/network work.

Clients should use deadlines when the product/request has a real latency budget. Reusable low-level libraries should not invent arbitrary deadlines when the caller is responsible for policy.

Respect cancellation and avoid continuing expensive work after the RPC no longer needs a result.

## Connections

gRPC client connections/channels are designed for reuse and multiplexing. Do not dial a new connection per RPC.

Own connection lifecycle at a service/application boundary and close it during shutdown when appropriate.

Connection pooling is usually unnecessary at the gRPC layer unless a specific load-balancing/network requirement calls for multiple channels.

## Interceptors

Use interceptors for cross-cutting transport concerns such as:

- authentication/authorization plumbing;
- tracing/metrics/log correlation;
- panic recovery at the transport boundary;
- consistent metadata handling;
- policy-based retries where the client architecture owns them.

Do not move business validation or domain authorization decisions into generic interceptors when they need request/domain context.

## Retries

Retry only operations that are safe under the service semantics. Prefer gRPC/service-config retry support where appropriate instead of handwritten loops around every call.

Consider:

- idempotency;
- retryable status codes;
- backoff/jitter;
- caller deadline;
- server/load impact.

Never retry cancellation/deadline blindly.

## Health and Readiness

Implement the standard gRPC health service when orchestrators/load balancers/clients use it. Readiness should represent whether the service can handle useful work, not simply whether the process is alive.

Keep health semantics aligned with deployment infrastructure; Kubernetes does not inherently require one specific gRPC implementation if another probe strategy is used.

## Reflection

Reflection is useful for development, debugging, and dynamic tooling. Production policy depends on threat model and operational needs.

Do not disable it solely because “production must never expose reflection”; instead decide whether API discoverability is acceptable and protected by the same network/auth boundaries as the service.

## TLS and Transport Security

Protect RPC traffic according to the deployment trust boundary.

TLS/mTLS is normally appropriate across untrusted networks and service-mesh/public boundaries. Plaintext can be acceptable inside a separately authenticated/encrypted local transport or tightly controlled test environment.

Security requirements should come from the architecture/threat model, not a blanket `TLS MUST` statement detached from transport context.

## Metadata

Use metadata for transport/request context such as auth tokens, trace correlation, locale, or protocol-level hints.

Do not put large business payloads or mutable application state in metadata.

## Streaming

For streaming RPCs:

- define who closes/sends terminal status;
- handle client/server cancellation promptly;
- consider backpressure and bounded application buffering;
- avoid a goroutine per message without bounds;
- surface partial-progress semantics explicitly when errors can occur after earlier messages.

## Graceful Shutdown

Stop accepting new work, allow in-flight RPCs a bounded opportunity to finish according to application shutdown policy, then force termination if necessary.

Do not wait forever for a stuck stream. The timeout belongs to application/deployment shutdown policy.

## Testing

Choose the narrowest layer that proves the behavior:

- direct service method tests for domain/status mapping;
- in-memory transport (`bufconn`) when serialization/interceptors/client behavior matter;
- integration tests against real network/TLS only for behavior those layers can expose.

Test status codes and structured details, not only error strings.

## Observability

Trace/measure RPC method, status, latency, and relevant server/client spans. Keep labels bounded; do not use arbitrary IDs as metric labels.

Log request identifiers and safe diagnostic context without serializing secrets or large payloads by default.

## Common Failures

- raw domain/internal error returned as `Unknown` or leaked to clients;
- dialing per request;
- arbitrary timeout inside a low-level helper conflicting with caller budget;
- retrying non-idempotent RPCs;
- unbounded stream buffering;
- health check that says healthy while critical dependencies make useful work impossible;
- security/reflection rules copied without considering actual network boundary.

## Verification

Run unit/service tests, then transport/integration tests only where needed. Exercise cancellation, deadline, status mapping, streaming termination, retry/idempotency, and graceful shutdown for production-critical services.
