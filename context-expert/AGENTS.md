---
name: context-expert
description: Context engineering for AI agent systems. Use when designing context architecture, debugging context failures (lost-in-middle, poisoning, distraction), optimizing token usage (compression, masking, KV-cache, partitioning), or implementing filesystem-based context offloading (scratch pads, plan persistence, sub-agent workspaces).
---

# Context Expert Skill

## Operating Rules

- Treat context as a finite attention budget, not a storage bin
- Optimize for tokens-per-task (total cost to complete), not tokens-per-request
- Apply progressive disclosure: load summaries first, full content on demand
- Place critical information at attention-favored positions (beginning and end)
- Trigger compaction at 70–80% utilization — never wait for symptoms
- Validate compression output against source before discarding originals
- Never compress tool definitions, schemas, or system prompts

## Task Workflow

### Diagnose context failure
- Read `references/degradation.md` to identify pattern (lost-in-middle, poisoning, distraction, confusion, clash)
- Check context utilization ratio against 60–70% effective capacity threshold
- Apply the Four-Bucket Mitigation Framework (Write → Select → Compress → Isolate)

### Optimize context usage
- Read `references/optimization.md` for techniques ordered by impact
- Apply KV-cache optimization first (zero quality risk)
- Then observation masking (60–80% reduction in tool outputs)
- Then compaction (50–70% reduction, <5% quality loss)
- Then partitioning (for tasks exceeding 60% of window)

### Implement compression
- Read `references/optimization.md` § Compression Strategies
- Choose method: Anchored Iterative (best quality) vs Regenerative (readable) vs Opaque (max savings)
- Solve artifact trail problem first — file paths, function names, error codes
- Evaluate with probe-based testing, not ROUGE/embedding similarity

### Offload context to filesystem
- Read `references/filesystem.md` for implementation patterns
- Redirect tool outputs >2000 tokens to scratch files
- Write plans as structured YAML for re-reading across turns
- Use per-agent directory isolation for sub-agent workspaces
- Load skills dynamically — names in static context, full content on demand

### Design context architecture
- Read `references/fundamentals.md` for anatomy of context
- Organize system prompts: background → instructions → tool guidance → output format
- Calibrate instruction altitude: heuristic-driven, not hyper-specific or vague
- Budget tokens explicitly per component; reserve 5–10% buffer

### Topic Router

| Topic | Reference |
|-------|-----------|
| Anatomy, attention, progressive disclosure, budgeting | `references/fundamentals.md` |
| 5 failure patterns, detection, metrics, recovery | `references/degradation.md` |
| Compression, masking, KV-cache, partitioning, evaluation | `references/optimization.md` |
| Scratch pad, plans, sub-agent workspace, terminal, self-modification | `references/filesystem.md` |

## Key Thresholds

| Metric | Value |
|--------|-------|
| Effective capacity | 60–70% of advertised window |
| Compaction trigger | 70–80% utilization |
| Tool output dominance | 80%+ of tokens in agent trajectories |
| Token estimate (English) | ~4 chars/token (code: 2–3) |
| Tool schema inflation | 2–3× after JSON serialization |
| KV-cache target hit rate | 70%+ for stable workloads |
| Masking target | 60–80% reduction, <2% quality impact |
| Compaction target | 50–70% reduction, <5% quality loss |

## References

- `references/fundamentals.md` — Context anatomy (system prompts, tools, retrieved docs, history, tool outputs), attention U-curve, progressive disclosure, token budgeting
- `references/degradation.md` — 5 failure patterns (lost-in-middle, poisoning, distraction, confusion, clash), detection signals, counterintuitive findings, mitigation framework
- `references/optimization.md` — Compression strategies (anchored iterative, regenerative, opaque), observation masking, KV-cache optimization, context partitioning, probe-based evaluation
- `references/filesystem.md` — Scratch pad offloading, plan persistence, sub-agent file workspaces, dynamic skill loading, terminal capture, self-modification guards
