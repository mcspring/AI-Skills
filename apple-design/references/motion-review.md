# Motion Review

Review motion by interaction semantics, not by a universal duration/easing table. The goal is responsive, coherent, interruptible feedback that preserves spatial understanding and accessibility.

## Review Order

1. **Purpose** — does motion explain state, hierarchy, continuity, or direct manipulation?
2. **Input response** — does feedback begin promptly and track the active gesture/pointer when appropriate?
3. **Continuity** — do origin, direction, velocity, and destination preserve the element's spatial identity?
4. **Interruptibility** — can repeated or gesture-driven interactions retarget from the current visual state?
5. **Performance** — does the implementation avoid unnecessary layout/repaint work on hot paths?
6. **Accessibility** — does Reduce Motion / `prefers-reduced-motion` preserve meaning with less movement?
7. **Consistency** — does the motion fit the platform and the rest of the product?

Only report issues that materially affect usability, accessibility, correctness, or perceived quality.

## Strong Findings

Flag these when the context makes them harmful:

- animation blocks or delays direct input;
- a drag/slider/scrubber fails to track the interaction continuously;
- an interrupted transition jumps to a logical target instead of continuing from its live presentation state;
- anchored UI (popover/menu/tooltip) appears from an unrelated origin;
- movement conveys required information with no reduced-motion alternative;
- hover-only behavior is applied to coarse/non-hover pointers without a fallback;
- a hot animation repeatedly triggers expensive layout/paint work and profiling shows frame loss;
- decorative motion runs on extremely frequent keyboard/command actions and makes them feel slower.

Avoid treating stylistic preferences such as one specific easing curve, scale value, or duration as correctness failures.

## Timing and Easing

Choose timing from distance, hierarchy, frequency, input modality, and platform conventions.

Useful tendencies, not laws:

- direct feedback should feel immediate;
- small UI changes are usually quicker than large spatial transitions;
- entering/exiting UI often benefits from responsive deceleration;
- on-screen relocation may use symmetric or spring-like motion when continuity matters;
- high-frequency actions benefit from little or no decorative motion;
- system/native component timing is usually preferable to a custom imitation.

If a duration or spring value is proposed, present it as a starting point to tune against the real interaction.

## Physical and Spatial Continuity

- Start anchored elements from their visual cause when the relationship is meaningful.
- Preserve direction between enter/exit when that direction communicates where content came from or returns to.
- Hand off gesture velocity when momentum is part of the interaction.
- Avoid transformations that make an element appear to materialize from an implausible point unless that effect is intentional.
- Use rubber-banding/resistance only when it communicates a boundary and remains predictable.

## Interruptibility

Rapidly repeated and gesture-driven motion should generally be retargetable.

Prefer primitives that continue from current presentation state:

- native platform transitions/springs;
- CSS transitions or Web Animations when they can retarget cleanly;
- explicit gesture state plus spring/velocity handoff when physics are required.

Keyframes remain appropriate for self-contained sequences that are not expected to be interrupted or retargeted.

## Rendering Performance

Prefer compositor-friendly properties such as transforms and opacity on high-frequency web motion, but do not turn this into a blanket ban on layout animation. Layout properties can be appropriate when the semantic effect requires real layout and the measured cost is acceptable.

Investigate with platform tools (Instruments, browser performance tooling) before declaring an implementation too expensive.

Common risks:

- `transition: all` unintentionally animating unrelated properties;
- large blur/filter regions;
- per-frame style/layout reads mixed with writes;
- parent-level variables invalidating large subtrees;
- excessive view/state invalidation during native animations.

## Accessibility

Reduced-motion behavior should preserve state and causality while reducing displacement, scale, parallax, or repeated motion. Crossfades, instant state changes, or shorter/subtler transitions are all valid depending on context.

For web hover effects, gate behavior to devices that actually support hover/fine pointers when the interaction would otherwise be inaccessible or confusing.

## Review Output

Match the host code-review format. For each actionable issue, include:

- location;
- observed behavior/risk;
- smallest useful change;
- why the change improves interaction, accessibility, or performance.

Use severity only when it helps prioritize. Do not force every review into a fixed table or Block/Approve verdict unless the surrounding workflow requests that format.

## Related References

- `fluid-interfaces.md` — direct manipulation, momentum, continuity, materials, typography.
- `design-engineering.md` — implementation choices and component polish.
- `motion-vocabulary.md` — terminology for describing motion precisely.