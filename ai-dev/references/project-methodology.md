# Project Methodology

Task-model fit evaluation, pipeline architecture, structured output design, cost estimation, and production case studies.

## Task-Model Fit

Run every proposed task through these tables before writing code.

### Proceed When

| Characteristic | Rationale |
|----------------|-----------|
| Synthesis across sources | LLMs combine multi-source information better than rule-based alternatives |
| Subjective judgment with rubrics | Grading, classification with criteria maps naturally to language reasoning |
| Natural language output | When the goal is human-readable text |
| Error tolerance | Individual failures don't break the system |
| Batch processing | No conversational state required between items |
| Domain knowledge in training | Model already has relevant context |

### Stop When

| Characteristic | Rationale |
|----------------|-----------|
| Precise computation | Math, counting, exact algorithms unreliable |
| Real-time requirements | LLM latency too high for sub-second responses |
| Perfect accuracy required | Hallucination risk makes 100% impossible |
| Proprietary data dependence | Model lacks necessary context |
| Sequential dependencies | Each step compounds errors |
| Deterministic output required | Same input must produce identical output |

### Manual Prototype (Always Do This First)
Copy one representative input into the model interface. Evaluate: Does the model have the knowledge? Can it produce the right format? What failure modes appear? This takes minutes and prevents hours of wasted work.

---

## Pipeline Architecture

Structure as staged pipeline — only the Process stage is non-deterministic:

```
acquire → prepare → process → parse → render
```

| Stage | Deterministic | Expensive | Key Property |
|-------|---------------|-----------|--------------|
| Acquire | Yes | Low | Fetch raw data from APIs/files/databases |
| Prepare | Yes | Low | Transform into prompt format |
| Process | **No** | **High** | Execute LLM calls |
| Parse | Yes | Low | Extract structured data from responses |
| Render | Yes | Low | Generate final outputs |

### Design Principles
- **Discrete**: Clear boundaries, debuggable independently
- **Idempotent**: Re-running produces same results
- **Cacheable**: Intermediate results persist to disk
- **Independent**: Each stage runs separately

### File System as State Machine

```
data/{batch_id}/{item_id}/
  raw.json         # acquire complete
  prompt.md        # prepare complete
  response.md      # process complete
  parsed.json      # parse complete
```

Check if item needs processing by checking output file existence. Re-run by deleting output + downstream files. Debug by reading intermediate files directly.

---

## Structured Output Design

Include in every structured prompt:
1. **Section markers** — explicit headers parsers can match on
2. **Format examples** — show exactly what output looks like
3. **Rationale disclosure** — "I will be parsing this programmatically"
4. **Constrained values** — enumerated options, score ranges, fixed formats

Build parsers that handle variations: flexible regex, sensible defaults for missing sections, log failures rather than crash.

---

## Cost Estimation

```
Total cost = (items × tokens_per_item × price_per_token) + 20–30% buffer
```

Estimate input tokens (prompt + context) and output tokens per item before starting. Track actual costs during development. If costs exceed estimates: reduce context via truncation, use smaller models for simpler items, cache partial results, parallelize for wall-clock time.

### Parallel Execution
- Small batches (1–10): sequential fine
- Medium (10–100): 5–15 workers, respect API rate limits
- Large (100+): chunk with checkpoints, implement resume

---

## Choosing Single vs Multi-Agent

Default to single-agent pipelines for batch processing. Escalate to multi-agent only when:
- Parallel exploration of different aspects is required
- Task exceeds single context window capacity
- Specialized sub-agents demonstrably improve quality on benchmarks

See `multi-agent.md` for architecture patterns when multi-agent is justified.

---

## Architectural Reduction

Start minimal, add complexity only when production evidence proves it necessary. More sophisticated tooling can constrain rather than enable model performance.

**Reduce when**: data layer well-documented, model has sufficient reasoning, specialized tools constraining rather than enabling, more time maintaining scaffolding than improving outcomes.

**Add complexity when**: data messy/undocumented, domain requires specialized knowledge, safety constraints must limit capabilities, operations genuinely benefit from structured workflows.

See `tool-design.md` § Architectural Reduction for detailed patterns and the Vercel d0 case study.

---

## Case Studies

### Karpathy HN Time Capsule
- **Task**: Analyze 930 HN discussions with hindsight grading
- **Pipeline**: fetch → prompt → analyze → parse → render, 15 parallel workers
- **Result**: $58 total, ~1 hour, static HTML output
- **Lessons**: manual validation first, file-system state, idempotent stages, agent-assisted development (3 hours to working code)

### Vercel d0 Architectural Reduction
- **Task**: Text-to-SQL agent for internal analytics
- **Before**: 17 tools, 80% success, 274s avg, ~102K tokens
- **After**: 2 tools (bash + SQL), 100% success, 77s avg, ~61K tokens
- **Lessons**: tools were constraining reasoning; good documentation replaces tool sophistication; build for future models

### Manus Context Engineering
- **Task**: General-purpose consumer agent, 50+ tool calls
- **Key patterns**: KV-cache optimization (10× cost difference cached vs uncached), append-only context, mask don't remove tools, filesystem as unlimited memory, todo.md recitation for attention, keep errors in context
- **Lessons**: refactored framework 5 times; simple unopinionated designs adapt better to model improvements

### Anthropic Multi-Agent Research
- **Task**: Complex topic research with parallel agents
- **Architecture**: Orchestrator-worker, lead spawns subagents for parallel exploration
- **Key finding**: 3 factors explain 95% of performance variance — token usage (80%), tool calls, model choice
- **Token economics**: multi-agent ~15× baseline; requires high-value tasks to justify cost

---

## Iteration Principles

1. Plan for multiple refactoring cycles — no project gets architecture right first try
2. Test across model generations to verify harness isn't limiting performance
3. Keep architecture unopinionated so refactoring is cheap
4. Build systems that benefit from model improvements rather than locking in limitations
5. The Bitter Lesson: structures added for current limitations become constraints as models improve

---

## Gotchas

1. **Skipping manual validation** — building automation before verifying model can do the task
2. **Monolithic pipelines** — combining stages makes debugging/iteration difficult
3. **Over-constraining models** — guardrails that helped weaker models become liabilities as capabilities improve
4. **Ignoring costs until production** — token costs compound quickly at scale
5. **Perfect parsing expectations** — LLMs don't follow format instructions perfectly; build robust parsers
6. **Premature optimization** — adding caching/parallelization before basic pipeline works
7. **Model version lock-in** — building pipelines that only work with one specific model
8. **Evaluation-less deployment** — shipping without measuring output quality means regressions go undetected
