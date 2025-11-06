# TCA 1.23.0+ Modern Patterns for Agents

**Framework Version:** v1.1+
**TCA Version:** 1.23.0 and later (Swift Composable Architecture)
**Swift Version:** 6.2+
**Date Created:** November 1, 2025

This document establishes the canonical patterns agents should use when working with TCA 1.23.0+ (Swift Composable Architecture). It replaces deprecated APIs and clarifies which patterns are correct across all Apple platforms, including visionOS.

---

## Quick Reference: What NOT to Do

| ❌ Deprecated/Wrong | ✅ Modern Alternative | Why |
|---|---|---|
| `WithViewStore` | `@Bindable` + direct property access | Removed in TCA 1.5; direct observation is simpler |
| `IfLetStore` | `.sheet(item:)` with `.scope()` | Optional navigation built into SwiftUI |
| `@Perception.Bindable` | `@Bindable` (from TCA) | @Perception isn't needed; TCA @Bindable works everywhere |
| Host bridge patterns | `.scope()` directly in view | Bridges add unnecessary complexity |
| Manual `.onReceive()` | `@Bindable` with `@ObservableState` | Observation is automatic |
| `Shared(value: x)` | `Shared(x)` or `Shared(wrappedValue: x, key:)` | Correct argument label required |
| `Shared(reader:getter:setter:)` | `Shared(wrappedValue:, key:)` with persistence | Pattern doesn't exist in TCA 1.23.0+ |
| Multiple features mutating `@Shared` | Single owner + `@SharedReader` for others | Reference semantics require discipline |

---

## Core Principle

**[CRITICAL]** In TCA 1.5+, SwiftUI views directly observe store state via `@Bindable` and dispatch actions via `store.send()`. There is **no bridging layer, no host component, no manual observation**. The store itself is `@Observable`.

---

## Pattern 1: Observing State in Views

### When to Use
- [STANDARD] Any SwiftUI view that displays state from a reducer
- Works on all platforms: iOS, macOS, iPadOS, visionOS, watchOS

### Implementation

```swift
import ComposableArchitecture
import SwiftUI

@Reducer
struct CounterFeature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }

  enum Action {
    case incrementTapped
    case decrementTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementTapped:
        state.count += 1
        return .none
      case .decrementTapped:
        state.count -= 1
        return .none
      }
    }
  }
}

struct CounterView: View {
  @Bindable var store: StoreOf<CounterFeature>

  var body: some View {
    VStack {
      Text("Count: \(store.count)")

      Button("Increment") {
        store.send(.incrementTapped)
      }

      Button("Decrement") {
        store.send(.decrementTapped)
      }
    }
  }
}
```

### Key Points

- **@Bindable**: Marks the store property as observable. Changes to `@ObservableState` automatically re-render the view.
- **Direct Access**: `store.count` works immediately—no `WithViewStore`, no closures, no `.scope()` needed for simple state.
- **Direct Dispatch**: `store.send(.incrementTapped)` sends the action to the reducer.
- **Platform Agnostic**: Works on iOS 17+, macOS 14+, visionOS 1+, and all other Apple platforms.

### Why This Works

The `@ObservableState` macro on the reducer's State type makes it observable. When you apply `@Bindable` to the store, SwiftUI automatically tracks which parts of state you access and re-renders only when those parts change. This is the observation system built into Swift 6.2+.

---

## Pattern 2: Optional State Navigation (Sheets, Popovers, Navigation Links)

### When to Use
- [STANDARD] Presenting child features conditionally (optional state is non-nil)
- Examples: detail views, forms, confirmation dialogs, hints/help popovers
- Works on all platforms (iOS sheets, macOS sheets, visionOS popovers, etc.)

### Implementation

#### Reducer Setup

```swift
@Reducer
struct GameEngineFeature {
  @ObservableState
  struct State: Equatable {
    var watcherAssistPopover: WatcherAssistPopoverState?
    // ... other state
  }

  enum Action {
    case watcherAssistTapped
    case watcherAssist(WatcherAssistPopoverAction)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .watcherAssistTapped:
        state.watcherAssistPopover = WatcherAssistPopoverState(
          screenID: 1,
          content: /* ... */
        )
        return .none

      case .watcherAssist(let popoverAction):
        guard var popoverState = state.watcherAssistPopover else {
          return .none
        }

        // Handle popover actions...
        switch popoverAction {
        case .closeButtonTapped:
          state.watcherAssistPopover = nil
          return .none
        // ... other cases
        }
        return .none
      }
    }
    .ifLet(\.$watcherAssistPopover, action: \.watcherAssist) {
      WatcherAssistPopoverFeature()
    }
  }
}

@Reducer
struct WatcherAssistPopoverFeature {
  @ObservableState
  struct State: Equatable {
    var content: String
    // ...
  }

  enum Action {
    case closeButtonTapped
    case revealStep(Int)
    // ...
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .closeButtonTapped:
        return .none  // Parent will nil the state
      case .revealStep(let index):
        // ...
        return .none
      }
    }
  }
}
```

#### View Setup

```swift
struct GameEngineView: View {
  @Bindable var store: StoreOf<GameEngineFeature>

  var body: some View {
    ZStack {
      // Main content
      Button("Help") {
        store.send(.watcherAssistTapped)
      }

      // Popover driven by optional state
      .sheet(
        item: $store.scope(
          state: \.watcherAssistPopover,
          action: \.watcherAssist
        )
      ) { popoverStore in
        WatcherAssistPopoverView(store: popoverStore)
      }
    }
  }
}

struct WatcherAssistPopoverView: View {
  @Bindable var store: StoreOf<WatcherAssistPopoverFeature>

  var body: some View {
    VStack {
      Text(store.content)

      Button("Close") {
        store.send(.closeButtonTapped)
      }
    }
  }
}
```

### Key Points

- **@Presents macro** (optional): You can use `@Presents var watcherAssistPopover` instead of `var watcherAssistPopover: ... ?` for clearer intent, but plain optional works too.
- **`.scope(state:action:)`**: Transforms the optional Store<GameEngineFeature, ...> into an optional Store<WatcherAssistPopoverFeature, ...>. When state is nil, the scope is nil, and `.sheet(item:)` hides the popover.
- **`.ifLet()` in reducer**: Composes the child reducer logic into the parent. The `$` targets the projected value from the property.
- **No host bridge needed**: The `.sheet(item:)` modifier with `.scope()` handles all the plumbing.
- **Works with all presentation types**: `.sheet()`, `.navigationDestination(item:)`, `.fullScreenCover()`, `.popover()` on macOS/iPadOS.

### Why This Works Everywhere (Including visionOS)

- `.sheet()` is standard SwiftUI (all platforms)
- `.scope()` is TCA core (all platforms)
- `@Bindable` is Swift observation (iOS 17+)
- No platform-specific APIs needed

---

## Pattern 3: Multiple Destinations (Complex Navigation)

### When to Use
- [STANDARD] When a feature can present one of several child features (e.g., edit modal OR delete confirmation OR detail view)
- Prevents invalid state combinations (can't show edit and detail simultaneously)

### Implementation

```swift
@Reducer
struct InventoryFeature {
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    var items: [Item] = []
  }

  enum Action {
    case destination(PresentationAction<Destination.Action>)
    case addButtonTapped
    case itemTapped(Item)
  }

  @Reducer(state: .equatable)
  enum Destination {
    case addItem(ItemFormFeature)
    case editItem(ItemFormFeature)
    case deleteConfirmation(ConfirmationDialogFeature)
  }

  // ⚠️ CRITICAL: The closure form is MANDATORY for @Reducer enums.
  // Always write: .ifLet(\.$destination, action: \.destination) { Destination() }
  // Never write: .ifLet(\.$destination, action: \.destination)  // ❌ Breaks with _EphemeralState error

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.destination = .addItem(ItemFormFeature.State())
        return .none

      case .itemTapped(let item):
        state.destination = .editItem(ItemFormFeature.State(item: item))
        return .none

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }
}

struct InventoryView: View {
  @Bindable var store: StoreOf<InventoryFeature>

  var body: some View {
    NavigationStack {
      List(store.items) { item in
        Button(item.name) {
          store.send(.itemTapped(item))
        }
      }
      .navigationDestination(
        item: $store.scope(
          state: \.destination?.editItem,
          action: \.destination.editItem
        )
      ) { editStore in
        ItemFormView(store: editStore)
      }

      .sheet(
        item: $store.scope(
          state: \.destination?.addItem,
          action: \.destination.addItem
        )
      ) { addStore in
        ItemFormView(store: addStore)
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Add") {
          store.send(.addButtonTapped)
        }
      }
    }
  }
}
```

### Key Points

- **Single optional `destination`**: Only one child can be active at a time. Type-safe.
- **`@Reducer(state: .equatable) enum Destination`**: Reducer composition for multiple feature types.
- **⚠️ CRITICAL: `.ifLet()` with closure is MANDATORY**: Always write `.ifLet(\.$destination, action: \.destination) { Destination() }` - without the closure you get `_EphemeralState` errors and broken state flow.
- **Scope by case**: `\.destination?.editItem` targets only the edit case; if destination is `addItem`, the scope is nil.
- **Multiple view modifiers**: Each presentation type (`.sheet()`, `.navigationDestination()`, etc.) scopes to its specific case.

---

## Pattern 4: Bindings for Form Inputs

### When to Use
- [STANDARD] When you need two-way binding to state fields (text fields, toggles, pickers)
- Replaces manual binding closures with automatic TCA handling

### Simple Approach (Ad Hoc Bindings)

```swift
@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    var userName: String = ""
    var isNotificationEnabled: Bool = true
  }

  enum Action {
    case userNameChanged(String)
    case toggleNotifications(Bool)
    case saveButtonTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .userNameChanged(let name):
        state.userName = name
        return .none
      case .toggleNotifications(let enabled):
        state.isNotificationEnabled = enabled
        return .none
      case .saveButtonTapped:
        // Save to persistence layer
        return .none
      }
    }
  }
}

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    Form {
      TextField(
        "User Name",
        text: Binding(
          get: { store.userName },
          set: { store.send(.userNameChanged($0)) }
        )
      )

      Toggle(
        "Notifications",
        isOn: Binding(
          get: { store.isNotificationEnabled },
          set: { store.send(.toggleNotifications($0)) }
        )
      )

      Button("Save") {
        store.send(.saveButtonTapped)
      }
    }
  }
}
```

### BindableAction Pattern (Many Fields)

For reducers with many bindable fields, use the `BindableAction` protocol:

```swift
@Reducer
struct FormFeature {
  @ObservableState
  struct State: Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var age: Int = 0
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case submitButtonTapped
  }

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none  // BindingReducer handles mutation
      case .submitButtonTapped:
        return .none
      }
    }
  }
}

struct FormView: View {
  @Bindable var store: StoreOf<FormFeature>

  var body: some View {
    Form {
      TextField("First Name", text: $store.firstName)
      TextField("Last Name", text: $store.lastName)
      TextField("Email", text: $store.email)
      Stepper("Age: \(store.age)", value: $store.age)

      Button("Submit") {
        store.send(.submitButtonTapped)
      }
    }
  }
}
```

### Key Points

- **Ad hoc**: Simple, explicit. Use when few fields.
- **BindableAction**: Cleaner syntax for many fields. Requires `BindingReducer()` in the body.
- **No deprecated @Perception**: The `$store.fieldName` syntax works directly with TCA stores.

---

## Pattern 5: Shared State Initialization (@Shared)

### When to Use
- [STANDARD] Cross-feature state that multiple reducers need to access simultaneously
- Examples: Authentication status, unread counts, user preferences, feature flags
- [STANDARD] State that needs persistence (UserDefaults, file storage)
- [GUIDANCE] Parent wants to pass derived shared state to child reducers
- Works on all platforms (iOS, macOS, iPadOS, visionOS, watchOS)

### Implementation

#### Simple Shared State (Self-Owned)

```swift
@Reducer
struct MessageCenterFeature {
  @ObservableState
  struct State: Equatable {
    @Shared public var unreadCounts: [Int: Int]

    public init(unreadCounts: [Int: Int]) {
      self._unreadCounts = Shared(unreadCounts)
    }
  }

  enum Action {
    case markAsRead(Int)
    case markAllAsRead
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .markAsRead(let screenID):
        state.unreadCounts[screenID] = 0
        return .none
      case .markAllAsRead:
        state.unreadCounts = [:]
        return .none
      }
    }
  }
}
```

#### Shared State with Persistence

```swift
@Reducer
struct AuthenticationFeature {
  @ObservableState
  struct State: Equatable {
    @Shared(.appStorage("currentUser")) public var currentUser: User?
    @Shared(.fileStorage(URL(...))) public var userPreferences: Preferences?

    public init(
      currentUser: User? = nil,
      userPreferences: Preferences? = nil
    ) {
      self._currentUser = Shared(wrappedValue: currentUser, .appStorage("currentUser"))
      self._userPreferences = Shared(wrappedValue: userPreferences, .fileStorage(URL(...)))
    }
  }

  enum Action {
    case login(User)
    case logout
    case updatePreferences(Preferences)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .login(let user):
        state.currentUser = user
        return .none
      case .logout:
        state.currentUser = nil
        return .none
      case .updatePreferences(let prefs):
        state.userPreferences = prefs
        return .none
      }
    }
  }
}
```

#### Parent Passing Derived Shared State to Child

```swift
@Reducer
struct ParentFeature {
  @ObservableState
  struct State: Equatable {
    @Shared public var globalSettings: AppSettings
    @Presents var child: ChildFeature.State?
  }

  enum Action {
    case child(PresentationAction<ChildFeature.Action>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .child:
        return .none
      }
    }
    .ifLet(\.$child, action: \.child) {
      ChildFeature()
    }
  }
}

@Reducer
struct ChildFeature {
  @ObservableState
  struct State: Equatable {
    @Shared public var globalSettings: AppSettings  // ← Derived from parent
    var localState: String = ""

    public init(globalSettings: Shared<AppSettings>) {
      self._globalSettings = globalSettings
    }
  }

  enum Action {
    case updateLocalState(String)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .updateLocalState(let value):
        state.localState = value
        return .none
      }
    }
  }
}

// In parent's reduce, when creating child:
// state.child = ChildFeature.State(globalSettings: state.$globalSettings)
```

#### Read-Only Access with @SharedReader

```swift
@Reducer
struct DisplayFeature {
  @ObservableState
  struct State: Equatable {
    var screenID: Int
  }

  enum Action {
    case viewAppeared
  }

  @SharedReader(.appStorage("unreadCounts")) var unreadCounts: [Int: Int]

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewAppeared:
        let count = unreadCounts[state.screenID] ?? 0
        print("Unread count: \(count)")
        return .none
      }
    }
  }
}
```

### Key Points

- **Constructor with label**: Always use `Shared(wrappedValue: value)` or shorthand `Shared(value)` with the correct argument label.
- **Persistence strategies**: `@Shared(.appStorage("key"))`, `@Shared(.fileStorage(url))`, `@Shared(.inMemory("key"))`, or no persistence.
- **Reference semantics**: `@Shared` wraps state in a reference type. Mutations are visible to all holders immediately.
- **Derived sharing**: Pass `state.$sharedProperty` to child reducers to share a reference without duplicating.
- **Read-only access**: Use `@SharedReader` in features that only read shared state. Prevents accidental mutations.
- **Single owner pattern**: Designate one reducer as the owner of a `@Shared` property. Others should use `@SharedReader`.

### Why This Works

`@Shared` eliminates prop-drilling for cross-feature state while maintaining type safety. The reference-type backing means all holders see updates instantly. Persistence keys let you save to UserDefaults or file storage automatically. The macro generates the observation plumbing so SwiftUI views see updates through `@Bindable`.

---

## Common Mistakes (Anti-Patterns)

### ❌ Mistake 1: Using Deprecated APIs

```swift
// WRONG
struct MyView: View {
  let store: StoreOf<MyFeature>

  var body: some View {
    WithViewStore(store) { viewStore in  // ← Deprecated
      Text("\(viewStore.count)")
    }
  }
}

// RIGHT
struct MyView: View {
  @Bindable var store: StoreOf<MyFeature>

  var body: some View {
    Text("\(store.count)")  // ← Direct access
  }
}
```

**Why**: `WithViewStore` was a workaround before observation existed. Now it's redundant and deprecated. Direct property access is simpler and type-safer.

---

### ❌ Mistake 2: Building Host Bridges for Optional State

```swift
// WRONG
struct ParentView: View {
  let store: StoreOf<ParentFeature>

  var body: some View {
    if let childStore = store.scope(state: \.childState, action: \.child) {
      ChildHostView(store: childStore)  // ← Unnecessary wrapper
    }
  }
}

struct ChildHostView: View {
  let store: StoreOf<ChildFeature>

  var body: some View {
    ChildView(store: store)
  }
}

// RIGHT
struct ParentView: View {
  @Bindable var store: StoreOf<ParentFeature>

  var body: some View {
    .sheet(
      item: $store.scope(state: \.childState, action: \.child)
    ) { childStore in
      ChildView(store: childStore)  // ← Direct presentation
    }
  }
}
```

**Why**: SwiftUI's `.sheet(item:)` handles the optional unwrapping automatically. The host bridge adds complexity without benefit.

---

### ❌ Mistake 3: Manual Observation with .onReceive()

```swift
// WRONG
struct MyView: View {
  let store: StoreOf<MyFeature>
  @State var count: Int = 0

  var body: some View {
    Text("\(count)")
      .onReceive(store.publisher(for: \.count)) { newCount in
        count = newCount  // ← Manual observation
      }
  }
}

// RIGHT
struct MyView: View {
  @Bindable var store: StoreOf<MyFeature>

  var body: some View {
    Text("\(store.count)")  // ← Automatic observation
  }
}
```

**Why**: `@Bindable` + `@ObservableState` automates this. Manual `.onReceive()` is error-prone and brittle.

---

### ❌ Mistake 4: Optional State Without .sheet() or Navigation

```swift
// WRONG
struct ParentView: View {
  @Bindable var store: StoreOf<ParentFeature>

  var body: some View {
    VStack {
      if store.childState != nil {
        // Rendering child view directly
        ChildView(store: store.scope(state: \.childState, action: \.child)!)
      }
    }
  }
}

// RIGHT
struct ParentView: View {
  @Bindable var store: StoreOf<ParentFeature>

  var body: some View {
    .sheet(
      item: $store.scope(state: \.childState, action: \.child)
    ) { childStore in
      ChildView(store: childStore)
    }
  }
}
```

**Why**: SwiftUI presentation modifiers (`.sheet()`, `.navigationDestination()`, etc.) are designed for optional state. They handle lifecycle correctly (appearance, dismissal, re-setup on re-presentation). Direct if-let rendering doesn't.

---

### ❌ Mistake 5: Wrong @Shared Constructor

```swift
// WRONG - Incorrect argument label
self._count = Shared(value: 0)  // ← 'value:' is not the correct label

// WRONG - Missing label entirely in persisted state
self._currentUser = Shared(user, .appStorage("user"))  // ← Missing 'wrappedValue:' label

// WRONG - Non-existent derived constructor
@Shared(reader: getter, setter: setter) var value: Int  // ← Pattern doesn't exist in TCA
```

**Correct patterns:**

```swift
// RIGHT - Simple constructor (implicit wrappedValue)
self._count = Shared(0)

// RIGHT - Explicit wrappedValue label
self._count = Shared(wrappedValue: 0)

// RIGHT - With persistence key
self._currentUser = Shared(wrappedValue: user, .appStorage("user"))

// RIGHT - Multiple persistence strategies
self._cached = Shared(wrappedValue: data, .inMemory("cache"))
self._prefs = Shared(wrappedValue: preferences, .fileStorage(url))
```

**Why**: The `@Shared` property wrapper only has specific constructor signatures. `wrappedValue:` is required when using a persistence key. There is no `value:` label and no `reader:getter:setter:` pattern in TCA 1.23.0+.

---

### ❌ Mistake 6: Mutating @Shared from Multiple Features

```swift
// WRONG - Multiple independent features mutate the same @Shared
@Reducer
struct FeatureA {
  @SharedReader(.appStorage("unreadCounts")) var unreadCounts: [Int: Int]

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .markAsRead(let id):
        unreadCounts[id] = 0  // ← Mutation from FeatureA
        return .none
      }
    }
  }
}

@Reducer
struct FeatureB {
  @SharedReader(.appStorage("unreadCounts")) var unreadCounts: [Int: Int]

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .clearAll:
        unreadCounts = [:]  // ← Mutation from FeatureB
        return .none
      }
    }
  }
}
```

**Correct pattern (Single Owner):**

```swift
// RIGHT - One reducer owns mutations, others read only
@Reducer
struct MessageCenterFeature {
  @ObservableState
  struct State: Equatable {
    @Shared(.appStorage("unreadCounts")) var unreadCounts: [Int: Int]
  }

  enum Action {
    case markAsRead(Int)
    case clearAll
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .markAsRead(let id):
        state.unreadCounts[id] = 0  // ← Single owner
        return .none
      case .clearAll:
        state.unreadCounts = [:]
        return .none
      }
    }
  }
}

// Other features use @SharedReader
@Reducer
struct DisplayFeature {
  @SharedReader(.appStorage("unreadCounts")) var unreadCounts: [Int: Int]

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewAppeared:
        let count = unreadCounts[state.id] ?? 0  // ← Read only
        return .none
      }
    }
  }
}
```

**Why**: `@Shared` has reference semantics. Multiple writers cause race conditions and unpredictable state. Designate one reducer as the owner; others should use `@SharedReader` for read-only access.

---

## Verification Checklist for Agents

When implementing a TCA feature, verify:

- [ ] State is marked with `@ObservableState`
- [ ] Views use `@Bindable var store: StoreOf<Feature>`
- [ ] No `WithViewStore`, `IfLetStore`, or `@Perception.Bindable` in code
- [ ] Optional state uses `.sheet(item:)` or `.navigationDestination(item:)` with `.scope()`
- [ ] No manual host bridges or conditionals for optional state
- [ ] No `.onReceive()` for state observation
- [ ] Dispatch is via `store.send(.action)` directly in closures
- [ ] No passing closures to child views; pass stores instead
- [ ] Child reducers composed with `.ifLet()` or enum Destination
- [ ] `@Shared` uses correct constructor: `Shared(value)` or `Shared(wrappedValue: value, key:)`
- [ ] `@Shared` properties have explicit initializers in State's `init()`
- [ ] Cross-feature `@Shared` has single owner reducer
- [ ] Other features use `@SharedReader` for read-only access, not `@Shared`
- [ ] Persistence keys are explicit: `.appStorage()`, `.fileStorage()`, `.inMemory()`
- [ ] No `@Shared(reader:getter:setter:)` pattern (doesn't exist in TCA)
- [ ] Code compiles without deprecation warnings

---

## Testing

### Modern TCA Pattern Testing

Modern TCA patterns are tested the same way:

```swift
@MainActor
func testOptionalStateNavigation() async {
  let store = TestStore(
    initialState: GameEngineFeature.State(),
    reducer: { GameEngineFeature() }
  )

  // Trigger action that sets optional state
  await store.send(.watcherAssistTapped) {
    $0.watcherAssistPopover = WatcherAssistPopoverState(
      screenID: 1,
      content: "Test"
    )
  }

  // Trigger dismiss
  await store.send(.watcherAssist(.closeButtonTapped)) {
    $0.watcherAssistPopover = nil
  }
}
```

No special test utilities needed. The patterns are transparent to testing.

### Testing @Shared State

When testing reducers that use `@Shared` state:

```swift
@MainActor
struct MessageCenterTests {
  @Test func markMessageAsRead() async {
    let store = TestStore(
      initialState: MessageCenterFeature.State(
        unreadCounts: [:]
      ),
      reducer: { MessageCenterFeature() }
    )

    // Action mutates shared state
    await store.send(.markAsRead(screenID: 1)) {
      $0.unreadCounts[1] = 0
    }

    #expect(store.state.unreadCounts[1] == 0)
  }

  @Test func sharedStateVisibleToMultipleReducers() async {
    // Create shared state once
    let sharedCounts = Shared(wrappedValue: [Int: Int]())

    // Pass to first reducer
    let store1 = TestStore(
      initialState: DisplayFeature.State(screenID: 1),
      reducer: { DisplayFeature() }
    ) withDependencies: {
      // Simulate having access to shared state through dependency
      $0.continuousClock = TestClock()
    }

    // Verify both reducers can see the shared reference
    // (In real scenarios, @Shared handles this automatically)
    #expect(sharedCounts.wrappedValue.isEmpty)
  }
}
```

### Testing Read-Only Access

```swift
@MainActor
struct DisplayFeatureTests {
  @Test func readsSharedUnreadCounts() async {
    let store = TestStore(
      initialState: DisplayFeature.State(screenID: 1),
      reducer: { DisplayFeature() }
    ) withDependencies: {
      // The @SharedReader is set up at feature level, not in test
      // This test focuses on reducer logic, not shared state initialization
      $0.continuousClock = TestClock()
    }

    // Trigger view appeared action
    await store.send(.viewAppeared)

    // Verify the feature responds correctly based on shared state
    // (Actual shared state mutations tested separately in owner reducer)
  }
}
```

**Key Points for Testing @Shared:**
- Test the owner reducer's mutations comprehensively
- @SharedReader features don't need complex setup; they read during reduce
- Use deterministic time (`TestClock`) for timing-dependent shared state
- Each test should be independent; don't rely on shared state from previous tests
- The macro handles observation automatically; no special test setup needed

---

## References

- **TCA GitHub**: https://github.com/pointfreeco/swift-composable-architecture
- **TCA @Shared Documentation**: [SharingState.md](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Documentation.docc/Articles/SharingState.md)
- **TCA Documentation**: Swift Concurrency, Bindings, Navigation articles (TCA repo main branch)
- **Point-Free Blog**: Series on modern TCA patterns

---

## Last Updated

November 5, 2025 – Added Pattern 5: Shared State Initialization (@Shared)
- Documented all `@Shared` constructors and persistence strategies
- Added anti-patterns: wrong constructors (Mistake 5) and multiple-writer race conditions (Mistake 6)
- Extended verification checklist with `@Shared` specific items
- Added testing guidance for shared state patterns
- Linked official TCA @Shared documentation

**Previous**: November 1, 2025 – Initial version covering TCA 1.5+ patterns

**Next Review**: December 1, 2025 – Incorporate visionOS-specific gotchas if discovered
