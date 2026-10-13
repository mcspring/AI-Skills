# Context Optimization

Use this reference when active context is becoming expensive, noisy, stale, or too large for reliable task completion.

## Optimize in This Order

Prefer interventions with the lowest information risk first:

1. **Select** — stop loading irrelevant material.
2. **Structure** — make evidence/tool results easier to locate.
3. **Offload** — keep large artifacts outside active context with reliable retrieval handles.
4. **Mask/prune** — remove obsolete low-value observations.
5. **Compact** — summarize history while preserving durable state and evidence.
6. **Isolate** — split independent investigations when one context creates interference.

Do not compact useful evidence simply because a fixed token percentage was reached.

## Retrieval Before Compression

The cheapest token is often the token never loaded.

Improve:

- file/symbol/topic routing;
- metadata and summaries;
- exact-section retrieval;
- deduplication;
- query refinement.

If the agent repeatedly loads whole documents to answer narrow questions, fix retrieval granularity before building a stronger summarizer.

## Observation Pruning

Tool outputs dominate many agent trajectories. Keep the parts needed for future action:

- exact error and location;
- identifiers/paths/URLs;
- command result and relevant measurements;
- state transitions;
- evidence supporting a decision.

Drop repeated banners, unchanged listings, verbose logs after the relevant lines are captured, and intermediate output superseded by later state.

## Offloading

Move large content to a durable artifact when it can be fetched reliably later.

Store a compact pointer in active context:

- artifact/file identifier;
- short description;
- relevant section/range;
- provenance/version;
- reason it may be needed again.

Offloading without a good retrieval key merely converts context loss into retrieval failure.

## Compaction

A good compaction preserves the task state needed to continue:

- goal and constraints;
- completed actions;
- unresolved issues;
- current workspace/system state;
- decisions and rationale;
- exact artifacts/errors/IDs needed later;
- next likely actions.

It should remove narration, repetition, dead hypotheses, and details recoverable cheaply from source.

### Validate Compaction

Probe the compacted state with questions such as:

- What remains to be done?
- Which files/objects were changed?
- What failed and why?
- What constraints must not be violated?
- Where is the supporting evidence?

If the compacted context cannot answer these, it discarded task state rather than compressing it.

## Compression Styles

Choose based on use:

- **structured state summary** — best for agent continuation;
- **human-readable narrative** — useful for handoff/review;
- **machine-oriented compact representation** — useful only if downstream retrieval/parsing is reliable.

Avoid opaque compression when humans/agents must debug or update the state later.

## Prompt Caching

Keep stable prefixes stable when the model/provider supports caching:

- system/developer rules;
- tool schemas;
- stable project instructions.

Put volatile observations later. Measure cache hit behavior rather than assuming exact savings.

## Partitioning and Sub-Agents

Split context when work is genuinely separable:

- independent research tracks;
- large code areas with minimal shared state;
- independent verification/review;
- tasks where one branch's tool output would distract another.

Define a narrow handoff contract: question, constraints, expected result, evidence/provenance.

Do not create sub-agents only to shrink context if coordination overhead exceeds the benefit.

## Long Context

When long context is unavoidable:

- keep source boundaries and metadata explicit;
- retrieve/rank relevant sections where possible;
- separate current task state from archival evidence;
- eliminate duplicate copies of the same document/tool output;
- verify key facts against source instead of trusting old summaries.

## Metrics

Tune optimization from telemetry for the specific model/workload:

- task success/accuracy;
- tokens per completed task;
- retrieval precision/recall;
- tool-output share;
- cache hit rate;
- latency;
- compaction/recovery failures.

Thresholds are experiment results, not universal rules.

## Avoid

- fixed compaction triggers copied across models;
- compressing system/tool contracts into lossy prose;
- retaining every tool output “just in case”;
- deleting provenance when summarizing evidence;
- partitioning highly coupled work into agents that must constantly resynchronize;
- optimizing tokens while increasing retries or reducing correctness.
