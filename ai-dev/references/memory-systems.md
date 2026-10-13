# Memory Systems

Memory is retrieval infrastructure for information that must outlive the active context. Start with the simplest durable representation that can be retrieved reliably; add vector or graph infrastructure only when evaluations show a need.

## Decide What Deserves Memory

Store information when it is useful beyond the current turn/session, costly to reconstruct reliably, attributable to a source or event, and retrievable with a clear key, query, entity, or time boundary.

Do not treat the transcript as memory by default. Summaries, decisions, facts, artifacts, and pointers are usually more useful than raw history.

## Memory Layers

| Layer | Good for | Typical implementation |
|---|---|---|
| Working | current reasoning/task state | active context / scratchpad |
| Session | intermediate artifacts, checkpoints | files, KV state, database rows |
| Long-term factual | durable preferences/domain facts | structured store + provenance |
| Semantic retrieval | fuzzy topical recall over many records | embeddings/vector search |
| Entity/relational | identity and relationship traversal | relational or graph model |
| Temporal | facts whose truth changes over time | validity/event metadata or temporal graph |

Use the shallowest layer that passes retrieval evaluations.

## Retrieval Before Storage Complexity

A sophisticated store does not compensate for poor retrieval. Evaluate recall, precision, freshness, provenance, and latency/cost. Keep benchmark numbers tied to the exact dataset, framework version, embedding model, and retrieval configuration; do not encode cross-benchmark percentages as universal architecture rules.

## Retrieval Strategies

| Strategy | Use when | Main risk |
|---|---|---|
| exact/keyed | identifiers and known facts | misses paraphrases |
| keyword/full-text | lexical match matters | vocabulary mismatch |
| semantic | fuzzy topical retrieval | plausible but contextually wrong matches |
| entity/graph | relationships and identity matter | schema/ingestion complexity |
| temporal | facts evolve | incomplete validity metadata |
| hybrid | no single signal is reliable enough | tuning/operational complexity |

Retrieve just in time and return the smallest evidence set that supports the task.

## Provenance and Freshness

A durable memory record should usually contain content, source/producing event, creation/update time, owner/scope, confidence for inferred facts, and validity/supersession metadata when facts can change.

Prefer explicit supersession or validity history over silently overwriting important facts.

## Consolidation

Consolidate when duplicated or stale records reduce retrieval quality, not merely on a fixed schedule.

Typical process:

1. group candidate duplicates/conflicts;
2. preserve provenance and timestamps;
3. merge equivalent facts or mark superseded ones;
4. rebuild/update retrieval indexes;
5. rerun representative retrieval probes.

Do not discard history required for audit or temporal queries.

## Framework Choice

Frameworks such as Mem0, Zep/Graphiti, Letta, Cognee, LangMem, or a project-specific store are implementation options, not architecture requirements. Compare them using the workload's actual needs: tenancy, provenance, temporal queries, self-editing, graph traversal, deployment model, latency, and operational burden.

Framework APIs and benchmark standings change quickly; verify current documentation before recommending one.

## Failure Modes

- **Memory stuffing**: too many records enter context. Tighten retrieval and evidence limits.
- **Stale poisoning**: old facts outrank current facts. Add validity and supersession rules.
- **Identity collision**: records for different entities merge. Use stable IDs/entity resolution.
- **Context mismatch**: related memory comes from the wrong project/user/session. Filter by scope.
- **Write amplification**: every message becomes memory. Extract only durable information.
- **Lost provenance**: summaries cannot be traced back to evidence. Preserve source pointers.

## Verification

Create probes from real tasks: known-answer recall, conflicting updates, stale facts, cross-project isolation, empty retrieval, and large-memory behavior. Evaluate end-to-end task quality rather than retrieval similarity alone.