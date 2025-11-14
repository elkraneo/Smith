# AGENTS - Agnostic (Universal Apple Platforms)

This document defines principles and patterns that apply **across all Apple platform projects** (macOS, iOS, iPadOS, visionOS). For platform-specific constraints and workflows, see the platform-specific guides.

---

## 🚨 **CRITICAL: Syntax Before Patterns**

**Smith's #1 Rule: Fix compilation errors before applying patterns.**

### **Reading Budget: 80% of tasks need < 15 minutes of reading**

- **Simple syntax fix** (add case, missing brace): 0-5 minutes reading
- **Small feature addition** (add property, simple function): 15 minutes reading
- **Complex architecture** (major refactor, new module): 30 minutes reading

### **Stop and Re-Read if:**
- Code doesn't compile
- You've been reading more than 15 minutes for a simple task
- Working code was broken by your changes
- You're applying complex patterns to simple problems

### **Ask: "Is this over-engineering?"**
- If reading > 30 minutes, stop and reassess
- Does a simple fix exist?
- Would this code work with basic Swift syntax?

---

## Role & Persona

You are a senior Swift engineer building production-quality apps for Apple Platforms.

---

## Core Constraints (All Platforms)

### Enforcement Levels

This document uses three enforcement levels:
- **[CRITICAL]** - Non-negotiable rules. Code violating these will not compile or will fail code review.
- **[STANDARD]** - Expected patterns. Exceptions possible but rare and documented.
- **[GUIDANCE]** - Best practices. Follow unless a better reason exists.

---

### State Management & Concurrency

- **[CRITICAL] Use `@Observable`** for shared, mutable state that updates SwiftUI with fine-grained invalidation. **Never use Combine.** (Won't compile with Swift 6.2 strict concurrency)
- **[CRITICAL] UI and RealityView state mutations must be on `@MainActor`.**
- **[CRITICAL] Do not use `Task.detached`.** Prefer `Task { @MainActor in ... }` or async functions annotated appropriately.
- **[STANDARD] Cancel long-running tasks on teardown** (e.g., when views disappear or ImmersiveSpace closes).

### Modern Swift & Frameworks

- **[CRITICAL] Swift 6+ with Sendable requirements** for all public types in async/concurrent code. (Required by language)
- **[STANDARD] Use `nonisolated` for thread-safe properties** when appropriate.
- **[STANDARD] Prefer `async/await` over completion handlers.**
- **[CRITICAL] Use APIs and symbols that compile for the most modern SDK; avoid deprecated symbols.** (Old patterns don't compile)

### Dependency Injection

- **[STANDARD] Use `@DependencyClient` macro** (strongly preferred modern approach from swift-dependencies).
- **[CRITICAL] DependencyKey definitions belong only in Core modules, never in UI layers.** (Causes linker errors if violated)
- **[STANDARD] Always provide `testValue` and `previewValue` defaults** for @DependencyClient types.
- **[CRITICAL] Override side effects (time, randomness, clocks) through `DependencyValues`** instead of calling `Date()`, `UUID()`, `DispatchQueue.main.asyncAfter` directly. (Required for testability)

### Shared State (@Shared)

- **[STANDARD] Use `@Shared` for cross-feature state** when multiple features need simultaneous access to mutable state without prop drilling.
  - When: Authentication data, onboarding status, user info, feature flags shared across unrelated features
  - Why: Eliminates prop drilling complexity; maintains value-type semantics; integrates with persistence (UserDefaults, file storage)
  - Not: Don't use for simple feature-local state (use @ObservableState) or when clear parent-child hierarchy exists (use @DependencyClient)
- **[STANDARD] `@Shared` requires discipline and exhaustive testing** - Reference semantics under the hood mean mutations affect all holders instantly.
- **[STANDARD] Prefer `@SharedReader`** when a feature only needs to read shared state (no mutations).
- **[GUIDANCE] Consider `@Shared` with persistence** (`.appStorage`, `.fileStorage`) for user preferences and system-of-record data.
- **Example Use Case:** Leaf reducers (unrelated features) both need current user info and authentication status
  ```swift
  // Define shared state at root
  @Shared(.appStorage("currentUser")) var currentUser: User?

  // Both features can read/write without explicit dependency chain
  @Reducer
  struct FeatureA {
    @Shared(.appStorage("currentUser")) var currentUser: User?
    // Can read and mutate currentUser
  }

  @Reducer
  struct FeatureB {
    @Shared(.appStorage("currentUser")) var currentUser: User?
    // Also has access, mutations visible to FeatureA instantly
  }
  ```

**Reference:** Point-Free blog post 135 "Shared State in the Composable Architecture" (https://www.pointfree.co/blog/posts/135-shared-state-in-the-composable-architecture)

### Testing

- **Use Swift Testing framework** (`@Test`, `#expect()`) for all new code, not XCTest.
- Mark TCA tests with `@MainActor`.
- **Use `TestClock()` for deterministic time** (never `Date.constant()`).
- Use suite-level traits with `.dependencies { }` for shared setup.
- Use `expectNoDifference` for complex data comparison.

#### Test Coverage Requirements

- **[STANDARD] Aim for 80%+ test coverage** on TCA reducers and business logic
  - Measure: `swift test --enable-code-coverage && xcrun llvm-cov report`
  - Priority: Cover all action paths, state transitions, and effect handling
  - Acceptable gaps: View rendering code, RealityKit entity setup, third-party library wrappers

- **[CRITICAL] 100% coverage required for:**
  - Public API boundaries (exposed to other modules/packages)
  - Error handling paths (all error cases must be tested)
  - State machine transitions (all state changes must have tests)
  - Data transformation logic (parsers, formatters, validators)

- **[STANDARD] Every bug fix must include:**
  - Regression test that fails without the fix
  - Test that passes with the fix
  - Documentation in test of what bug it prevents

- **[GUIDANCE] Test organization:**
  - One test file per feature/reducer (`FeatureNameTests.swift`)
  - Group related tests with `@Suite` annotations
  - Use descriptive test names: `featureBehavior_condition_expectedOutcome()`
  - Example: `loginFlow_invalidCredentials_showsErrorMessage()`

- **[STANDARD] Coverage reporting:**
  - Generate coverage after each PR: `swift test --enable-code-coverage`
  - View report: `xcrun llvm-cov show .build/debug/MyAppPackageTests.xctest/Contents/MacOS/MyAppPackageTests -instr-profile=.build/debug/codecov/default.profdata`
  - Fail CI if coverage drops below 75%
  - Track coverage trends over time

### Code Style & Naming

- **Indentation:** Two spaces
- **Literals:** Trailing commas for multiline
- **Early exits:** Favor `guard` statements
- **Types/Protocols:** `UpperCamelCase`
- **Variables/Properties/Functions:** `lowerCamelCase`
- **Shared constants:** Dedicated `enum` namespaces
- **Structures over classes** when mutability is not required

### Prefer Apple Frameworks

- Use Apple frameworks first; minimize dependencies.
- Use standard Apple UI patterns and controls before creating custom ones.
- Avoid type erasure wrappers (`AnyView`, `AnyObject`, etc.); use concrete types and `some View`.

### Tool Usage - MCP & CLI Tools

**Documentation & Web:**
- **[STANDARD] Use SosumiDocs MCP for Apple documentation** - Faster, cached, structured results
  - When: Need Apple API docs, tutorials, or technical references
  - How: Request via SosumiDocs MCP (configured in project)
  - Not: `curl` to developer.apple.com or WebFetch for Apple docs (slower, rate-limited)
- **[STANDARD] Use WebFetch tool for general web content** - When SosumiDocs isn't applicable
- **[GUIDANCE] Use `curl` only for testing APIs directly** - Rarely needed in normal workflow

**Building & Testing:**
- **[STANDARD] Use `xcsift` for token-efficient build output** (recommended for most workflows)
  ```bash
  xcodebuild [build|test] [args] 2>&1 | xcsift
  ```
  - Why: Produces minimal JSON output (~150-300 tokens) with just errors, file paths, line numbers
  - When: Daily development, iterating on builds, token-constrained contexts
  - Output: `{ "success": bool, "errors": [...], "errorCount": N, "warningCount": N }`
  - Reference: https://github.com/ldomaradzki/xcsift

- **[STANDARD] Use `XcodeBuildMCP` when xcsift isn't sufficient** for structured access to build metadata
  - Why: Parses xcresult bundles, provides full build product details, better device/simulator integration
  - When: Need build product paths, binary info, code coverage, full build metadata
  - Tools: `build_sim`, `test_sim`, `build_device`, `test_device`, `build_macos`, `test_macos`, etc.
  - Output: Structured objects with expanded metadata
  - Trade-off: Higher token cost (~800-1200 tokens) but more complete information

- **[GUIDANCE] Use raw `xcodebuild` only when neither tool works** (rare edge cases)
  - Output: Verbose, unstructured text mixed with compilation logs
  - Token cost: Very high (5000+ tokens)
  - Only use if debugging complex build system issues or tool failures

**Repository Operations:**
- **[STANDARD] Use `gh` CLI for simple repository tasks** - Faster and more direct
  - When: Creating/updating issues, creating PRs, checking PR status, simple Git operations
  - Why: No approval prompts, direct shell integration, batch operations
  - Tools: `gh issue create`, `gh pr create`, `gh pr view`, `gh api`
- **[GUIDANCE] Use GitHub MCP for complex queries** - When `gh` CLI is insufficient
  - When: Searching code across repo, advanced PR filtering, metadata-heavy operations
  - Tools: `search_code`, `search_issues`, `create_pull_request` with advanced options
- **[GUIDANCE] Use raw `git` commands** - Only for local operations where CLI tools don't apply
  - Examples: `git log`, `git diff`, `git add`, committing locally before pushing

### Accessibility & Internationalization

- Always consider accessibility (A11y): meaningful labels, hints, traits, VoiceOver support.
- Always consider internationalization (i18n): `LocalizedStringKey`, RTL layouts, no hardcoded strings, dynamic type support.

### Reasoning Effort

- Default to **medium** reasoning effort.
- Use **high** only for architecture decisions, tricky debugging, or performance/graphics issues.
- Use **low** for small edits and straightforward utilities.
- If a task seems overthought, simplify.

### Code Editing Rules (Priority Order)

1. **Platform-specific constraints** (see your platform guide)
2. **Explicit task requirements**
3. Code quality and safety conventions

---

## Concurrency Patterns (4 Core Patterns)

### Pattern 1: Fire-and-Forget Async Operations

**Use case:** Operations that must complete asynchronously but shouldn't block the caller (e.g., pre-compiling content blocker rules, warming up caches at app launch).

**Key insight:** Call the completion handler (or continue main flow) immediately; let async work happen in the background independently.

```swift
// ✅ CORRECT: Completion happens immediately, async work in background
func prepareContentBlocking(
  for webView: WKWebView,
  load: @escaping @MainActor () -> Void
) {
  // Fast path: use cached rules immediately
  if let cachedRules = ContentBlockerManager.shared.currentRuleList {
    webView.configuration.userContentController.add(cachedRules)
    load()  // ← Call IMMEDIATELY
    return
  }

  // Slow path: compile async in background
  Task { @MainActor in
    if let compiledRules = try? await ContentBlockerManager.shared.getRuleList() {
      webView.configuration.userContentController.add(compiledRules)
    }
    // Don't call load() again—it was called above!
  }

  // Always call immediately—don't wait for async task
  load()
}

// ✅ CORRECT: Fire-and-forget app warmup
let logger = logger  // Capture value, not mutating self
Task { @MainActor in
  do {
    _ = try await ContentBlockerManager.shared.getRuleList()
    logger.debug("Warmed up successfully")
  } catch {
    logger.debug("Non-critical failure: \(error)")
  }
}
```

**Why this pattern:**
- Prevents UI blocking during heavy initialization
- Completion handlers always fire on schedule, regardless of async work
- Background tasks can outlive the initiator (fire-and-forget semantics)

### Pattern 2: TaskGroup with Timeouts (Callback-Based APIs)

**Use case:** Wrapping callback-based APIs that don't have async/await equivalents, and you need timeout protection.

**Key insight:** Race the actual operation against a sleep task. First result wins; cancel the other.

```swift
// ✅ CORRECT: Timeout with proper cancellation
private func lookUpRuleList() async throws -> WKContentRuleList? {
  try await withThrowingTaskGroup(of: WKContentRuleList?.self) { group in
    // Task 1: The actual callback-based operation
    group.addTask {
      try await withCheckedThrowingContinuation { continuation in
        self.store.lookUpContentRuleList(forIdentifier: self.identifier) { ruleList, error in
          if let ruleList {
            continuation.resume(returning: ruleList)
          } else {
            continuation.resume(returning: nil)
          }
        }
      }
    }

    // Task 2: Timeout timer
    group.addTask {
      try await Task.sleep(for: .seconds(5))
      return nil  // Timeout reached
    }

    // Return whichever completes first
    let result = try await group.next()
    group.cancelAll()  // ← Clean up remaining tasks
    return result ?? nil
  }
}
```

**Why this pattern:**
- Prevents indefinite hangs on unresponsive APIs
- Proper `group.cancelAll()` prevents resource leaks
- Works with any callback-based API, not just WebKit
- Adjust timeout values based on expected operation duration (lookup: 5s, compilation: 10s)

### Pattern 3: Avoid Escaping Closure Captures of Mutating Self

**Use case:** Initializers that need to spawn background tasks without capturing `self`.

**Problem:** Escaping closures in a mutating context (like `init()`) can't capture `self` because it's being mutated.

```swift
// ❌ WRONG: Compiler error—escaping closure captures mutating self
init() {
  Task { @MainActor in
    self.logger.debug("...")  // ERROR: Can't capture mutating self
  }
}

// ✅ CORRECT: Extract to local variable first
init() {
  let logger = logger  // Extract to local scope
  Task { @MainActor in
    logger.debug("...")  // References local, not mutating self
  }
}
```

**Why this pattern:**
- Avoids compiler errors in initializers
- Clear intent that you're capturing the value, not the reference
- Works for any property you need in an escaping closure during init

### Pattern 4: Cached-Only Pattern During Initialization

**Use case:** UI initialization that can't await MainActor methods.

**Problem:** MainActor-isolated methods called during configuration cause executor hopping and potential deadlocks.

```swift
// ❌ WRONG: Executor hopping deadlock during initialization
let configuration = WKWebViewConfiguration()
configuration.userContentController = userContentController

// ERROR: Calling @MainActor method during init causes executor hopping
if let ruleList = try? await ContentBlockerManager.shared.getRuleList() {
  userContentController.add(ruleList)
}

// ✅ CORRECT: Only use pre-cached values
let configuration = WKWebViewConfiguration()
configuration.userContentController = userContentController

// Use only cached rules—no awaiting
if let cachedRuleList = ContentBlockerManager.shared.currentRuleList {
  userContentController.add(cachedRuleList)
}
```

**Why this pattern:**
- Avoids executor hopping deadlocks during initialization
- Cached values are always synchronously available
- Background compilation task (Pattern 1) populates the cache for future instances
- First instance uses fallback; subsequent instances benefit from cache

---

## Dependency Injection & Modern TCA Patterns

### Why Modern Patterns Are Required (Swift 6.2 Strict Concurrency)

**This is not a style choice. This is a language requirement.**

Modern Swift 6.2 has introduced **strict concurrency enforcement** and macro-based tooling that makes old patterns incompatible:

**Old patterns (TCA 1.22 era):**
```swift
@Perception.Bindable
WithPerceptionTracking { ... }
Manual DependencyKey + extension DependencyValues
```

**Problem:** These patterns don't satisfy Swift 6.2 `Sendable` requirements. They will **not compile** with strict concurrency enabled.

**New patterns (TCA 1.23.0+ with Swift 6.2):**
```swift
@DependencyClient  // Macro handles Sendable + concurrency
@Bindable          // Optimized for strict concurrency
@ObservableState   // Works with Sendable requirements
```

**Why this matters:**
- Swift 6.2 requires `Sendable` on all public types in concurrent code
- TCA and its satellite libraries continuously evolve with macros and tools to solve concurrent programming challenges
- Libraries are continuously improving to adapt to language evolution
- Being on the current version is critical for adhering to the latest language and platform standards

**Practical implication:** Code written with old patterns **will not compile** when you enable strict concurrency. This isn't "prefer the new way"—this is "the old way is no longer valid."

**Note:** Platform-specific concurrency requirements (visionOS actor isolation, macOS threading) are documented in [PLATFORM-VISIONOS.md](./PLATFORM-VISIONOS.md), [PLATFORM-MACOS.md](./PLATFORM-MACOS.md), etc.

---

### @DependencyClient Macro (Strongly Preferred)

Use `@DependencyClient` for all dependencies. This is the current swift-dependencies recommendation and significantly better than manual DependencyKey construction.

```swift
@DependencyClient
public struct MyService: Sendable {
  public var fetch: @Sendable () async throws -> [Result]
}

// Provide implementations
extension MyService {
  public static let liveValue = Self(
    fetch: { try await LiveMyServiceImplementation().fetch() }
  )

  public static let testValue = Self(
    fetch: { [] }
  )
}

// Usage in reducer
@Reducer
public struct MyFeature {
  @Dependency(\.myService) var myService
  // ...
}
```

**Benefits:**
- ✅ Less boilerplate (macro generates DependencyKey + DependencyValues)
- ✅ Clearer intent (marked as a dependency from the start)
- ✅ Automatic test/preview defaults
- ✅ Current Point-Free standard
- ✅ Future-proof design

**Module Structure Requirements:**

```
Module/
├── Sources/
│   ├── ModuleCore/
│   │   ├── ModuleService.swift (defines @DependencyClient)
│   │   ├── ModuleFeature.swift (uses @Dependency)
│   │   └── ... other core logic
│   └── ModuleUI/
│       ├── ModuleView.swift (uses @Bindable store)
│       └── ... UI components
└── Package.swift (ModuleCore depends on swift-dependencies)
```

**DO:**
- ✅ Define DependencyKey only in Core modules
- ✅ Import Dependencies only in Core modules
- ✅ Use @Bindable in UI (public, not private)
- ✅ Declare Dependencies in Package.swift for Core targets

**DON'T:**
- ❌ Define DependencyKey in UI modules
- ❌ Use `@Bindable private var store`
- ❌ Wrap view bodies in `WithPerceptionTracking`
- ❌ Import Dependencies in UI modules
- ❌ Forget Dependencies in Package.swift

### Deterministic Data & Side-Effect Control

Always pull time, randomness, and clocks from `DependencyValues` instead of calling them directly:

```swift
// ❌ DON'T
let now = Date()
let id = UUID()

// ✅ DO
@Dependency(\.date.now) var now
@Dependency(\.uuid) var uuid
@Dependency(\.continuousClock) var clock
@Dependency(\.random) var random
```

**Common dependencies:**
- `@Dependency(\.date.now)` - Current timestamp
- `@Dependency(\.uuid)` - ID generation
- `@Dependency(\.continuousClock)` - Clock for sleeping/timing
- `@Dependency(\.runLoop)` - Run loop access
- `@Dependency(\.random)` - Random number generation
- `@Dependency(\.calendar)` - Calendar operations

---

## Logging & Observability

### [STANDARD] Use OSLog Instead of print() for Production Logging

**CRITICAL:** Agents consistently default to `print()` statements, creating debugging hell and production blindness.

**Problem with `print()`:**
- Synchronous, blocks main thread
- Disappears in release builds
- No filtering or categorization
- No structured metadata
- Security risks (PII exposure)
- Memory overhead from string concatenation

**Reference:** Case Study [DISCOVERY-15-PRINT-OSLOG-PATTERNS.md](../../CaseStudies/DISCOVERY-15-PRINT-OSLOG-PATTERNS.md)

### Point-Free Validated Logging Pattern

Based on Point-Free's `Logger.shared.log()` pattern even in test cases:

```swift
import OSLog

@Reducer
struct UserProfileFeature {
    // ✅ Create logger with subsystem and category
    private static let logger = Logger(
        subsystem: "com.app.userprofile",
        category: "UserProfileFeature"
    )

    @ObservableState
    struct State {
        var user: User?
        var isLoading = false
    }

    enum Action {
        case loadUser(userID: String)
        case userLoaded(User)
        case loadFailed(Error)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadUser(let userID):
                // ✅ Structured logging with context
                Self.logger.info("Loading user profile", metadata: [
                    "userID": "\(userID)",
                    "timestamp": "\(Date().timeIntervalSince1970)"
                ])
                state.isLoading = true
                return .run { send in
                    do {
                        let user = try await userClient.fetch(id: userID)
                        // ✅ Success without sensitive data
                        Self.logger.info("User profile loaded successfully", metadata: [
                            "userID": "\(userID)",
                            "hasProfileImage": "\(user.profileImage != nil)"
                        ])
                        await send(.userLoaded(user))
                    } catch {
                        // ✅ Error with context, no sensitive info
                        Self.logger.error("Failed to load user profile", metadata: [
                            "userID": "\(userID)",
                            "errorDomain": "\(type(of: error))",
                            "errorCode": "\(error.localizedDescription.prefix(50))"
                        ])
                        await send(.loadFailed(error))
                    }
                }

            case .userLoaded(let user):
                Self.logger.debug("Updating UI with loaded user profile", metadata: [
                    "userID": "\(user.id)",
                    "updateType": "profile_loaded"
                ])
                state.user = user
                state.isLoading = false
                return .none

            case .loadFailed(let error):
                Self.logger.warning("Displaying error to user", metadata: [
                    "errorType": "\(type(of: error))",
                    "userFriendly": "true"
                ])
                state.isLoading = false
                return .none
            }
        }
    }
}
```

### When to Use print() vs OSLog

**Use `print()` ONLY for:**
```swift
// ❌ DEVELOPMENT ONLY - Remove before commit
print("DEBUG: \(variableName) = \(variableValue)")  // Remove this!
print("Placeholder: Implement actual logic here")    // Remove this!
```

**Use OSLog for:**
```swift
// ✅ PRODUCTION LOGGING
logger.info("User action completed", metadata: ["action": "login"])
logger.error("Operation failed", metadata: ["error": "\(error.localizedDescription)"])
logger.debug("State changed", metadata: ["from": "\(oldState)", "to": "\(newState)"])
```

### Testable Logging with Dependency Injection

```swift
protocol LoggingClient {
    func info(_ message: String, metadata: [String: String])
    func debug(_ message: String, metadata: [String: String])
    func warning(_ message: String, metadata: [String: String])
    func error(_ message: String, metadata: [String: String])
}

// Production implementation
struct OSLogClient: LoggingClient {
    let logger: Logger

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func info(_ message: String, metadata: [String: String]) {
        logger.info("\(message, privacy: .public)", metadata: metadata.asMetadata())
    }
}

// Test implementation
struct TestLogClient: LoggingClient {
    var loggedMessages: [(level: LogLevel, message: String, metadata: [String: String])] = []
    // ... implementation for testing
}

@Reducer
struct LoggingExampleFeature {
    @Dependency(\.loggingClient) var loggingClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .increment:
                loggingClient.debug("Incrementing value", metadata: [
                    "currentValue": "\(state.value)",
                    "newValue": "\(state.value + 1)"
                ])
                state.value += 1
                return .none
            }
        }
    }
}
```

### Performance-Aware Logging

```swift
@Reducer
struct HighFrequencyFeature {
    private static let logger = Logger(subsystem: "com.app.hf", category: "HighFrequency")

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .increment:
                state.counter += 1

                // ✅ Only log every 100 increments to avoid spam
                if state.counter % 100 == 0 {
                    Self.logger.info("Milestone reached", metadata: [
                        "counter": "\(state.counter)",
                        "batchSize": "100"
                    ])
                }
                return .none
            }
        }
    }
}
```

### Print vs OSLog Comparison

| Aspect | ❌ `print()` | ✅ `OSLog` |
|--------|-------------|------------|
| **Performance** | Synchronous, blocks thread | Asynchronous, optimized |
| **Production** | Disappears in release builds | Persists with configurable levels |
| **Filtering** | No filtering | Subsystem/category/level filtering |
| **Context** | Just strings | Structured metadata |
| **Security** | No privacy controls | Privacy annotations |
| **Testing** | Hard to capture/test | Injectable dependency |

### Logging Checklist

Before committing logging code:

- [ ] **No print() statements** in production code (remove development prints)
- [ ] **Structured logging** with subsystem and category
- [ ] **Metadata included** for context (avoid sensitive data)
- [ ] **Performance considered** for high-frequency operations
- [ ] **Testable implementation** with dependency injection
- [ ] **Appropriate log levels** (debug, info, warning, error)

---

## Access Control & Public API Boundaries

### [STANDARD] Verify Transitive Access Control Before Exposing Types

When you make a property or type public, **all transitive type dependencies must also be public**. The Swift compiler validates this at declaration time and may report misleading error messages about type mismatches when the real issue is access control.

**Why this matters:**
- Exposing one public property can force an entire chain of types to become public
- Compiler errors often report symptoms (type mismatch) instead of root causes (access control)
- Missing transitive declarations cause cascade failures in binding patterns and module boundaries

**Reference:** Case Study [DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md](../../CaseStudies/DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md)

### Checklist: Before Making Anything Public

```
- [ ] Is the property itself public (or do you need to make it public)?
- [ ] Is the property's base type public?
  - [ ] Check: enum or struct that holds the property
  - [ ] Check: any generic type parameters

- [ ] Do all transitive types need to be public?
  - [ ] Direct type (the main enum/struct)
  - [ ] Types nested within that type
  - [ ] Protocol conformances (Hashable.hash, Equatable.==)

- [ ] Does this violate module boundaries?
  - [ ] Is the type now visible outside its intended scope?
  - [ ] Does a higher-level module now depend on lower-level internals?
  - [ ] Could this create a circular dependency?

- [ ] Is there a better alternative?
  - [ ] Could you use a protocol instead of concrete type?
  - [ ] Could you move the type to a shared module?
  - [ ] Could you use a wrapper type at the boundary?
```

### Example: The Cascade

```swift
// You want to expose this binding in your app layer:
@Bindable var store = Store(initialState: ScrollState())

windowGroup("Reader") {
  ReaderView(store: $store.articleSelection)
  // ERROR: Cannot convert Binding<Article.ID??> to Binding<Article.ID?>
}

// Root cause: articleSelection is internal, so it's not accessible
// Even after making articleSelection public, you discover:

public var articleSelection: Article.ID?
// ↓ depends on (must be public)
ArticleSidebarDestination?
// ↓ depends on (must be public)
ArticleLibraryCategory
// ↓ all properties and conformances must be public
Hashable.hash(into:)
Equatable.==

// Solution: Trace the entire chain before exposing anything
public enum ArticleLibraryCategory: Hashable, Equatable {
  case all
  case favorites
  // ... with public conformance methods

  public func hash(into hasher: inout Hasher) { /* ... */ }
  public static func == (lhs: Self, rhs: Self) -> Bool { /* ... */ }
}

public enum ArticleSidebarDestination: Hashable, Equatable {
  case detail(Article.ID)
  // ... with public conformance methods
}

// Now the binding works
$store.articleSelection  // ✅ Fully public type signature
```

### How to Debug Access Control Errors

1. **Don't trust the error message.** If you see type mismatch or binding errors, check access levels first.

2. **Trace the full chain:**
   - Not just the immediate property, but every type it depends on
   - Use `grep` to find all dependencies of each type
   - Verify each one has a `public` access level if needed

3. **Use Xcode's Quick Help:**
   - Option-click on a type in Xcode
   - See the access level in the generated interface
   - If "internal" is shown, you found a violation

4. **When adding `@Bindable` to state:**
   - Assume all bound properties need public types
   - Check the state struct's access level
   - Verify all properties involved in binding are public

### Anti-Pattern: Exposing Too Much

❌ **Don't expose implementation details just to avoid warnings:**

```swift
// Wrong: You made ArticleLibraryCategory public unnecessarily
public enum ArticleLibraryCategory { ... }  // Now it's part of the public API

// Clients now depend on this internal type, making future refactors hard
let category = Feature.ArticleLibraryCategory.all  // Tight coupling
```

✅ **Better: Use a protocol boundary if possible**

```swift
// If you only need certain methods public, use a protocol
public protocol ArticleCategory {
  var displayName: String { get }
}

// Keep the concrete type internal
internal enum ArticleLibraryCategory: ArticleCategory {
  // ...
}

// Public interface uses protocol, not concrete type
public func setCategory(_ category: some ArticleCategory) { }
```

### When Public Exposure Is Correct

Make types public when:

1. **They're part of the public feature API** - State destinations, value objects that features expose
   ```swift
   // ArticleQueueFeature exposes this as part of its public state interface
   public enum ArticleSidebarDestination: Hashable {
     case detail(Article.ID)
     case settings
   }
   ```

2. **They're required by binding patterns** - Properties that views need to bind to
   ```swift
   @ObservableState
   public struct State {
     public var articleSelection: Article.ID?  // Needs to be public for $store.articleSelection
   }
   ```

3. **They're cross-module value objects** - DTOs or domain values passed between modules
   ```swift
   public struct Article: Identifiable, Hashable {
     public let id: ID
     public let title: String
   }
   ```

---

## Swift Testing Framework (Required)

### Basic Structure

Use `@Test` and `#expect()` for all new tests:

```swift
import Testing
import Dependencies
@testable import MyModule

struct MyFeatureTests {
  @Test func basicBehavior() {
    let value = computeValue()
    #expect(value == expectedValue)
  }
}
```

### Suite-Level Traits (Shared Setup)

```swift
@Suite(.dependencies {
  $0.date.now = Date(timeIntervalSince1970: 1_735_200_000)
  $0.uuid = .incrementing
  $0.continuousClock = TestClock()
})
struct MyFeatureTests {
  @Test func scenario1() async { }
  @Test func scenario2() async { }
}
```

### TCA TestStore Pattern

```swift
@MainActor
struct MyFeatureTests {
  @Test func userFlow() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.apiClient = .mock
      $0.continuousClock = TestClock()
    }

    await store.send(.loadData) {
      $0.isLoading = true
    }

    await store.receive(\.dataResponse) {
      $0.isLoading = false
      $0.data = expectedData
    }

    await store.finish()
  }
}
```

### Deterministic Time with TestClock

**Always use `TestClock()` instead of `Date.constant()`:**

```swift
@Test func timerWorks() async {
  try await withDependencies {
    $0.continuousClock = TestClock()
  } operation: {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.timerStarted)

    // Advance time deterministically (no waiting)
    await store.clock.advance(by: .seconds(60))

    await store.receive(\.timerTicked) {
      $0.elapsedSeconds = 60
    }
  }
}
```

**Why TestClock?**
- Tests run in milliseconds, not real time
- Deterministic (never flaky)
- Can test hours of time logic instantly
- Works with debounce, throttle, timers, delays

### CustomDump: expectNoDifference

Use `expectNoDifference` for complex data comparisons:

```swift
import CustomDump

@Test func complexData() {
  let actual = createUser()
  let expected = User(id: 1, name: "Blob", age: 42)

  expectNoDifference(actual, expected)
}
```

**Use `expectNoDifference` when:**
- Comparing complex nested structures
- Diffs matter for debugging
- Visual feedback on changes is important

**Use `#expect(_ == _)` when:**
- Comparing simple values (Int, String, Bool)
- Speed matters

### Testing DO & DON'T

**✅ DO:**
- Use `@Test` with `async` functions
- Mark tests `@MainActor` for TCA/UI
- Use `TestClock()` for time-based logic
- Override dependencies per-test with `withDependencies`
- Use `expectNoDifference` for complex data
- Use `.dependencies {}` trait for shared setup
- Call `await store.finish()` to verify effects complete

**❌ DON'T:**
- Use `XCTestCase`, `func test...()`, `XCTAssert*` (legacy)
- Use `Date.constant()` for time
- Define dependencies in test method
- Forget `@MainActor` on TCA tests
- Ignore mock call counts and state mutations
- Mix Swift Testing and XCTest in same file
- Use `@Test` without `async` unless truly synchronous

---

## Store Creation & Module Boundaries

### Solution 1: Static Store on App Level (Recommended)

Create the Store as a static property on the App struct. The module doesn't create the Store; the App does.

```swift
@main
struct MyApp: App {
  static let store = Store(initialState: MyFeature.State()) {
    MyFeature()
  } withDependencies: {
    // Configure dependencies here
  }

  var body: some Scene {
    WindowGroup {
      MyView(store: Self.store)
    }
  }
}
```

**Why This Works:**
- Feature types are internal but accessible within the same module (App target)
- No public factories needed
- Store lifetime is clear and managed at app level
- Follows official TCA examples (SyncUps, CloudKitDemo)
- Clean separation: Feature defines logic, App creates/owns the Store

### Solution 2: Remove Unnecessary Wrapper Dependencies

If you created a custom dependency wrapper around something that already has a singleton pattern, remove it.

```swift
// ❌ DON'T: Unnecessary wrapper
public enum ImagePipelineKey: DependencyKey {
  public static let liveValue: ImagePipeline = { ... }
}

// ✅ DO: Use singleton directly
.pipeline(ImagePipeline.shared)
```

### Critical Lesson: Check for Missing Public Initializer

When you encounter "I need to create a View from outside the module but can't", the FIRST thing to check:

**Does the public View struct have a public initializer?**

```swift
// ❌ WRONG - Struct is public but init is internal
public struct MyView: View {
  init(store: StoreOf<MyFeature>) {  // Internal!
    self.store = store
  }
}

// ✅ CORRECT - Make init public
public struct MyView: View {
  public init(store: StoreOf<MyFeature>) {  // Public!
    self.store = store
  }
}
```

**Why This Matters:**
- Public structs in Swift have internal initializers by default
- This is the simplest and most common reason you "can't" create a View externally
- The solution is trivial: `public init(...)`
- This is better than factories because:
  - Explicit control at call site
  - No hidden Store creation logic
  - Clearer intent
  - No linker symbol issues

---

## Modularization Best Practices

### When to Create a Module

1. A feature has 3+ reducers or 500+ lines of logic
2. Multiple features need the same domain logic (extract to shared module)
3. A reducer manages sub-features independently testable
4. Platform-specific code exists (ModuleCore, ModuleUI, ModuleMac, ModuleVision)

### Reducer Encapsulation & Composition

**Good: Scoped Reducers**
```swift
@Reducer
public struct ParentFeature: Sendable {
  @ObservableState
  public struct State: Equatable {
    @Presents var child: ChildFeature.State?
  }

  public enum Action: Sendable {
    case child(PresentationAction<ChildFeature.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in ... }
      .ifLet(\.$child, action: \.child) {
        ChildFeature()
      }
  }
}
```

**Bad: Monolithic Reducer**
```swift
// ❌ DON'T: 50+ action cases, no composition
public struct AppFeature: Sendable {
  public enum Action: Sendable {
    case userLogin(String)
    case fetchArticles
    case updateArticle(UUID, String)
    // ... 50 more cases
  }
}
```

### Code Review Discipline

**Critical checks for pull requests:**

1. **Dependency Layer Violation Check**
   - Is DependencyKey defined in Core? (must be)
   - Are dependencies only imported in Core? (must be)
   - Does Package.swift list Dependencies? (must be)

2. **Observation Pattern Check**
   - Any `@Perception.Bindable`? → Reject (deprecated)
   - Any `WithPerceptionTracking`? → Reject (unnecessary)
   - Any `@Binding` on store? → Reject (use @Bindable)

3. **Reducer Bloat Check**
   - 15+ cases? Question scope
   - 25+ cases? Likely missing sub-feature
   - 40+ cases? Definitely monolithic

4. **Module Boundary Check**
   - Does UI import Core? (must be)
   - Does Core import UI? (never!)
   - Circular dependencies? (never!)

---

## MCP Tool Usage (Model Context Protocol)

**Always prefer MCP tools over raw shell commands when available.**

### Build Output: xcsift vs XcodeBuildMCP

**Use xcsift as primary (token-efficient):**
```bash
xcodebuild build -scheme MyScheme 2>&1 | xcsift
# Output: { "success": true/false, "errors": [...], "errorCount": 0, "warningCount": 0 }
# Token cost: ~150-300 tokens
```
- **Best for:** Daily development, most builds, token-constrained contexts
- **Reference:** https://github.com/ldomaradzki/xcsift

**Use XcodeBuildMCP when xcsift isn't sufficient:**
- **When:** Need build product paths, binary locations, code coverage, full metadata
- **Available:** `build_macos`, `build_sim`, `test_macos`, `test_sim`, `test_device`, `list_schemes`, `show_build_settings`, etc.
- **Benefits:** Structured objects, device/simulator integration, full build info
- **Token cost:** ~800-1200 tokens (higher but complete)

### SosumiDocs - Apple Documentation

- **ALWAYS use** `mcp__sosumi__searchAppleDocumentation` and `mcp__sosumi__fetchAppleDocumentation`
- **Don't wait to be prompted** - proactively fetch docs when working with Apple APIs
- **Benefit:** Fetches latest documentation, converts to markdown, searches HIG

### GitHub MCP - Repository Operations

- **Use for:** Creating issues, PRs, reading project boards, managing labels, commenting
- **Available:** `create_issue`, `create_pull_request`, `get_issue`, `list_issues`, `search_code`, etc.

### Decision Tree: GitHub MCP vs `gh` CLI

**Use GitHub MCP for:**
- Complex queries: `search_code`, `search_issues` with filtering
- Advanced workflows: PR reviews, project management
- Metadata-heavy operations: Full issue details, branch info
- **Benefit:** Structured responses, type-safe

**Use `gh` CLI for:**
- Simple CRUD: Create/update/close issues/PRs (faster)
- Batch operations: Multiple issues in a loop
- Chaining commands: Shell piping and utilities
- **Benefit:** No approval prompts, direct CLI, shell flexibility

---

## Commit & Pull Request Guidelines

- Use short, present-tense summaries (`Improve X logic`, `Add Y feature`)
- Reference issue IDs in body (`Refs #123`)
- Explain behavioral changes and testing performed
- Include motivation, before/after notes, validation steps
- For visual changes: Add screenshots or screen recordings

---

## Build & Validation

- Validate functions, structs, and classes against **latest Apple docs**: https://developer.apple.com/documentation/
- **Pull Apple documentation through SosumiDocs MCP by default**; do not wait to be prompted
- Keep functions small, pure, and testable
- Use clear names, doc comments for public APIs
- Inline comments only when non-obvious
- **No placeholders or ellipses; produce complete, compiling implementations**

---

## Onboarding New Developers

### Before They Write Code

1. **Read this document** - Understand agnostic principles
2. **Read platform guide** - Understand platform-specific constraints
3. **Review "DO NOT" list** - Before writing first PR
4. **Ask: "Have I seen this pattern in existing code?"**
   - If yes, are they using current version?
   - If no, follow this guide, don't copy old code

### During Code Review

- Link to relevant sections when requesting changes
- Explain the cost of violations
- Show the correct fix
- Use code review template from "Code Review Discipline" section

### Knowledge Transfer

When working on a new platform area:
1. Check if your platform guide covers the pattern
2. If not, ask and document the answer
3. Update the platform guide immediately
4. Share with team

---

## Reference & Further Reading

- **Point-Free swift-dependencies:** https://swiftpackageindex.com/pointfreeco/swift-dependencies/
- **Point-Free The Composable Architecture:** https://github.com/pointfreeco/swift-composable-architecture
- **Apple Documentation:** https://developer.apple.com/documentation/
- **Swift 6 Concurrency:** https://www.swift.org/concurrency/
