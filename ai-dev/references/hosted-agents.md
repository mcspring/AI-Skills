# Hosted Agent Infrastructure

Sandbox lifecycle, image builds, warm pools, API layer, multiplayer support, client integrations, and metrics.

## Core Insight

Session speed should be limited only by model provider time-to-first-token. All infrastructure setup must complete before the user starts their session.

---

## Sandbox Infrastructure

### Image Registry Pattern
Pre-build environment images every 30 minutes. Each image includes:
- Cloned repository at known commit
- All runtime dependencies installed
- Initial setup and build commands completed
- Cached files from running app and test suite

On session start, spin up from latest image — repository is at most 30 minutes stale, making remaining git sync fast.

### Snapshot and Restore
Take filesystem snapshots at key points:
- After initial image build (base snapshot)
- When agent finishes changes (session snapshot)
- Before sandbox exit for potential follow-up

Snapshots enable instant restoration for follow-up prompts without re-running setup.

### Warm Pool Strategy
Maintain pre-warmed sandboxes for high-volume repositories:
- Keep sandboxes ready before users start sessions
- Expire and recreate as new image builds complete
- Start warming on keystroke (predictive warm-up, not on submit)
- Scale pool size by traffic patterns and time-of-day — avoid fixed pools

### Git Configuration
Configure git identity explicitly in every sandbox:
- Generate GitHub app installation tokens for repository access
- Set `user.name` and `user.email` for the prompting user, not the app
- Refresh tokens before sensitive operations (PR creation)

---

## Speed Optimizations

### Predictive Warm-Up
Start sandbox setup when user begins typing (5–30 seconds typing interval). Clone latest changes in parallel. For fast spin-up, sandbox ready before user finishes typing.

### Parallel File Reading
Allow file reads immediately even if git sync incomplete — incoming prompts rarely touch recently-changed files. Block only writes until sync completes. 30-minute staleness rarely matters for research.

### Maximize Build-Time Work
Move everything possible to image build (invisible to users):
- Full dependency installation
- Database schema setup
- Initial app and test suite runs (populates caches)

---

## API Layer

### Per-Session State Isolation
Use isolated storage per session (SQLite per session via Durable Objects):
- Dedicated database per session
- No cross-session interference
- Handles hundreds of concurrent sessions

### Real-Time Streaming
Stream all agent work in real-time:
- Token streaming from model providers
- Tool execution status updates
- File change notifications

Use WebSocket connections with hibernation APIs for idle cost reduction while maintaining open connections.

### Client Synchronization
Single state system that syncs across all clients (chat, Slack, web, extension). All changes sync to session state, enabling seamless client switching.

---

## Self-Spawning Agents

Expose three primitives:
1. **Start** new session with specified parameters
2. **Read** status of any session (check-in)
3. **Continue** main work while sub-sessions run in parallel

Use for: research across repositories, parallel subtask execution, breaking monolithic tasks into smaller PRs.

---

## Multiplayer Support

Design for multiplayer from day one — nearly free with proper sync architecture.

### Implementation
- Sessions NOT tied to single authors — pass authorship to each prompt
- Attribute code changes to the prompting user
- Update git config per prompt with author's identity
- Create PRs using the prompting user's GitHub token (not bot's)

### Use Cases
- Teaching non-engineers to use AI effectively
- Live QA sessions with multiple team members
- Real-time PR review with immediate changes
- Collaborative debugging sessions

---

## Client Integrations

### Slack Bot (First Distribution Channel)
Creates virality loop as team members see others using it:
- Natural chat interface, no syntax required
- Build classifier (fast model + repo descriptions) for repository routing
- Allow "unknown" for ambiguous cases

### Web Interface (Power User Surface)
- Real-time streaming on desktop and mobile
- Hosted VS Code inside sandbox
- Before/after screenshots for PRs
- Statistics: sessions → merged PRs (primary metric)

### Chrome Extension (Non-Engineering Users)
- Sidebar chat with screenshot tool
- Extract DOM/React internals instead of raw images (higher precision, lower tokens)
- Distribute via managed device policy (bypasses Chrome Web Store)

---

## Authentication

### Sandbox-to-API Flow
1. Sandbox pushes changes (updating git user config)
2. Sandbox sends event to API with branch name + session ID
3. API uses user's GitHub token to create PR
4. GitHub webhooks notify API of PR events

PRs appear as authored by the human, not the bot — preserves audit trail and prevents users from approving their own AI-generated changes.

---

## Metrics That Matter

| Metric | Why |
|--------|-----|
| Sessions → merged PRs | Primary success metric |
| Time to first model response | User perception of speed |
| PR approval rate / revision count | Quality of agent output |
| Agent-written code % per repo | Adoption depth |

---

## Framework Selection

**Server-first architecture**: structure agent as server, with TUI/desktop apps as thin clients. Prevents duplicating agent logic across surfaces. Plugin system enables runtime interception (tool.execute.before) for safety and observability.

**Code as source of truth**: prefer frameworks where agent can read its own source — prevents hallucinating about its own capabilities.

---

## Gotchas

1. **Cold start latency** — users perceive >5s as broken; use warm pools + predictive warm-up
2. **Image staleness** — infrequent rebuilds = outdated dependencies; set 30-min cadence, alert on build failures
3. **Sandbox cost runaway** — no timeout/budget caps → unexpected costs; hard timeout (4 hours), per-session ceiling
4. **Auth token expiration** — long tasks fail mid-session; implement token refresh, check validity before PR creation
5. **Git config missing** — commits fail in background agents; always set identity explicitly, never assume from image
6. **State loss on recycle** — sandbox recycled before results extracted; always snapshot + extract artifacts before termination
7. **Oversubscribing warm pools** — too many warm sandboxes wastes money during low-traffic; autoscale by traffic patterns
8. **Missing output extraction** — work done but results never pulled out; build explicit extraction (push branch, create PR) into teardown
