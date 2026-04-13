# macOS App Lifecycle Reference

Architecture review guide for macOS app lifecycle management. Covers state transitions, networking, power management, security, and deployment compliance. Goal: ensure the app is a **Good Mac Citizen** — efficient, resilient, and seamless.

## Sentinel Principles

| Principle | Description |
|-----------|-------------|
| **Prove, Don't Promise** | All lifecycle assumptions must have logs or tests |
| **Efficiency First** | Inactive apps must not waste CPU/GPU/network |
| **Seamless Continuity** | Users should feel they never left after restart |
| **Respect the Battery** | No background bandwidth/power waste without consent |
| **Recover Gracefully** | Assume unstable networks; recover transparently on wake/reconnect |

---

## 1. Lifecycle State & Delegate Management

### Architecture Detection

Identify the app's architecture first:
- **Pure SwiftUI** — `@main struct MyApp: App { var body: some Scene { ... } }`
- **AppKit** — `NSApplicationDelegate` + storyboard/xib
- **Hybrid** — SwiftUI scenes with `@NSApplicationDelegateAdaptor`

### Launch Compliance

Never block the main thread in `applicationDidFinishLaunching`. Defer heavy work:

```swift
// ❌ Bad: blocking main thread
func applicationDidFinishLaunching(_ notification: Notification) {
    let data = loadLargeDatabase()  // blocks UI
    configureUI(with: data)
}

// ✅ Good: defer heavy work
func applicationDidFinishLaunching(_ notification: Notification) {
    configureMinimalUI()
    Task.detached(priority: .utility) {
        let data = await self.loadLargeDatabase()
        await MainActor.run { self.configureUI(with: data) }
    }
}
```

### State Transitions

| Notification | Action |
|-------------|--------|
| `didBecomeActiveNotification` | Resume timers, reconnect sockets, restore full rendering |
| `didResignActiveNotification` | Pause timers, reduce rendering, lower heartbeat frequency |
| `willTerminateNotification` | Flush pending writes, save `resumeData`, release IOKit assertions |

SwiftUI equivalent using `ScenePhase`:

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { _, newPhase in
    switch newPhase {
    case .active:
        networkManager.resume()
    case .inactive:
        networkManager.reduceFrequency()
    case .background:
        networkManager.suspendNonCritical()
    @unknown default: break
    }
}
```

> **Note:** On macOS, `ScenePhase` tracks the _scene_, not the app. Individual windows can have different phases. Use `NSApplication` notifications for app-wide events.

### Graceful Exit

```swift
func applicationWillTerminate(_ notification: Notification) {
    // 1. Persist unsaved state
    persistenceController.saveContext()
    // 2. Store network resume data
    activeDownloads.forEach { $0.cancel(byProducingResumeData: saveResumeData) }
    // 3. Release power assertions
    if let assertionID { IOPMAssertionRelease(assertionID) }
    // 4. Log shutdown
    Logger.lifecycle.info("App terminated cleanly")
}
```

---

## 2. SwiftUI Scene & Window Management

### Scene Configuration

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .defaultSize(width: 900, height: 600)

        #if os(macOS)
        Settings { SettingsView() }
        #endif
    }
}
```

### Window Restoration with @SceneStorage

```swift
struct ContentView: View {
    @SceneStorage("selectedTab") private var selectedTab = "general"
    @SceneStorage("scrollPosition") private var scrollPosition: Double = 0

    var body: some View {
        TabView(selection: $selectedTab) { /* ... */ }
    }
}
```

> Each window instance gets independent `@SceneStorage` values. This is the preferred mechanism for per-window state persistence.

### AppKit Bridge Points

Use AppKit interop for features SwiftUI doesn't cover:

| Feature | Approach |
|---------|----------|
| `NSStatusItem` (custom) | `@NSApplicationDelegateAdaptor` + manual setup |
| Custom menu bar items | `commands` modifier or `NSMenu` bridge |
| Global hotkeys | `NSEvent.addGlobalMonitorForEvents` |
| Window-level control | `NSWindow` via `NSViewRepresentable` coordinator |

### SwiftData / Persistence

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self])
    }
}
```

Ensure `modelContext.save()` is called in `willTerminate` for unsaved changes.

---

## 3. Networking & Connectivity

### A. Network Path Monitoring

Never retry blindly on failure. Wait for path recovery:

```swift
import Network

final class NetworkMonitor: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = false
    var isExpensive: Bool = false
    var onReconnect: (() -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wasDisconnected = self?.isConnected == false
            self?.isConnected = path.status == .satisfied
            self?.isExpensive = path.isExpensive

            if wasDisconnected && path.status == .satisfied {
                self?.onReconnect?()  // trigger pending retries
            }
        }
        monitor.start(queue: queue)
    }

    func stop() { monitor.cancel() }
}
```

### B. Expensive Network Handling

```swift
// Pause large transfers on metered connections
if networkMonitor.isExpensive {
    downloadTask.suspend()
    Logger.network.info("Paused download: expensive network detected")
}
```

Check `path.isConstrained` for Low Data Mode compliance—reduce prefetching and telemetry.

### C. Retry Strategy

```swift
// ❌ Bad: hardcoded retry interval
Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in retryRequest() }

// ✅ Good: event-driven retry on reconnection
networkMonitor.onReconnect = { [weak self] in
    self?.retryPendingRequests()
}
```

---

## 4. Power & Sleep Lifecycle

### App Nap Compatibility

When a window is fully occluded or minimized, macOS may throttle the app via **App Nap**. Network tasks must adapt:

| Scenario | Action |
|----------|--------|
| Window occluded | Reduce WebSocket heartbeat to minimum |
| Window visible again | Restore normal heartbeat frequency |
| App resigned active | Suspend non-critical polling |

```swift
NotificationCenter.default.addObserver(
    forName: NSApplication.didResignActiveNotification,
    object: nil, queue: .main
) { _ in
    webSocketManager.heartbeatInterval = 60  // slow heartbeat
}

NotificationCenter.default.addObserver(
    forName: NSApplication.didBecomeActiveNotification,
    object: nil, queue: .main
) { _ in
    webSocketManager.heartbeatInterval = 10  // normal heartbeat
}
```

### Background URLSession

For large downloads/uploads that must survive app termination or system restart:

```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.app.background-transfer")
config.isDiscretionary = true       // let system choose optimal time
config.sessionSendsLaunchEvents = true  // relaunch app on completion

let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
```

> The system daemon (`nsurlsessiond`) manages the transfer even if the app is terminated.

### Preventing System Sleep

For critical transfers (e.g., database sync), temporarily prevent sleep:

```swift
import IOKit.pwr_mgt

var assertionID: IOPMAssertionID = 0

func preventSleep(reason: String) {
    IOPMAssertionCreateWithName(
        kIOPMAssertionTypeNoIdleSleep as CFString,
        IOPMAssertionLevel(kIOPMAssertionLevelOn),
        reason as CFString,
        &assertionID
    )
}

func allowSleep() {
    IOPMAssertionRelease(assertionID)
    assertionID = 0
}
```

> **Always** release the assertion when the critical task completes. Leaking assertions drains battery.

---

## 5. Security & Sandbox Compliance

### App Sandbox Entitlements

Minimize entitlements to the smallest required set:

| Entitlement | Purpose |
|-------------|---------|
| `com.apple.security.network.client` | Outbound network requests |
| `com.apple.security.network.server` | Local server / listener |
| `com.apple.security.app-sandbox` | Sandbox enabled (required for Mac App Store) |

> Only request `network.server` if the app exposes a local service (e.g., localhost API).

### App Transport Security (ATS)

```xml
<!-- ❌ Never do this without justification -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- ✅ Exception for specific domain only -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>legacy-api.example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Hardened Runtime & Notarization

- All embedded third-party libraries must be properly signed
- No dynamic code injection (`com.apple.security.cs.disable-library-validation` = avoid unless necessary)
- Use `notarytool` for automated notarization:

```bash
xcrun notarytool submit MyApp.zip \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait
```

---

## 6. Data Sync & Persistence

### Resume Data on Termination

```swift
func applicationWillTerminate(_ notification: Notification) {
    for task in activeDownloadTasks {
        task.cancel { resumeData in
            if let data = resumeData {
                UserDefaults.standard.set(data, forKey: "resumeData-\(task.taskIdentifier)")
            }
        }
    }
}

// On next launch
func resumePendingDownloads() {
    for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("resumeData-") {
        if let data = UserDefaults.standard.data(forKey: key) {
            let task = session.downloadTask(withResumeData: data)
            task.resume()
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
```

### Dirty Data Marking

When a network request fails and the app is closing, mark local data as pending sync:

```swift
struct SyncRecord: Codable {
    let id: UUID
    let payload: Data
    let status: SyncStatus  // .pending | .synced | .failed
    let lastAttempt: Date
}
```

> Never silently discard unsynced data. Persist it and retry on next launch or reconnect.

---

## 7. Build & Observability

### OSLog for Lifecycle Events

```swift
import OSLog

extension Logger {
    static let lifecycle = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Lifecycle")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Network")
}

// Usage
Logger.lifecycle.info("App launched in \(launchDuration, format: .fixed(precision: 2))s")
Logger.network.warning("Request failed: \(error.localizedDescription)")
```

### xcodebuild CLI Integration

```bash
# Build, sign, and archive
xcodebuild archive \
    -scheme MyApp \
    -archivePath build/MyApp.xcarchive \
    CODE_SIGN_IDENTITY="Developer ID Application: Team Name"

# Export for distribution
xcodebuild -exportArchive \
    -archivePath build/MyApp.xcarchive \
    -exportPath build/release \
    -exportOptionsPlist ExportOptions.plist
```

### Test Strategy

Lifecycle-critical tests to cover:

| Test | What to Verify |
|------|---------------|
| Window restoration | `@SceneStorage` values survive relaunch |
| Network resilience | Retries trigger on `NWPathMonitor` reconnect |
| Graceful shutdown | `willTerminate` flushes all pending writes |
| App Nap behavior | Heartbeat reduces when resigned active |
| Background transfer | `URLSession.background` resumes after termination |

---

## 8. Review Workflow

When reviewing macOS lifecycle code:

1. **Identify architecture** — Pure SwiftUI / AppKit / Hybrid
2. **Audit state transitions** — Check all notification handlers for active/inactive/terminate
3. **Discover risks** — Memory leaks, state loss, HIG violations, battery drain
4. **Provide fixes** — Concrete Swift code examples
5. **Check distribution** — Entitlements, signing, `notarytool` automation

### Review Output Template

| Dimension | Result | Recommendation |
|-----------|--------|----------------|
| **State Transitions** | ⚠️/✅/❌ | Specific fix |
| **Window Management** | ⚠️/✅/❌ | Specific fix |
| **Network Awareness** | ⚠️/✅/❌ | Specific fix |
| **Power Management** | ⚠️/✅/❌ | Specific fix |
| **Security Compliance** | ⚠️/✅/❌ | Specific fix |
| **Build & Observability** | ⚠️/✅/❌ | Specific fix |
| **Background Transfer** | ⚠️/✅/❌ | Specific fix |
| **Mac Citizen Score** | ⚠️/✅/❌ | Specific fix |

---

## Best Practices Summary

- Defer heavy launch work off the main thread
- Monitor `ScenePhase` per-window; use `NSApplication` notifications for app-wide events
- Use `NWPathMonitor` for event-driven retries — never hardcode retry intervals
- Reduce heartbeat/polling when app resigns active or enters App Nap
- Use `URLSessionConfiguration.background` for transfers that must survive termination
- Release `IOPMAssertion` immediately after critical tasks complete
- Minimize sandbox entitlements; avoid blanket `NSAllowsArbitraryLoads`
- Persist `resumeData` and mark unsynced records on termination
- Log all lifecycle transitions with `OSLog`
- Cover lifecycle behavior (window restore, network resilience, graceful shutdown) in tests
