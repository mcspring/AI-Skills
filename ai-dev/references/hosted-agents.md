# Hosted and Background Agents

Use this reference for server-side agents that run in sandboxes/containers, persist beyond one client connection, or serve multiple clients/users.

## Server Owns Durable Work

Keep long-running agent state on the server rather than binding it to one browser, Slack thread, or desktop connection.

Persist:

- task/run ID;
- user/workspace identity and permissions;
- current status/checkpoint;
- artifact/workspace version;
- tool side effects;
- outputs/errors needed for resume.

Clients should be resumable views/controllers of that state.

## Sandbox Lifecycle

A sandbox should have a clear lifecycle:

1. create or restore an environment;
2. sync/mount the required workspace and credentials;
3. execute with least privilege;
4. persist artifacts/checkpoints that must survive;
5. terminate/hibernate according to workload policy.

Do not assume one universal image rebuild or warm-pool cadence. Tune startup strategy from dependency churn, security patching, cache hit rate, latency SLOs, and infrastructure cost.

## Warm Starts

Warm pools/prebuilt images can reduce startup latency but increase idle cost and staleness risk.

Measure:

- cold-start distribution;
- warm-pool hit rate;
- image age/security requirements;
- workspace sync cost;
- idle resource spend.

Use those signals to choose pool size and refresh policy.

## Workspace Synchronization

Treat source/workspace state as versioned data.

Before mutation, ensure the agent knows which revision it is editing. Use optimistic concurrency/checkpoints where possible so a stale worker does not overwrite newer user work.

Reads may tolerate different freshness than writes, but that policy should come from product semantics—not a fixed time threshold.

## Credentials and Permissions

Inject only credentials needed for the task. Prefer scoped, short-lived tokens and server-side policy enforcement.

Keep tool permissions separate from what the model merely knows how to request. A model instruction is not an authorization boundary.

## Network and Data Boundaries

Define:

- outbound network policy;
- allowed domains/services;
- secret redaction/logging policy;
- artifact retention;
- tenant/workspace isolation;
- limits on CPU/memory/disk/runtime.

Multi-tenant agents require isolation at infrastructure and authorization layers, not only prompt separation.

## API Shape

A hosted run commonly needs:

- create/start;
- stream/read events;
- get current status/result;
- provide user input/approval;
- cancel;
- resume/retry from checkpoint;
- list/download artifacts.

Use stable run/artifact IDs so clients can reconnect without replaying the full event stream.

## Streaming

Stream state changes that matter to users or downstream systems:

- phase/action starts;
- approval requests;
- meaningful tool results;
- artifacts;
- final status/error.

Avoid verbose token-level/internal logs when they do not help the user make a decision.

## Background Execution

If the user disconnects, the server should know whether the run:

- continues;
- pauses awaiting reconnect/approval;
- cancels automatically.

Make this an explicit product policy. Preserve enough checkpoint state to recover from worker failure without rerunning irreversible steps.

## Multi-Client / Multiplayer

When several clients or users can observe/control a run:

- centralize authoritative task state;
- version mutable workspace state;
- define who can approve/cancel/edit;
- attribute actions to the initiating/approving user;
- expose conflicts rather than silently taking last write.

## Code Agents

For agents editing repositories:

- isolate working copies/worktrees when concurrent edits can collide;
- checkpoint before risky multi-file changes;
- run verification in the same environment that produced the edit;
- attribute commits according to product/user policy;
- keep generated patches/artifacts reviewable.

## Observability

Measure the full run lifecycle:

- queue/cold-start time;
- model/tool latency;
- sandbox failures;
- retries;
- user approval wait time;
- tokens and infrastructure cost;
- task success/accepted output;
- resume/recovery rate.

Infrastructure optimization should follow these traces, not fixed folklore.

## Avoid

- client-local state as the only copy of a long-running task;
- blanket permanent credentials inside sandboxes;
- fixed warm-pool/image cadences without telemetry;
- writes from stale workspace revisions;
- conflating model instructions with authorization;
- replaying irreversible side effects after worker retry.
