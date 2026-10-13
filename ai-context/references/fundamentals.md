# Context Engineering Fundamentals

Use this reference to decide what belongs in active model context, what should be retrieved later, and how to structure context for reliable attention.

## Context Is an Attention Surface

A model context window is not equivalent to reliable working memory. More tokens can help when they add relevant evidence, but irrelevant, stale, repetitive, or conflicting tokens can reduce answer quality.

Do not assume a universal “effective capacity” percentage. Usable context depends on model, task, retrieval quality, position, repetition, and the type of reasoning required.

## Context Layers

Typical agent context contains:

1. system/developer instructions;
2. tool schemas and capability descriptions;
3. task/user instructions;
4. retrieved project/domain knowledge;
5. conversation/decision history;
6. tool observations and artifacts;
7. temporary reasoning state needed for the current step.

These layers have different lifetimes. Stable rules should not be repeatedly regenerated; large observations should not remain active after they stop being useful.

## Progressive Disclosure

Load the smallest representation that lets the agent choose the next step:

- index/name/description first;
- short summary next;
- exact source section when needed;
- full artifact only when the task truly requires it.

This reduces distraction and makes retrieval decisions explicit.

## High-Signal Context

Prioritize information that changes the next action:

- explicit user goal and acceptance criteria;
- current state and constraints;
- exact errors/diagnostics;
- relevant files/symbols/IDs;
- decisions already made and why;
- evidence needed to verify the result.

Historical detail that does not affect the current task should be summarized or offloaded.

## Stable Prefixes and Prompt Caching

When the platform supports prompt caching, keep long-lived instruction/tool prefixes stable. Put changing task data later rather than rewriting stable schemas/instructions each turn.

Caching is an optimization, not a reason to preserve irrelevant context.

## Attention Placement

Important constraints should be easy to find and semantically distinct. Do not rely on one fixed “best position” rule across every model.

Useful practices:

- keep critical global rules in the instruction layer;
- repeat a task-critical constraint near the action only when necessary to prevent ambiguity;
- structure long retrieved content with headings/metadata so relevant sections are identifiable;
- avoid burying current state inside old transcripts.

## Context vs Memory

Context is what the model can attend to now. Memory is durable information that can be retrieved into context later.

Store information externally when:

- it must survive compaction/session boundaries;
- it is large but only occasionally needed;
- it has clear retrieval keys/provenance;
- keeping it active would crowd out current evidence.

Do not use external memory for ephemeral facts that are cheaper and safer to recompute.

## Context Budgeting

Budget from the task backward rather than a universal percentage.

Reserve room for:

- expected tool observations;
- retrieved evidence;
- the model's output;
- retries or unexpected diagnostics.

Track actual token/tool growth in representative runs. Trigger selection/compaction based on observed degradation or approaching model limits, not a hard-coded fraction copied between models.

## Instruction Altitude

Good instructions specify invariants and decision criteria without scripting every trivial step.

Too vague:
- “write good code.”

Too narrow:
- dozens of brittle rules that only fit one implementation/version.

Prefer:
- goal;
- constraints;
- correctness/safety boundaries;
- tool/reference routing;
- verification expectations.

## Conflicts and Freshness

When context sources disagree:

1. identify authority and recency;
2. prefer direct/current sources over summaries;
3. preserve the conflict if it matters rather than blending incompatible claims;
4. update or invalidate stale memory/reference state.

## Evaluation

Evaluate context architecture with real tasks:

- correctness/goal completion;
- retrieval precision and missed evidence;
- unnecessary context loaded;
- total tokens/tool calls/latency;
- failure recovery after long trajectories.

A smaller context is better only when it preserves or improves task performance.
