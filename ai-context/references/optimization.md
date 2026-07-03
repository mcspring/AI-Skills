# Context Optimization

Compression strategies, observation masking, KV-cache optimization, context partitioning, and evaluation.

## Priority Order

Apply in this sequence — each subsequent technique is higher risk:

1. **KV-cache optimization** — zero quality risk, immediate cost/latency savings
2. **Observation masking** — 60–80% reduction in tool outputs, <2% quality impact
3. **Compaction** — 50–70% reduction, <5% quality loss; lossy — apply after masking
4. **Context partitioning** — split across sub-agents; real coordination overhead

---

## KV-Cache Optimization

Stable prefixes enable cache reuse. Structure every prompt:

1. System prompt (most stable — never changes within session)
2. Tool definitions (stable across requests)
3. Reused templates and few-shot examples
4. Conversation history (grows but shares prefix)
5. Current query and dynamic content (always last)

**Critical**: even a single whitespace change invalidates the entire cache downstream. Remove timestamps, session IDs, and counters from system prompts. Move dynamic metadata to a separate user message.

**Targets**: 70%+ hit rate → 50%+ cost reduction, 40%+ latency reduction.

---

## Observation Masking

Mask selectively based on recency and relevance:

- **Never mask**: current-task observations, most recent turn, active reasoning chains, error outputs during debugging
- **Mask after 3+ turns**: verbose outputs whose key points are extracted. Replace with: `[Obs:{ref_id} elided. Key: {summary}. Full content retrievable.]`
- **Always mask immediately**: duplicate outputs, boilerplate headers, already-summarized results

**Targets**: 60–80% reduction in masked observations, <2% quality impact.

---

## Compression Strategies

Three production-ready approaches — choose by session profile:

### Anchored Iterative Summarization (Best Quality — Score: 3.70)
For long-running sessions where file tracking matters. Maintains structured persistent summaries with mandatory sections:

```markdown
## Session Intent
[What the user is trying to accomplish]

## Files Modified
- auth.controller.ts: Fixed JWT token generation
- config/redis.ts: Updated connection pooling

## Decisions Made
- Using Redis connection pool instead of per-request connections

## Current State
- 14 tests passing, 2 failing

## Next Steps
1. Fix remaining test failures
```

On compression trigger: summarize only newly-truncated span and **merge** into existing summary (don't regenerate). Structure forces preservation — dedicated sections act as checklists.

### Regenerative Full Summary (Readable — Score: 3.44)
For sessions with clear phase boundaries. Generates detailed structured summary on each trigger. Weakness: cumulative detail loss across repeated cycles.

### Opaque Compression (Max Savings — Score: 3.35)
For short sessions with low re-fetching costs. 99%+ compression ratios but sacrifices interpretability entirely. Never use when debugging or artifact tracking is critical.

### Artifact Trail Problem (CRITICAL)
Artifact trail integrity scores only **2.2–2.5/5.0** across all methods. Always preserve explicitly:
- Files created (full paths)
- Files modified (with function names, not just file names)
- Files read but not changed
- Specific identifiers: function names, variable names, error messages, error codes

Implement a **separate artifact index** rather than relying on the summarizer.

---

## Compression Triggers

| Strategy | Trigger Point | Trade-off |
|----------|---------------|-----------|
| Fixed threshold | 70–80% utilization | Simple, may compress early |
| Sliding window | Last N turns + summary | Predictable size |
| Importance-based | Low-relevance first | Complex, preserves signal |
| Task-boundary | At logical completions | Clean summaries, unpredictable timing |

**Default**: sliding window with structured summaries for coding agents.

---

## Context Partitioning

Split across sub-agents when estimated context exceeds 60% of window. Each agent gets clean, focused context for its subtask.

**Break-even**: typically requires 3+ independent subtasks. Below that, coordination overhead (system prompt + tools + aggregation per sub-agent) exceeds savings.

### Three-Phase Workflow for Large Codebases
1. **Research** — explore architecture, compress into structured analysis document
2. **Planning** — convert research into implementation spec (5M-token codebase → ~2000 words)
3. **Implementation** — execute against spec + active working files only

---

## Probe-Based Evaluation

Traditional metrics (ROUGE, embedding similarity) fail for functional compression quality. Use probes:

| Probe Type | Tests | Example |
|------------|-------|---------|
| Recall | Factual retention | "What was the original error message?" |
| Artifact | File tracking | "Which files have we modified?" |
| Continuation | Task planning | "What should we do next?" |
| Decision | Reasoning chain | "What did we decide about Redis?" |

### Six Scoring Dimensions
1. **Accuracy** — file paths, function names, error codes correct? (largest variation: 0.6 gap)
2. **Context Awareness** — reflects current conversation state?
3. **Artifact Trail** — knows files read/modified? (universally weak: 2.2–2.5)
4. **Completeness** — addresses all parts of question?
5. **Continuity** — can work continue without re-fetching?
6. **Instruction Following** — respects stated constraints?

---

## Gotchas

1. **Never compress tool definitions/schemas** — agent can't invoke tools whose parameters are summarized away
2. **Compressed summaries hallucinate facts** — validate against source before discarding originals
3. **Compression breaks artifact references** — "updated the config file" when agent needs `config/redis.ts`
4. **Early turns contain irreplaceable constraints** — protect from compression or extract into persistent preamble
5. **95% compression compounds** — 3 cycles at 95% → 0.0125% of original remains
6. **Code doesn't compress like prose** — removing one token from a function signature makes it useless
7. **Compaction under pressure loses critical state** — at >85% utilization, summarization quality itself degrades
8. **Whitespace breaks KV-cache** — pin system prompts as immutable strings; diff templates byte-for-byte
9. **Timestamps in system prompts destroy cache** — `Current date: {today}` forces daily cache miss
10. **Masking error outputs breaks debugging** — suspend masking for error-related observations during active debug
