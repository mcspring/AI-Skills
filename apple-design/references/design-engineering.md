# Design Engineering and UI Polish

Use this reference for implementation-level interaction polish, especially web UI. Platform-level motion principles live in `fluid-interfaces.md`; review methodology lives in `motion-review.md`.

## Principle

Polish is the accumulation of small decisions that improve comprehension, responsiveness, and confidence. Optimize for clear behavior before decorative motion.

## Interaction States

Every interactive control should define the states users can encounter:

- default;
- hover/pointer focus where applicable;
- pressed/active;
- keyboard focus;
- disabled;
- loading/progress;
- success/error when the action has asynchronous consequences.

Use semantic controls first so input, focus, and accessibility behavior are inherited rather than rebuilt.

## Press Feedback

Give controls immediate feedback when interaction begins. Scale, opacity, material, highlight, or shape changes can work; choose the smallest effect consistent with platform conventions.

Do not standardize one scale value globally. A compact icon button and a large card should not necessarily deform by the same amount.

## Entrances and Exits

Animate only when transition continuity helps people understand where content came from or went.

Good defaults:

- combine opacity with a small spatial/scale change when hierarchy benefits;
- keep origin consistent with the triggering control for menus/popovers;
- make exits at least as understandable as entrances;
- avoid large scale-from-zero effects for ordinary UI because they exaggerate motion and destroy spatial continuity.

Frequently triggered UI should remain interruptible.

## Easing and Springs

Use conventional easing for predetermined transitions and spring-like motion when gesture velocity, direct manipulation, or interruption should carry through naturally.

Do not choose spring constants from a universal table. Tune from:

- travel distance;
- expected interruption frequency;
- whether the action carries momentum;
- visual mass/scale;
- accessibility settings.

See `fluid-interfaces.md` for physics and velocity handoff.

## Direct Manipulation

During dragging/resizing/sliding:

- track input continuously;
- use pointer capture on the web when the gesture must survive pointer movement outside the element;
- preserve the active pointer identity in multi-touch situations;
- use resistance beyond bounds when it communicates a limit better than a hard stop;
- hand off release velocity only when momentum is part of the interaction.

## Popovers, Menus, and Tooltips

- anchor visual motion to the trigger when spatial origin matters;
- keep placement adaptive to available space;
- avoid long repeated tooltip delays after a user has already entered a tooltip-learning flow;
- ensure keyboard/focus behavior provides equivalent access.

## CSS / Web Motion

Prefer the browser's native primitives when they express the behavior clearly:

- CSS transitions for simple state changes;
- `@starting-style` for entry transitions where supported;
- WAAPI for programmatic, interruptible timelines;
- JavaScript for gesture state, physics, or coordination that CSS alone cannot represent.

Avoid `transition: all`; name the properties whose change is intentional.

## Rendering Performance

`transform` and `opacity` are often compositor-friendly, but they are not the only properties that can ever be animated. Treat “transform/opacity only” as a performance heuristic, not a correctness rule.

For hot interactions:

- inspect browser/devtools rendering and paint cost;
- avoid large expensive blur/filter regions when they miss frame budgets;
- reduce layout-triggering work inside pointer/scroll handlers;
- batch DOM reads/writes when relevant;
- test on representative lower-powered devices.

## Transforms

Remember that transforms affect descendants and coordinate systems.

- `scale()` changes child rendering too;
- percentage translation uses the element's own box;
- `transform-origin` changes perceived motion source;
- 3D transforms can create depth but also introduce perspective/legibility issues.

Use transforms to express spatial relationships, not just to make movement visually busy.

## `clip-path`

`clip-path` can produce reveals, comparisons, progress masks, and shape transitions without changing document layout.

Use it when clipping is semantically part of the effect. Validate performance on Safari/mobile before relying on complex continuously animated paths.

## Stagger

Stagger can communicate grouping/order in a one-time reveal. Keep it short enough that later items are not delayed from interaction. Avoid replaying stagger for frequently updated lists.

## Perceived Performance

Motion should make real waiting easier to understand, not disguise a slow operation indefinitely.

Prefer:

- immediate acknowledgement;
- optimistic UI when rollback semantics are safe;
- skeleton/progress only when duration justifies it;
- progressive content when partial results are useful.

## Accessibility

- respect `prefers-reduced-motion` and platform Reduce Motion;
- do not remove information when reducing motion—replace spatial motion with crossfade/static state changes as needed;
- gate hover-specific interactions on devices that actually support hover/fine pointers;
- keep focus visible and keyboard actions immediate;
- avoid flashing/repetitive motion that becomes distracting.

## Review Questions

1. Does the motion explain state or spatial relationship?
2. Is feedback immediate?
3. Can the interaction be interrupted safely?
4. Does the control work with keyboard/touch/pointer/assistive input as relevant?
5. Does reduced motion preserve meaning?
6. Is the rendering path smooth on representative hardware?
7. Would a native/platform component already solve the interaction better?
