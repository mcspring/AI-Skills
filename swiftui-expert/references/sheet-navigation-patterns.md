# SwiftUI Navigation and Presentation

Use this reference for `NavigationStack`, `NavigationSplitView`, sheets, popovers, inspectors, dialogs, and navigation state.

## Model Navigation as State

Prefer value-based navigation when navigation destinations correspond to domain values/routes. Keep navigation state at the ownership level that must restore/control it.

Use `NavigationPath` when the route types are heterogeneous or the app needs programmatic stack manipulation; a typed collection can be simpler when one route type is sufficient.

Do not store navigation state globally unless multiple independent scenes/features truly share it.

## NavigationStack

Use on modern targets for push-style navigation.

Keep `navigationDestination(for:)` close enough to the stack that route mapping is understandable. Avoid scattering duplicate destination registrations for the same type across nested views.

Destination models should have stable identity/value semantics appropriate to navigation restoration.

## NavigationSplitView

Use for sidebar/content/detail structures on iPad/macOS and adaptable layouts.

Model selection separately from presentation width. Let the system adapt columns when possible instead of maintaining parallel “phone vs desktop” navigation architectures unnecessarily.

Test compact/regular transitions and window resizing because selection and stack state may interact during adaptation.

## Sheets

A sheet represents presented state. Prefer item-driven presentation when there is a concrete model/item to present; boolean presentation is fine when the content does not depend on a distinct value.

Keep the presented item's identity stable. Do not synchronize a boolean plus a separate optional item if one source of truth can express the presentation.

Dismiss with environment `dismiss` or by changing owned presentation state according to who owns the flow.

## Alerts and Confirmation Dialogs

Use native alert/dialog APIs for short decisions and destructive confirmation. Do not build a custom sheet simply to reproduce platform alert semantics.

The 2027 SDK generation adds item-binding patterns for alerts/confirmation dialogs similar to other item-driven presentations; use when supported and it removes duplicated boolean/item state.

## Popovers

Use popovers for transient contextual controls/details, respecting platform adaptation (for example compact environments may present differently).

Do not hard-code desktop-only geometry when the same feature runs on multiple size classes/platforms.

## Inspectors

Use inspector APIs for secondary editable/detail information that belongs beside primary content, especially on macOS/iPad.

Let system inspector behavior adapt/collapse rather than emulating an inspector with arbitrary overlays when native semantics fit.

## Presentation Detents

Use detents when partial-height sheet states correspond to meaningful interaction stages. Keep content usable at each supported detent and test keyboard/accessibility text effects.

Avoid excessive custom detent logic merely to achieve a precise screenshot height.

## Navigation and State Ownership

Ask who owns the flow:

- local feature view → local route/selection state;
- coordinator/root feature → shared route state passed/bound down;
- deep link/restoration → serializable route state at a durable boundary.

Do not put view instances in route state. Store values needed to reconstruct destinations.

## Deep Links

Parse external URLs/activities into typed route/domain values, validate them, then update navigation state.

Keep parsing/security/business validation outside view builders.

## Restoration

Persist only navigation state worth restoring and whose referenced data can still be resolved. Handle deleted/unauthorized resources gracefully instead of assuming every old route remains valid.

## Availability

Use the modern API allowed by the project's minimum target. Gate only newer features, not the entire navigation structure, when an older base API already exists.

Prefer a clear fallback over maintaining two complete navigation architectures unless target differences require it.

## Liquid Glass / Current Design

Current SDK system navigation bars, toolbars, sheets, sidebars, and related controls inherit platform material behavior automatically. Remove legacy custom backgrounds before layering custom glass/material effects.

See `liquid-glass.md`.

## Common Failures

- boolean + optional item drifting out of sync for one presentation;
- random/nonstable route identity;
- destination registration duplicated/conflicting across hierarchy;
- global navigation store for purely local flows;
- custom overlay replacing native sheet/popover/inspector without need;
- compact/resize behavior untested;
- route state containing view/controller objects.

## Review Checklist

1. Is navigation/presentation represented by one clear source of truth?
2. Is route identity stable and restorable if needed?
3. Does ownership match the scope of the flow?
4. Does the UI adapt across size classes/windows/platforms?
5. Are native sheet/dialog/popover/inspector semantics used where appropriate?
6. Are newer APIs narrowly availability-gated?
