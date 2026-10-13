# SwiftUI API Modernization Lookup

Use this reference to identify current SwiftUI APIs by deployment target. Check the project's actual Xcode/SDK and minimum OS before applying a migration.

This is a lookup, not a requirement to modernize unrelated code.

## iOS 15+ Baseline Replacements

Prefer current names when the minimum target supports them:

| Older API/pattern | Current API |
|---|---|
| `navigationBarTitle` | `navigationTitle` |
| `navigationBarItems` | `toolbar` / `ToolbarItem` |
| `navigationBarHidden` | `toolbarVisibility(..., for:)` |
| `edgesIgnoringSafeArea` | `ignoresSafeArea` |
| `foregroundColor` | `foregroundStyle` where style semantics fit |
| `cornerRadius` | `clipShape(.rect(cornerRadius:))` for explicit clipping |
| `actionSheet` | `confirmationDialog` |
| old alert builder | modern `alert` actions/message overloads |
| `TextField` commit callbacks | `onSubmit` / focus APIs |
| generic accessibility variants | dedicated accessibility modifiers |
| `animation(_:)` without value | `animation(_:value:)` or explicit `withAnimation` |

Do not replace an older API merely because a newer spelling exists when deployment/source compatibility requires the old form.

## iOS 16+

### Navigation

Use `NavigationStack` / `NavigationSplitView` for modern value-based navigation instead of `NavigationView` in new code targeting iOS 16+.

Prefer route values plus `navigationDestination(for:)` for programmatic/restorable flows.

### Styling/Input

- `tint` supersedes many `accentColor` uses.
- `autocorrectionDisabled` replaces the older disable-autocorrection form.
- `PasteButton` is preferable for user-initiated transferable paste flows where it fits.

### Charts

Swift Charts base APIs (`Chart`, standard marks, axes/scales) are available from this generation. See `charts.md`.

## iOS 17+

### Observation

Use Observation (`@Observable`) for new observable models where the project's toolchain/deployment target allows it.

Typical SwiftUI ownership:

- owned observable → `@State`;
- injected observable read-only → plain property;
- injected observable requiring bindings → `@Bindable`.

See `state-management.md`.

### `onChange`

Prefer the zero-parameter or old/new-value modern overloads over deprecated `onChange(of:perform:)` forms.

### Gestures

Use `MagnifyGesture` and `RotateGesture` instead of deprecated magnification/rotation gesture names when available.

### Scrolling and Charts

This generation adds modern scroll targeting/position behaviors and chart selection/scrolling APIs. Use the dedicated references rather than geometry/preference hacks when native APIs solve the requirement.

## iOS 18+

### Tabs

The newer `Tab` APIs provide a more structured model than legacy `tabItem` composition for new code targeting this generation.

### SwiftUI / Foundation Integration

Prefer framework-native APIs for presentation, scrolling, container values, and data-driven chart plots when they remove custom plumbing. Check exact availability in the SDK documentation before adopting a specific symbol.

## iOS 26+

### Liquid Glass

Current SDK components adopt Liquid Glass/material behavior automatically. Prefer system navigation/toolbars/tabs/sheets before applying custom glass effects.

Use custom glass only for a justified functional layer and gate the specific custom API, not unrelated surrounding UI.

See `liquid-glass.md`.

### Animation

`@Animatable` can replace manual `animatableData` implementations in applicable custom animatable types.

### Charts

`Chart3D`, `SurfacePlot`, Z-axis, camera/pose APIs arrive in this generation. Prefer 2D unless a third quantitative dimension materially helps understanding.

### Concurrency/UI

Swift 6.2-era approachable-concurrency behavior and typed framework APIs affect how SwiftUI code interacts with isolation. Inspect project language/default-isolation settings rather than assuming all iOS 26 projects use the same behavior.

## iOS 27+ / Xcode 27 Generation

WWDC26 introduces another SwiftUI API generation. Confirm symbol availability against the installed SDK because compiler-generated/back-deployed behavior and runtime-only behavior differ.

### Documents

New document infrastructure supports direct URL access, asynchronous/incremental reading/writing, progress, and more flexible document creation sources.

Use these APIs for large or partially updated documents when full-file rewrite models are inappropriate.

### Reordering

Native reorderable-container APIs extend reordering beyond `List` to stacks, grids, and custom layouts.

Prefer native reordering before implementing a custom drag/drop ordering engine. For extremely large collections, test traversal/layout cost with realistic data.

### Swipe Actions

Swipe actions can be hosted for content outside traditional `List` using the new container support. Preserve accessible/non-swipe action paths when discoverability matters.

### Alerts and Dialogs

Item-binding presentation patterns are available for alerts and confirmation dialogs, reducing duplicated boolean + optional-item state.

### Toolbars

New toolbar capabilities include adaptive visibility priority, overflow behavior, pinned trailing items, and minimize-on-scroll patterns.

Use semantic priority/grouping instead of hard-coded width logic where system adaptation solves the problem.

### AsyncImage

`AsyncImage` participates in standard HTTP caching in the new generation. Customize request/session/cache policy only when product semantics require something different.

### `@State`

`@State` is macro-based in the new toolchain and lazily initializes stored class instances once for the view lifetime. This improves direct reference ownership in state and can back-deploy as a compiler-generated behavior where supported.

Do not infer this behavior solely from the deployment target; the build toolchain matters.

### Builders

SwiftUI's builder implementation/API evolves toward `ContentBuilder` in relevant surfaces. Follow compiler migration guidance rather than reproducing old specialized-builder behavior manually.

### Agent Skills in Xcode

Xcode 27 includes SwiftUI-oriented agent skills/context support. Treat those as development-tool assistance, not runtime APIs or a substitute for checking project deployment/toolchain constraints.

## Cross-Version Rules

### Availability

Gate the narrow symbol/feature requiring the newer OS. Avoid duplicating an entire screen into “old” and “new” implementations unless the interaction genuinely differs.

### Back Deployment

Some language/macros/toolchain-generated features can back-deploy while framework symbols require a newer runtime. Verify which category a feature belongs to.

### Deprecation

A deprecation warning is a modernization signal, not proof that the current code is broken. During a focused bug/feature task, separate unrelated migration unless it blocks compilation or correctness.

### Native Before Custom

As SwiftUI gains navigation, scrolling, layout, reordering, swipe, presentation, observation, and material APIs, remove custom compatibility plumbing only when the minimum target and behavior allow it.

## Quick Review Checklist

1. What Swift/Xcode SDK is the project actually building with?
2. What is the minimum deployment target per platform?
3. Is the proposed API runtime-gated, compiler/back-deployed, or both?
4. Does a native current API replace custom UIKit/AppKit/geometry plumbing?
5. Is modernization part of the requested change or should it be a separate suggestion?
6. Is the fallback meaningful and maintained, rather than a duplicate implementation for its own sake?
