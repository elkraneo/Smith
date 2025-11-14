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

## Pattern 2.1: Conditional UI Elements (Toolbar Items, Buttons, etc.)

### When to Use
- [STANDARD] Showing/hiding UI elements based on state conditions
- Examples: conditional toolbar buttons, conditional form fields, conditional UI sections
- **NOT** for presenting modals, sheets, or navigation destinations

### Implementation

#### Conditional Toolbar Items (CORRECT)

```swift
@Reducer
struct ListFeature {
    @ObservableState
    struct State {
        var items: [Item] = []
        var hasSelection = false
        var canEdit = false
    }

    enum Action {
        case selectItem(Item?)
        case deleteSelected
        case editSelected
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .selectItem(let item):
                state.hasSelection = item != nil
                state.canEdit = item?.isEditable ?? false
                return .none

            case .deleteSelected:
                // Delete logic here
                return .none

            case .editSelected:
                // Edit logic here
                return .none
            }
        }
    }
}

struct ListView: View {
    @Bindable var store: StoreOf<ListFeature>

    var body: some View {
        List(store.items, id: \.id, selection: $store.selection) { item in
            Text(item.title)
        }
        .toolbar {
            // ✅ CORRECT: Conditional toolbar items based on state
            ToolbarItemGroup(placement: .bottomBar) {
                if store.hasSelection {
                    Button("Delete") {
                        store.send(.deleteSelected)
                    }
                }

                if store.canEdit {
                    Button("Edit") {
                        store.send(.editSelected)
                    }
                }
            }
        }
    }
}
```

### Key Points

- **Simple `if` statements**: Use `if store.condition` for conditional UI elements
- **No `.sheet()` or `.navigationDestination()`**: Those are for presentation state, not UI state
- **State-driven**: UI visibility should be driven by reducer state
- **ToolbarItemGroup**: Use for multiple conditional toolbar items
- **Placement**: Choose appropriate toolbar placement for platform

### ❌ Common Mistake: Using Presentation Modifiers for UI State

```swift
// ❌ WRONG: Using .sheet() for conditional toolbar item
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        .sheet(item: $store.scope(state: \.deleteButton)) { deleteStore in  // ❌ WRONG
            Button("Delete") {
                store.send(.deleteButtonTapped)
            }
        }
    }
}

// ✅ CORRECT: Simple conditional rendering
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        if store.shouldShowDeleteButton {  // ✅ CORRECT
            Button("Delete") {
                store.send(.deleteButtonTapped)
            }
        }
    }
}
```

**Why this distinction matters:**
- **Presentation state**: Needs lifecycle management (appearance/dismissal animations)
- **UI state**: Simple show/hide based on boolean conditions
- **Performance**: Presentation modifiers have overhead
- **Correct semantics**: Different UI patterns for different purposes

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

## Pattern 6: Delegate Action Flow (Parent-Child Communication)

**Use case:** Child reducer needs to communicate events to parent (navigation, completion, errors, state changes that affect parent).

**Key Principle:** Delegates flow UP the hierarchy exactly once. Child sends `.delegate(X)`, parent handles it and MAY send `.delegate(Y)` to its parent (different action). Never re-forward the same delegate.

### The Pattern

```swift
// ✅ CORRECT: Child sends delegate, parent maps to its own delegate

// Child Feature
@Reducer
public struct ChildFeature {
  @ObservableState
  public struct State: Equatable {
    public var isLoading: Bool = false
    public var result: String = ""
  }

  public enum Action: Sendable {
    case buttonTapped
    case taskCompleted(String)

    // Delegate actions for parent communication
    public enum Delegate: Sendable {
      case completed(result: String)
      case cancelled
      case errorOccurred(Error)
    }
    case delegate(Delegate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .buttonTapped:
        state.isLoading = true
        return .run { send in
          let result = await performTask()
          await send(.taskCompleted(result))
        }

      case .taskCompleted(let result):
        // Do child-specific cleanup
        state.isLoading = false
        state.result = result
        // Send ONE delegate UP to parent
        return .send(.delegate(.completed(result: result)))

      case .delegate:
        // Child never handles its own delegates
        return .none
      }
    }
  }
}

// Parent Feature
@Reducer
public struct ParentFeature {
  @ObservableState
  public struct State: Equatable {
    @Presents var child: ChildFeature.State?
    public var childResults: [String] = []
  }

  public enum Action: Sendable {
    case showChild
    case child(PresentationAction<ChildFeature.Action>)

    // Parent's own delegates (different from child's)
    public enum Delegate: Sendable {
      case allTasksCompleted(results: [String])
      case workflowCancelled
    }
    case delegate(Delegate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showChild:
        state.child = ChildFeature.State()
        return .none

      // ✅ CORRECT: Map child delegate to parent delegate (different action)
      case .child(.presented(.delegate(.completed(let result)))):
        state.child = nil  // Clean up child state
        state.childResults.append(result)

        // Send NEW delegate to grandparent (if needed)
        if state.childResults.count >= 3 {
          return .send(.delegate(.allTasksCompleted(results: state.childResults)))
        }
        return .none

      case .child(.presented(.delegate(.cancelled))):
        state.child = nil
        // Send different delegate to grandparent
        return .send(.delegate(.workflowCancelled))

      case .child(.presented(.delegate(.errorOccurred))):
        state.child = nil
        // Handle error, don't propagate to grandparent
        return .none

      // ❌ NEVER DO THIS:
      // case .delegate(.allTasksCompleted):
      //   return .send(.delegate(.allTasksCompleted))  // INFINITE LOOP!

      case .delegate:
        // Parent never handles its own delegates (grandparent does)
        return .none
      }
    }
    .ifLet(\.$child, action: \.child) {
      ChildFeature()
    }
  }
}
```

### Anti-Pattern: Delegate Re-Forwarding

```swift
// ❌ WRONG: Re-forwarding same delegate creates infinite loop
@Reducer
public struct BadParent {
  public enum Action {
    case child(PresentationAction<ChildFeature.Action>)
    public enum Delegate {
      case taskCompleted(String)  // ← Same as child's delegate!
    }
    case delegate(Delegate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // ❌ WRONG: Re-forwarding same delegate
      case .delegate(.taskCompleted(let result)):
        // Some logic...
        return .send(.delegate(.taskCompleted(result)))  // INFINITE LOOP!

      // ❌ WRONG: Mapping child delegate to same name in parent
      case .child(.presented(.delegate(.completed(let result)))):
        // Cleans up child...
        return .send(.delegate(.taskCompleted(result)))  // Then triggers above!
      }
    }
  }
}
```

**Why this is wrong:**
1. `case .delegate(.taskCompleted)` sends `.send(.delegate(.taskCompleted))`
2. Which triggers `case .delegate(.taskCompleted)` again
3. Infinite loop, app hangs or crashes

### Verification Checklist

Use this checklist before merging any parent-child reducer integration:

- [ ] Child reducer sends `.delegate(X)` to communicate with parent
- [ ] Parent handles `.delegate(X)` in `case .child(.presented(.delegate(X))):`
- [ ] Parent does NOT have `case .delegate(X): return .send(.delegate(X))`
- [ ] Parent MAY send `.delegate(Y)` to its parent (different action name)
- [ ] Delegate enum names are unique per reducer level (no collisions)
- [ ] No action appears in BOTH `case .delegate(X):` and `.send(.delegate(X))`
- [ ] TestStore test includes `await store.finish()` to catch infinite loops

### Testing Strategy

```swift
@Test @MainActor
func childDelegateMappedToParent() async {
  let store = TestStore(initialState: ParentFeature.State()) {
    ParentFeature()
  }

  // Show child
  await store.send(.showChild) {
    $0.child = ChildFeature.State()
  }

  // Trigger child action that sends delegate
  await store.send(.child(.presented(.taskCompleted("result")))) {
    $0.child?.isLoading = false
    $0.child?.result = "result"
  }

  // ✅ Verify child sends delegate
  await store.receive(\.child.presented.delegate.completed) { result in
    #expect(result == "result")
  }

  // ✅ Verify parent maps to its own delegate
  await store.receive(\.child.dismiss) {
    $0.child = nil
    $0.childResults = ["result"]
  }

  // ✅ No infinite effects (this would hang if loop exists)
  await store.finish()
}

@Test @MainActor
func delegateDoesNotCreateInfiniteLoop() async {
  let store = TestStore(initialState: ParentFeature.State()) {
    ParentFeature()
  }

  await store.send(.showChild)
  await store.send(.child(.presented(.taskCompleted("test"))))

  // ✅ If there's an infinite loop, .finish() will timeout
  await store.finish()  // Pass = no loop, Timeout = loop detected
}
```

### Common Patterns

#### Pattern A: Terminal Delegate (No Propagation)

```swift
case .child(.presented(.delegate(.cancelled))):
  state.child = nil
  // ✅ Handle locally, don't send to grandparent
  return .none
```

#### Pattern B: Mapped Delegate (Propagate with Different Name)

```swift
case .child(.presented(.delegate(.completed(let result)))):
  state.child = nil
  state.results.append(result)
  // ✅ Send different delegate to grandparent
  return .send(.delegate(.workflowStepCompleted(result: result)))
```

#### Pattern C: Conditional Delegate (Only Propagate Sometimes)

```swift
case .child(.presented(.delegate(.itemSelected(let id)))):
  state.child = nil
  state.selectedItems.append(id)

  // ✅ Only send delegate when threshold reached
  if state.selectedItems.count >= 5 {
    return .send(.delegate(.selectionComplete(ids: state.selectedItems)))
  }
  return .none
```

### Key Points

- **Flow direction:** Delegates always flow UP (child → parent → grandparent)
- **Mapping:** Parent maps child delegates to its own delegates (different names)
- **Never re-forward:** Never `case .delegate(X): return .send(.delegate(X))`
- **Unique names:** Each reducer level has unique delegate enum
- **Testing:** Use `await store.finish()` to catch infinite loops
- **Terminal actions:** Some delegates handled locally, not propagated

### Why This Works

Delegate actions separate **internal reducer logic** from **parent communication**. Child reducers can evolve independently while maintaining a stable delegate API. Parents decide how to interpret child delegates without coupling to child implementation details. This prevents tight coupling and makes reducers composable and testable.

**Reference:** See DISCOVERY-12 for real-world example of delegate re-forwarding causing infinite loops.

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

**Why**: SwiftUI presentation modifiers (`.sheet()`, `.navigationDestination()`, etc.) are designed for **presentation state** (modals, sheets, navigation destinations). They handle lifecycle correctly (appearance, dismissal, re-setup on re-presentation).

**Note**: This applies to presentation state only, not conditional UI elements like toolbar items. Use simple `if` statements for conditional UI rendering:

```swift
// ✅ CORRECT: Conditional toolbar item (NOT presentation state)
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        if store.shouldShowDeleteButton {  // Conditional UI state
            Button("Delete") {
                store.send(.deleteButtonTapped)
            }
        }
    }
}

// ❌ WRONG: Don't use .sheet() for conditional UI elements
.sheet(item: $store.scope(state: \.deleteButton)) {  // This is for presentations, not UI state
    Button("Delete") { ... }
}
```

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
- [ ] Optional presentation state uses `.sheet(item:)` or `.navigationDestination(item:)` with `.scope()`
- [ ] Conditional UI elements use simple `if` statements (not presentation modifiers)
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

## Pattern 6: Nested @Reducer Extraction (VALIDATED)

### When to Use
- **[CRITICAL]** ANY time you have child reducers in navigation or modal presentation
- **[CRITICAL]** When using enum-based destinations with @Reducer
- **[CRITICAL]** Validated against actual Point-Free TCA examples

### 🚨 CRITICAL: Agent Anti-Patterns to Avoid

**These patterns cause catastrophic agent failure (VALIDATED as WRONG):**
```swift
// ❌ AGENT OVER-ENGINEERING (WRONG)
@Reducer
struct ParentFeature {
    enum Action {
        case child(ChildFeature.Action = ChildFeature.body)  // ❌ WRONG: .body not needed
    }

    enum Destination {
        case modal(ChildFeature.State = ChildFeature.body)  // ❌ WRONG: .body not needed
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in ... }
        .ifLet(\.$destination, action: \.destination) {
            Destination()  // ❌ WRONG: Closure not needed
        }
    }
}
```

### Implementation: Point-Free Validated Patterns (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN (VALIDATED)
@Reducer
struct ParentFeature {
    @ObservableState
    struct State {
        var childState: ChildFeature.State
        var destination: Destination?
    }

    enum Action {
        case child(ChildFeature.Action)      // ✅ SIMPLE: no .body extraction needed
        case destination(PresentationAction<Destination.Action>)
        case otherAction
    }

    @Reducer(state: .equatable)
    enum Destination {
        case modal(ChildFeature.State)      // ✅ SIMPLE: no .body extraction needed
        case settings(SettingsFeature.State) // ✅ SIMPLE DECLARATION
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .otherAction:
                return .none
            case .destination:
                return .none
            }
        }
        Scope(state: \.childState, action: \.child) {
            ChildFeature()
        }
        .ifLet(\.$destination, action: \.destination)  // ✅ SIMPLE: no closure needed
    }
}
```

### Navigation Stack Pattern (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN (VALIDATED)
@Reducer
struct SignUpFeature {
    @Reducer
    enum Path {
        case basics(BasicsFeature)           // ✅ SIMPLE: no .body
        case personalInfo(PersonalInfoFeature) // ✅ SIMPLE DECLARATION
        case summary(SummaryFeature)
        case topics(TopicsFeature)
    }

    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        @Shared var signUpData: SignUpData
    }

    enum Action {
        case path(StackActionOf<Path>)       // ✅ SIMPLE: no .body extraction
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .path(.element(id: _, action: .topics(.delegate(.stepFinished)))):
                state.path.append(.summary(SummaryFeature.State(signUpData: state.$signUpData)))
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)     // ✅ SIMPLE: no closure needed
    }
}
```

### Multiple Destinations Pattern (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN (VALIDATED)
@Reducer
struct MultipleDestinations {
    @Reducer
    enum Destination {
        case drillDown(Counter)              // ✅ SIMPLE: no .body
        case popover(Counter)                // ✅ SIMPLE DECLARATION
        case sheet(Counter)
    }

    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>) // ✅ SIMPLE
        case showDrillDown
        case showPopover
        case showSheet
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .showDrillDown:
                state.destination = .drillDown(Counter.State())
                return .none
            case .showPopover:
                state.destination = .popover(Counter.State())
                return .none
            case .showSheet:
                state.destination = .sheet(Counter.State())
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)  // ✅ SIMPLE: no closure needed
    }
}
```

### Extension Conformance (REACTIVE, NOT PROACTIVE)

```swift
@Reducer
struct ChildFeature {
    @ObservableState
    struct State {
        var value: Int
        var items: [String]
    }

    enum Action {
        case load
        case loaded([String])
        case dismiss
    }

    var body: some Reducer<State, Action> { ... }
}

// ❌ DON'T ADD PROACTIVELY:
// extension ChildFeature.State: Equatable {}
// extension ChildFeature.Action: Sendable {}

// ✅ ONLY ADD WHEN COMPILER COMPLAINS:
// If you get "Type 'ChildFeature.State' does not conform to Equatable"
// THEN add: extension ChildFeature.State: Equatable {}
```

### Agent Simplification Rules

#### Rule 1: Copy Point-Free Examples Literally
```swift
// ✅ COPY THIS EXACT PATTERN:
@Reducer
enum Destination {
    case child(ChildFeature)                // ✅ SIMPLE
}

enum Action {
    case destination(PresentationAction<Destination.Action>) // ✅ SIMPLE
}

var body: some Reducer<State, Action> {
    Reduce { state, action in ... }
    .ifLet(\.$destination, action: \.destination)  // ✅ SIMPLE
}
```

#### Rule 2: Compile First, Fix Second
```bash
# 1. Build first, see what actually breaks
xcodebuild build -scheme MyScheme

# 2. If it compiles: ✅ YOU'RE DONE
# 3. If you get errors: fix ONLY what breaks
```

#### Rule 3: Extensions Only When Required
```swift
// ❌ DON'T ADD BY DEFAULT
// extension MyFeature.State: Equatable {}

// ✅ ONLY ADD WHEN COMPILER SAYS:
// error: type 'MyFeature.State' does not conform to protocol 'Equatable'
// THEN: extension MyFeature.State: Equatable {}
```

### Verification Checklist for Nested @Reducer

Before committing nested @Reducer code:

- [ ] **Simple enum cases**: `case child(ChildFeature.State)` (no `= .body`)
- [ ] **Simple actions**: `case child(ChildFeature.Action)` (no `= .body`)
- [ ] **Simple composition**: `.ifLet(\.$destination, action: \.destination)` (no closure)
- [ ] **Extensions only when needed**: Add only if compiler complains
- [ ] **Preview constructible**: Can create state without compilation errors
- [ ] **Follows Point-Free examples**: Looks like official TCA examples

### Agent Workflow for Nested @Reducer

1. **Start with Point-Free template**: Copy the simple patterns exactly
2. **Compile first**: See what actually breaks before adding complexity
3. **Fix only what breaks**: Don't add extensions proactively
4. **Test preview construction**: Verify #Preview works
5. **Run verification checklist**: All items must pass

**This prevents the catastrophic agent confidence destruction cascade by using proven Point-Free patterns that work.**

**Source**: Validated against Point-Free TCA examples in `/Examples/CaseStudies/SwiftUICaseStudies/`

---

## References

- **TCA GitHub**: https://github.com/pointfreeco/swift-composable-architecture
- **TCA @Shared Documentation**: [SharingState.md](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Documentation.docc/Articles/SharingState.md)
- **TCA Documentation**: Swift Concurrency, Bindings, Navigation articles (TCA repo main branch)
- **Point-Free Blog**: Series on modern TCA patterns

---

## Last Updated

November 13, 2025 – CORRECTED Pattern 6: Nested @Reducer Extraction (VALIDATED)
- **CRITICAL**: Corrected nested @Reducer patterns after validating against actual Point-Free TCA examples
- **FIXED**: Removed incorrect `= .body` syntax that doesn't exist in Point-Free patterns
- **FIXED**: Removed unnecessary closure forms for `.ifLet` and `.forEach`
- **FIXED**: Changed from proactive to reactive extension conformance (add only when compiler complains)
- **VALIDATED**: All patterns now match actual Point-Free examples from `/Examples/CaseStudies/SwiftUICaseStudies/`
- Added agent anti-patterns section showing what agents typically get wrong
- Added simplification rules: copy Point-Free literally, compile first, fix only what breaks
- Updated verification checklist with correct Point-Free patterns
- Linked DISCOVERY-14 for detailed analysis of actual vs incorrect patterns

November 5, 2025 – Added Pattern 5: Shared State Initialization (@Shared)
- Documented all `@Shared` constructors and persistence strategies
- Added anti-patterns: wrong constructors (Mistake 5) and multiple-writer race conditions (Mistake 6)
- Extended verification checklist with `@Shared` specific items
- Added testing guidance for shared state patterns
- Linked official TCA @Shared documentation

**Previous**: November 1, 2025 – Initial version covering TCA 1.5+ patterns

**Next Review**: December 1, 2025 – Incorporate visionOS-specific gotchas if discovered
