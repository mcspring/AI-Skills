# macOS SwiftUI Reference

Scenes, window styling, views, file operations, drag & drop, and AppKit interop for macOS SwiftUI apps.

## Scene Types

| API | Availability | Usage |
|-----|-------------|-------|
| `WindowGroup` | macOS 11+ | Multiple window instances, tabbed interface |
| `Window` | macOS 13+ | Single unique window; app quits if sole scene |
| `Settings` | macOS 11+ | Preferences window (Cmd+,) |
| `MenuBarExtra` | macOS 13+ | Persistent menu bar icon/menu |
| `UtilityWindow` | macOS 15+ | Floating tool palette, receives FocusedValues |
| `DocumentGroup` | macOS 11+ | Document-based file management |

### Settings

```swift
Settings {
    TabView {
        Tab("General", systemImage: "gear") { GeneralSettingsView() }
        Tab("Advanced", systemImage: "star") { AdvancedSettingsView() }
    }
    .scenePadding()
    .frame(maxWidth: 350, minHeight: 100)
}
```

Open programmatically: `@Environment(\.openSettings) private var openSettings` (macOS 14+) or `SettingsLink`.

### MenuBarExtra

```swift
// Dropdown menu (default)
MenuBarExtra("My Utility", systemImage: "hammer") {
    Button("Action One") { /* ... */ }
    Divider()
    Button("Quit") { NSApplication.shared.terminate(nil) }
}

// Popover panel
MenuBarExtra("Status", systemImage: "chart.bar") {
    DashboardView().frame(width: 240)
}
.menuBarExtraStyle(.window)
```

- **Toggleable**: pass `isInserted:` with `@AppStorage` binding
- **Menu-bar-only app**: sole scene + `LSUIElement = true` in Info.plist

### WindowGroup vs Window

- `WindowGroup` keeps the app running after all windows close; supports multiple instances
- `Window` (as sole scene) quits the app when closed; single instance only
- Use `@Environment(\.openWindow)` to open windows programmatically

### UtilityWindow (macOS 15+)

Floating inspector/palette: receives `FocusedValues` from focused main window, floats above main windows, hides when app inactive, auto-adds View menu toggle.

### DocumentGroup

Requires `FileDocument` or `ReferenceFileDocument` conformance. Provides File > New/Open/Save menu commands.

---

## Window Styling

### Toolbar Styles (macOS-only)

| Style | Description |
|-------|-------------|
| `.unified` | Title + toolbar in one row |
| `.unifiedCompact` | Reduced height |
| `.expanded` | Title above toolbar |

```swift
.windowToolbarStyle(.unified(showsTitle: false))
```

### Window Sizing & Position

```swift
WindowGroup {
    ContentView()
        .frame(minWidth: 600, minHeight: 400)
}
.defaultSize(width: 900, height: 600)
.defaultPosition(.center)
.windowResizability(.contentMinSize)
```

| `windowResizability` | Behavior |
|---------------------|----------|
| `.automatic` | System decides |
| `.contentSize` | Fixed, no user resize |
| `.contentMinSize` | Resizable with min bounds |

### Window Style

`.windowStyle(.hiddenTitleBar)` — chromeless window for media players or custom-chrome apps.

---

## Navigation & Layout

### NavigationSplitView

On macOS: columns always side-by-side, translucent sidebar, variable-width resizing.

```swift
NavigationSplitView {
    List(items, selection: $selectedId) { item in Text(item.name) }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
} detail: {
    DetailView(id: selectedId)
}
```

### Inspector (macOS 14+)

Trailing-edge panel, resizable by dragging.

```swift
MainContent()
    .inspector(isPresented: $showInspector) {
        InspectorView()
            .inspectorColumnWidth(min: 200, ideal: 250, max: 400)
    }
```

### HSplitView & VSplitView (macOS-only)

IDE-style equal-peer panes with user-draggable dividers. Use `NavigationSplitView` for sidebar-driven navigation instead.

```swift
HSplitView {
    FileTreeView().frame(minWidth: 200)
    CodeEditorView().frame(minWidth: 400)
    PreviewPane().frame(minWidth: 200)
}
```

---

## Table (macOS-specific Styling)

```swift
Table(people) { /* columns */ }
    .tableStyle(.bordered(alternatesRowBackgrounds: true))
    .tableColumnHeaders(.hidden)  // optional
```

See `list-patterns.md` for Table creation, selection, sorting basics.

---

## Commands & Keyboard

```swift
.commands {
    CommandMenu("Tools") {
        Button("Run Analysis") { /* ... */ }
            .keyboardShortcut("r", modifiers: [.command, .shift])
    }
    CommandGroup(after: .newItem) {
        Button("New From Template...") { /* ... */ }
    }
}
```

Placements: `.newItem`, `.saveItem`, `.help`, `.toolbar`, `.sidebar`. Use `.replacing(_:)`, `.before(_:)`, `.after(_:)`.

---

## File Operations

### fileImporter / fileExporter

```swift
.fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
    if case .success(let urls) = result, let url = urls.first {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        // use url
    }
}
```

> **Always** call `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` on returned URLs.

### macOS file dialog customization (macOS 13+)

`.fileDialogMessage(_:)`, `.fileDialogConfirmationLabel(_:)`, `.fileExporterFilenameLabel(_:)`

---

## Drag, Drop & Pasteboard

Cross-app drag and drop on macOS. Prefer `Transferable` (modern) over `NSItemProvider` (legacy).

```swift
// Drag source
Text(item.title).draggable(item)

// Drop target
VStack { /* content */ }
    .dropDestination(for: MyItem.self) { items, location in
        droppedItems.append(contentsOf: items)
        return true
    }
```

### PasteButton & CopyButton

- `PasteButton(payloadType:)` — reads clipboard via Transferable (does NOT auto-validate on macOS)
- `CopyButton(item:)` — copies Transferable content (macOS 15+)

---

## AppKit Interop

| API | Direction | Usage |
|-----|-----------|-------|
| `NSViewRepresentable` | AppKit → SwiftUI | Wrap NSView |
| `NSViewControllerRepresentable` | AppKit → SwiftUI | Wrap NSViewController |
| `NSHostingController` | SwiftUI → AppKit | Host SwiftUI as VC |
| `NSHostingView` | SwiftUI → AppKit | Host SwiftUI as NSView |

```swift
struct SearchField: NSViewRepresentable {
    @Binding var text: String
    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.delegate = context.coordinator
        return field
    }
    func updateNSView(_ nsView: NSSearchField, context: Context) { nsView.stringValue = text }
    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }
    // Coordinator implements NSSearchFieldDelegate...
}
```

> **Never** set `frame`/`bounds` directly on views managed by `NSViewRepresentable` — SwiftUI owns the layout.

---

## Platform Conditionals

Always wrap macOS-only scenes and APIs in `#if os(macOS)`:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        #if os(macOS)
        Settings { SettingsView() }
        MenuBarExtra("Status", systemImage: "bolt") { StatusMenu() }
        #endif
    }
}
```

---

## Best Practices

- Use `Settings` for preferences — not custom windows
- Use `MenuBarExtra` — not manual `NSStatusItem`
- Use `WindowGroup` as primary scene; `Window` for supplementary singletons
- Use `NavigationSplitView` for sidebar navigation; `HSplitView` for IDE-style equal panes
- Use `Inspector` for trailing panels — integrates with toolbar
- Define `Commands` for all repeatable actions — users expect keyboard shortcuts
- Use `Transferable` for drag & drop — fall back to `NSItemProvider` only for legacy
- Always `startAccessingSecurityScopedResource()` on file importer URLs
- Prefer native SwiftUI over AppKit interop when possible
