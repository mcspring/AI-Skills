# Agent Tool Design

Use this reference when defining function tools, MCP tools, command surfaces, or tool result contracts for an agent.

## Tools Are Contracts

A tool description should make clear:

- what the tool does;
- when to use it;
- required and optional inputs;
- what it returns;
- important side effects;
- permissions/irreversibility;
- expected failure modes.

Design for model selection and recovery, not only for human API aesthetics.

## One Clear Purpose

Prefer a small number of semantically distinct tools over many overlapping variants.

Bad split:
- `read_text_file`
- `read_markdown_file`
- `read_json_file`

when one `read_file` contract can express all three safely.

Good split occurs when permissions, side effects, latency, or output semantics differ enough that the agent must make a meaningful choice.

There is no universal maximum tool count. Measure selection quality as collections grow; namespaces, routing, and progressive disclosure can support larger ecosystems than a flat list.

## Input Schema

Prefer:

- typed enums over free-form magic strings;
- separate fields over overloaded mini-languages;
- bounded/defaulted values where useful;
- identifiers that can be reused in follow-up calls;
- explicit destructive/irreversible flags only when they represent real behavior.

Avoid giant schemas containing options the agent almost never needs.

## Output Design

Return the smallest structured result that supports the next action.

Useful output often includes:

- success/error status;
- stable resource IDs;
- concise result/summary;
- changed state/version;
- diagnostics or retryability;
- a handle/URI for large content.

Do not dump large raw payloads into context when a summary plus retrievable reference is sufficient.

## Errors

Errors should help the agent recover.

Include:

- what failed;
- which input/resource caused it;
- whether retry may succeed;
- current state if partial mutation occurred;
- the next valid action when known.

Prefer machine-distinguishable error codes plus concise human-readable detail.

Do not hide permission, validation, revision-conflict, or partial-write distinctions behind a generic “failed.”

## Side Effects and Safety

Read and write actions should be distinguishable in semantics and permission boundaries.

For mutations:

- support optimistic concurrency/version checks where state can change concurrently;
- make idempotency explicit when possible;
- return the resulting version/state;
- require approval at consequential boundaries according to the host product's policy.

Do not make a “preview” tool mutate silently.

## Tool Granularity

A tool should normally map to one meaningful operation, not one implementation syscall.

Too fine-grained tools increase planning overhead and context churn. Too coarse tools hide important choices and make failures hard to recover from.

Choose granularity around the agent's decision boundary.

## Search and Retrieval Tools

Separate navigation/search from fetching full content when progressive disclosure helps.

Typical pattern:

1. search/list → compact candidates/IDs;
2. read/fetch → exact selected content;
3. follow links/sections → deeper detail only when needed.

Results should expose provenance and freshness when those affect decisions.

## Tool Names

Use concise, stable names within a clear namespace. Avoid encoding version numbers or implementation details into names unless they are semantically relevant.

For MCP, server names already provide namespace; choose tool names that remain understandable when rendered as `server.tool` or equivalent.

## Long-Running Operations

For operations that may exceed one request:

- return an operation/job ID;
- expose status/cancel when the platform supports it;
- stream or checkpoint meaningful progress rather than verbose heartbeat text;
- make retry/resume semantics explicit.

Do not keep the model blocked on logs that do not change the next decision.

## Tool Evolution

Treat schema changes like API changes. Preserve compatibility where clients/models may have cached assumptions, and evaluate changed descriptions against representative selection tasks.

## Evaluation

Measure:

- correct tool selection;
- argument validity;
- unnecessary calls;
- recovery after tool errors;
- output tokens/context footprint;
- task success and latency.

If the model repeatedly confuses two tools, improve semantics/consolidate before adding more prompt instructions.

## Avoid

- overlapping aliases with slightly different names;
- descriptions that only restate the function name;
- raw multi-thousand-line output when a retrievable artifact works;
- success responses that omit the resource/version needed next;
- generic errors with no recovery information;
- hard-coded global tool-count limits without workload evidence.
