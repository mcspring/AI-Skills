# Context Degradation Patterns

Five predictable failure modes, detection signals, mitigation strategies, and counterintuitive findings.

## The Five Patterns

### 1. Lost-in-Middle
**Symptom**: Correct information exists in context but model ignores it; responses contradict provided data.

**Cause**: U-shaped attention curve — middle positions receive 10–40% less recall than beginning/end.

**Fix**: Place critical info at edges. Prepend summaries of key findings. Add explicit section headers as attention anchors. For full documents, append conclusions at end.

### 2. Context Poisoning
**Symptom**: Degraded quality on previously-successful tasks, persistent hallucinations despite correction, wrong tool/parameter selection.

**Cause**: Hallucination, tool error, or incorrect retrieved fact enters context and compounds through self-reference.

**Fix**: Remove poisoned content — don't layer corrections on top. Truncate to before poisoning point or restart with verified-only context. Track claim provenance to detect.

**Vectors**: tool outputs, retrieved documents, model-generated summaries.

### 3. Context Distraction
**Symptom**: Performance drops when more context is added despite content being individually valid.

**Cause**: Even a single irrelevant document triggers measurable degradation (step function, not linear). Models cannot "skip" irrelevant content.

**Fix**: Filter aggressively before loading. Move "might be needed" info behind tool calls. Use namespacing and structural organization.

### 4. Context Confusion
**Symptom**: Responses address wrong aspect of query, tools called for wrong task, requirements blended from multiple sources.

**Cause**: Multiple task types or objective switches within a single context.

**Fix**: Segment tasks into separate context windows. Use explicit "context reset" markers. Isolate objectives, constraints, and tool definitions per task.

### 5. Context Clash
**Symptom**: Unpredictable resolution of contradictions — model picks one source silently.

**Cause**: Multiple correct-but-contradictory sources (version conflicts, perspective differences, multi-source retrieval).

**Fix**: Establish source priority rules before conflicts arise. Mark contradictions explicitly. Filter outdated versions before they enter context.

---

## Four-Bucket Mitigation Framework

| Strategy | When to Apply | Action |
|----------|---------------|--------|
| **Write** | Utilization >70% | Save context outside window (scratchpads, files, external storage) |
| **Select** | Distraction/confusion symptoms | Pull only relevant context via retrieval + filtering |
| **Compress** | All content is relevant but growing | Summarize, abstract, mask observations |
| **Isolate** | Confusion/clash, independent tasks | Split across sub-agents with isolated contexts |

---

## Counterintuitive Findings

1. **Shuffled context can outperform coherent context** — incoherent haystacks produce better retrieval because coherent context creates false associations. Test both arrangements.

2. **Single distractors have outsized impact** — the hit from one irrelevant document is disproportionately large vs adding more after the first. Treat distractor prevention as binary.

3. **Low needle-question similarity accelerates degradation** — tasks requiring inference across dissimilar content degrade faster. Maximize semantic overlap between queries and retrieved content.

4. **Larger contexts often hurt** — performance is non-linear with a cliff edge. Many models degrade meaningfully at 8K–16K tokens even with much larger windows. Processing 400K costs exponentially more than 200K.

---

## Detection Signals

Monitor these to diagnose active degradation:

| Signal | Suggests |
|--------|----------|
| Correct info present but ignored | Lost-in-middle |
| Quality drops on previously-working tasks | Poisoning |
| Persistent hallucinations despite correction | Poisoning |
| Wrong tools or parameters selected | Poisoning or confusion |
| Performance drops with more context added | Distraction |
| Requirements blended from multiple sources | Confusion |
| Contradictions resolved silently | Clash |
| Repetitive outputs or missed instructions | Utilization threshold exceeded |

---

## Gotchas

1. **Normal variance looks like degradation** — establish baseline over multiple runs; look for sustained decline correlated with context growth, not one-off drops
2. **Model thresholds go stale** — re-benchmark quarterly and after model updates; thresholds can shift 20–50%
3. **Needle-in-haystack ≠ production quality** — 99% needle scores don't predict real workload performance (multi-fact reasoning, instruction following)
4. **RAG contradictions poison silently** — two disagreeing retrieved docs → model silently picks one → looks correct but is random
5. **Bad prompts masquerade as degradation** — test same prompt at low context first; if it fails at 2K tokens, the problem is the prompt
6. **Degradation is a cliff, not a slope** — performance holds steady then drops sharply; set triggers well before the cliff (70% of known onset)
7. **Over-organizing context can backfire** — heavy structural formatting doesn't always help; test for specific tasks
