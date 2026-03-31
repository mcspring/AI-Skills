# Filesystem-Based Context Engineering

Use the filesystem as overflow layer. Files let agents store, retrieve, and update effectively unlimited context through a single interface.

## When to Use

**Use when**: tool outputs >2000 tokens, tasks span multiple turns, multiple agents need shared state, skills overflow system prompt, logs need selective querying.

**Avoid when**: tasks complete in single turns, context fits in window, latency is critical, model lacks filesystem tools.

## Four Context Failure Modes (Filesystem Remedies)

| Mode | Problem | Fix |
|------|---------|-----|
| Missing | Needed info absent | Persist tool outputs and intermediate results to files |
| Under-retrieved | Retrieved content doesn't cover what's needed | Structure files for targeted retrieval (grep-friendly, clear headers) |
| Over-retrieved | Too much content wastes tokens | Offload bulk to files, return compact references |
| Buried | Niche info hidden across many files | Combine glob + grep (structural) with semantic search (conceptual) |

---

## Pattern 1: Scratch Pad

Redirect large tool outputs to files, return summaries + references.

```python
def handle_tool_output(output: str, threshold: int = 2000) -> str:
    if len(output) < threshold:
        return output
    file_path = f"scratch/{tool_name}_{timestamp}.txt"
    write_file(file_path, output)
    summary = extract_summary(output, max_tokens=200)
    return f"[Output in {file_path}. Summary: {summary}]"
```

Use `grep` + `read_file` with line ranges for targeted retrieval from offloaded files.

## Pattern 2: Plan Persistence

Write plans as structured YAML. Re-read at start of each turn to re-orient.

```yaml
# scratch/current_plan.yaml
objective: "Refactor authentication module"
status: in_progress
steps:
  - id: 1
    description: "Audit current auth endpoints"
    status: completed
  - id: 2
    description: "Design new token validation flow"
    status: in_progress
  - id: 3
    description: "Implement and test changes"
    status: pending
```

This acts as "manipulating attention through recitation" — forces the agent to reload its objective.

## Pattern 3: Sub-Agent File Workspace

Route sub-agent findings through filesystem, not message chains (avoids "game of telephone" summarization loss).

```
workspace/agents/
├── research_agent/
│   ├── findings.md
│   └── status.json
├── code_agent/
│   ├── changes.md
│   └── test_results.txt
└── coordinator/
    └── synthesis.md
```

Enforce per-agent directory isolation to prevent write conflicts.

## Pattern 4: Dynamic Skill Loading

Store skills as files. Include only names + one-line descriptions in static context. Load full skill on demand.

```
Available skills (load with read_file when relevant):
- database-optimization: Query tuning and indexing strategies
- api-design: REST/GraphQL best practices
- testing-strategies: Unit, integration, and e2e testing patterns
```

Converts O(n) static token cost into O(1) per task.

## Pattern 5: Terminal & Log Persistence

Persist terminal output to files. Query with targeted grep instead of loading entire histories.

```bash
grep -A 5 "error" terminals/1.txt
```

## Pattern 6: Self-Modification

Have agents write learned preferences to instruction files. Guard with validation — self-modification can accumulate incorrect instructions. Review persisted preferences periodically.

---

## File Organization

```
project/
├── scratch/           # Ephemeral working files
│   ├── tool_outputs/  # Large tool results
│   └── plans/         # Active plans and checklists
├── workspace/agents/  # Sub-agent workspaces (isolated per agent)
├── agent/             # Agent configuration
│   ├── preferences.yaml
│   └── patterns.md
├── skills/            # Loadable skill definitions
├── terminals/         # Terminal output (searchable)
└── history/           # Chat history archives
```

Use consistent naming conventions. Include timestamps/IDs in scratch files.

---

## Search Techniques

Combine filesystem tools for context discovery:

| Tool | Use For |
|------|---------|
| `ls` / `list_dir` | Discover directory structure |
| `glob` | Find files matching patterns (`**/*.py`) |
| `grep` | Search file contents, return matching lines |
| `read_file` with ranges | Read specific sections without full load |

Use filesystem search for structural/exact-match queries. Semantic search for conceptual queries. Combine both for comprehensive discovery.

---

## Token Accounting

Track before and after applying filesystem patterns:
- Static vs dynamic context ratio (target: static <20%)
- Tool output sizes before/after offloading (target: >50% savings)
- Retrieval precision — how often loaded content is actually used (target: >70%)

---

## Gotchas

1. **Scratch dir unbounded growth** — implement retention policy (age/count-based), cleanup at session boundaries
2. **Race conditions in multi-agent access** — enforce per-agent directory isolation or use append-only files
3. **Stale file references** — always verify existence before reading cached paths; re-discover with glob if missing
4. **Glob false matches** — scope to specific directories and extensions, not `**/*`
5. **File size surprises** — check size before reading; use line-range reads for large files
6. **Scratch pad format drift** — define schema (YAML/JSON/structured markdown) from first write
7. **Hardcoded absolute paths** — use relative paths from project root or resolve dynamically
