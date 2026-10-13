# Fluid Interfaces

Use this reference for direct manipulation, gesture-driven motion, spatial continuity, materials, feedback, and typography. Start from platform-native behavior; add custom physics only when they improve the interaction.

## Core Model

A fluid interface preserves a clear relationship between **input → visual response → resulting state**.

Priorities:

1. respond promptly;
2. track direct manipulation continuously;
3. preserve spatial identity;
4. allow interruption and reversal;
5. hand off momentum when it communicates intent;
6. adapt motion for accessibility.

## Direct Manipulation

Dragging, scrubbing, resizing, and sliding should normally track the pointer/touch continuously rather than waiting for gesture completion.

Preserve the grab offset where it matters: an object should not jump so its center snaps beneath the pointer when the user grabs it off-center.

Use platform gesture APIs first. On the web, pointer capture can keep a drag coherent when the pointer leaves the element.

## Interruptibility

Interactive transitions should continue from the current presented state when retargeted. Do not make the user wait for one animation to finish before reversing or beginning the next interaction.

This matters most for:

- drawers/sheets;
- draggable cards;
- scrubbers/sliders;
- toggles and rapidly repeated controls;
- transient UI such as toasts or popovers.

A self-contained decorative sequence may reasonably remain non-interruptible.

## Springs and Easing

Choose motion from semantics rather than a global preset.

- Native/system components: keep their system behavior when possible.
- Gesture/momentum: springs often preserve velocity and retarget naturally.
- Predetermined state changes: platform transitions, CSS transitions, or WAAPI may be simpler.
- Continuous/indefinite motion: linear timing can be appropriate.

Spring response, damping/bounce, and duration are tuning inputs. Validate them at real device/window size instead of treating one set of constants as an Apple standard.

## Velocity and Momentum

When motion continues after a gesture, preserve continuity between finger/pointer velocity and animated velocity when the interaction implies momentum.

Projecting a release position can help choose a snap target, but the projection model and deceleration constants are implementation details. Prefer the platform's native scroll/gesture behavior where it already expresses the intended physics.

## Boundaries and Resistance

Rubber-banding can communicate that content is moving beyond a soft boundary. Resistance should increase progressively and remain reversible.

Use it selectively; arbitrary resistance on ordinary controls can make input feel inaccurate.

## Spatial Continuity

Use motion to answer “where did this come from?” and “where did it go?”

- Anchor popovers/menus to their source when that relationship is meaningful.
- Keep enter/exit paths consistent when direction encodes navigation.
- Use shared-element/matched-geometry transitions only when identity is genuinely shared.
- Avoid unrelated transforms that obscure hierarchy.

## Frame Performance

For high-frequency web motion, transforms and opacity are often the cheapest path because they can stay composited. Layout animation is not inherently wrong; use it when the semantic effect requires layout and measure the cost.

For native Apple platforms, use Instruments when frame pacing or invalidation is in question. Avoid optimizing animation code from folklore alone.

## Materials and Depth

Apple's current material model separates a **functional layer** from the **content layer**:

- Liquid Glass is primarily for controls and navigation floating above content.
- Standard materials belong in the content layer when separation/depth is needed.
- System components inherit the current platform material behavior automatically.
- Custom Liquid Glass should be used sparingly and semantically, not as decoration across the whole content surface.
- Respect system appearance, contrast, transparency, and accessibility settings; do not depend on a material's apparent color.

When a standard control already provides the correct material, prefer it over a custom reproduction.

## Multimodal Feedback

Visual motion, haptics, and sound should share the same causal event. Use haptics/audio only when they improve confirmation or physicality; avoid adding feedback to every minor state change.

The exact synchronization/timing should be validated on the target platform rather than encoded as a universal frame-level constant.

## Reduced Motion

Reduced Motion does not necessarily mean “remove all animation.” Preserve meaning with alternatives such as:

- crossfade instead of large translation;
- shorter/smaller displacement;
- instant state change where movement adds no information;
- reduced parallax, zoom, and repeated oscillation.

Also validate Dynamic Type, contrast, focus/keyboard navigation, and touch/pointer interaction because motion is only one accessibility dimension.

## Typography

Prefer system text styles and semantic hierarchy. They already account for platform typography and accessibility scaling.

For custom typography:

- validate legibility across sizes and Dynamic Type/text scaling;
- tune tracking/leading for the actual font and size rather than one global value;
- preserve hierarchy with size, weight, spacing, and placement before adding decorative effects;
- avoid motion that destabilizes reading position.

## Design Process

1. Prototype the real interaction, not just screenshots.
2. Test touch, pointer, keyboard, and assistive paths that apply.
3. Resize/rotate/window the UI and confirm continuity.
4. Interrupt gestures/transitions mid-flight.
5. Test Reduce Motion and increased contrast/transparency settings.
6. Profile only when performance is uncertain or demonstrably poor.

## Review Questions

- Does input receive immediate, continuous feedback?
- Can the interaction reverse without a visual jump?
- Does motion preserve spatial identity and hierarchy?
- Are custom physics necessary, or would native behavior be clearer?
- Are materials used semantically in the correct layer?
- Does reduced motion preserve the same information?
- Is a performance claim supported by measurement?