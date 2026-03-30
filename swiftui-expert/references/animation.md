# SwiftUI Animations

Comprehensive animation guide: implicit/explicit animations, transitions, phase/keyframe animations, transactions, and the Animatable protocol.

## Core Concepts

State changes trigger view updates. SwiftUI compares the new tree to the current render tree and interpolates animatable properties (~60 fps). Animations are additive, cancelable, and blend smoothly when interrupted.

---

## Implicit vs Explicit Animations

```swift
// Implicit — animate when a specific value changes
Rectangle()
    .frame(width: isExpanded ? 200 : 100, height: 50)
    .animation(.spring, value: isExpanded)

// Explicit — event-driven
Button("Toggle") {
    withAnimation(.spring) { isExpanded.toggle() }
}
```

**When to use which:**
- **Implicit**: tied to specific value changes, precise scope in view tree
- **Explicit**: event-driven (button taps, gestures)

**Placement**: animation modifiers go AFTER the properties they animate.

```swift
// ✓ Animation after properties
Rectangle()
    .frame(width: isExpanded ? 200 : 100, height: 50)
    .animation(.default, value: isExpanded)

// ✗ Animation before properties — won't work
Rectangle()
    .animation(.default, value: isExpanded)
    .frame(width: isExpanded ? 200 : 100, height: 50)
```

### Selective Animation

```swift
// Multiple animation modifiers for selective control
Rectangle()
    .frame(width: isExpanded ? 200 : 100, height: 50)
    .animation(.spring, value: isExpanded)     // animate size
    .foregroundStyle(isExpanded ? .blue : .red)
    .animation(nil, value: isExpanded)          // don't animate color

// iOS 17+ scoped animation
Rectangle()
    .foregroundStyle(isExpanded ? .blue : .red)  // not animated
    .animation(.spring) {
        $0.frame(width: isExpanded ? 200 : 100, height: 50)  // animated
    }
```

---

## Timing Curves

| Curve | Use Case |
|-------|----------|
| `.spring` | Interactive elements, most UI |
| `.easeInOut` | Appearance changes |
| `.bouncy` | Playful feedback (iOS 17+) |
| `.linear` | Progress indicators only |

Modifiers: `.speed(2.0)`, `.delay(0.5)`, `.repeatCount(3, autoreverses: true)`

---

## Transitions

Animate views being **inserted or removed** from the render tree (not property changes on existing views).

```swift
// Transition requires animation context OUTSIDE the conditional
VStack {
    Button("Toggle") { showDetail.toggle() }
    if showDetail {
        DetailView()
            .transition(.slide.combined(with: .opacity))
    }
}
.animation(.spring, value: showDetail)
```

> **Critical:** Animation modifiers INSIDE conditionals are removed with the view — won't animate on removal.

### Built-in Transitions

| Transition | Effect |
|------------|--------|
| `.opacity` | Fade in/out (default) |
| `.scale` | Scale up/down |
| `.slide` | Slide from leading edge |
| `.move(edge:)` | Move from specific edge |

### Asymmetric Transitions

```swift
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .move(edge: .bottom).combined(with: .opacity)
))
```

### Custom Transitions (iOS 17+)

```swift
struct BlurTransition: Transition {
    var radius: CGFloat
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .blur(radius: phase.isIdentity ? 0 : radius)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}
```

### Identity and Transitions

View identity changes (`if/else` branches, `.id()` changes) trigger transitions, not property animations.

---

## The Animatable Protocol

Enables custom property interpolation during animations.

```swift
struct ShakeModifier: ViewModifier, Animatable {
    var shakeCount: Double

    var animatableData: Double {
        get { shakeCount }
        set { shakeCount = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: sin(shakeCount * .pi * 2) * 10)
    }
}
```

For multiple properties, use `AnimatablePair`:

```swift
var animatableData: AnimatablePair<CGFloat, Double> {
    get { AnimatablePair(scale, rotation) }
    set { scale = newValue.first; rotation = newValue.second }
}
```

### @Animatable Macro (iOS 26+)

Auto-synthesizes `animatableData`. Use `@AnimatableIgnored` for non-animatable properties:

```swift
@Animatable
struct Wedge: Shape {
    var startAngle: Angle
    var endAngle: Angle
    @AnimatableIgnored var drawClockwise: Bool
    func path(in rect: CGRect) -> Path { /* ... */ }
}
```

---

## Transactions

The underlying mechanism for all animations. `withAnimation` is shorthand for `withTransaction`.

```swift
// Implicit animations override explicit (later in view tree wins)
Button("Tap") { withAnimation(.linear) { flag.toggle() } }
    .animation(.bouncy, value: flag)  // .bouncy wins!

// Disable animations
.transaction { $0.animation = nil }
.transaction { $0.disablesAnimations = true }
```

### Custom Transaction Keys (iOS 17+)

Pass metadata through the animation system via `TransactionKey` to vary animation per source.

---

## Phase Animations (iOS 17+)

Cycle through discrete phases automatically. Replaces manual `DispatchQueue.asyncAfter` sequencing.

```swift
// Triggered shake
Button("Shake") { trigger += 1 }
    .phaseAnimator([0.0, -10.0, 10.0, -5.0, 5.0, 0.0], trigger: trigger) { content, offset in
        content.offset(x: offset)
    }

// Enum phases (recommended)
enum BouncePhase: CaseIterable {
    case initial, up, down, settle
    var scale: CGFloat {
        switch self {
        case .initial: 1.0; case .up: 1.2; case .down: 0.9; case .settle: 1.0
        }
    }
}
```

---

## Keyframe Animations (iOS 17+)

Precise timing control with exact values at specific times. Tracks run **in parallel**.

```swift
Button("Bounce") { trigger += 1 }
    .keyframeAnimator(initialValue: AnimationValues(), trigger: trigger) { content, value in
        content.scaleEffect(value.scale).offset(y: value.verticalOffset)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(1.2, duration: 0.15)
            SpringKeyframe(0.9, duration: 0.1)
            SpringKeyframe(1.0, duration: 0.15)
        }
        KeyframeTrack(\.verticalOffset) {
            LinearKeyframe(-20, duration: 0.15)
            LinearKeyframe(0, duration: 0.25)
        }
    }
```

| Keyframe Type | Behavior |
|---------------|----------|
| `CubicKeyframe` | Smooth interpolation |
| `LinearKeyframe` | Straight-line |
| `SpringKeyframe` | Spring physics |
| `MoveKeyframe` | Instant jump |

---

## Animation Completion (iOS 17+)

```swift
withAnimation(.spring) { isExpanded.toggle() } completion: { showNextStep = true }
```

---

## Performance

- **Prefer transforms** (`scaleEffect`, `offset`, `rotationEffect`) over layout changes (`.frame`, `.padding`)
- **Scope animations narrowly** — don't apply at root level
- **Gate threshold** in scroll handlers — don't animate every frame

---

## Disabling Animations

```swift
.transaction { $0.animation = nil }       // remove animation
.transaction { $0.disablesAnimations = true }  // prevent override
```

---

## Quick Reference

### Do
- Use `.animation(_:value:)` with value parameter
- Use `withAnimation` for event-driven animations
- Place transitions outside conditional structures
- Prefer transforms over layout changes
- Use `phaseAnimator`/`keyframeAnimator` for multi-step sequences
- Implement `animatableData` for custom Animatable types

### Don't
- Use deprecated `.animation(_:)` without value
- Put animation modifiers inside conditionals for transitions
- Animate layout properties in hot paths
- Use `DispatchQueue.asyncAfter` for animation sequencing
- Forget `animatableData` implementation (silent failure)
