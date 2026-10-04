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

## 迭代评审记录 - 优化 Swift Concurrency SKILL (2026-07-10)

### 需求与问题分析
- **目标**：根据 Swift 官方 Concurrency 编程指南（https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/），优化 `swift-concurrency` SKILLs，指导 AI 代理关于 Swift 并发编程的最佳实践。
- **背景**：原 `swift-concurrency` SKILL 虽然具备一定的 Swift Concurrency 指引，但缺失了 Swift 6 最核心的 Region-Based Isolation (SE-0414)、`sending` 修饰符 (SE-0430)、Unavailable Conformance、以及 Structured Concurrency 下 Discarding Task Groups (SE-0381) 与 `withTaskCancellationHandler` 的详细指导和安全红线。
- **问题**：AI 代理在编写并发代码时可能会盲目推荐 `@MainActor`，或忽略由于 unconsumed results 在标准 TaskGroup 中累积造成的内存泄漏，同时缺乏对 `Mutex` (Synchronization 库，iOS 18+/macOS 15+) 的正确选型依据。

### 技术方案设计与决策
1. **入口指南升级 (SKILL.md)**：
   - 在 Fast Path 诊断阶段引入 Region Isolation 和 `sending` 的静态规则审计。
   - 丰富 Common Diagnostics 表格，新增关于 Region Isolation 冲突和 Task-isolated variables 传递的典型编译器诊断与极简安全修复方案。
   - 升级 Concurrency Tool Selection 选型表，加入 `withDiscardingTaskGroup`（针对 fire-and-forget 的侧重内存效率场景）与 `Mutex`（针对同步锁场景）。
2. **任务与取消机制深化 (tasks.md)**：
   - 补充 `withTaskCancellationHandler(operation:onCancel:isolation:)` 规范，指导如何安全桥接同步取消回调（例如 URLSession 任务取消、Combine 订阅注销），添加防止 `onCancel` 与主 `operation` 间共享可变状态引起数据竞争的警告红线。
   - 补充 `Memory Safety: TaskGroup vs DiscardingTaskGroup` 段落，清晰指引大循环/轮询场景下使用标准 TaskGroup 会发生内存泄露的风险。
   - 规范循环内部调用 `Task.checkCancellation()` 和 `Task.isCancelled` 的结构化范式。
3. **类型安全与区域隔离 (sendable.md)**：
   - 澄清隐式 `Sendable` 仅适用于非 public 类型（结构体/枚举），强调 API 边界契约需显式声明。
   - 引入 Unavailable Conformance (`@available(*, unavailable) extension T: Sendable {}`) 指南，规避非 Sendable 类型被误传递的漏洞。
   - 全面重写 Region-Based Isolation (SE-0414) 和 `sending` (SE-0430) 专题，细化“Disconnected Region”的概念并提供详细的代码样例。
4. **Actor 隔离与同步锁 (actors.md)**：
   - 深入重写 Actor Reentrancy 的 bug 表现形式（await 悬挂期间状态变更），提供 **Re-verify Invariants** (重回隔离区后校验) 与 **Mutate First and Rollback** (先操作后补偿回滚) 两种最佳实践设计模式。
   - 补充 `isolated` 参数机制，特别指出“一个函数最多包含一个 isolated 参数”的编译器安全限制。
   - 补充 `Mutex` 同步锁在 iOS 18+ 上的应用指南及与 Actor 的选型决策树。

### 变更记录

#### 修改文件 (Modified)
- [SKILL.md](file:///Users/mc/Workspaces/AI-Skills/swift-concurrency/SKILL.md)
- [tasks.md](file:///Users/mc/Workspaces/AI-Skills/swift-concurrency/references/tasks.md)
- [sendable.md](file:///Users/mc/Workspaces/AI-Skills/swift-concurrency/references/sendable.md)
- [actors.md](file:///Users/mc/Workspaces/AI-Skills/swift-concurrency/references/actors.md)
- [Review.md](file:///Users/mc/Workspaces/AI-Skills/Review.md)
