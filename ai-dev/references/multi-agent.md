# Multi-Agent Architecture

Three architectural patterns, context isolation, consensus mechanisms, token economics, and failure modes.

## When to Use Multi-Agent

Reach for multi-agent when a single agent's context fills to the point of degradation. Three signals: lost-in-middle effect, attention scarcity, context poisoning from irrelevant content.

**Context isolation is the primary benefit** — each sub-agent operates in a clean context window focused on its subtask. Do not use multi-agent for organizational metaphor or role anthropomorphization.

## Token Economics

Budget substantially higher costs:

| Architecture | Token Multiplier | Use Case |
|--------------|------------------|----------|
| Single agent chat | 1× baseline | Simple queries |
| Single agent + tools | ~4× baseline | Tool-using tasks |
| Multi-agent system | ~15× baseline | Complex research/coordination |

BrowseComp finding: 3 factors explain 95% of performance variance — token usage (80%), tool calls, model choice. Model quality improvements often outperform raw token increases.

---

## Pattern 1: Supervisor/Orchestrator

Central agent maintains global state, decomposes objectives, routes to specialists, synthesizes results.

```
User Query → Supervisor → [Specialist, Specialist, ...] → Aggregation → Output
```

**Choose when**: tasks have clear decomposition, coordination across domains needed, human oversight important.

**Trade-offs**: strict workflow control and easier human-in-the-loop, but supervisor context becomes bottleneck (+), supervisor failures cascade, telephone game problem emerges.

### Telephone Game Problem
Supervisors paraphrase sub-agent responses, losing fidelity (~50% worse initially per LangGraph benchmarks). Fix with `forward_message` tool that passes sub-agent responses directly to users. Prefer swarm over supervisor when sub-agents can respond directly.

### Supervisor Scaling
Cap workers per supervisor at 3–5. At 5+ workers, supervisor spends more tokens processing summaries than workers on actual tasks. Add a second supervisor tier rather than overloading one.

---

## Pattern 2: Peer-to-Peer/Swarm

No central control. Agents communicate directly via explicit handoff mechanisms.

```python
def transfer_to_agent_b():
    return agent_b  # Handoff via function return
```

**Choose when**: tasks require flexible exploration, rigid planning counterproductive, requirements emerge dynamically.

**Trade-offs**: no single point of failure and effective breadth-first scaling, but coordination complexity grows with agent count, divergence risk without central state keeper.

Define explicit handoff protocols with state passing. Ensure agents communicate context needs to receiving agents.

---

## Pattern 3: Hierarchical

Layers of abstraction: strategy (goal definition) → planning (task decomposition) → execution (atomic tasks).

**Choose when**: clear hierarchical structure, workflows involve management layers, tasks need both high-level planning and detailed execution.

**Trade-offs**: clean separation of concerns at each level, but coordination overhead between layers, potential strategy-execution misalignment.

---

## Context Isolation Mechanisms

Select by task complexity:

| Mechanism | When to Use | Trade-off |
|-----------|-------------|-----------|
| **Instruction passing** | Simple, well-defined subtasks | Maintains isolation, limits flexibility |
| **File system coordination** | Complex tasks needing shared state | Scales better than message-passing, adds latency |
| **Full context delegation** | Complex tasks needing complete understanding | Partially defeats isolation purpose |

**Default**: instruction passing. Escalate to file system when shared state needed. Avoid full delegation unless genuinely required.

### File System Coordination
Preferred over message-passing for state that multiple agents need faithfully (avoids telephone game). Use per-agent directory isolation. Implement simple lock files for concurrent access prevention.

---

## Consensus Mechanisms

### Weighted Voting
Weight agent votes by confidence or expertise. Avoid simple majority — it treats hallucinations from weak models as equal to strong model reasoning.

### Debate Protocols
Structure agents to critique each other over multiple rounds. Adversarial critique often yields higher accuracy than collaborative consensus. Guard against **sycophantic convergence** — agents agreeing to be agreeable rather than correct. Counter by assigning explicit adversarial roles.

### Trigger-Based Intervention
Monitor for: stall (no progress), sycophancy (agents mimicking without unique reasoning), divergence (drifting from objectives).

---

## Failure Modes

### Supervisor Bottleneck
Supervisor context pressure grows non-linearly with workers. **Fix**: constrain worker output schemas to distilled summaries; checkpoint supervisor state.

### Coordination Overhead
Communication consumes tokens and introduces latency. **Fix**: minimize communication with clear handoff protocols; batch results; use async patterns. Measure whether multi-agent actually saves time vs single agent with longer context.

### Divergence
Agents pursuing different goals without coordination. **Fix**: clear objective boundaries per agent; convergence checks; time-to-live limits.

### Error Propagation
One agent's hallucination becomes another's "fact." **Fix**: validate outputs between agents; retry with circuit breakers; verification agent for critical outputs.

### Agent Sprawl
Adding agents past 3–5 shows diminishing returns — communication channels grow quadratically. Start with minimum viable agents.

### Over-Decomposition
Splitting too finely creates more coordination overhead than the task itself. Decompose only when subtasks genuinely benefit from separate contexts.

---

## Framework Patterns

| Framework | Philosophy | Best For |
|-----------|------------|----------|
| **LangGraph** | Graph-based state machines with explicit nodes/edges | Structured workflows with clear state transitions |
| **AutoGen** | Conversational/event-driven, GroupChat pattern | Flexible multi-turn coordination |
| **CrewAI** | Role-based process flows, hierarchical crews | Organizational metaphor with defined roles |

Choose based on coordination needs, not framework popularity. All implement the same core patterns with different APIs.

---

## Gotchas

1. **Token cost underestimation** — teams consistently underbudget, missing coordination overhead, retries, consensus rounds. Budget 15× and treat less as bonus.
2. **Sycophantic consensus** — LLMs bias toward agreement; require explicit disagreement before convergence.
3. **Telephone game in message-passing** — use filesystem coordination for faithful state sharing.
4. **Missing shared state** — agents without shared storage duplicate work and produce inconsistent outputs.
5. **Over-decomposition** — 10-step pipeline with 10 agents spends more on handoffs than work.
6. **Error propagation cascades** — add validation checkpoints; never trust upstream output without verification.
