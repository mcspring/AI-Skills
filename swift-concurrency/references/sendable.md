# Sendable

Use this when:

- A value or reference type must cross an isolation boundary safely.
- You are resolving "non-Sendable type" compiler diagnostics.
- You need to decide between value types, `@unchecked Sendable`, actors, or region-based isolation.

Skip this file if:

- The issue is about which actor should own the state. Use `actors.md`.
- The issue is about how async functions execute. Use `threading.md`.

## What is Sendable?

`Sendable` indicates a type is safe to share across isolation domains (actors, tasks, threads). The compiler verifies thread-safety at compile time.

```swift
public protocol Sendable {}
```

Empty protocol, but triggers compiler verification of thread-safety.

## Isolation Domains

Three types of isolation in Swift Concurrency:

### 1. Nonisolated (default)

No concurrency restrictions, but can't modify isolated state:

```swift
func computeValue(a: Int, b: Int) -> Int {
    return a + b
}
```

### 2. Actor-isolated

Dedicated isolation domain with serialized access:

```swift
actor Library {
    var books: [String] = []
    
    func addBook(_ title: String) {
        books.append(title)
    }
}

// External access requires await
await library.addBook("Swift Concurrency")
```

### 3. Global actor-isolated

Shared isolation domain across types:

```swift
@MainActor
func updateUI() {
    // Runs on main thread
}
```

## Data Races vs Race Conditions

### Data Race

Multiple threads access shared mutable state, at least one writes, without synchronization:

```swift
// ⚠️ Data race
var counter = 0
DispatchQueue.global().async { counter += 1 }
DispatchQueue.global().async { counter += 1 }
```

**Detection**: Enable Thread Sanitizer in scheme settings.

**Prevention**: Use actors or Sendable types:

```swift
actor Counter {
    private var value = 0
    
    func increment() {
        value += 1
    }
}
```

### Race Condition

Timing-dependent behavior leading to unpredictable results:

```swift
let counter = Counter()

for _ in 1...10 {
    Task { await counter.increment() }
}

// May print inconsistent values
print(await counter.getValue())
```

**Key difference**: Swift Concurrency prevents data races but not race conditions. You must still ensure proper sequencing.

## Value Types (Structs, Enums)

### Implicit conformance

Non-public structs and enums with Sendable members are implicitly `Sendable`. If a type is `public` or `@usableFromInline`, it must explicitly declare conformance to `Sendable` because the compiler cannot guarantee internal details across modules, and explicit conformance ensures the API contract is maintained.

```swift
// Implicitly Sendable (internal structure, all members are Sendable)
struct Person {
    var name: String
}
```

### Explicit conformance required

Public types must explicitly declare conformance:

```swift
public struct Person: Sendable {
    public var name: String
}
```

### Opting Out: Unavailable Conformance

To explicitly prevent a type from being sent across isolation domains (opting out of implicit conformance or preventing accidental transfers), you can declare an unavailable `Sendable` conformance.

```swift
struct FileDescriptor {
    let rawValue: Int
}

@available(*, unavailable)
extension FileDescriptor: Sendable {}
```

### Frozen types

Public frozen types can be implicitly Sendable:

```swift
@frozen
public struct Point: Sendable {
    public var x: Double
    public var y: Double
}
```

### All members must be Sendable

```swift
public struct Person: Sendable {
    var name: String
    var hometown: Location // Must also be Sendable
}

public struct Location: Sendable {
    var name: String
}
```

### Copy-on-write makes mutability safe

```swift
public struct Person: Sendable {
    var name: String // Mutable but safe due to COW
}
```

Each mutation creates a copy, preventing concurrent access to same instance.

## Reference Types (Classes)

### Requirements for Sendable classes

Must be:
1. `final` (no inheritance)
2. Immutable stored properties only
3. All properties Sendable
4. No superclass or `NSObject` only

```swift
final class User: Sendable {
    let name: String
    let id: Int
    
    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}
```

### Why non-final classes can't be Sendable

Child classes could introduce unsafe mutability:

```swift
// Can't be Sendable
class Purchaser {
    func purchase() { }
}

// Could introduce data races
class GamePurchaser: Purchaser {
    var credits: Int = 0 // Mutable!
}
```

### Actor isolation makes classes Sendable

```swift
@MainActor
class ViewModel {
    var data: [Item] = [] // Safe due to actor isolation
}
// Implicitly Sendable
```

### Composition over inheritance

```swift
final class Purchaser: Sendable {
    func purchase() { }
}

final class GamePurchaser {
    let purchaser: Purchaser = Purchaser()
    // Handle credits separately
}
```

## Functions and Closures (@Sendable)

Mark functions/closures that cross isolation domains:

```swift
actor ContactsStore {
    func removeAll(_ shouldRemove: @Sendable (Contact) -> Bool) async {
        contacts.removeAll { shouldRemove($0) }
    }
}
```

### Captured values must be Sendable

```swift
let query = "search"

// ✅ Immutable capture
store.filter { contact in
    contact.name.contains(query)
}

var query = "search"

// ❌ Mutable capture
store.filter { contact in
    contact.name.contains(query) // Error
}
```

### Capture lists for mutable values

```swift
var query = "search"

// ✅ Capture immutable snapshot
store.filter { [query] contact in
    contact.name.contains(query)
}
```

## @unchecked Sendable

**Use as last resort.** Tells compiler to skip verification—you guarantee thread-safety.

### When to use

Manual locking mechanisms the compiler can't verify:

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return items[key]
    }
    
    func set(_ key: String, value: Data) {
        lock.lock()
        defer { lock.unlock() }
        items[key] = value
    }
}
```

### Risks

- No compile-time safety
- Easy to introduce data races
- Must manually ensure all access uses lock

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]
    
    // ⚠️ Forgot lock - data race!
    var count: Int {
        items.count
    }
}
```

**Better**: Use actor instead:

```swift
actor Cache {
    private var items: [String: Data] = [:]
    
    var count: Int { items.count }
    
    func get(_ key: String) -> Data? {
        items[key]
    }
    
    func set(_ key: String, value: Data) {
        items[key] = value
    }
}
```

## Region-Based Isolation (SE-0414)

In Swift 6, the compiler uses **Region-Based Isolation** to track mutable state. The compiler analyzes the control-flow of your program to determine if a non-`Sendable` value belongs to a disconnected isolation region.
If a non-`Sendable` value is transferred to another isolation domain (e.g., captured by a background `Task` or sent to an actor), but the compiler can prove that the value is **never accessed again** in the source domain after the transfer, it is allowed without errors.

```swift
class Article {
    var title: String
    init(title: String) { self.title = title }
}

func check() {
    let article = Article(title: "Swift Concurrency")
    
    // Transferred to the background Task's isolation region
    Task {
        print(article.title) // ✅ OK - region transferred
    }
    
    // No accesses to `article` here in the caller
}
```

### Accessing After Transfer Causes Compiler Error

If you attempt to access the variable after it has been transferred, the compiler detects that the region is not disconnected and raises an isolation error:

```swift
func check() {
    let article = Article(title: "Swift Concurrency")
    
    Task {
        print(article.title) // Transferred here
    }
    
    // ❌ Compiler Error: sending 'article' risks causing data races
    // 'article' is a non-Sendable type and is accessed after transfer
    print(article.title) 
}
```

---

## The sending Modifier (SE-0430)

For explicit function boundaries (methods and parameters), you can use the `sending` modifier to require that a non-`Sendable` parameter or return value is in a disconnected isolation region. This enables safe transfers across isolation domains.

### 1. Function Parameters

Using `sending` on a parameter requires the caller to pass a value from a disconnected region, transferring ownership to the callee.

```swift
actor Logger {
    func log(article: Article) {
        print(article.title)
    }
}

// callee accepts a 'sending' non-Sendable parameter
func printTitle(article: sending Article) async {
    let logger = Logger()
    await logger.log(article: article) // Transfers into actor
}

// Caller Usage
func process() async {
    let article = Article(title: "Swift")
    await printTitle(article: article) // ✅ OK - transferred
    
    // ❌ Error: 'article' is accessed here after being sent
    print(article.title)
}
```

### 2. Return Values

Using `sending` on a return type guarantees the callee returns a value in a disconnected region, transferring ownership to the caller's isolation domain.

```swift
@MainActor
func createArticle(title: String) -> sending Article {
    // Returns a freshly created, disconnected Article
    return Article(title: title)
}

func processArticle() async {
    // Calling MainActor function, but result is 'sending'
    let article = await createArticle(title: "Swift 6") 
    
    // Since it was 'sending', we own it in our region
    Task {
        print(article.title) // ✅ OK to send to background
    }
}
```

## Global Variables

Must be concurrency-safe since accessible from any context.

### Problem

```swift
class ImageCache {
    static var shared = ImageCache() // ⚠️ Not concurrency-safe
}
```

### Solution 1: Actor isolation

```swift
@MainActor
class ImageCache {
    static var shared = ImageCache()
}
```

### Solution 2: Immutable + Sendable

```swift
final class ImageCache: Sendable {
    static let shared = ImageCache()
}
```

### Solution 3: nonisolated(unsafe)

**Last resort** - you guarantee safety:

```swift
struct APIProvider: Sendable {
    nonisolated(unsafe) static private(set) var shared: APIProvider!
    
    static func configure(apiURL: URL) {
        shared = APIProvider(apiURL: apiURL)
    }
}
```

Use `private(set)` to limit mutation points.

## Custom Locks + Sendable

### Legacy code with locks

```swift
final class BankAccount: @unchecked Sendable {
    private var balance: Int = 0
    private let lock = NSLock()
    
    func deposit(amount: Int) {
        lock.lock()
        balance += amount
        lock.unlock()
    }
    
    func getBalance() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return balance
    }
}
```

### Migration strategy

**New code**: Use actors

**Existing code**: 
1. If isolated and small scope → migrate to actor
2. If widely used → use `@unchecked Sendable`, file migration ticket

```swift
// Better: Migrate to actor
actor BankAccount {
    private var balance: Int = 0
    
    func deposit(amount: Int) {
        balance += amount
    }
    
    func getBalance() -> Int {
        balance
    }
}
```

## Decision Tree

```
Need to share type across isolation domains?
├─ Value type (struct/enum)?
│  ├─ Public? → Add explicit Sendable
│  └─ Internal? → Implicit Sendable (if members Sendable)
│
├─ Reference type (class)?
│  ├─ Can be final + immutable? → Sendable
│  ├─ Needs mutation?
│  │  ├─ Can use actor? → Use actor (automatic Sendable)
│  │  ├─ Main thread only? → @MainActor
│  │  └─ Has custom lock? → @unchecked Sendable (temporary)
│  └─ Can be struct instead? → Refactor to struct
│
└─ Function/closure? → @Sendable attribute
```

## Common Patterns

### Restructure to avoid non-Sendable dependencies

```swift
// Instead of storing non-Sendable type
public struct Person: Sendable {
    var hometown: String // Just the name
    
    init(hometown: Location) {
        self.hometown = hometown.name
    }
}
```

- **Prefer actors for mutable state** — see [actors.md § Mutex vs Actor](actors.md#mutex-alternative-to-actors) for the comparison.
- **Use @MainActor for UI-bound types** — see [actors.md § @MainActor Best Practices](actors.md#mainactor-best-practices).

## Best Practices

1. **Prefer value types** - structs/enums are easier to make Sendable
2. **Use actors for mutable state** - automatic thread-safety
3. **Avoid @unchecked Sendable** - use only for proven thread-safe code
4. **Mark public types explicitly** - don't rely on implicit conformance
5. **Ensure all members Sendable** - one non-Sendable breaks the chain
6. **Use @MainActor for UI types** - simple isolation for view models
7. **Capture immutably** - use capture lists for mutable variables
8. **Test with Thread Sanitizer** - catches runtime data races
9. **File migration tickets** - track @unchecked Sendable usage
