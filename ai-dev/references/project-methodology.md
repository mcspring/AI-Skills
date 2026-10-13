# AI Project Methodology

Use this reference when deciding whether an LLM/agent is appropriate, designing the first implementation, and setting up evaluations.

## Start With the Task

Define before choosing architecture:

- input and output;
- what “correct” means;
- acceptable latency/cost;
- failure consequences;
- data/tool access needed;
- representative easy, normal, and adversarial cases.

If success cannot be evaluated, prompt or model optimization will become guesswork.

## Validate Task–Model Fit

Prototype manually with real examples before building infrastructure.

Ask:

- Can the model produce useful output with the information a real system can provide?
- Which failures are model limitations versus missing context/tools?
- Does deterministic code solve important parts more reliably?
- Is human review required at consequential boundaries?

Do not automate a task whose manual model workflow is already unreliable unless the system design directly addresses that failure.

## Use Models for Judgment, Code for Determinism

Good model work:

- ambiguous classification;
- synthesis and explanation;
- extraction where source variation is high;
- planning when next actions depend on observations;
- natural-language transformation.

Prefer deterministic code for:

- validation;
- arithmetic/accounting;
- permissions;
- state transitions;
- parsing stable formats;
- irreversible execution rules.

Combine them rather than forcing all logic into prompts.

## Smallest Architecture First

Choose the simplest structure matching the task:

### Direct model call

For one bounded transformation with known context.

### Pipeline

For predictable stages such as acquire → prepare → model → validate → render.

Make stages independently testable/idempotent when possible.

### Agent loop

Use when the model must inspect observations and choose the next tool/action dynamically.

### Multi-agent

Add only when parallelism, context isolation, specialization, or independent verification provides measurable value. See `multi-agent.md`.

## Structured Outputs

When downstream code consumes model output, define a schema rather than parsing prose heuristically.

Validate the result and distinguish:

- model refusal/failure;
- schema/validation failure;
- tool/data failure;
- business-rule rejection.

Retry only failure modes likely to improve with retry or changed context.

## State and Resumability

Persist durable workflow state outside the model context:

- input/artifact IDs;
- completed stages;
- decisions requiring continuity;
- tool side effects;
- output/evaluation results.

Prefer idempotent stages and versioned artifacts so work can resume after interruption without replaying everything.

## Evaluation Before Optimization

Build a compact representative eval set early.

Track metrics appropriate to the task:

- correctness/acceptance rate;
- groundedness/evidence quality;
- tool selection/action success;
- latency;
- tokens/tool cost per completed task;
- retry/failure rate;
- human correction rate.

Include regression cases from real failures.

## Prompt and Context Iteration

Change one meaningful variable at a time when diagnosing quality:

1. missing/incorrect context;
2. unclear goal/output contract;
3. tool design/retrieval problems;
4. model capability/routing;
5. orchestration complexity.

Do not compensate for poor context/tool contracts with increasingly long prompts.

## Model Routing

Use a smaller/faster model for a bounded stage only when evals demonstrate sufficient quality. Use stronger reasoning for tasks where errors or ambiguity justify the cost.

Avoid routing rules based only on token length or superficial task labels; measure end-to-end success.

## Cost

Estimate cost per completed task, including:

- input/output tokens;
- repeated context;
- tool/search calls;
- retries;
- sub-agents;
- failed runs.

There is no universal single-agent or multi-agent multiplier. Production traces should determine the economics.

## Human-in-the-Loop

Place approval where consequences justify it:

- irreversible external actions;
- high-value financial/legal/security changes;
- ambiguous changes with large blast radius;
- publication/communication when organizational policy requires review.

Do not insert human approval into harmless internal steps only because the workflow uses AI.

## Production Readiness

Before scaling, ensure:

- representative evals run continuously;
- tool permissions are least-privilege;
- side effects are observable/idempotent where feasible;
- prompts/models/tools are versioned;
- failures expose enough state to recover;
- sensitive data handling is defined;
- usage/cost/latency can be measured.

## Avoid

- architecture-first design before proving task-model fit;
- multi-agent orchestration because roles sound realistic;
- vector databases/memory before a retrieval need exists;
- treating one demo as an evaluation;
- optimizing token count while retries increase;
- hiding deterministic business logic inside prompts.
