---
name: ai-dev
description: AI agent project development and architecture. Use when designing agent systems, building LLM pipelines, implementing multi-agent coordination, designing agent tools/MCP interfaces, choosing memory frameworks (Mem0, Zep, Letta, Cognee), building hosted/background agents, or evaluating task-model fit for LLM processing.
---

# AI Agent Development

## Operating Rules

- Validate task-model fit with manual prototype before building automation
- Default to single-agent pipeline; escalate to multi-agent only for context isolation needs
- Design tools as contracts — answer what/when/returns in every description
- Start with simplest viable memory layer; add complexity when retrieval degrades
- Structure pipelines as discrete, idempotent, cacheable stages
- Estimate token costs before starting; track throughout development
- Build minimal architectures that benefit from model improvements
- Expect and plan for multiple architectural iterations

## Task Workflow

### Start a new LLM project
- Read `references/project-methodology.md` for task-model fit, pipeline design, cost estimation
- Run manual prototype first (copy one input into model, evaluate output)
- Structure as `acquire → prepare → process → parse → render` pipeline
- Use file system for state management (file existence = idempotency)

### Design multi-agent architecture
- Read `references/multi-agent.md` for patterns and trade-offs
- Choose pattern by coordination need: supervisor (centralized), swarm (flexible), hierarchical (layered)
- Budget for ~15× token cost vs single agent
- Context isolation is the primary benefit — not role anthropomorphization

### Design agent tools
- Read `references/tool-design.md` for contracts, consolidation, architectural reduction
- Consolidate overlapping tools until each has one unambiguous purpose
- Write descriptions that answer: what it does, when to use it, what it returns
- Use `ServerName:tool_name` for MCP; limit to 10–20 tools per collection

### Implement agent memory
- Read `references/memory-systems.md` for framework comparison and implementation
- Start with file-system memory; escalate to vector store → knowledge graph → temporal KG
- Choose framework: Mem0 (fast integration), Zep/Graphiti (temporal), Letta (self-editing), Cognee (multi-layer semantic)
- Consolidate periodically — invalidate but don't discard

### Build hosted agent infrastructure
- Read `references/hosted-agents.md` for sandbox lifecycle, API layer, multiplayer
- Pre-build images on 30-minute cadence; use warm pools for instant spin-up
- Structure as server-first with thin clients (Slack, web, extension)
- Attribute commits to prompting user, not bot identity

## Topic Router

| Topic | Reference |
|-------|-----------|
| Task-model fit, pipeline architecture, structured output, cost estimation, case studies | `references/project-methodology.md` |
| Supervisor/swarm/hierarchical patterns, context isolation, consensus, failure modes | `references/multi-agent.md` |
| Tool contracts, consolidation, architectural reduction, MCP naming, error design | `references/tool-design.md` |
| Memory layers, framework comparison (Mem0/Zep/Letta/Cognee), temporal KG, benchmarks | `references/memory-systems.md` |
| Sandbox lifecycle, warm pools, API layer, multiplayer, client integrations | `references/hosted-agents.md` |

## Key Metrics

| Metric | Value |
|--------|-------|
| Single agent token multiplier | ~4× baseline |
| Multi-agent token multiplier | ~15× baseline |
| Token cost variance explained | 80% by token usage (BrowseComp) |
| Tool collection limit | 10–20 per application |
| Tool schema inflation | 2–3× after JSON serialization |
| Warm pool image cadence | 30 minutes |
| PR merge rate | Primary hosted agent success metric |
| Cost estimation buffer | 20–30% for retries/failures |

## References

- `references/project-methodology.md` — Task-model fit tables, canonical pipeline (acquire→render), file-system state, structured output design, cost estimation, case studies (Karpathy HN, Vercel d0, Manus, Anthropic multi-agent)
- `references/multi-agent.md` — 3 architectural patterns (supervisor, swarm, hierarchical), context isolation mechanisms, consensus/debate protocols, token economics, failure modes and mitigations
- `references/tool-design.md` — Tool-agent contract design, consolidation principle, architectural reduction (fewer tools = better performance), MCP naming, error message design, response format optimization
- `references/memory-systems.md` — 5 memory layers (working→temporal KG), framework landscape (Mem0, Zep/Graphiti, Letta, Cognee, LangMem), retrieval strategies, benchmarks (LoCoMo, HotPotQA, DMR), consolidation
- `references/hosted-agents.md` — Sandbox infrastructure (image builds, warm pools, snapshots), API layer (Durable Objects, WebSocket streaming), multiplayer support, client integrations (Slack, web, Chrome extension), metrics
