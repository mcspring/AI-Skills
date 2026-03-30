# gRPC Services

Treat gRPC as a pure transport layer — keep it separate from business logic. Use `google.golang.org/grpc`.

## Quick Reference

| Concern | Package / Tool |
| --- | --- |
| Service definition | `protoc` or `buf` with `.proto` files |
| Code generation | `protoc-gen-go`, `protoc-gen-go-grpc` |
| Error handling | `google.golang.org/grpc/status` + `codes` |
| Rich error details | `errdetails.BadRequest` via `status.WithDetails` |
| Interceptors | `grpc.ChainUnaryInterceptor`, `grpc.ChainStreamInterceptor` |
| Middleware | `github.com/grpc-ecosystem/go-grpc-middleware` |
| Testing | `google.golang.org/grpc/test/bufconn` |
| TLS / mTLS | `google.golang.org/grpc/credentials` |
| Health checks | `google.golang.org/grpc/health` |

## Proto Organization

Organize by domain with versioned directories (`proto/user/v1/`). Always use `Request`/`Response` wrapper messages — bare types can't evolve.

## Server

```go
srv := grpc.NewServer(
    grpc.ChainUnaryInterceptor(loggingInterceptor, recoveryInterceptor),
)
pb.RegisterUserServiceServer(srv, svc)
healthpb.RegisterHealthServer(srv, health.NewServer())

go srv.Serve(lis)

// Graceful shutdown
stopped := make(chan struct{})
go func() { srv.GracefulStop(); close(stopped) }()
select {
case <-stopped:
case <-time.After(15 * time.Second):
    srv.Stop()
}
```

### Interceptor Pattern

```go
func loggingInterceptor(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
    start := time.Now()
    resp, err := handler(ctx, req)
    slog.Info("rpc", "method", info.FullMethod, "duration", time.Since(start), "code", status.Code(err))
    return resp, err
}
```

## Client

- Reuse connections — HTTP/2 multiplexes RPCs on one connection
- `context.WithTimeout` on every call — no deadline = hang forever
- `round_robin` with `dns:///` for Kubernetes headless services
- Pass auth tokens via `metadata.NewOutgoingContext`

```go
conn, err := grpc.NewClient("dns:///user-service:50051",
    grpc.WithTransportCredentials(creds),
    grpc.WithDefaultServiceConfig(`{
        "loadBalancingPolicy": "round_robin",
        "methodConfig": [{"name": [{"service": ""}], "timeout": "5s"}]
    }`),
)
client := pb.NewUserServiceClient(conn)
```

## Error Handling

Always return `status.Errorf` with specific codes:

| Code | When |
| --- | --- |
| `InvalidArgument` | Malformed input |
| `NotFound` | Entity doesn't exist |
| `AlreadyExists` | Create conflict |
| `PermissionDenied` | Lacks permission |
| `Unauthenticated` | Missing/invalid token |
| `ResourceExhausted` | Rate limit / quota |
| `Unavailable` | Transient, safe to retry |
| `Internal` | Unexpected bug |
| `DeadlineExceeded` | Timeout |

```go
// ✗ Raw error → codes.Unknown
return nil, fmt.Errorf("user not found")

// ✓ Specific code
return nil, status.Errorf(codes.NotFound, "user %q not found", req.UserId)
```

## Streaming

| Pattern | Use Case |
| --- | --- |
| Server streaming | Log tailing, result sets |
| Client streaming | File upload, batch |
| Bidirectional | Chat, real-time sync |

Prefer streaming over large single messages.

## Security

- TLS MUST be enabled in production
- mTLS or service mesh for service-to-service auth
- `credentials.PerRPCCredentials` + auth interceptor for user auth
- Disable reflection in production

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Raw `error` return | `status.Errorf` with specific code |
| No deadline on client calls | Always `context.WithTimeout` |
| New connection per request | Create once, reuse |
| Reflection in production | Disable — prevents API discovery |
| `codes.Internal` for all errors | Wrong codes break retry logic |
| Bare types as RPC args | Wrapper messages for evolution |
| Missing health check | Kubernetes can't determine readiness |
| Ignoring context cancellation | Check `ctx.Err()` in long operations |
