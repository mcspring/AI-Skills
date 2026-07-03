# Context Fundamentals

Core concepts: context anatomy, attention mechanics, progressive disclosure, and token budgeting.

## Anatomy of Context

Five components compete for the attention budget:

### System Prompts
Organize into distinct sections (background → instructions → tool guidance → output format) using XML tags or markdown headers. Place critical constraints at beginning and end where recall is 85–95%.

**Instruction altitude**: aim for heuristic-driven — specific enough to guide behavior, flexible enough to generalize. Start minimal, add instructions reactively based on observed failure modes.

```markdown
<BACKGROUND_INFORMATION>
Context about the domain, user preferences, or project-specific details
</BACKGROUND_INFORMATION>

<INSTRUCTIONS>
Core behavioral guidelines — numbered steps with room for judgment
</INSTRUCTIONS>

<TOOL_GUIDANCE>
When and how to use available tools
</TOOL_GUIDANCE>

<OUTPUT_DESCRIPTION>
Expected output format and quality standards
</OUTPUT_DESCRIPTION>
```

### Tool Definitions
Answer three questions: what the tool does, when to use it, what it returns. Include parameter defaults and error cases. Keep the tool set minimal — bloated sets create ambiguous decision points and inflate 2–3× after JSON serialization.

**Strong description example:**
```
Retrieve customer info by ID or email.
Use when: user asks about customer details, history, or status.
Returns: { name, email, account_status, order_history_summary }
Returns null if not found. Returns error if database unreachable.
```

### Retrieved Documents
Maintain lightweight identifiers (file paths, stored queries) — load data just-in-time. Strong identifiers (`customer_pricing_rates.json`) let agents locate files without search; weak identifiers (`data/file1.json`) force unnecessary loads.

When chunking, split at semantic boundaries (section headers, paragraph breaks), not arbitrary character limits.

### Message History
Serves as scratchpad memory for tracking progress across turns. Monitor growth — can dominate context in long sessions. Replace stale tool outputs with compact summaries once processed.

### Tool Outputs
Dominate context: observations can reach **83.9% of total tokens** in agent trajectories. Apply observation masking: replace verbose outputs with compact references. Retain only the 5 most recently accessed file contents.

---

## Attention Mechanics

### The U-Shaped Curve
Beginning and end positions receive 85–95% recall accuracy. Middle positions suffer **10–40% reduced recall** (Liu et al., 2023 "Lost in the Middle"). This is a consequence of attention mechanics, not a model bug.

### Effective Capacity
Assume **60–70% of advertised window** as usable. A 200K-token model starts degrading at 120–140K tokens. Complex retrieval accuracy can drop to 15% at extreme lengths.

### Position Encoding
Interpolation extends sequence handling beyond training lengths but introduces degradation in positional precision at extended contexts.

---

## Progressive Disclosure

Load context in layers, not all at once:

1. **Skill selection** — names + one-line descriptions at startup; full skill content on demand
2. **Document loading** — summaries first; detail sections only when task requires
3. **Tool result retention** — recent results in full; compress/evict older results

**Rule**: if activated, load fully. Partial loads create confusing gaps that degrade reasoning.

---

## Token Budgeting

### Budget Allocation

| Component | Typical Range | Notes |
|-----------|---------------|-------|
| System prompt | 500–2000 tokens | Stable across session |
| Tool definitions | 100–500 per tool | Grows with tool count |
| Retrieved documents | Variable | Often largest consumer |
| Message history | Variable | Grows with conversation |
| Tool outputs | Variable | Can dominate context |
| **Reserved buffer** | **5–10% of total** | **Never allocate** |

### Token Estimation

| Content Type | Chars/Token |
|-------------|-------------|
| English prose | ~4 |
| Code | 2–3 |
| URLs/file paths | ~1 (each slash/dot = separate token) |
| Non-English text | 1–2 |

Use the provider's actual tokenizer (tiktoken, Anthropic API) for budget-critical calculations. The ~4 chars/token heuristic breaks for code, URLs, and non-English.

### Context Quality vs Quantity

Apply the **signal-density test**: for each piece of context, ask whether removing it would change the model's output. If not, remove it. Redundant content actively dilutes attention from high-signal content.

---

## Gotchas

1. **Nominal window ≠ effective capacity** — budget for 60–70%; exceeding causes sudden drops, not gradual degradation
2. **Tool schemas inflate 2–3×** — 10 tools with moderate schemas → 5,000–8,000 tokens before any message
3. **History balloons in agentic loops** — 20–30 iterations → 70–80% of window consumed silently
4. **Critical instructions in the middle get lost** — never place safety/format/behavior rules in mid-prompt
5. **Eager progressive disclosure defeats its purpose** — strict activation thresholds, not "maybe relevant"
6. **Mixed instruction altitudes** — don't interleave hyper-specific rules with vague directives
