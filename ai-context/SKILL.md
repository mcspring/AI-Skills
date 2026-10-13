---
name: context-expert
description: Design and debug context for AI agents. Use for prompt/context architecture, retrieval, context degradation, token/cost control, compaction, tool-output handling, filesystem offloading, and long-running agent state.
---

# Context Engineering

Treat context as a limited attention surface. Optimize for task completion quality and total cost, not for filling the largest possible window.

## Core Guidance

- Put durable instructions in stable context; retrieve task-specific knowledge on demand.
- Prefer progressive disclosure: summaries/indexes first, source detail only when needed.
- Preserve high-signal artifacts such as file paths, symbols, decisions, errors, and evidence when compacting history.
- Keep tool schemas and repeated prefixes stable when prompt caching benefits from it.
- Remove stale, duplicated, contradictory, and low-value observations before compressing useful evidence.
- Offload large intermediate artifacts to files or external state when the agent can reliably retrieve them later.
- Isolate independent work when combining it would create distraction or conflicting assumptions.
- Evaluate context changes on representative tasks and probes; do not rely on universal token thresholds.

## Workflow

1. Identify what the model must know now versus what it can retrieve later.
2. Diagnose the failure mode: missing context, distraction, stale/poisoned context, conflict, retrieval failure, or excessive tool output.
3. Apply the smallest useful intervention: select → structure → offload → compact → isolate.
4. Re-run the task and compare correctness, latency, and total token/tool cost.

## Reference Router

| Need | Reference |
|---|---|
| Context anatomy, attention, progressive disclosure | `references/fundamentals.md` |
| Degradation patterns and recovery | `references/degradation.md` |
| Compaction, masking, caching, partitioning | `references/optimization.md` |
| Filesystem/scratch state and sub-agent workspaces | `references/filesystem.md` |

## Design Principle

Use thresholds only as telemetry-derived triggers for a specific model/workload. Context windows, cache behavior, tool-output mix, and model attention characteristics change over time, so fixed percentages belong in experiments or references—not as universal operating rules.