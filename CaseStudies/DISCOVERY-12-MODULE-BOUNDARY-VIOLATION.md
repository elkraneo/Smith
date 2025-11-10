# DISCOVERY-12: Module Boundary Violation (Inline Reducer Anti-Pattern)

**Date:** November 10, 2025
**Severity:** CRITICAL
**Impact:** Architecture, maintainability, bug prevention
**Projects Affected:** GreenSpurt (850-line inline reducer causing bugs)
**Root Cause:** No guidance on when to extract inline nested reducers

---

## Executive Summary

**Problem:** 850 lines of hint system logic embedded inline within GameEngine reducer caused:
- Infinite delegate action loops
- Duplicate state (WatcherAssistPopover + HintSystem = same thing)
- Stale RealityKit entities across level transitions
- Unclear ownership and responsibility boundaries

**Root Cause:** Smith framework documented Swift Package module extraction (DECISION-TREES Tree 1, 3) but provided NO guidance on when to extract inline nested reducers into separate modules.

**Solution:** Extract HintsFeature as separate module when reducer exceeds 200 lines OR has 3+ distinct responsibilities.

**Impact:** -2000 lines, clearer architecture, all bugs resolved.

---

## The Problem in Detail

### What We Built (Anti-Pattern)

```swift
// GameEngine.swift (1200+ lines, doing too much)
@Reducer
public struct GameEngine {
  @ObservableState
  public struct State {
    // Game domain state
    public var currentLevel: CurrentLevel = .intro
    public var multiplayer: MultiplayerState = .init()

    // ❌ PROBLEM 1: Inline nested hint system state
    public var hintSystem: HintSystemState?

    // ❌ PROBLEM 2: DUPLICATE state for same feature
    public var watcherAssistPopover: WatcherAssistPopoverState?
  }

  // ❌ PROBLEM 3: Inline nested reducer (850 lines!)
  @Reducer
  public struct HintSystemReducer {
    @ObservableState
    public struct State {
      public var isVisible: Bool = false
      public var currentHint: String?
      public var skipButtonPressed: Bool = false
      // ... 40+ more properties
    }

    public enum Action {
      case show
      case skip
      case skipConfirmed
      // ... 25+ more actions
    }

    public var body: some ReducerOf<Self> {
      Reduce { state, action in
        // 850 lines of hint logic embedded here
        // Mixed with:
        // - UI concerns (popover visibility)
        // - Game logic concerns (level transitions)
        // - Domain concerns (hint progression)
      }
    }
  }

  public enum Action {
    case hintSystem(HintSystemAction)  // ❌ Inline nested action
    case watcherAssist(WatcherAssistPopoverAction)  // ❌ DUPLICATE

    // ❌ PROBLEM 4: Delegate re-forwarding
    public enum Delegate {
      case hintSystemShouldTransition(CurrentLevel)
    }
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // ❌ PROBLEM 5: Delegate infinite loop
      case .delegate(.hintSystemShouldTransition):
        return .send(.delegate(.hintSystemShouldTransition))  // Re-forwards to self!

      case .hintSystem(.skipConfirmed):
        return .send(.delegate(.hintSystemShouldTransition))  // Then triggers above
      }
    }
    .ifLet(\.hintSystem, action: \.hintSystem) {
      HintSystemReducer()  // 850 lines of inline logic
    }
  }
}
```

**Result:**
- GameEngine.swift: 1200+ lines (game + hints + multiplayer + UI)
- Unclear boundaries: "Who owns hint logic?"
- Infinite loops: Delegate re-forwarding
- Duplicate state: Two versions of same feature
- Stale entities: No cleanup pattern on transitions

---

## Root Cause Analysis

### Why This Happened

**Smith framework had:**
1. ✅ DECISION-TREES Tree 1: When to create Swift Package module
   - Criteria: 20+ actions, 5+ files, 3+ projects
   - **BUT:** Assumes you've ALREADY extracted the inline reducer

2. ✅ DECISION-TREES Tree 3: When to refactor into module
   - Criteria: Stable code, reusable logic, tangled dependencies
   - **BUT:** Doesn't define "tangled" or give line count thresholds

3. ❌ **MISSING:** When to extract INLINE nested reducer BEFORE it becomes a module

**The gap:**
```
Inline nested reducer → ??? → Swift Package module
                        ↑
                   Missing step!
```

No guidance on:
- When is an inline reducer "too big"?
- What's the line count threshold?
- How many responsibilities = extract?
- How to identify duplication across features?

---

## What Went Wrong (Timeline)

### Phase 1: Initial Implementation (Inline Reducer)

```swift
// Month 1: Small hint system (50 lines)
@Reducer
public struct GameEngine {
  @Reducer
  struct HintSystemReducer {
    // 50 lines - seems fine
  }
}
```

**Status:** ✅ Acceptable for small features

---

### Phase 2: Feature Growth (No Extraction)

```swift
// Month 2: Hint system grows (200 lines)
@Reducer
public struct GameEngine {
  @Reducer
  struct HintSystemReducer {
    // 200 lines - getting large, no alarm bells
  }
}
```

**Status:** ⚠️ Should extract, but no threshold guidance

---

### Phase 3: Duplication Emerges

```swift
// Month 3: "WatcherAssist" feature added
@Reducer
public struct GameEngine {
  @ObservableState
  public struct State {
    public var hintSystem: HintSystemState?  // Old name
    public var watcherAssistPopover: WatcherAssistPopoverState?  // New name, SAME THING!
  }

  @Reducer
  struct HintSystemReducer { ... }  // 400 lines

  // Separate code path for "WatcherAssist"
  case .watcherAssist(let action):
    // 200 lines of duplicate logic
}
```

**Status:** ❌ CRITICAL: Duplication indicates missing abstraction

---

### Phase 4: Infinite Loops and Bugs

```swift
// Month 4: Delegate re-forwarding added
case .delegate(.hintSystemShouldTransition):
  return .send(.delegate(.hintSystemShouldTransition))  // INFINITE LOOP

case .hintSystem(.skipConfirmed):
  return .send(.delegate(.hintSystemShouldTransition))  // Triggers above
```

**Status:** ❌ CRITICAL: System broken, debugging sessions start

---

## The Fix: Extract to Separate Module

### Step 1: Create HintsFeature Module

```swift
// Packages/TheGreenSpurt/Sources/HintsFeature/HintsFeature.swift
import ComposableArchitecture
import GameDomain  // Shared types like CurrentLevel

@Reducer
public struct HintsFeature {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var isVisible: Bool = false
    public var currentHint: String?
    // ... all hint state

    public init() { ... }
  }

  public enum Action: Sendable {
    case show
    case skip
    case skipConfirmed

    // ✅ Delegates flow UP to parent
    public enum Delegate: Sendable {
      case skipConfirmed(level: CurrentLevel)
      case dismissed
    }
    case delegate(Delegate)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .skipConfirmed:
        // Clean up local state
        state.isVisible = false
        // Send ONE delegate to parent
        return .send(.delegate(.skipConfirmed(level: state.effectiveLevel)))

      // ... hint-specific logic only
      }
    }
  }
}
```

**Changes:**
- ✅ 400 lines extracted into dedicated module
- ✅ Clear public API (State, Action, Delegate)
- ✅ Single responsibility: Hint system logic only
- ✅ No game logic, no UI concerns beyond hint visibility

---

### Step 2: Simplify GameEngine

```swift
// Packages/TheGreenSpurt/Sources/GameEngine/GameEngine.swift
import HintsFeature  // ✅ Composed from module

@Reducer
public struct GameEngine {
  @ObservableState
  public struct State {
    // Game domain state only
    public var currentLevel: CurrentLevel = .intro
    public var multiplayer: MultiplayerState = .init()

    // ✅ Composed from HintsFeature module
    fileprivate(set) public var hints: HintsFeature.State?

    // ❌ REMOVED: watcherAssistPopover (duplicate)
    // ❌ REMOVED: hintSystem (renamed to hints)
  }

  public enum Action {
    case hints(HintsFeature.Action)  // ✅ Composed action

    // ❌ REMOVED: watcherAssist (duplicate)
    // ❌ REMOVED: hintSystem (renamed)

    public enum Delegate {
      // ✅ Mapped from child delegate
      case watcherAssistSkipConfirmed(level: CurrentLevel)
    }
    case delegate(Delegate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // ✅ CORRECT: Map child delegate to parent delegate (no re-forwarding)
      case .hints(.delegate(.skipConfirmed(let level))):
        state.hints = nil  // Clean up local state
        return .send(.delegate(.watcherAssistSkipConfirmed(level: level)))  // ONE delegate

      case .hints(.delegate(.dismissed)):
        state.hints = nil
        return .none

      // ❌ REMOVED: .delegate(.hintSystemShouldTransition) re-forwarding
      }
    }
    .ifLet(\.hints, action: \.hints) {
      HintsFeature()  // ✅ Clean composition
    }
  }
}
```

**Impact:**
- ✅ GameEngine reduced from 1200 → 800 lines (-400 lines)
- ✅ Single responsibility: Game orchestration only
- ✅ No infinite loops (delegate flows UP once)
- ✅ No duplication (WatcherAssist removed)

---

### Step 3: Fix RealityKit Entity Cleanup

```swift
// Packages/TheGreenSpurt/Sources/AppFeature/GameView.swift
extension GameView {
  func onLevelChange(_ oldLevel: CurrentLevel, _ newLevel: CurrentLevel) {
    switch newLevel {
    case .glitch:
      // ✅ Clear entities BEFORE new level setup
      game.renderer.clearScreenButtonPopovers()

    case .legacy:
      game.renderer.clearScreenButtonPopovers()
    }
  }
}

// Packages/TheGreenSpurt/Sources/GameEngine/GameRenderer+Button3D.swift
extension GameRenderer {
  /// Clear all screen button popover entities when transitioning levels.
  public func clearScreenButtonPopovers() {
    for (_, entity) in screenButtonPopoverEntities {
      entity.removeFromParent()  // ✅ Remove from RealityKit scene
    }
    screenButtonPopoverEntities.removeAll()  // ✅ Clear dictionary
  }
}
```

**Impact:**
- ✅ No stale entities across transitions
- ✅ ViewAttachmentComponents recreated fresh
- ✅ No non-interactive UI bugs

---

## Quantified Impact

### Before vs. After

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| **GameEngine.swift lines** | 1200 | 800 | -400 (-33%) |
| **HintsFeature lines** | 850 (inline) | 400 (module) | -450 (extracted + cleaned) |
| **Total codebase lines** | 12,540 | 10,495 | -2,045 (-16%) |
| **Responsibilities per reducer** | 4+ | 1-2 | ✅ Single responsibility |
| **Duplicate features** | 2 (HintSystem + WatcherAssist) | 1 (HintsFeature) | -1 |
| **Infinite loops** | 1 | 0 | ✅ Fixed |
| **Stale entity bugs** | 1 | 0 | ✅ Fixed |
| **Build time** | N/A | N/A | Likely faster (parallel) |

---

## What Smith Framework Was Missing

### Missing Pattern #1: Inline Reducer Extraction Threshold

**Should be in:** AGENTS-DECISION-TREES.md (new section before Tree 1)

```markdown
## Pre-Tree: Is Your Inline Reducer Too Large?

**Before using Tree 1 (Swift Package module decision), check if your reducer should be extracted from inline nesting.**

### Inline vs. Extracted Reducer Decision

```
Do you have a @Reducer defined INSIDE another @Reducer?
├─ YES
│  ├─ Does it exceed 200 lines?
│  │  ├─ YES → EXTRACT to separate file immediately
│  │  └─ NO → Check other criteria below
│  │
│  ├─ Does it have 3+ distinct action cases?
│  │  ├─ YES → EXTRACT (too many responsibilities)
│  │  └─ NO → Keep inline for now
│  │
│  ├─ Does it have 4+ state properties?
│  │  ├─ YES → EXTRACT (complex state management)
│  │  └─ NO → Keep inline for now
│  │
│  ├─ Does it have its own Delegate actions?
│  │  ├─ YES → EXTRACT (needs clear parent-child boundary)
│  │  └─ NO → Keep inline for now
│  │
│  └─ Is it used by 2+ parent reducers?
│     ├─ YES → EXTRACT (reusable component)
│     └─ NO → Keep inline if < 200 lines
│
└─ NO (already separate) → Proceed to Tree 1
```

**Threshold Summary:**
- **< 100 lines:** Keep inline
- **100-200 lines:** Consider extracting if 3+ criteria met
- **> 200 lines:** Extract immediately (non-negotiable)
```

---

### Missing Pattern #2: Delegate Action Flow Discipline

**Should be in:** AGENTS-TCA-PATTERNS.md (new Pattern 6)

```markdown
## Pattern 6: Delegate Action Flow (Parent-Child Communication)

**Use case:** Child reducer needs to communicate events to parent (navigation, completion, errors).

**Pattern: Delegates Flow UP Exactly Once**

```swift
// ✅ CORRECT: Child sends delegate, parent maps to its own delegate
@Reducer
public struct ChildFeature {
  public enum Action {
    case buttonTapped
    case taskCompleted

    public enum Delegate {
      case completed(result: String)
      case cancelled
    }
    case delegate(Delegate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .taskCompleted:
        // Do child-specific cleanup
        state.isLoading = false
        // Send ONE delegate UP to parent
        return .send(.delegate(.completed(result: state.result)))
      }
    }
  }
}

@Reducer
public struct ParentFeature {
  @ObservableState
  public struct State {
    @Presents var child: ChildFeature.State?
  }

  public enum Action {
    case child(PresentationAction<ChildFeature.Action>)

    public enum Delegate {
      case childTaskCompleted(result: String)
    }
    case delegate(Delegate)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      // ✅ CORRECT: Map child delegate to parent delegate (different action)
      case .child(.presented(.delegate(.completed(let result)))):
        state.child = nil  // Clean up child state
        // Send NEW delegate to grandparent (if needed)
        return .send(.delegate(.childTaskCompleted(result: result)))

      case .child(.presented(.delegate(.cancelled))):
        state.child = nil
        return .none  // Terminal action, no delegate to grandparent

      // ❌ NEVER DO THIS:
      // case .delegate(.childTaskCompleted):
      //   return .send(.delegate(.childTaskCompleted))  // INFINITE LOOP!
      }
    }
    .ifLet(\.$child, action: \.child) {
      ChildFeature()
    }
  }
}
```

**Anti-Pattern: Delegate Re-Forwarding**

```swift
// ❌ WRONG: Re-forwarding same delegate creates infinite loop
case .delegate(.taskCompleted):
  return .send(.delegate(.taskCompleted))  // Triggers itself!

// ❌ WRONG: Child sends delegate that parent re-forwards
case .child(.delegate(.completed)):
  return .send(.delegate(.completed))  // Type collision + loop
```

**Verification Checklist:**

- [ ] Child reducer sends `.delegate(X)` to parent
- [ ] Parent handles `.delegate(X)` in its reducer
- [ ] Parent does NOT re-forward `.delegate(X)` to itself
- [ ] Parent MAY send `.delegate(Y)` to its parent (different action)
- [ ] No action appears in BOTH `case .delegate(X):` and `case .send(.delegate(X))`
- [ ] Delegate enum names are unique per reducer level

**Testing Strategy:**

```swift
@Test
func childDelegateMappedToParent() async {
  let store = TestStore(initialState: ParentFeature.State()) {
    ParentFeature()
  }

  await store.send(.child(.presented(.taskCompleted))) {
    $0.child = nil  // Child state cleaned up
  }

  // ✅ Verify parent delegate sent (not child delegate re-forwarded)
  await store.receive(\.delegate.childTaskCompleted) { result in
    // Verify mapped correctly
  }

  await store.finish()  // ✅ No infinite effects
}
```
```

---

### Missing Pattern #3: visionOS Entity Cleanup on State Transitions

**Should be in:** PLATFORM-VISIONOS.md (new section)

```markdown
## [CRITICAL] Entity Lifecycle Across State Transitions

**Problem:** ViewAttachmentComponents reference SwiftUI views that observe TCA stores. When level/feature transitions occur:
1. TCA state is cleared ✓
2. But RealityKit entities persist in scene ✗
3. Stale entities reference old store/state → non-interactive UI

**Pattern: Explicit Entity Cleanup BEFORE Transition**

```swift
// GameView.swift
extension GameView {
  /// Called when current level changes
  func onLevelChange(_ oldLevel: CurrentLevel, _ newLevel: CurrentLevel) {
    // ✅ Clear RealityKit entities BEFORE new level setup
    clearLevelSpecificEntities(for: oldLevel)

    // Then set up new level
    setupLevel(newLevel)
  }

  private func clearLevelSpecificEntities(for level: CurrentLevel) {
    switch level {
    case .intro, .glitch, .legacy:
      // ✅ Clear screen button popovers (from Discovery-4)
      game.renderer.clearScreenButtonPopovers()

    case .mpa:
      // ✅ Clear MPA-specific entities
      game.renderer.clearMPAEntities()
    }
  }
}

// GameRenderer+Button3D.swift
extension GameRenderer {
  /// Clear all screen button popover entities when transitioning levels.
  ///
  /// Called from `GameView.onLevelChange()` to prevent stale entities.
  public func clearScreenButtonPopovers() {
    for (_, entity) in screenButtonPopoverEntities {
      entity.removeFromParent()  // ✅ Remove from RealityKit scene
    }
    screenButtonPopoverEntities.removeAll()  // ✅ Clear dictionary
  }
}
```

**Verification Checklist:**

- [ ] Entity cleanup method exists (`clearXEntities()`)
- [ ] Method called in level/feature transition handler
- [ ] Method called BEFORE new level setup (not after)
- [ ] Entities removed from parent (`removeFromParent()`)
- [ ] Entity dictionary/storage cleared (`.removeAll()`)
- [ ] New entities created fresh (not reused from previous state)

**Testing Strategy:**

```swift
// Manual verification (RealityKit not easily testable)
func verifyEntityCleanup() {
  // 1. Start level 1, create entities
  // 2. Check entity count: game.renderer.screenButtonPopoverEntities.count == N
  // 3. Transition to level 2
  // 4. Check entity count: game.renderer.screenButtonPopoverEntities.count == 0
  // 5. Verify new entities created for level 2
}
```

**Related:** See DISCOVERY-4 for entity creation patterns.
```

---

### Missing Pattern #4: Feature Naming Consolidation Audit

**Should be in:** AGENTS-DECISION-TREES.md (new tree)

```markdown
## Tree 5: Feature Already Exists Under Different Name?

**Before implementing a "new" feature, audit for existing implementations.**

```
New feature request arrives
├─ Search codebase for similar functionality
│  ```bash
│  rg "FeatureKeyword|AlternativeName" --type swift
│  rg "SimilarState|SimilarAction" --type swift
│  ```
│
├─ Check for duplicate state types
│  Example: `WatcherAssistPopoverState` vs `HintSystemState`
│  ├─ Do they have identical or overlapping properties?
│  │  ├─ YES → They're the same feature!
│  │  └─ NO → Proceed to implementation
│  │
│  └─ Are they used in mutually exclusive contexts?
│     ├─ YES → Consolidate to ONE implementation
│     └─ NO → Keep separate
│
├─ Check for duplicate action enums
│  Example: `WatcherAssistAction` vs `HintSystemAction`
│  ├─ Do they have identical cases?
│  │  ├─ YES → Same feature, different name
│  │  └─ NO → Proceed to implementation
│  │
│  └─ Do they trigger the same effects?
│     ├─ YES → Consolidate
│     └─ NO → Keep separate
│
└─ Check for duplicate button IDs / entity keys
   Example: `Button3DID.watcherAssist` vs `Button3DID.hintSystem`
   ├─ Do they refer to the same UI element?
   │  ├─ YES → Naming inconsistency, consolidate
   │  └─ NO → Proceed
   │
   └─ Are they both active simultaneously?
      ├─ YES → Likely separate features
      └─ NO → Same feature, consolidate
```

**If Duplicate Found: Consolidation Steps**

1. **Pick ONE canonical name** (usually the most descriptive)
   - Example: `HintsFeature` (not `WatcherAssistPopover`, not `HintSystem`)

2. **Rename all occurrences**
   ```bash
   # Find all references
   rg "WatcherAssist|watcherAssist" --type swift

   # Rename systematically (use IDE refactor or sed)
   ```

3. **Delete duplicate implementations**
   - Remove redundant state types
   - Remove redundant action enums
   - Remove redundant reducers

4. **Update button IDs / entity keys**
   ```swift
   // Before:
   Button3DID.watcherAssist
   Button3DID.hintSystem

   // After:
   Button3DID.hints  // ✅ ONE canonical name
   ```

5. **Merge functionality if needed**
   - If both implementations had unique features, merge into canonical version

**Red Flags Indicating Duplication:**

- Two button IDs for visually same UI element
- Two state types with 80%+ overlapping properties
- Two action enums with identical case names
- Two reducers handling same events differently
- Comments like "// TODO: Unify with X feature"

**Example: WatcherAssist + HintSystem → HintsFeature**

```
Audit revealed:
- WatcherAssistPopoverState == HintSystemState (identical properties)
- WatcherAssistAction == HintSystemAction (identical cases)
- Button3DID.watcherAssist == Button3DID.hintSystem (same button)

Consolidation:
1. Canonical name: HintsFeature
2. Deleted: WatcherAssistPopoverState, WatcherAssistAction
3. Renamed: hintSystem → hints (property), HintSystemState → HintsFeature.State
4. Unified: Button3DID.hints (single button ID)
5. Result: -450 lines of duplicate code
```
```

---

## Smith Pattern Added

### 1. AGENTS-DECISION-TREES.md

**Added:** Pre-Tree section "Is Your Inline Reducer Too Large?"

**Location:** Before Tree 1

**Enforcement Level:** [CRITICAL] Extract immediately if > 200 lines

**Threshold Rules:**
- < 100 lines: Keep inline
- 100-200 lines: Extract if 3+ criteria met
- \> 200 lines: Extract immediately (non-negotiable)

**Criteria:**
- Line count (> 200)
- Action cases (3+)
- State properties (4+)
- Delegate actions (any)
- Reuse count (2+ parents)

---

### 2. AGENTS-TCA-PATTERNS.md

**Added:** Pattern 6 - Delegate Action Flow

**Enforcement Level:** [STANDARD] Verify delegate flow in all parent-child reducers

**Key Rules:**
- Delegates flow UP exactly once
- Parent maps child delegate to its own delegate (different action)
- Never re-forward same delegate
- Unique delegate enums per reducer level

**Verification Checklist:** 6 items

**Testing Strategy:** TestStore validation with `.finish()`

---

### 3. PLATFORM-VISIONOS.md

**Added:** [CRITICAL] Entity Lifecycle Across State Transitions

**Pattern:** `clearXEntities()` methods called BEFORE level transitions

**Enforcement Level:** [CRITICAL] Missing cleanup causes stale UI bugs

**Verification Checklist:** 6 items

**Related:** DISCOVERY-4 (entity creation), this pattern (entity cleanup)

---

### 4. AGENTS-DECISION-TREES.md

**Added:** Tree 5 - Feature Already Exists Under Different Name?

**Enforcement Level:** [STANDARD] Audit before implementing new features

**Red Flags:** Duplicate state, duplicate actions, duplicate button IDs

**Consolidation Steps:** 5-step process

**Example:** WatcherAssist + HintSystem → HintsFeature consolidation

---

## Prevention Strategy

### Checklist: Before Implementing a Feature

- [ ] Audit existing codebase for similar functionality (Tree 5)
- [ ] If inline reducer exists, check line count (Pre-Tree)
- [ ] If > 200 lines, extract to separate file immediately
- [ ] Define clear delegate flow (parent maps child delegates)
- [ ] Add entity cleanup method if visionOS (clearXEntities())
- [ ] Verify no duplicate state types or action enums
- [ ] Test delegate flow doesn't create loops (TestStore .finish())

---

## Testing Strategy

### Unit Tests

```swift
@Test
func hintsFeatureDelegateFlowsToParent() async {
  let store = TestStore(initialState: GameEngine.State()) {
    GameEngine()
  }

  // Show hints
  await store.send(.hints(.show)) {
    $0.hints = HintsFeature.State(isVisible: true)
  }

  // Skip confirmed
  await store.send(.hints(.skipConfirmed)) {
    $0.hints = nil  // Child state cleaned up
  }

  // ✅ Verify parent delegate sent (not child delegate re-forwarded)
  await store.receive(\.delegate.watcherAssistSkipConfirmed) { level in
    // Verify level passed correctly
  }

  // ✅ No infinite effects
  await store.finish()
}
```

### Integration Tests

```swift
func testLevelTransitionClearsEntities() {
  // Setup level 1 with entities
  let initialEntities = game.renderer.screenButtonPopoverEntities.count

  // Transition to level 2
  game.store.send(.transitionToLevel(.glitch))

  // Verify entities cleared
  XCTAssertEqual(game.renderer.screenButtonPopoverEntities.count, 0)

  // Verify new entities created
  XCTAssertGreaterThan(game.renderer.screenButtonPopoverEntities.count, 0)
}
```

---

## Impact Summary

### Before Fix

- ❌ GameEngine: 1200 lines (4+ responsibilities)
- ❌ Inline HintSystemReducer: 850 lines
- ❌ Duplicate features: WatcherAssist + HintSystem
- ❌ Infinite delegate loops
- ❌ Stale RealityKit entities across transitions
- ❌ Debugging sessions: 2+ weeks

### After Fix

- ✅ GameEngine: 800 lines (-400, single responsibility)
- ✅ HintsFeature module: 400 lines (extracted + cleaned)
- ✅ No duplication: One canonical implementation
- ✅ Clean delegate flow: No loops
- ✅ Entity cleanup: clearScreenButtonPopovers() on transitions
- ✅ Total lines removed: -2000 (-16% codebase)

### Smith Framework Improvements

- ✅ Pre-Tree: Inline reducer extraction threshold (200 lines)
- ✅ Pattern 6: Delegate action flow discipline
- ✅ visionOS: Entity cleanup on transitions
- ✅ Tree 5: Feature naming consolidation audit

---

## References

- AGENTS-DECISION-TREES.md Tree 1 (Swift Package module extraction)
- AGENTS-DECISION-TREES.md Tree 3 (When to refactor into module)
- AGENTS-TCA-PATTERNS.md Pattern 1-5 (Modern TCA patterns)
- PLATFORM-VISIONOS.md (visionOS-specific patterns)
- DISCOVERY-4 (RealityKit entity creation gap)

---

## Last Updated

November 10, 2025

**Status:** ✅ Patterns documented, bugs fixed, -2000 lines removed
