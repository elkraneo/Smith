# Smith Quick Start Guide

**Read this first. Everything else can wait.**

This is your **5-minute crash course** in Smith patterns. Read the full docs later when you need specifics.

---

## The 10 Critical Rules

### 1. Swift 6.2 Strict Concurrency
```swift
// ✅ CORRECT
@Observable
final class ViewModel: Sendable {
  var state: String = ""
}

// ❌ WRONG - @Published doesn't work with strict concurrency
class ViewModel: ObservableObject {
  @Published var state: String = ""
}
```

### 2. Modern TCA 1.23.0+ Binding
```swift
// ✅ CORRECT - Direct binding with @Bindable
struct MyView: View {
  @Bindable var store: StoreOf<Feature>

  var body: some View {
    TextField("Name", text: $store.name)
  }
}

// ❌ WRONG - WithViewStore is deprecated
struct MyView: View {
  let store: StoreOf<Feature>

  var body: some View {
    WithViewStore(store) { viewStore in
      TextField("Name", text: viewStore.$name)
    }
  }
}
```

### 3. Optional State Navigation
```swift
// ✅ CORRECT - Use .sheet(item:) with .scope()
.sheet(item: $store.scope(state: \.destination?.detail, action: \.destination.detail)) { store in
  DetailView(store: store)
}

// ❌ WRONG - Don't create host bridges
if let detailStore = store.scope(state: \.detail, action: \.detail) {
  DetailHostBridge(store: detailStore)
}
```

### 4. Reducer Composition with .ifLet
```swift
// ✅ CORRECT - Must use closure form for @Reducer enums
Reduce { state, action in
  // parent logic
}
.ifLet(\.detail, action: \.detail) {
  DetailFeature()  // Closure provides child reducer
}

// ❌ WRONG - Missing closure causes action routing failures
.ifLet(\.detail, action: \.detail)  // No child reducer!
```

### 5. Dependency Injection
```swift
// ✅ CORRECT - Use @DependencyClient for services
@DependencyClient
struct APIClient: Sendable {
  var fetchUser: @Sendable (String) async throws -> User
}

// ❌ WRONG - Singletons break testing
class APIClient {
  static let shared = APIClient()
}
```

### 6. Testing with Swift Testing
```swift
// ✅ CORRECT - Swift Testing (not XCTest)
@Test @MainActor
func featureLoadsData() async {
  let store = TestStore(initialState: Feature.State()) {
    Feature()
  }

  await store.send(.load)
  await store.receive(.response(.success(data)))
  await store.finish()  // Critical: verify all effects complete
}

// ❌ WRONG - XCTest is deprecated for new tests
class FeatureTests: XCTestCase {
  func testFeatureLoadsData() { ... }
}
```

### 7. Deterministic Time Testing
```swift
// ✅ CORRECT - Use TestClock for time-based logic
@Suite(.dependencies {
  $0.continuousClock = TestClock()
})
struct TimingTests {
  @Test @MainActor
  func delayWorks() async {
    let store = TestStore(initialState: Feature.State()) { Feature() }
    await store.send(.start)
    await store.clock.advance(by: .seconds(3))  // Instant in tests
    await store.receive(.timeout)
  }
}

// ❌ WRONG - Real delays make tests slow and flaky
await Task.sleep(for: .seconds(3))
```

### 8. Access Control (Transitive)
```swift
// ✅ CORRECT - All transitive types must be public
public struct Feature: Reducer {
  public enum Destination: Hashable {  // Must be public
    case detail(Detail)  // Detail must also be public
  }

  public var body: some ReducerOf<Self> { ... }
}

// ❌ WRONG - Internal types break binding projections
public struct Feature: Reducer {
  enum Destination: Hashable { ... }  // Internal breaks $store.destination
}
```

### 9. Exclusive State (visionOS)
```swift
// ✅ CORRECT - Remove old entity before showing new
parent.removeChild(oldLevelEntity)
oldLevelEntity.components.set([])  // Clear after removal

let newLevelEntity = Entity()
parent.addChild(newLevelEntity)

// ❌ WRONG - Concurrent entities cause visual bugs
let newLevelEntity = Entity()
parent.addChild(newLevelEntity)
// oldLevelEntity still visible!
```

### 10. Task Scope Boundaries
Before editing code, define:
- **Safe Zone** - Files you can freely edit (in scope)
- **Approval Zone** - Files you must ask about first (affected)
- **Forbidden Zone** - Files you must never touch (out of scope)

Example: "Fix intro level bug"
- Safe: IntroLevel.swift, IntroLevelTests.swift
- Approval: AppFeature.swift (routing), GameEngine.swift (entity creation)
- Forbidden: MPALevel.swift, GlitchLevel.swift (unrelated levels)

---

## The 5 Most Common Mistakes

### 1. Using Deprecated TCA APIs
**Symptom:** Deprecation warnings, complex bridges, features don't work

**Fix:** Use modern patterns:
- `@Bindable` (not WithViewStore)
- `.sheet(item:)` (not host bridges)
- Direct property access (not `.onReceive()`)

**Full details:** AGENTS-TCA-PATTERNS.md lines 1–350

---

### 2. Access Control Cascade Failures
**Symptom:** Type mismatch errors like `Binding<ID??>` when code looks correct

**Fix:** Check access levels of ALL transitive types:
```
public property → depends on Enum → depends on Case → depends on Associated Type
```

All must be public if property is public.

**Full details:** AGENTS-AGNOSTIC.md lines 443–598, DISCOVERY-5

---

### 3. Missing .ifLet Closure
**Symptom:** Child actions never reach child reducer, silent failures

**Fix:** Always use closure form:
```swift
.ifLet(\.child, action: \.child) { ChildFeature() }
```

**Full details:** DISCOVERY-6, AGENTS-TCA-PATTERNS.md lines 510–580

---

### 4. Forgetting await store.finish()
**Symptom:** Tests pass but effects don't complete, race conditions

**Fix:** Always end tests with:
```swift
await store.finish()
```

**Full details:** AGENTS-AGNOSTIC.md lines 601–735

---

### 5. Creating Entities Too Late (visionOS)
**Symptom:** PresentationComponent popovers/dialogs never appear

**Fix:** Create entities early (in setup), toggle visibility later:
```swift
// ✅ Setup
func configureButton() {
  button.components.set(...)
  ensurePopoverEntity()  // Create NOW
}

// ✅ Later
func showPopover() {
  popoverEntity.isEnabled = true  // Just toggle visibility
}

// ❌ WRONG
func showPopover() {
  let popover = Entity()  // Too late!
  parent.addChild(popover)
}
```

**Full details:** PLATFORM-VISIONOS.md lines 120–185, DISCOVERY-4

---

## Decision Trees (Quick Reference)

### When to Create a Module?
```
Is this 20+ actions OR 5+ files OR 3+ projects?
├─ YES → Create Swift Package module
└─ NO → Keep in main target
```

### When to Use @Shared vs @DependencyClient?
```
Is this cross-feature state (auth, user, flags)?
├─ YES → @Shared (with @SharedReader for read-only)
└─ NO → Is there a clear parent-child hierarchy?
    ├─ YES → @DependencyClient (explicit passing)
    └─ NO → Still probably @DependencyClient (avoid global state)
```

### When to Use @Observable vs @ObservableState?
```
Is this TCA reducer state?
├─ YES → @ObservableState (TCA macro)
└─ NO → Is this a view model or service?
    ├─ YES → @Observable (Swift macro)
    └─ NO → Is this a simple data model?
        └─ YES → No macro (just struct/class)
```

**Full details:** AGENTS-DECISION-TREES.md

---

## Tool Usage Rules

### Documentation
```
❌ curl https://developer.apple.com/documentation/...
✅ Use SosumiDocs MCP (cached, faster)
```

### Building
```
❌ xcodebuild -scheme MyApp -destination ...
✅ Use XcodeBuildMCP (better error parsing)
```

### GitHub Operations
```
Simple operations (view PR, list issues):
✅ gh pr list, gh issue view 123

Complex operations (create PR with templates):
✅ GitHub MCP (richer data access)
```

**Full details:** AGENTS-AGNOSTIC.md lines 69–94

---

## Where to Go Next

### For AI Agents
1. **You just read this** ✅
2. **Start coding** - Reference this guide when stuck
3. **Before submitting:** Fill out Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md
4. **Deep dive:** Read AGENTS-TCA-PATTERNS.md for complex TCA scenarios

### For Humans
1. **You just read this** ✅
2. **Project-specific notes:** Read your project's CLAUDE.md
3. **Platform details:** Read PLATFORM-[YOURPLATFORM].md
4. **Architectural decisions:** Read AGENTS-DECISION-TREES.md

### When You Hit a Wall
1. **Search case studies:** grep -r "your error" CaseStudies/
2. **Check TCA patterns:** AGENTS-TCA-PATTERNS.md (common mistakes section)
3. **Ask for help:** Reference the specific Smith rule you're confused about

---

## The Full Framework

This Quick Start covers ~80% of what you need. The full framework has:

- **AGENTS-AGNOSTIC.md** - Complete Swift 6.2 + TCA 1.23.0+ patterns (900 lines)
- **AGENTS-TCA-PATTERNS.md** - All TCA scenarios with examples (1000+ lines)
- **AGENTS-DECISION-TREES.md** - Every architectural decision flowchart
- **PLATFORM-*.md** - macOS, iOS, iPadOS, visionOS specific rules
- **CaseStudies/** - 11 real bug investigations with fixes
- **Tests/** - Submission templates and evaluation checklists

**You don't need to read all of that now.** Bookmark this guide and reference it when coding.

---

## Last Updated

**Version:** 1.1
**Date:** November 10, 2025
**For:** Smith Framework v1.1+

**Next Review:** Add patterns as they're discovered
