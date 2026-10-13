---
name: ai-dev
description: Design and build AI agent systems. Use for LLM pipelines, tool/MCP design, memory, multi-agent coordination, hosted agents, evaluations, and task-model fit.
---

# AI Agent Development

Prefer the smallest architecture that reliably completes the task. Add orchestration, memory, and agents only when evaluation shows a concrete need.

## Core Guidance

- Prototype the task manually before automating it; define success cases and failure cases first.
- Prefer deterministic code for deterministic work and models for judgment, synthesis, or ambiguous transformation.
- Start with one agent and explicit tools. Add sub-agents when parallelism, context isolation, specialization, or independent verification improves results.
- Design tools as narrow contracts with clear inputs, outputs, side effects, errors, and permission boundaries.
- Keep tool results compact and structured; return identifiers or summaries when full payloads can be retrieved later.
- Treat memory as retrieval infrastructure, not a transcript archive. Store durable facts/decisions with provenance and invalidate stale state.
- Make long-running workflows resumable and idempotent; persist checkpoints/artifacts outside the model context.
- Use structured outputs where downstream code depends on model results.
- Build evaluations around representative tasks before optimizing prompts, models, routing, or architecture.
- Measure quality, latency, token/tool cost, and failure recovery rather than relying on fixed agent-count or token-multiplier rules.

## Reference Router

| Need | Reference |
|---|---|
| Task-model fit, pipeline/evaluation methodology | `references/project-methodology.md` |
| Multi-agent patterns and isolation | `references/multi-agent.md` |
| Tools, MCP contracts, errors, response design | `references/tool-design.md` |
| Memory/retrieval systems | `references/memory-systems.md` |
| Sandboxes and hosted/background agents | `references/hosted-agents.md` |

## Architecture Heuristics

- **Pipeline** when stages and data flow are predictable.
- **Agent loop** when the next action depends on observations.
- **Sub-agents** when independent contexts or parallel investigation reduce interference.
- **Memory** when information must survive beyond the active context and can be retrieved reliably.
- **Human approval** at consequential or irreversible boundaries.

Avoid hard-coded limits such as a universal maximum tool count, fixed multi-agent cost multiplier, or fixed warm-pool cadence. Tune those from model/tool behavior and production telemetry.