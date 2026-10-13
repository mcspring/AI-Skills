# SwiftUI Liquid Glass

Use this reference for adopting Apple's Liquid Glass material and related platform design behavior. Start from system components; customize only when the interface needs something the system does not already provide.

## Design Role

Liquid Glass is a functional material layer for controls and navigation that floats above content. It should reinforce hierarchy, direct manipulation, and spatial continuity without obscuring the content people are trying to use.

Apple's current guidance is explicit:

- use Liquid Glass primarily for controls and navigation;
- avoid treating it as a general content-background material;
- use standard materials for the content layer;
- apply custom glass sparingly;
- prefer system components because they automatically inherit platform updates and accessibility behavior.

## Availability

Liquid Glass arrived with the 26-generation Apple platform SDKs and continues to evolve in the 27-generation releases.

Check both build SDK and deployment target before using a specific API. Do not wrap an entire view hierarchy in availability checks if only one custom effect is version-specific.

## Prefer System Components

Navigation bars, tab bars, toolbars, sidebars, sheets, buttons, menus, and other standard controls pick up the current design language automatically when built with current SDKs.

Before applying `.glassEffect` or building a custom material surface:

1. remove legacy custom chrome that fights the system appearance;
2. run the app with current SDK/runtime;
3. inspect contrast, hierarchy, edge-to-edge content, and resizing;
4. customize only the remaining requirement.

## Content vs Functional Layer

Use Liquid Glass for interface elements that operate on content, not as decoration behind the content itself.

Good candidates:

- floating controls;
- navigation and toolbar controls;
- transient interactive controls over rich content;
- custom components that behave like system controls.

Usually avoid it for:

- article/card backgrounds;
- large static content panels;
- decorative translucent layers stacked behind other glass;
- surfaces with nothing meaningful underneath to refract.

## Regular vs Clear

Choose material variants by semantic context, not by which one looks prettier in a screenshot.

Clear glass is intended for visually rich backgrounds where showing more underlying content still preserves control legibility. Regular glass is a safer default for controls that need stronger separation.

System accessibility and appearance settings can change how variants render, so do not depend on an exact opacity/color.

## Custom Effects

When a custom view truly needs glass:

- keep the effect boundary around the interactive/function layer;
- use shapes that match the control's hit target and visual identity;
- keep text/symbol contrast robust across light/dark and rich backgrounds;
- avoid stacking multiple glass surfaces where hierarchy becomes ambiguous;
- test scrolling content behind the material, because refraction/context is part of the effect.

Do not manually recreate the optical appearance with fixed blur/opacity values when native material can provide the semantics and adapt over time.

## Interaction

Glass should participate in interaction rather than behave like a static translucent bitmap.

Use native control styles and current APIs so press, hover, focus, pointer, and motion behavior evolve with the platform.

macOS 27 and related platform updates continue refining material response and control feedback; avoid hard-coding last year's visual constants into custom implementations.

## Edge-to-Edge Content

The current design direction lets content extend beneath navigation/control layers while materials and scroll-edge effects preserve hierarchy.

Prefer system scroll-edge and container behavior before adding opaque backgrounds or manual gradients whose only purpose is to separate bars from content.

## Color

Use color sparingly in navigation and controls. Let underlying content contribute to the material appearance and use semantic/system colors for labels and icons.

Do not choose a material based on a fixed apparent tint: appearance, contrast, transparency, and accessibility settings can alter the result.

## Accessibility

Test with:

- Reduce Transparency;
- Increase Contrast;
- Reduce Motion;
- light/dark appearances;
- different wallpapers/content backgrounds;
- Dynamic Type and accessibility text sizes.

If the interface loses hierarchy or legibility when transparency is reduced, the design is depending too heavily on the optical effect.

## Migration From Custom Chrome

When modernizing an older app:

1. build with the latest SDK first;
2. remove unnecessary custom toolbar/tab/sidebar backgrounds;
3. use semantic layout and system controls;
4. re-evaluate scroll-edge behavior and content extension;
5. add custom glass only where system components cannot represent the design.

Do not redesign the entire app solely to “adopt Liquid Glass.”

## Common Failures

- glass used as a card/background material throughout content;
- multiple overlapping custom glass layers;
- hard-coded blur, opacity, or color intended to imitate one OS release;
- custom controls that lose keyboard/focus/accessibility behavior;
- forcing glass where a standard material or plain surface is clearer;
- hiding poor information hierarchy behind visual effects.

## Review Checklist

1. Is the surface functional UI or content?
2. Could a system component provide the effect automatically?
3. Does the material clarify hierarchy?
4. Is contrast robust across backgrounds and accessibility settings?
5. Does content flow/scroll naturally beneath functional layers?
6. Are custom effects minimal and semantically justified?
7. Does the design still work if the system changes the exact glass rendering?
