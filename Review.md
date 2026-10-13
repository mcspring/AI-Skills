# 迭代评审记录 (Iteration Review)

## 需求与问题分析
- **目标**：重构 `skills-main` 文件夹下的多个子 SKILL，统一为符合 `ai-dev` SKILL 架构设计规范的 `apple-design` 结构。
- **背景**：原 `skills-main/skills` 包含 `emil-design-eng`、`review-animations`、`animation-vocabulary` 和 `apple-design` 4 个零散技能，缺乏统一的入口规范。而 `ai-dev` 代表了标准的单 SKILL + reference 架构，包含 Operating Rules, Task Workflow, Topic Router, Key Metrics, References 以及一致的 `AGENTS.md` 和 `CLAUDE.md` 配置。
- **问题**：多处规则分散不利于 AI 代理高效检索，且格式各异（有的有 `STANDARDS.md`，有的有 initial response 拦截等）。

## 技术方案设计与决策
1. **统一架构设计**：
   - 建立 `/Users/mc/Workspaces/AI-Skills/apple-design` 目录作为主 SKILL。
   - 编写 `apple-design/SKILL.md`，作为统一的入口。定义清晰的 YAML Frontmatter、操作系统层面的 Operating Rules、四大核心任务流（交互设计、组件开发、代码评审、术语词汇）、Topic Router 索引表、Key Metrics 指标表及 References 外部规范链接。
   - 创建 `AGENTS.md` 和 `CLAUDE.md` 保持与 `SKILL.md` 一致。
2. **规范化参考文档**：
   - 在 `apple-design/references/` 下建立细分的 `.md` 参考文件，完全迁移及规范化原有内容：
     - `design-engineering.md`：合并 UI 细节 polish、CSS clip-path、springs 物理、组件最佳实践等。
     - `fluid-interfaces.md`：整理 Apple WWDC 交互大纲（直接操作、物理动画、减速公式、深度层次）。
     - `motion-review.md`：合并 `review-animations` 动作审查标准与 `STANDARDS.md` 全量量化参数。
     - `motion-vocabulary.md`：收录完整的动词术语表。
3. **清理与重构**：
   - 清理已淘汰且未跟踪的 `skills-main` 文件夹，避免代码冗余。

## 变更记录

### 新增文件 (Added)
- `apple-design/SKILL.md`
- `apple-design/AGENTS.md`
- `apple-design/CLAUDE.md`
- `apple-design/references/design-engineering.md`
- `apple-design/references/fluid-interfaces.md`
- `apple-design/references/motion-review.md`
- `apple-design/references/motion-vocabulary.md`
- `Review.md`

### 删除文件 (Deleted)
- `skills-main/` 目录及其下的所有内容。

---

# 2026-10-13：Skill 主定义现代化

## 目标
- 审查全部顶层 `SKILL.md`，减少重复说明和硬编码约束，使 Skill 更适合 Agent 按需加载。
- 对齐当前语言与平台基线：Go 1.27、Rust 1.99、Swift 6.4、SwiftUI/iOS 27。
- `swiftui-expert` 参考 `twostraws/SwiftUI-Agent-Skill` 的按主题路由与 actionable review 思路。

## 设计决策
- 采用“**短主 Skill + 按需 reference**”结构：主 Skill 只保留触发范围、核心原则、reference router 和验证方法。
- 删除缺乏上下文依据的通用魔法数字与绝对规则，例如固定 context compaction 阈值、tool 数量、multi-agent token 倍数、benchmark 次数和统一动画参数。
- 版本特性先检查项目实际 toolchain / deployment target / MSRV，再决定是否采用；不为追新版本而迁移。
- 把 correctness、安全边界和可验证行为放在风格偏好之前，避免 architecture/style-only churn。

## 本轮变更
- 精简 `ai-context`、`ai-dev`、`apple-design`、`golang-dev`、`golang-expert`、`golang-perf`、`rust-expert`、`swift-concurrency`、`swiftui-expert` 共 9 个主 Skill。
- 主 Skill 总行数由 1099 行降至 417 行，减少约 62%。
- 为 `swiftui-expert/references/latest-apis.md` 增加 iOS 27 / WWDC26 API 概览，包括 Document API、通用 reordering/swipe actions、toolbar 自适应、AsyncImage caching 与新 `@State` 行为。

## 后续迭代
- 审查全部 `references/`，合并跨文档重复规则和过时版本说明。
- 优先拆分超大 reference，并建立更窄的按需路由，降低单次上下文加载成本。
- 更新 Go 1.27、Rust 1.99、Swift 6.4、SwiftUI/iOS 27 与 Apple 最新设计实践的细节内容。

---

# 2026-10-13：References 按需加载重构

## 目标
- 继续审查全部 `references/`，把教程型、重复型文档收敛为 Agent 可快速路由的决策参考。
- 清除与主 Skill 冲突的固定阈值、绝对化惯例和过时版本说明。
- 更新 Swift 6.4、Go 1.27、Rust 1.99、SwiftUI/iOS 27 与 Apple 当前设计实践。

## 设计决策
- 单个 reference 优先聚焦一个问题域，保留：适用场景、决策原则、关键边界、常见失败、验证方法。
- 删除可以由相邻 reference 覆盖的大段教程、重复示例和同义 checklist；跨主题内容改为引用路由。
- 将 300 行作为本轮的软上限：完整 API 目录允许较高信息密度，但不再保留 500–1000 行的单文件教程。
- 版本升级遵循项目实际 `go` directive、Rust MSRV/edition、Swift language/default isolation、Xcode SDK 与 deployment target，不把“最新版本”写成强制迁移要求。

## 版本更新
- **Swift 6.4**：补充 async `defer`、`withTaskCancellationShield`、Observation 细粒度通知，并把执行/isolation 判断从 Swift 6.2 固定描述升级为 project-settings-aware。
- **Go 1.27**：补充 generic methods、`encoding/json/v2` / `encoding/json/jsontext`、`goroutineleak` pprof；修正 `WaitGroup.Go` 为 Go 1.25+。
- **Rust 1.99**：新增 `modernization.md`，覆盖 Rust 2024/MSRV 工作流、C ABI variadics、raw-pointer layout API、`Box::leak` 所有权建议及相关稳定库 API。
- **SwiftUI/iOS 27**：补充 Document API、任意容器 reordering、通用 swipe actions、toolbar adaptive APIs、`AsyncImage` HTTP caching、macro-based lazy `@State`、ContentBuilder 等。
- **Apple Design**：Liquid Glass 统一按 functional layer / content layer 决策；优先系统组件，custom glass 仅用于明确的功能层需求。

## 重点重构
- Swift Concurrency：重写 `migration`、`tasks`、`actors`、`sendable`、`threading`、`async-sequences`、`async-algorithms`、`testing`、`memory-management`、`performance`、`core-data`，减少跨文件重复。
- SwiftUI：重写/收敛 `latest-apis`、`state-management`、`view-structure`、`performance-patterns`、`list-patterns`、`sheet-navigation-patterns`、`charts`、`liquid-glass`、`macos-app-lifecycle`。
- AI：移除 context 固定有效窗口/compaction 百分比、multi-agent 固定 token 倍数、tool 固定数量、hosted agent 固定 warm-pool cadence。
- Go：区分 correctness/security invariant 与社区惯例，移除 Context、interface、gRPC 等主题中过度绝对化的 `MUST/NEVER` 规则。
- Apple Design：`design-engineering` 从参数/框架教程收敛为交互状态、连续反馈、实现选择、性能与 accessibility 决策参考。
- 二次一致性审查继续收敛 `database`、`memory-systems`、`motion-review`、`fluid-interfaces`、Go naming/safety/design patterns 与 Rust error handling，消除与主 Skill 冲突的绝对化规则。

## 结果
- 全部 references 总行数由约 19,347 行降至约 9,915 行，减少约 49%。
- 当前最大的 reference 为 293 行；全部 reference 均控制在 300 行以内。
- 清理固定 `60–70%` / `70–80%` context 阈值、`~15×` multi-agent 成本、`10–20 tools`、`30-minute` cadence、本机 `file:///Users/...` 链接等遗留约束。
- 移除数据库“禁止 ORM”、固定 300ms 动画上限、固定 spring/velocity 参数、强制 motion review 输出格式，以及易过期的跨框架 memory benchmark 数字。
- `git diff --check` 通过。
