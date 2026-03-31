# Memory Systems

Memory layers, production framework comparison, retrieval strategies, temporal knowledge graphs, benchmarks, and consolidation.

## Core Principle

Default to the simplest layer that meets retrieval needs. Benchmark evidence: **tool complexity matters less than reliable retrieval** — Letta's filesystem agents scored 74% on LoCoMo using basic file operations, beating Mem0's specialized tools at 68.5%.

---

## Memory Layers

Pick the shallowest layer that satisfies persistence requirements. Each deeper layer adds infrastructure cost.

| Layer | Persistence | Implementation | When to Use |
|-------|------------|----------------|-------------|
| **Working** | Context window | Scratchpad in system prompt | Always — optimize positions |
| **Short-term** | Session-scoped | File-system, in-memory cache | Intermediate results, conversation state |
| **Long-term** | Cross-session | Key-value → graph DB | User preferences, domain knowledge |
| **Entity** | Cross-session | Entity registry + properties | Identity tracking ("John Doe" = same person) |
| **Temporal KG** | Cross-session + history | Graph with validity intervals | Facts that change, time-travel queries |

### Escalation Path
1. **Prototype**: File-system memory (structured JSON + timestamps) — validates behavior before infrastructure
2. **Scale**: Mem0 or vector store when semantic search and multi-tenant isolation needed
3. **Complex reasoning**: Zep/Graphiti (temporal bi-model) or Cognee (multi-layer semantic graph) for relationship traversal
4. **Full control**: Letta or Cognee when agent must self-manage memory

---

## Framework Landscape

| Framework | Architecture | Best For | Trade-off |
|-----------|-------------|----------|-----------|
| **Mem0** | Vector store + graph, pluggable backends | Multi-tenant, fast integration | Less specialized for multi-agent |
| **Zep/Graphiti** | Temporal KG, bi-temporal model | Enterprise relationship + temporal reasoning | Advanced features cloud-locked |
| **Letta** | Self-editing memory, tiered storage | Full agent introspection, stateful services | Complex for simple use cases |
| **Cognee** | Multi-layer semantic graph, customizable ECL pipeline | Evolving agent memory, multi-hop reasoning | Heavier ingest-time processing |
| **LangMem** | Memory tools for LangGraph | Teams already on LangGraph | Tightly coupled to LangGraph |

### Quick Start Examples

**Mem0:**
```python
from mem0 import Memory
m = Memory()
m.add("User prefers dark mode and Python 3.12", user_id="alice")
results = m.search("What theme does the user prefer?", user_id="alice")
```

**Graphiti (Zep's temporal KG):**
```python
from graphiti_core import Graphiti
graphiti = Graphiti("bolt://localhost:7687", "neo4j", "password")
await graphiti.add_episode(name="conv_42", episode_body="Alice moved to Berlin in January.", source=EpisodeType.message)
results = await graphiti.search("Where does Alice live?")
```

**Cognee:**
```python
import cognee
await cognee.add("./docs/")
await cognee.cognify()
await cognee.memify()
results = await cognee.search(query_text="query", query_type=SearchType.GRAPH_COMPLETION)
```

---

## Benchmarks

| System | DMR Accuracy | LoCoMo | HotPotQA (multi-hop) |
|--------|-------------|--------|---------------------|
| Cognee | — | — | Highest EM, F1, Correctness |
| Zep (Temporal KG) | 94.8% | — | Mid-range |
| Letta (filesystem) | — | 74.0% | — |
| Mem0 | — | 68.5% | Lowest |
| MemGPT | 93.4% | — | — |
| Vector RAG baseline | ~60-70% | — | — |

**Key takeaways**: Zep achieves 18.5% accuracy improvement on LongMemEval with 90% latency reduction. Cognee outperforms Mem0, Graphiti, LightRAG on multi-hop reasoning. Filesystem agents beat specialized tools on single-hop retrieval.

---

## Retrieval Strategies

| Strategy | Use When | Limitation |
|----------|----------|------------|
| **Semantic** (embedding similarity) | Direct factual queries | Degrades on multi-hop reasoning |
| **Entity-based** (graph traversal) | "Tell me everything about X" | Requires graph structure |
| **Temporal** (validity filter) | Facts change over time | Requires validity metadata |
| **Hybrid** (semantic + keyword + graph) | Best accuracy | Most infrastructure |

Zep's hybrid achieves 90% latency reduction by retrieving only relevant subgraphs. Cognee offers 14 search modes combining graph, vector, relational stores.

---

## Temporal Knowledge Graphs

Track bi-temporal validity: when events occurred AND when they were ingested.

```python
graph.create_temporal_relationship(
    source_id=user_node, rel_type="LIVES_AT", target_id=address_node,
    valid_from=datetime(2024, 1, 15), valid_until=datetime(2024, 9, 1)
)
# Query: Where did user live on March 1, 2024?
results = graph.query_at_time({"type": "LIVES_AT"}, query_time=datetime(2024, 3, 1))
```

Use entity registries (`get_or_create_node`) to maintain identity across conversations ("John Doe" always maps to same node).

---

## Memory Consolidation

Run periodically to prevent unbounded growth. **Invalidate but don't discard** — preserving history matters for temporal queries.

**Triggers**: memory count threshold, degraded retrieval quality, scheduled intervals.

**Process**: find duplicate facts (same subject + predicate), merge by keeping highest-confidence edge, update validity periods, rebuild indexes.

---

## Context Integration

- Load memories just-in-time, not preloaded
- Place in attention-favored positions (beginning or end of context)
- Extract entities from task, retrieve per-entity memories, format for context injection

### Error Recovery
1. **Empty retrieval**: broaden search (remove entity filter, widen time range), then ask user
2. **Stale results**: check `valid_until`, trigger consolidation
3. **Conflicting facts**: prefer most recent `valid_from`, surface conflict if low confidence
4. **Storage failure**: queue writes for retry; never block response on memory write

---

## Gotchas

1. **Stuffing everything into context** — use just-in-time retrieval with relevance filtering
2. **Ignoring temporal validity** — outdated information poisons agent behavior silently
3. **Over-engineering early** — filesystem agent can outperform complex tooling
4. **No consolidation** — unbounded growth degrades retrieval quality
5. **Embedding model mismatch** — writing with one model, reading with another → poor retrieval
6. **Graph schema rigidity** — over-structured schemas break when domain evolves; prefer generic relations
7. **Stale memory poisoning** — old contradicting memories corrupt behavior; implement confidence decay
8. **Memory-context mismatch** — topically related but contextually wrong memories; filter by session/domain metadata
