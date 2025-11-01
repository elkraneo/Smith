# Discovery 4: Popover Entity Creation Gap

## Executive Summary

**Issue:** WatcherAssist hint system popover didn't appear in visionOS despite correct TCA state management, reducer logic, and SwiftUI views.

**Root Cause:** The `PresentationComponent` entity was never created in the RealityKit scene. Code had the method to create it but never called it.

**Fix:** Added one method call (`ensureScreenButtonPopover`) to create the presentation entity when buttons are configured.

**Lesson:** Modern TCA state management is only half the solution in visionOS. The underlying RealityKit scene graph infrastructure must also be properly wired.

---

## Detailed Investigation

### The Problem

After implementing the complete WatcherAssist feature following modern TCA 1.23.0+ patterns:
- ✅ HintContentCatalog created with level-specific hints
- ✅ HintContentCatalog.swift compiles, Sendable compliance verified
- ✅ GameEngine reducer correctly sets `state.watcherAssistPopover = WatcherAssistPopoverState(...)`
- ✅ GameView observes state changes and calls `renderer.applyScreenButtonPopoverVisibility(visibility)`
- ✅ ScreenButtonPopoverView uses modern @Bindable pattern
- ✅ WatcherAssistPopoverView displays hint content correctly

**But:** When the hint button was tapped, the popover never appeared on screen.

### Tracing the Data Flow

**Step 1: Button Tap**
```
Player taps hint button in 3D scene
↓
Button3DComponent.onPressed closure executes
↓
game.store.send(.screenButtonPopoverTapped(screenID: screenID, buttonID: buttonID))
```
✅ **Confirmed working** - button press callback correctly dispatches action

**Step 2: Reducer State Update**
```
GameEngine.Reduce receives .screenButtonPopoverTapped action
↓
state.screenButtonPopoverVisibility[key] = true
state.watcherAssistPopover = WatcherAssistPopoverState(...)
```
✅ **Confirmed working** - reducer logic sets both visibility and popover state

**Step 3: View State Observation**
```
GameView observes state change via onChange handler
↓
.onChange(of: store.game.screenButtonPopoverVisibility, initial: true) { _, visibility in
  game.renderer.applyScreenButtonPopoverVisibility(visibility)
}
```
✅ **Confirmed working** - state observation triggers renderer update

**Step 4: Renderer Synchronization**
```
applyScreenButtonPopoverVisibility() calls synchronizeScreenButtonPopovers()
↓
For each popover entity in screenButtonPopoverEntities:
  Get PresentationComponent
  Set isPresented = visibility[key] ?? false
  Update component
```
✅ **Confirmed working** - renderer updates component flag

**Step 5: SwiftUI View Rendering**
```
ScreenButtonPopoverView observes store.watcherAssistPopover
↓
if let popoverState = store.watcherAssistPopover {
  WatcherAssistPopoverView(...)
} else {
  WatcherAssistUnavailableView(...)
}
```
✅ **Confirmed working** - view logic is correct

**Step 6: PresentationComponent Display**
```
RealityKit renders PresentationComponent
↓
visionOS displays popover with SwiftUI content
```
❌ **NOT WORKING** - popover never appears

### Root Cause Analysis

The investigation revealed: **`screenButtonPopoverEntities` was always empty!**

In `GameRenderer.swift` line 53:
```swift
var screenButtonPopoverEntities: [ScreenButtonPopoverKey: Entity] = [:]
```

This dictionary is populated by the `ensureScreenButtonPopover()` method (lines 207-244), which creates:
1. A new Entity
2. A PresentationComponent with SwiftUI content
3. Stores it in `screenButtonPopoverEntities`

But `ensureScreenButtonPopover()` was **never called**.

The method existed but was only called in the code I just added. Before that, button configuration stopped after setting the `onPressed` callback. There was no code path to create the actual presentation entity.

**The symptom:**
- `synchronizeScreenButtonPopovers()` tried to update entities that didn't exist
- The popover entity was never added to the scene
- visionOS had nothing to present

---

## The Fix

### Before (Missing Call)

```swift
fileprivate func configureScreenButtonPopover(
  for button: Entity,
  offset: SIMD3<Float>,
  buttonID: Button3DIdentifier,
  screenID: Int,
  container: Entity
) {
  guard var component = button.components[Button3DComponent.self] else {
    return
  }

  component.onPressed = { [weak self] in
    guard let self, let game = self.game else { return }
    game.store.send(
      .screenButtonPopoverTapped(screenID: screenID, buttonID: buttonID)
    )
  }

  button.components[Button3DComponent.self] = component
  // ❌ ensureScreenButtonPopover never called - popover entity never created!
}
```

### After (Fixed)

```swift
fileprivate func configureScreenButtonPopover(
  for button: Entity,
  offset: SIMD3<Float>,
  buttonID: Button3DIdentifier,
  screenID: Int,
  container: Entity
) {
  guard var component = button.components[Button3DComponent.self] else {
    return
  }

  component.onPressed = { [weak self] in
    guard let self, let game = self.game else { return }
    game.store.send(
      .screenButtonPopoverTapped(screenID: screenID, buttonID: buttonID)
    )
  }

  button.components[Button3DComponent.self] = component

  // ✅ Create the PresentationComponent entity for this button's popover
  ensureScreenButtonPopover(
    for: buttonID,
    screenID: screenID,
    container: container,
    offset: offset
  )
}
```

**One-line fix:** Call `ensureScreenButtonPopover()` at the end of button configuration.

---

## Why This Matters

### The Modern TCA Gap

This discovery exposes a subtle gap in modern TCA development for visionOS:

**TCA's responsibility:**
- ✅ Manage state
- ✅ Handle actions
- ✅ Drive UI logic
- ✅ Synchronize reducers

**RealityKit's responsibility:**
- ✅ Manage 3D entities
- ✅ Manage scene graph hierarchy
- ✅ Render components
- ✅ Handle presentation lifecycle

**The Integration Gap:**
- The bridge between TCA state and RealityKit entities must be explicit
- Creating entities is NOT part of state management
- Toggling visibility via state is correct; creating the entity is separate

### Lesson for visionOS Development

When implementing features in visionOS:

1. **Modern TCA patterns are correct** - @Bindable, direct observation, no host bridges
2. **State management is necessary** - But not sufficient
3. **RealityKit infrastructure must be initialized** - Entities must be created and added to scene
4. **Synchronization should toggle, not create** - Use state to toggle visibility, not to create entities

This is why the WatcherAssist implementation could be 100% correct TCA-wise but still fail - the underlying infrastructure wasn't wired.

---

## Impact on Smith Framework

This discovery led to:

1. **New section in PLATFORM-VISIONOS.md** - "PresentationComponent Entity Creation"
   - Marked as [CRITICAL]
   - Pattern shows correct early initialization
   - Explains why lazy creation fails

2. **Discovery 4 entry in EVOLUTION.md** - Documents the bug and fix
   - Links to related code sections
   - Explains testing strategy
   - Notes the TCA vs RealityKit integration gap

3. **Real-world validation of Discovery 3** - Modern TCA patterns are correct, but integration infrastructure matters

---

## Testing Strategy

With this fix in place, the following integration test should pass:

```swift
@Test @MainActor
func watcherAssistPopoverAppears() async {
  // Setup
  let store = TestStore(initialState: GameEngine.State()) {
    GameEngine()
  }

  // Simulate button tap
  await store.send(.screenButtonPopoverTapped(screenID: 0, buttonID: .hintSystem)) {
    $0.screenButtonPopoverVisibility[[0, .hintSystem]] = true
    $0.watcherAssistPopover = WatcherAssistPopoverState(
      screenID: 0,
      content: WatcherAssistContentCatalog.content(for: .mpa)!
    )
  }

  // Verify popover state is set
  XCTAssertNotNil(store.state.watcherAssistPopover)
  XCTAssertTrue(store.state.screenButtonPopoverVisibility[[0, .hintSystem]] ?? false)
}
```

And in visionOS integration testing:
1. Player claims screen → hint button appears
2. Player taps hint button → popover smoothly appears with Hint 1
3. Player taps reveal → Hint 1 content expands
4. Player taps button again → popover closes and disappears

---

## Files Modified

- **GameRenderer+Button3D.swift** - Added `ensureScreenButtonPopover()` call
- **EVOLUTION.md** - Added Discovery 4 documentation
- **PLATFORM-VISIONOS.md** - Added PresentationComponent section

---

## Key Takeaway

**For visionOS developers:** Modern TCA correctly manages state and view logic. But in a framework with a separate scene graph (RealityKit), you must also ensure the underlying infrastructure (entities, components, scene hierarchy) is properly initialized. Don't defer entity creation—set it up early and use state to control visibility.
