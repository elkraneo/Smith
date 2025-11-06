# SMITH Framework Essentials - 5 Patterns + Red Flags

**Purpose:** Single source of truth for framework patterns. Read this. Everything else is reference.

**Token Budget:** ~700 tokens (5-minute read)
**When to Read:** EVERY TASK - identify pattern, read relevant section, check verification

---

## 5 Core Patterns

### Pattern 1: Observing State (@Bindable + @ObservableState)

```swift
@Reducer
struct MyFeature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }

  enum Action {
    case incrementTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementTapped:
        state.count += 1
      }
      return .none
    }
  }
}

struct MyView: View {
  @Bindable var store: StoreOf<MyFeature>  // ← Marks observable

  var body: some View {
    Text("Count: \(store.count)")  // ← Direct access, auto-updates
    Button("Increment") {
      store.send(.incrementTapped)  // ← Direct dispatch
    }
  }
}
```

**Rules [CRITICAL]:**
- Use `@ObservableState` on all reducer State types
- Use `@Bindable` on view store properties
- Access state directly: `store.count` (no closures)
- Never use `@State`, `WithViewStore`, or manual `.onReceive()`

**Verification:**
- [ ] All State types have `@ObservableState`
- [ ] View stores use `@Bindable`
- [ ] State accessed directly in views
- [ ] No `WithViewStore` or deprecated APIs

---

### Pattern 2: Optional Navigation (.sheet + .scope)

```swift
@Reducer
struct GameFeature {
  @ObservableState
  struct State: Equatable {
    var helpPopover: HelpFeature.State?  // Optional = conditional presentation
  }

  enum Action {
    case helpTapped
    case help(HelpFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .helpTapped:
        state.helpPopover = HelpFeature.State()
        return .none
      case .help:
        return .none
      }
    }
    .ifLet(\.$helpPopover, action: \.help) {
      HelpFeature()
    }
  }
}

struct GameView: View {
  @Bindable var store: StoreOf<GameFeature>

  var body: some View {
    ZStack {
      Button("Help") { store.send(.helpTapped) }

      .sheet(
        item: $store.scope(
          state: \.helpPopover,
          action: \.help
        )
      ) { helpStore in
        HelpView(store: helpStore)
      }
    }
  }
}
```

**Rules [CRITICAL]:**
- Optional state = optional property on parent
- `.ifLet()` in reducer composes child feature
- `.sheet()` in view presents when non-nil
- Setting to `nil` dismisses automatically

**Verification:**
- [ ] Optional property defined in parent State
- [ ] `.ifLet()` + `.sheet()` pair present
- [ ] Child reducer composed with `.ifLet()`
- [ ] No manual dismiss logic

---

### Pattern 3: Enum Navigation (.ifLet with closure) ⚠️

**CRITICAL: Closure is mandatory. See DISCOVERY-6 for why.**

```swift
@Reducer
public enum GameLevel {
  case intro(IntroLevel)
  case gameplay(GameplayLevel)
  case results(ResultsLevel)

  // ⚠️ MANDATORY CLOSURE: Without this, you get _EphemeralState errors
}

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var level: GameLevel.State?
  }

  enum Action {
    case level(GameLevel.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Handle level transitions
      return .none
    }
    .ifLet(\.$level, action: \.level) {
      GameLevel.body  // ← CLOSURE IS MANDATORY
    }
  }
}
```

**Rules [CRITICAL]:**
- `@Reducer` macro on enum (not optional type)
- Enum contains reducer cases, not state types
- `.ifLet()` **MUST** include closure `{ GameLevel.body }`
- Removing closure → `_EphemeralState` error (internal conformance required)

**Common Mistake:** Writing `.ifLet(\.$level, action: \.level)` without closure ❌
**Fix:** Add closure: `.ifLet(\.$level, action: \.level) { GameLevel.body }` ✅

**Verification:**
- [ ] @Reducer macro on enum
- [ ] Enum contains reducers, not State types
- [ ] .ifLet() includes closure { GameLevel.body }
- [ ] No manual _EphemeralState conformance

---

### Pattern 4: Shared State (@Shared + @SharedReader) ⚠️

**See DISCOVERY-5: Multiple writers = data races. Single owner only.**

```swift
// Define at root reducer (single owner)
@Reducer
struct AppFeature {
  @Shared(.appStorage("theme")) var theme = Theme.light  // ← Single owner
  @Shared(.appStorage("hints")) var hintProgress = 0

  var body: some ReducerOf<Self> {
    // AppFeature can mutate theme
  }
}

// Other features read only
@Reducer
struct SettingsFeature {
  @SharedReader var theme: Theme  // ← Read-only, no mutations
  @SharedReader var hintProgress: Int

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Can read theme, hintProgress
      // Cannot mutate - no write access
      return .none
    }
  }
}
```

**Rules [CRITICAL]:**
- One feature owns `@Shared` (can mutate)
- All others use `@SharedReader` (read-only)
- Never multiple writers on same `@Shared` (race condition - DISCOVERY-5)
- Constructor: `Shared(wrappedValue: value, key:)` NOT `Shared(value: value)` ❌

**Verification:**
- [ ] Single owner identified for each @Shared
- [ ] Owner has writable @Shared
- [ ] All others have @SharedReader only
- [ ] No multiple features mutating same @Shared
- [ ] Constructor uses wrappedValue label (not value)

---

### Pattern 5: Dependencies (@DependencyClient)

```swift
@DependencyClient
struct DateClient: Sendable {
  var now: @Sendable () -> Date = { Date() }
}

extension DependencyValues {
  var dateClient: DateClient {
    get { self[DateClient.self] }
    set { self[DateClient.self] = newValue }
  }
}

@Reducer
struct MyFeature {
  @Dependency(\.dateClient) var dateClient

  enum Action {
    case checkTime
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .checkTime:
        let currentTime = dateClient.now()  // ← Uses injected client
        return .none
      }
    }
  }
}
```

**Rules [CRITICAL]:**
- Use `@DependencyClient` for all new dependencies
- Never call `Date()`, `UUID()`, `Int.random()` directly
- Override through `DependencyValues` in tests
- Define in Core modules only, never UI

**Verification:**
- [ ] @DependencyClient defined for each dependency
- [ ] No direct Date(), UUID(), random() calls
- [ ] All overrides through DependencyValues
- [ ] testValue and previewValue provided

---

## 5 Red Flags - Stop & Re-Read

| Red Flag | Fix | Read |
|----------|-----|------|
| `@State` in reducer | Use `@ObservableState` | AGENTS-TCA-PATTERNS Pattern 1 |
| `WithViewStore` in code | Use `@Bindable` | AGENTS-TCA-PATTERNS Pattern 1 |
| `.ifLet(\.$destination, action: \.destination)` (no closure) | Add closure `{ Destination() }` | DISCOVERY-6 |
| Multiple features mutating `@Shared` | Use single owner + @SharedReader | DISCOVERY-5 |
| `Task.detached` | Use `Task { @MainActor in ... }` | AGENTS-AGNOSTIC line 28 |
| `Shared(value: x)` | Use `Shared(wrappedValue: x)` | AGENTS-TCA-PATTERNS line 21 |
| Public property without checking dependencies | Trace transitive chain | DISCOVERY-5 |
| Calling `Date()` directly | Inject via @DependencyClient | Pattern 5 |

---

## Verification Template (Copy This)

Before committing ANY code:

- [ ] Identified pattern(s) used (1, 2, 3, 4, 5, or multiple)
- [ ] Read relevant pattern section entirely
- [ ] Read verification checklist for that pattern
- [ ] Checked for red flags
- [ ] All checklist items verified
- [ ] No violations remain

**If you can't check all boxes, do not commit.**

---

## When to Read Deep Docs

This essentials doc covers **80% of your work.** Read deep docs only when:

- ❓ "Should I use @Shared or @DependencyClient?" → AGENTS-DECISION-TREES.md
- ❓ "How do I test @Shared state?" → AGENTS-TCA-PATTERNS.md Testing section
- ❓ "What about concurrency?" → AGENTS-AGNOSTIC.md lines 162–313
- ❓ "How do I handle access control cascade?" → DISCOVERY-5

**Structure:**
```
📄 SMITH-FRAMEWORK-ESSENTIALS.md  ← START HERE (you are here)
├─ Reference: AGENTS-TCA-PATTERNS.md (linked from patterns)
├─ Reference: AGENTS-AGNOSTIC.md (linked from rules)
├─ Case Study: DISCOVERY-5 (linked from Pattern 4)
└─ Case Study: DISCOVERY-6 (linked from Pattern 3)
```

---

## The Discipline

**The Smith framework is not a style guide. It's correctness enforcement.**

- Patterns are backed by DISCOVERY case studies (real bugs)
- Rules are written because violations cause compilation/runtime errors
- Verification checklists prevent common mistakes
- Red flags are patterns that statistically cause failures

**Trust the patterns. Skip them, introduce bugs.**

---

**Last Updated:** November 6, 2025
**Framework Version:** v1.1+
**TCA Version:** 1.23.0+
**Related:** CLAUDE.md, AGENTS-TCA-PATTERNS.md, DISCOVERY-*.md
