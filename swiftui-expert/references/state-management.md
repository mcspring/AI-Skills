# SwiftUI State and Data Flow

Use this reference to choose state ownership, bindings, Observation, focus, environment, and compatibility wrappers.

## Start With Ownership

Before choosing a property wrapper, ask:

1. Who creates the value?
2. Who is allowed to mutate it?
3. Which views need to observe it?
4. Does the value need a binding projection?
5. What deployment target/toolchain behavior applies?

The wrapper follows the ownership model; it should not define the architecture.

## Modern Observation

For projects that support Observation, prefer `@Observable` models with SwiftUI-managed ownership.

Typical patterns:

- view-owned observable reference → store with `@State`;
- injected observable reference → plain property when only reading;
- injected observable that needs bindings → `@Bindable` locally;
- shared dependency from environment → `@Environment` with an observable value when appropriate.

Do not wrap every observable input in `@Bindable`; use it only where binding projection is needed.

## iOS 27 / Xcode 27 `@State`

With the 2027 SDK generation, `@State` is implemented as a macro and lazily initializes stored class instances once per view lifetime. This improves ownership of reference values stored directly in state.

Check the build toolchain before relying on this behavior; deployment target alone does not describe compiler-generated semantics.

## Swift 6.4 Observation

Swift 6.4 expands Observation with finer-grained and continuous change-notification capabilities. Use those APIs when code outside SwiftUI needs explicit observation behavior; do not recreate observation pipelines inside views unless the framework behavior is insufficient.

## `@State`

Use for local source-of-truth state owned by the view/lifetime SwiftUI manages.

Good fits:

- transient UI state;
- selected IDs/options;
- local value state;
- observable reference owned by the view when using Observation.

Avoid declaring an externally supplied changing value as `@State`: state initializes from the input rather than remaining a live mirror of it.

## `@Binding`

Use when a child needs read/write access to state owned elsewhere.

Prefer a plain value plus action closure when the child only needs to report a semantic event. A binding is appropriate when the child conceptually edits the same value.

## `@Bindable`

Use with Observation when you have an observable object but need `$model.property` bindings. It creates binding access; it does not create ownership.

## `let` and Plain Properties

Use plain stored properties for injected values the view reads.

`let` is appropriate for immutable configuration. A `var` may be appropriate when SwiftUI recreates the view with changing values or the property participates in APIs such as `onChange`; neither implies local state ownership.

## Legacy `ObservableObject`

For deployment/toolchains that require Combine-based observation:

- `@StateObject` owns an `ObservableObject` for the view lifetime;
- `@ObservedObject` observes an externally owned object;
- `@EnvironmentObject` retrieves an object supplied through the environment.

Do not migrate legacy wrappers solely for style if compatibility constraints require them.

## Focus

Use `@FocusState` for focus controlled by SwiftUI.

- Boolean state is fine for one focusable field.
- An optional enum usually scales better for several fields.

Keep focus identity stable and avoid coupling business state to keyboard focus unless the interaction requires it.

## Environment

Use environment values for dependencies/configuration that naturally flow through a view subtree.

Prefer `@Entry` for custom environment/container values when the project's toolchain supports it. Avoid environment as a service locator for arbitrary mutable global state.

## Derived State

Do not store values that can be cheaply derived from another source of truth unless caching is intentional and invalidation is defined.

Examples to derive rather than duplicate:

- filtered/sorted projections for small collections;
- booleans computed from existing state;
- display formatting that is cheap and deterministic.

For expensive derivations, move work outside `body` and cache at an appropriate ownership layer.

## Nested Models

Observation can track nested observable dependencies more precisely than older `ObservableObject` chains, but ownership should still be explicit. Avoid deeply nested mutable graphs when updates and lifetimes become difficult to reason about.

## Common Failures

- incoming value stored as `@State` and then failing to update;
- using `@Binding` for read-only configuration;
- using `@StateObject` for an object owned by a parent;
- shadowing one source of truth with a second synchronized copy;
- putting broad application state in environment only to avoid passing dependencies;
- performing network or persistence work from property access/body recomputation.

## Decision Guide

| Need | Prefer |
|---|---|
| local value/source of truth | `@State` |
| child edits parent-owned value | `@Binding` |
| observable model owned by view | `@State` + `@Observable` on modern toolchains |
| injected observable needs bindings | `@Bindable` |
| dependency/configuration down subtree | `@Environment` |
| pre-Observation object owned by view | `@StateObject` |
| pre-Observation injected object | `@ObservedObject` |
| focus state | `@FocusState` |

## Verification

Change the upstream value, child value, view identity, and navigation/presentation lifetime to verify the chosen owner behaves correctly. For unexpected refreshes, use SwiftUI update diagnostics and Instruments rather than adding wrappers speculatively.
