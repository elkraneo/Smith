# SMITH-TCA - Swift Composable Architecture Patterns

**TCA-specific patterns for Smith framework - modern Swift Composable Architecture 1.23.0+**

---

## 🔍 **When to Use smith-tca**

**Auto-load when user mentions:**
- "TCA", "Swift Composable Architecture", "@Reducer", "@ObservableState"
- "@Shared", "ComposableArchitecture", "store", "reducer"
- ".sheet", ".scope", "navigation", "state management"
- "Feature", "StoreOf", "@Bindable", "store.send"

---

## Core TCA Principles

### Modern TCA 1.23.0+ Rules
- **CRITICAL**: SwiftUI views observe store via `@Bindable`
- **CRITICAL**: No bridging layers, no manual observation
- **CRITICAL**: Store itself is `@Observable`
- **CRITICAL**: Use `@ObservableState` for reducer state
- **STANDARD**: Direct property access via `@Bindable`
- **STANDARD**: Actions dispatched via `store.send()`

---

## Essential Patterns

### Pattern 1: State Observation with @Bindable
**Use when:** Any SwiftUI view displays TCA state

```swift
struct CounterView: View {
  @Bindable var store: StoreOf<CounterFeature>

  var body: some View {
    Text("Count: \(store.count)")
    Button("Increment") {
      store.send(.incrementTapped)
    }
  }
}
```

### Pattern 2: Optional State Navigation (.sheet + .scope)
**Use when:** Sheet navigation with optional state

```swift
@Reducer
struct ParentFeature {
  @ObservableState
  struct State {
    var childState: ChildFeature.State?
  }

  enum Action {
    case childButtonTapped
    case child(ChildFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .childButtonTapped:
        state.childState = ChildFeature.State()
        return .none
      case .child:
        return .none
      }
    }
    .ifLet(\.childState, action: \.child) {
      ChildFeature()
    }
  }
}

// View implementation
struct ParentView: View {
  @Bindable var store: StoreOf<ParentFeature>

  var body: some View {
    Button("Show Child") {
      store.send(.childButtonTapped)
    }
    .sheet(item: $store.childState) { childState in
      ChildView(store: store.scope(state: \.childState, action: \.child))
    }
  }
}
```

### Pattern 3: Shared State (@Shared & @SharedReader)
**Use when:** Multiple features need simultaneous access to mutable state

```swift
// Define shared state at root
@Shared(.fileStorage("app-settings.json")) var appSettings: AppSettings

// Feature that writes to shared state
@Reducer
struct SettingsFeature {
  @Shared(.fileStorage("app-settings.json")) var appSettings: AppSettings

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .toggleDarkMode:
        appSettings.darkModeEnabled.toggle()
        return .none
      }
    }
  }
}

// Feature that only reads shared state
@Reducer
struct ThemeFeature {
  @SharedReader(.fileStorage("app-settings.json")) var appSettings: AppSettings

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .themeQuery:
        state.currentTheme = appSettings.darkModeEnabled ? .dark : .light
        return .none
      }
    }
  }
}
```

---

## Common Anti-Patterns to Avoid

| ❌ Wrong Pattern | ✅ Correct Pattern | Why |
|----------------|-------------------|-----|
| `WithViewStore(store)` | `@Bindable var store` | Deprecated since TCA 1.5 |
| `@State var state` | `@ObservableState struct State` | @State is Views-only |
| `Shared(value: data)` | `Shared(wrappedValue: data)` | Wrong constructor |
| Multiple @Shared writers | Single @Shared owner + @SharedReader | Prevents race conditions |
| Manual `.onReceive()` | `@Bindable` automatic observation | Built-in observation |

---

## @Shared Usage Discipline

### Single Owner Pattern
```swift
// ✅ CORRECT: Single owner that can write
@Reducer struct AuthenticationFeature {
  @Shared(.appStorage("auth")) var authState: AuthState

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .login:
        authState.isLoggedIn = true  // Can write
        return .none
      }
    }
  }
}

// ✅ CORRECT: Reader that can only read
@Reducer struct ProfileFeature {
  @SharedReader(.appStorage("auth")) var authState: AuthState

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .loadProfile:
        state.canEditProfile = authState.isLoggedIn  // Can only read
        return .none
      }
    }
  }
}
```

---

## Testing TCA Features

### Test Structure
```swift
@Test
func counterFeature() async {
  let store = TestStore(initialState: CounterFeature.State()) {
    CounterFeature()
  }

  await store.send(.incrementTapped) {
    $0.count = 1
  }

  await store.send(.decrementTapped) {
    $0.count = 0
  }
}
```

### @Shared Testing
```swift
@Test
func sharedStateMutation() async {
  @Shared(.fileStorage("test-settings.json")) var settings: AppSettings

  let store = TestStore(initialState: SettingsFeature.State()) {
    SettingsFeature()
  } dependencies: {
    $0.settings = settings
  }

  await store.send(.toggleDarkMode)
  #expect(settings.darkModeEnabled == true)
}
```

---

## TCA Decision Trees

### When to Use @Shared vs @Dependency
- **@Shared**: Cross-feature state, multiple simultaneous accessors
- **@Dependency**: Services, external APIs, single-purpose dependencies

### When to Extract Child Features
- Feature becomes >200 lines
- State has logical subsections
- Navigation flows are complex
- Multiple unrelated responsibilities

---

## Quick Reference

### Essential Imports
```swift
import ComposableArchitecture
import Dependencies  // For @DependencyClient usage
```

### Reducer Template
```swift
@Reducer
struct FeatureName {
  @ObservableState
  struct State: Equatable {
    // State properties
  }

  enum Action {
    // Actions
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Reducer logic
    }
    .ifLet(\.optionalState, action: \.optionalAction) {
      OptionalChildFeature()
    }
  }
}
```

### View Template
```swift
struct FeatureView: View {
  @Bindable var store: StoreOf<Feature>

  var body: some View {
    // View implementation
    Button("Action") {
      store.send(.action)
    }
  }
}
```

---

## Verification Checklist

### Reducer Validation
- [ ] Uses @Reducer macro
- [ ] State uses @ObservableState
- [ ] No @State usage in business logic
- [ ] Actions use enum, not struct
- [ ] Proper @Shared usage (single owner pattern)
- [ ] Dependency injection via @DependencyClient

### View Validation
- [ ] Uses @Bindable var store
- [ ] No WithViewStore usage
- [ ] Direct property access to store
- [ ] Proper navigation with .scope()
- [ ] No manual observation patterns

### Testing Validation
- [ ] Uses @Test and #expect()
- [ ] TCA tests marked @MainActor
- [ ] Proper @Shared testing patterns
- [ ] Dependency mocking when needed

---

**smith-tca provides modern, production-ready TCA patterns that prevent common mistakes and ensure maintainable Swift Composable Architecture applications.**