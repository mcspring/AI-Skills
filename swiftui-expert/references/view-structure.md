# SwiftUI View Structure

Use this reference for view decomposition, data dependencies, builders, containers, and reusable component boundaries.

## Split by Responsibility, Not Line Count

Extract a subview when it creates a meaningful boundary:

- independent state/lifecycle;
- narrower data dependencies/invalidation;
- reusable semantic component;
- complex conditional/layout logic that becomes easier to reason about separately;
- preview/test/accessibility behavior that deserves isolation.

Do not split every few lines into tiny forwarding views; indirection can make data flow harder to follow.

## Keep Dependencies Narrow

Pass the values/actions a child needs rather than a broad model/environment object when narrower inputs improve clarity or invalidation behavior.

A child that only displays a value should normally receive a value. A child that edits the parent's value may receive a binding. A semantic action can often be an explicit closure instead of exposing broad mutable state.

See `state-management.md`.

## View as Value

SwiftUI `View` values are lightweight descriptions. Avoid reasoning about a view struct instance as a long-lived controller object.

Persistent state belongs in SwiftUI state/observable models/resources with explicit ownership, not arbitrary mutable stored properties on the view value.

## `body`

Keep `body` declarative and cheap:

- compose views;
- derive inexpensive presentation values;
- choose branches/layout;
- attach effects/tasks/actions.

Move I/O, heavy computation, decoding, and side-effectful state mutation out of body evaluation.

## Conditional Structure and Identity

Changing structural branches can change view identity/state lifetime.

Use conditional views when the UI is genuinely different. When only style/visibility changes, modifiers may preserve identity more naturally.

Do not force one approach globally: state reset can be either a bug or the intended consequence of changing identity.

## `@ViewBuilder`

Use builders where callers should provide declarative child content.

Keep builder APIs simple:

```swift
struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding()
    }
}
```

Avoid type erasure (`AnyView`) unless heterogeneous runtime storage/API boundaries genuinely require it. Builders/opaque return types preserve more static structure.

## Content/Container APIs

For reusable containers:

- expose semantic configuration separately from child content;
- use `@ViewBuilder`/current content-builder APIs for child views;
- avoid introspecting arbitrary child structure unless a container API is specifically designed for it;
- prefer native container values/layout APIs over preference-key hacks when available.

The 2027 SDK generation evolves builder internals/API (`ContentBuilder` in relevant APIs). Let compiler migrations guide source changes rather than duplicating old builder machinery.

## Environment

Use environment for values naturally shared by a subtree (appearance, locale, dependencies with subtree semantics).

Avoid turning environment into an invisible global service registry. If a dependency is essential to understanding/reusing a component, explicit input may be clearer.

## Actions

Prefer semantic actions:

```swift
Row(item: item, onDelete: { delete(item.id) })
```

over handing a child an entire mutable store only so it can call one operation.

For controls that conceptually edit a value, a binding can be the more natural API.

## Layout Containers

Extract layout components when layout behavior itself is reusable or complicated. Consider custom `Layout` when repeatedly coordinating measurements/placement; see `layout-best-practices.md`.

Do not use `GeometryReader` solely because a subview boundary exists.

## Modifiers

Extract a custom `ViewModifier` when a group of modifiers represents one reusable semantic behavior/style. Avoid modifiers that hide substantial navigation/data mutations behind styling-looking APIs.

## Platform-Specific Structure

Use conditional compilation/availability at the narrowest platform/API boundary. Keep shared view semantics common when possible, but do not contort macOS/iOS UIs into one structure when platform interaction models differ.

## Performance

Subview extraction can reduce invalidation scope when it narrows dependencies; it is not a guaranteed optimization by itself.

Measure suspicious update behavior with SwiftUI diagnostics/Instruments. See `performance-patterns.md`.

## Common Failures

- monolithic view owns unrelated state and dependencies;
- tiny one-line components create excessive navigation without semantic benefit;
- broad environment/model dependency for one displayed value;
- side effects or expensive sorting/decoding in `body`;
- `AnyView` used to “fix” builder errors unnecessarily;
- state unexpectedly resets because structural identity changed;
- generic container APIs become more complex than their callers.

## Review Questions

1. Does each view have one understandable responsibility?
2. Are ownership and dependencies visible?
3. Would extraction create a useful state/invalidation/reuse boundary?
4. Is `body` declarative and cheap?
5. Are conditional branches intentionally changing identity/lifetime?
6. Can a native builder/container/layout API replace custom plumbing?
