---
name: swiftui-expert
description: Write, review, and modernize SwiftUI code for Apple platforms. Use for state/data flow, view composition, navigation, layout, accessibility, performance, animation, charts, macOS behavior, and current SwiftUI APIs.
---

# SwiftUI Expert

Review SwiftUI for correctness, current API usage, maintainability, accessibility, and measured performance. Report real issues; avoid style-only churn.

## Start Here

1. Check the project's Swift version, SDK/Xcode version, and deployment targets before recommending version-specific APIs.
2. Load only the references relevant to the task. For broad reviews, start with `references/latest-apis.md`.
3. Preserve project architecture unless the requested change requires restructuring.
4. During feature or bug-fix work, keep unrelated modernization as separate suggestions.

Current ecosystem baseline: Swift 6.4 and the 2027 Apple platform SDK generation are available. Never assume a project targets them; respect its existing toolchain and deployment target.

## Core Guidance

- Prefer native SwiftUI APIs; bridge to UIKit/AppKit only when SwiftUI cannot express the requirement cleanly.
- Treat each `View` as an invalidation boundary: pass only the data it reads and keep frequently changing state close to the smallest affected subtree.
- Use Observation (`@Observable`, `@State`, `@Bindable`) when supported by the project's target; use older wrappers when required by compatibility.
- Keep stable identity in `ForEach`/lists and avoid expensive work, filtering, formatting, decoding, or synchronous I/O in `body`.
- Prefer semantic controls such as `Button` over gesture-only tap handling, and validate Dynamic Type, VoiceOver, Reduce Motion, contrast, and hit targets.
- Use modern navigation and presentation APIs appropriate to the deployment target.
- Measure performance problems with Instruments when code inspection alone cannot establish impact.
- Apply Liquid Glass and other visual-system features intentionally; system components should usually provide the platform appearance automatically.
- Do not add third-party dependencies unless the task or project already calls for them.

## Reference Router

| Need | Reference |
|---|---|
| New/deprecated APIs and platform availability | `references/latest-apis.md` |
| State, Observation, bindings, environment | `references/state-management.md` |
| View composition and invalidation | `references/view-structure.md` |
| Runtime performance | `references/performance-patterns.md` |
| Lists, identity, `ForEach` | `references/list-patterns.md` |
| Adaptive/resizable layout | `references/layout-best-practices.md` |
| Navigation, sheets, inspectors | `references/sheet-navigation-patterns.md` |
| Scrolling and lazy containers | `references/scroll-patterns.md` |
| Animation and transitions | `references/animation.md` |
| Accessibility | `references/accessibility-patterns.md` |
| Charts | `references/charts.md` |
| Images | `references/image-optimization.md` |
| Liquid Glass / materials | `references/liquid-glass.md` |
| macOS UI and lifecycle | `references/macos.md`, `references/macos-app-lifecycle.md` |
| Menu bar + Tuist specifics | `references/macos-menubar-tuist.md` |

## Review Priorities

1. Correctness and data ownership.
2. API availability and deprecations.
3. Accessibility and adaptive layout.
4. Identity, invalidation, main-thread work, and measured performance.
5. Code clarity and maintainability.

For partial reviews, load only the matching references and return only actionable findings.