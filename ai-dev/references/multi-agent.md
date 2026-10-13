# Multi-Agent Architecture

Use this reference when deciding whether work should be split across agents and how those agents coordinate.

## Default to One Agent

Start with one capable agent plus explicit tools. Add agents only when they create a measurable advantage through:

- parallel independent investigation;
- context isolation;
- specialized tool/permission boundaries;
- independent verification;
- decomposition that reduces interference.

Multiple role names alone do not improve reasoning. Coordination adds latency, tokens, failure modes, and state-sync cost.

## Common Patterns

### Supervisor

One coordinator delegates bounded tasks and integrates results.

Best when:
- one place must own the final decision/state;
- subtasks are separable;
- central prioritization matters.

Risk: supervisor becomes context/cost bottleneck.

### Peer / Swarm

Agents hand work to one another or operate with decentralized coordination.

Best when:
- work graph is dynamic;
- agents can make local routing decisions;
- no single coordinator needs all detail.

Risk: duplicated work, loops, unclear ownership.

### Hierarchical

Coordinators delegate to sub-coordinators/workers.

Best only for genuinely large workflows with natural organizational boundaries. Avoid recreating an org chart for small tasks.

## Decomposition

A good subtask has:

- one clear question/goal;
- only the context needed for that question;
- explicit constraints and permissions;
- expected output shape;
- evidence/provenance requirements;
- a clear owner for integration.

If agents need the same full context and constantly exchange updates, decomposition may be making the task worse.

## Context Isolation

Isolation is often the strongest reason to use sub-agents. Give each agent the smallest relevant source set and return a compact result with references to recover detail later.

Do not copy entire parent transcripts into every child by default.

## Parallelism

Parallelize independent work only. Parallel agents that mutate the same state or depend on each other's intermediate decisions need explicit synchronization or serialization.

For code changes, prefer separate files/worktrees/patch proposals unless the execution environment provides safe concurrent editing.

## Verification Agents

Independent review can be valuable when errors are costly. A reviewer should receive the artifact, acceptance criteria, and enough evidence to check it—without being forced to inherit the producer's reasoning.

Avoid reflexive debate/consensus loops. Use additional reviewers when the expected error reduction justifies the cost.

## Shared State

Keep shared state explicit and durable:

- task status;
- decisions;
- artifact identifiers;
- ownership/locks;
- dependencies;
- results/evidence.

Do not rely on every agent having an identical conversational memory.

## Failure Handling

Plan for:

- worker timeout/failure;
- duplicate or contradictory answers;
- partial results;
- stale state;
- repeated delegation loops;
- unsafe/irreversible actions.

The coordinator should be able to continue from persisted state without replaying the entire conversation.

## Cost and Model Routing

There is no universal multi-agent token multiplier. Cost depends on delegation depth, duplicated context, tool calls, model choice, retries, and result verbosity.

Measure on representative tasks. Use cheaper/faster models for bounded subtasks only when evaluation shows quality remains sufficient.

## When Not to Use Multi-Agent

Stay single-agent when:

- the task is tightly sequential;
- all subtasks need the same context;
- coordination is more complex than the work;
- there is one small mutable artifact;
- independent review adds little value.

## Evaluation

Compare single vs multi-agent on:

- task success;
- latency;
- total tokens/tool calls;
- duplicated work;
- integration errors;
- recovery from worker failure.

Adopt the multi-agent design only if it wins on the metrics that matter for the product.
