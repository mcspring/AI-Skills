---
name: apple-design
description: Apple's approach to interface design, fluid physical motion, and design engineering craft. Use when designing, building, or reviewing gesture-driven UI, spring animations, drag/swipe/sheet interactions, momentum and interruptible transitions, translucent materials and depth, typography (optical sizing, tracking, leading), and reduced-motion. Includes Emil Kowalski's guidelines, code-review standards, and a reverse-lookup motion glossary.
---

# Apple Design & Craft

## Operating Rules

- **Design interaction and visuals together.** Motion is not a layer added after the pixels. Prototype interactively to discover and fine-tune the interface feel.
- **Prioritize continuous feedback.** Update the UI 1:1 with the pointer during dragging, sliding, or scrolling—never animate only at the end of the gesture.
- **Never lock out input during transitions.** Every animation must be interruptible, starting from the current presentation (live) values rather than target values.
- **Prefer CSS transitions/WAAPI for predetermined motion.** Use JS/springs for dynamic, interruptible, gesture-driven motion.
- **Keep keyboard-initiated actions immediate and predictable.** Avoid animation or delay when it slows repeated command use or obscures focus.
- **Ensure accessibility defaults.** Gate hover effects behind `@media (hover: hover) and (pointer: fine)` and provide crossfades or static transitions for `prefers-reduced-motion`.

## Task Workflow

### Build fluid UI interactions
- Read [fluid-interfaces.md](references/fluid-interfaces.md) for core principles (Response, 1:1 Tracking, Interruptibility).
- Use springs for gesture-driven interactions: damping ratio `1.0` (critically damped) for menus, and `~0.8` (under-damped) when the gesture carries momentum (flicks, throws).
- Implement 1:1 tracking using Pointer Events with `setPointerCapture`.
- Handle velocity handoff by passing raw absolute velocity or relative velocity normalized by remaining distance.
- Project momentum on release using the exponential-decay projection formula to determine snap targets.
- Implement progressive boundary resistance (rubber-banding) using the damping formula: `(overshoot * dimension * constant) / (dimension + constant * abs(overshoot))`.

### Build polished UI components
- Read [design-engineering.md](references/design-engineering.md) for detail rules.
- Add instant press feedback on buttons (`transform: scale(0.97)` on `:active`).
- Avoid entrances from `scale(0)` when they distort perceived size; use a modest scale and opacity change only when it clarifies hierarchy.
- Make popovers and dropdowns origin-aware by setting `transform-origin` to their trigger (except modals).
- Skip tooltip delays on subsequent hovers using transient state classes.
- Use CSS transitions (not keyframes) for rapidly triggered items like toasts to support interruption.
- Add subtle `filter: blur(2px)` to mask imperfect crossfades.
- Use `@starting-style` to animate enter states without JS when possible.
- Use brief staggered entrances only when they improve scanning; tune or remove them based on group size and interaction speed.

### Review UI and motion code
- Read [motion-review.md](references/motion-review.md) for the Ten Non-Negotiable Standards, escalation triggers, and remediation hierarchy.
- Prefer compositor-friendly properties for high-frequency motion, but allow layout animation when semantics require it and measured performance is acceptable.
- Investigate `transition: all`, `scale(0)` entrances, `ease-in` timing, and missing hover queries when they cause unintended motion, poor responsiveness, or input-specific behavior gaps.
- When a code-level comparison helps, use a table such as `Before / After / Why`; choose a format that fits the findings.
- State impact and recommend `Block` or `Approve` when the review context requires an explicit decision.

### Identify motion terminology
- Read [motion-vocabulary.md](references/motion-vocabulary.md) for reverse-lookup glossary matching sensations to standard terms.
- Use precise terms (e.g. Stagger, Morph, Rubber-banding) when prompting AIs or designers.
- Disambiguate similar terms (e.g., crossfade vs. morph vs. shared element transition) for clarity.

## Topic Router

| Topic | Reference |
|-------|-----------|
| UI Polish, component design rules, spring configuration, perceived performance, CSS transform & clip-path tips | [design-engineering.md](references/design-engineering.md) |
| WWDC fluid interface design, response latency, direct manipulation, interruptibility, rubber-banding, depth & translucency, typography | [fluid-interfaces.md](references/fluid-interfaces.md) |
| Motion code review methodology, ten non-negotiable standards, aggressive escalation triggers, remedial hierarchy, findings table | [motion-review.md](references/motion-review.md) |
| Comprehensive reverse-lookup glossary of UI motion terms (entrances, sequencing, scroll, feedback, easing, performance) | [motion-vocabulary.md](references/motion-vocabulary.md) |

## Tuning Guidance

- Treat timing, scale, spring, velocity, and resistance values as starting points—not Apple-wide standards.
- Prefer native gesture and animation behavior when it already matches the interaction. Tune custom physics on the target device and validate interruption, frame pacing, and accessibility.
- For the decision framework, see [fluid-interfaces.md](references/fluid-interfaces.md); for implementation trade-offs, see [design-engineering.md](references/design-engineering.md).

## References

- [design-engineering.md](references/design-engineering.md) — UI polish rules, button scales, CSS transform secrets, clip-path reveals, stagger delays, WAAPI programmatic animation, and Sonner component design philosophy.
- [fluid-interfaces.md](references/fluid-interfaces.md) — Distilled WWDC design talks: response latency, 1:1 direct tracking, interruptibility, damping ratio/response physics, momentum projection, spatial consistency, depth materials, typography, and accessibility.
- [motion-review.md](references/motion-review.md) — Animation review process, ten non-negotiable standards, findings table, aggressive escalation triggers, and remediation hierarchy.
- [motion-vocabulary.md](references/motion-vocabulary.md) — Comprehensive reverse-lookup glossary of web animation vocabulary for matching user descriptions with standard motion terminology.
