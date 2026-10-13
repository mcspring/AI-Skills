---
name: apple-design
description: Design and review Apple-quality interfaces across native apps and the web. Use for interaction design, motion, gestures, materials, hierarchy, typography, accessibility, and polished design-engineering details.
---

# Apple Design & Craft

Design for clarity, direct manipulation, continuity, platform conventions, and accessibility. Use motion and materials to explain structure—not as decoration by default.

## Core Guidance

- Start from platform-native behavior and controls before inventing custom interaction.
- Keep direct manipulation responsive: interaction should track the pointer/touch continuously and remain interruptible.
- Preserve spatial continuity when content moves, transforms, expands, or changes hierarchy.
- Prefer semantic hierarchy, typography, spacing, alignment, and system materials over ornamental chrome.
- Use depth, translucency, and Liquid Glass where they reinforce structure and platform identity; avoid stacking effects that reduce legibility.
- Respect Reduce Motion, contrast, Dynamic Type/text scaling, keyboard/assistive input, focus, and pointer/touch differences.
- Tune springs, durations, velocity handoff, and resistance from the interaction context rather than fixed global constants.
- For web implementations, prefer compositor-friendly motion and native CSS/WAAPI when sufficient; use JS when interaction state or gesture physics requires it.
- Review visual polish together with behavior: press states, hover/focus, interruption, resizing, rotation/window changes, and error/empty/loading states.

## Workflow

1. Identify the platform, input methods, content hierarchy, and accessibility constraints.
2. Reuse system conventions where they already solve the interaction.
3. Prototype the interaction at real size and speed; inspect continuity and interruption, not only static screenshots.
4. Load the narrow reference that matches the problem.
5. Treat numeric motion values as starting points to tune, not universal requirements.

## Reference Router

| Need | Reference |
|---|---|
| Component polish, web motion implementation | `references/design-engineering.md` |
| Direct manipulation, springs, momentum, materials, typography | `references/fluid-interfaces.md` |
| Motion/design code review | `references/motion-review.md` |
| Motion terminology | `references/motion-vocabulary.md` |

## Current Apple Direction

Apple's current design language continues to emphasize adaptive system materials, depth, fluid continuity, strong content hierarchy, platform-specific behavior, and accessible alternatives. Let system components inherit the current visual language where possible instead of manually recreating it.

Avoid absolute rules such as one animation-duration ceiling, one spring for every component, or mandatory transform-only animation. Performance and motion decisions depend on platform, rendering path, accessibility, and interaction semantics.