# Tool Design for Agents

Tool-agent contracts, consolidation principle, architectural reduction, MCP naming, error design, and response optimization.

## Tools as Contracts

Design each tool as a self-contained contract between a deterministic system and a non-deterministic agent. Agents infer intent from descriptions and generate calls that must match expected formats — every ambiguity becomes a failure mode.

### Description Structure
Every tool description must answer four questions:

1. **What does it do?** — exact action, not "helps with" or "can be used for"
2. **When to use it?** — direct triggers ("User asks about pricing") + indirect signals ("Need current market rates")
3. **What inputs?** — types, constraints, defaults, format examples
4. **What does it return?** — output structure, success examples, error conditions

**Strong example:**
```
Retrieve customer info by ID or email.
Use when: user asks about customer details, history, or status.
Args: customer_id (format "CUST-######"), format ("concise"|"detailed")
Returns: { name, email, account_status, order_history_summary }
Returns null if not found. Returns error if database unreachable.
```

---

## The Consolidation Principle

If a human engineer cannot definitively say which tool to use in a given situation, an agent cannot do better. Reduce until each tool has one unambiguous purpose.

**Why it works**: each tool competes for attention during selection, each description consumes tokens, overlapping functionality creates ambiguity. Vercel reduced from 17 to 2 tools and achieved +20% success rate.

**When NOT to consolidate**: fundamentally different behaviors, different contexts, must be callable independently. Over-consolidation creates tools with too many parameters for agents to parameterize correctly (>8–10 parameters → split).

---

## Architectural Reduction

Push consolidation to its extreme: remove most specialized tools in favor of primitive, general-purpose capabilities.

### The File System Agent Pattern
Provide file system access via single command execution tool. Agent uses `grep`, `cat`, `find`, `ls` to explore. Works because:
- File systems are a proven 50-year-old abstraction models understand deeply
- Standard tools have predictable behavior
- Agents chain primitives flexibly vs constrained predefined workflows
- Good documentation in files replaces summarization tools

### Vercel d0 Case Study

| Metric | 17 tools | 2 tools | Change |
|--------|----------|---------|--------|
| Execution time | 274.8s | 77.4s | 3.5× faster |
| Success rate | 80% | 100% | +20% |
| Token usage | ~102K | ~61K | −37% |
| Steps | ~12 | ~7 | −42% |

The specialized tools were solving problems the model could handle: pre-filtering context, constraining options, wrapping in validation logic. Each guardrail became a maintenance burden. Each model update required recalibration.

### When Reduction Fails
- Data layer messy or undocumented
- Domain requires specialized knowledge model lacks
- Safety constraints must limit capabilities
- Operations genuinely benefit from structured workflows

### Build for Future Models
Ask whether each tool enables new capabilities or constrains reasoning the model could handle. Tools built as guardrails often become liabilities as models improve.

---

## MCP Tool Naming

Always use fully qualified names: `ServerName:tool_name`

```python
# Correct
"Use the BigQuery:bigquery_schema tool to retrieve table schemas."
# Wrong — fails with multiple servers
"Use the bigquery_schema tool..."
```

Audit for namespace collisions when adding new providers.

---

## Tool Collection Design

Limit to **10–20 tools** per application. More tools = more description overlap = worse selection accuracy.

**Namespace** with common prefixes (`db_*`, `web_*`) as collection grows. Agents route to namespace first, then select tool within group.

**Response format options**: offer concise (key fields) vs detailed (complete record). Document when to use each so agents learn to select appropriately.

---

## Error Message Design

Every error message must be actionable for agent recovery:
- State what went wrong specifically
- Include the invalid value and expected format
- Provide a concrete corrected example
- Indicate whether retry is appropriate

```json
{
  "error": {
    "code": "INVALID_CUSTOMER_ID",
    "message": "ID 'CUST-123' does not match required format",
    "expected_format": "CUST-######",
    "example": "CUST-000001",
    "retryable": true
  }
}
```

---

## Tool Optimization Feedback Loop

Feed observed failures to an agent to diagnose issues and improve descriptions. Production testing shows 40% reduction in task completion time through this pattern:

1. Agent attempts tool usage across diverse tasks
2. Collect failure modes and friction points
3. Agent analyzes failures and proposes improved descriptions
4. Test improved descriptions against same tasks

---

## Gotchas

1. **Vague descriptions** — "Search the database" leaves too many questions; state exact database, query format, return shape
2. **Cryptic parameter names** — `x`, `val`, `param1` force guessing; use `customer_id`, `max_results`
3. **Missing error recovery** — generic "Error occurred" provides zero recovery signal
4. **Inconsistent naming** — `id` in one tool, `identifier` in another creates confusion
5. **MCP namespace collisions** — two servers exposing `search` → agent can't disambiguate
6. **Tool description rot** — descriptions become inaccurate as APIs evolve; treat as code, version and test
7. **Parameter explosion** — too many optional params overwhelm agents; use sensible defaults, group into `options` object
