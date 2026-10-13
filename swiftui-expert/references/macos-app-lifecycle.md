# macOS SwiftUI App Lifecycle

Use this reference for scene/window lifecycle, background work, shutdown, networking, persistence, power, and deployment behavior in macOS SwiftUI apps.

## Scenes Own UI Lifetime

A SwiftUI macOS app is composed from scenes such as `WindowGroup`, `Window`, `DocumentGroup`, `Settings`, and `MenuBarExtra`.

Put UI lifetime/state at the narrowest scene/window scope that owns it. Do not assume one process = one window: users can create, close, and restore multiple windows/scenes.

## App-Wide Services

Long-lived services such as repositories, sync engines, or agent connections can be owned above individual scenes when they intentionally outlive windows.

Separate service lifetime from UI observation:

- service manages resource/process/network lifetime;
- scenes observe the subset of state they need;
- closing one window should not accidentally terminate app-wide work unless that is intended.

## Scene Phase

Use `scenePhase` for high-level active/inactive/background transitions where appropriate, but do not treat it as a precise per-window event log.

Persist important state based on data semantics rather than waiting only for termination/background callbacks, because macOS apps can be killed or crash without a graceful final event.

## Window Management

Use current SwiftUI scene/window APIs before AppKit bridging.

Test:

- multiple windows;
- reopen after all windows close;
- window restoration;
- resizing/minimum/ideal sizes;
- full screen;
- commands/menu actions;
- deep links/open-window flows.

Bridge to AppKit when SwiftUI does not expose required window behavior cleanly.

## Menu Bar Apps

Use `MenuBarExtra` when the product is fundamentally a status/menu-bar experience. Decide explicitly whether a Dock icon/main window should exist and how users open settings/primary UI.

Keep menu content fast; do not start blocking network/file work synchronously while the menu is opening.

See `macos-menubar-tuist.md` for project-specific setup.

## Background and Long-Running Work

A macOS process can remain alive without a visible window, but lifetime is still governed by app policy/system/user actions.

For long work:

- own tasks in a durable service, not a transient view;
- support cancellation and restart/resume as appropriate;
- persist checkpoints for work that must survive process restarts;
- expose progress/state to any reopened window.

Do not use a view `.task` for work intended to outlive that view.

## Networking

Reuse sessions/connections according to their API semantics. Propagate cancellation from user operations and implement reconnect/backoff for long-lived connections based on product requirements.

React to sleep/wake/network changes only when the service actually needs special handling; modern network APIs already handle many transient changes.

## Sleep and Power

Do not prevent idle/system sleep by default.

Use process/activity assertions only for bounded work where interruption would materially harm the user, and release them promptly. Long-running background utilities should cooperate with system power policy.

## Persistence

Persist user data continuously/transactionally enough that app termination does not become the primary save mechanism.

For window/UI restoration, store lightweight identifiers and reconstruct current data rather than serializing live view/service objects.

## Termination and Cleanup

Prefer explicit shutdown/cancellation APIs for resources that need orderly cleanup. Final process termination is not guaranteed to provide enough time for network synchronization or long async writes.

Cleanup should be idempotent where possible because services can stop due to user action, window/app lifecycle, error recovery, or tests.

## Security and Sandboxing

For sandboxed apps:

- request only required entitlements;
- use user-selected/security-scoped access for files outside the container as required;
- persist bookmarks only when continuing access is needed;
- keep credentials in Keychain rather than preferences/files;
- validate external URLs/files and avoid assuming prior authorization persists forever.

## Login Items / Helpers

Use current ServiceManagement APIs for login/background helpers. Make the user-facing enable/disable state explicit and reversible.

Do not ship a helper simply to keep work alive if ordinary app/service architecture can satisfy the requirement.

## App Nap and Timers

Avoid frequent polling/timers when event-driven APIs exist. Timer frequency should reflect actual product latency needs; background polling has energy cost and can be coalesced/throttled by the system.

## Updates and Distribution

Lifecycle assumptions differ between App Store, Developer ID, enterprise/internal, and development builds.

Verify:

- sandbox/entitlements;
- signing/notarization;
- update mechanism;
- helper/login-item packaging;
- file/network permissions;
- minimum macOS version.

## Current Design/System Behavior

macOS 27 continues evolving Liquid Glass/material/window behavior. Prefer native toolbars, sidebars, inspectors, controls, and window APIs so the app inherits platform updates instead of freezing one OS version's chrome in custom code.

## Common Failures

- app-wide task stored in a window view and cancelled when the window closes;
- relying on termination callback as the only save point;
- blocking work while opening a menu;
- permanent power assertion;
- duplicated service instance per window unintentionally;
- manual AppKit window plumbing when modern SwiftUI scenes solve it;
- assuming one-window lifecycle on a multi-window app.

## Verification

Test launch, multiple-window creation/closure, reopen with zero windows, sleep/wake where relevant, offline/reconnect, cancellation, crash/restart recovery, permissions, and packaged/notarized behavior—not only Xcode debug launch.
