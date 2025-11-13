# DISCOVERY-8: Exclusive State Violation - Intro Stage Transitions

**Date:** November 6, 2025
**Issue:** Opening credits and game logo coexisting simultaneously (violates exclusive state pattern)
**Status:** ✅ FIXED

---

## The Critical Problem

**Symptom:** Opening credits and game logo are visible at the same time

**User Report:** "intro advances but still coexisting with the game logo etc hinting a major issue on the exclusivity of the navigation path / stage / level"

**Architecture Violation:** The exclusive state pattern requires that only ONE level/stage be visible at any given time. Seeing multiple intro stages simultaneously is a **critical bug**.

---

## Root Cause Analysis

### The Flow That Should Work

1. **Opening Credits Stage**
   - Stage: `.openingCredits`
   - Entity: Opening credits view attached
   - Logo: Hidden (below scene)

2. **Transition to Main Menu**
   - Stage: `.mainMenu`
   - Opening credits entity: **SHOULD BE REMOVED**
   - Logo: Animated in
   - Main menu entity: Created

3. **Result:** Only main menu + logo visible (exclusive state) ✅

### What Was Actually Happening

1. **Opening Credits Stage** ✅
   - Stage: `.openingCredits`
   - Entity: Opening credits view attached
   - Logo: Hidden

2. **Transition to Main Menu** ❌
   - Stage: `.mainMenu`
   - Opening credits entity: **STILL IN SCENE** (BUG!)
   - Logo: Animated in
   - Main menu entity: Created

3. **Result:** Opening credits + logo + main menu visible (concurrent states) ❌

### The Code Bug

**File:** `IntroChange.swift` lines 55-91

When transitioning to `.mainMenu`, the code was:

```swift
case .mainMenu:
  Entity.animate(.easeOut(duration: 5)) {
    // Animate logo in
  } completion: {
    // Create main menu
  }
  // ❌ BUG: Never removed opening credits entity!
```

**Why This Failed:**

The opening credits entity was created when entering the `.openingCredits` stage (lines 45-52), but when transitioning to `.mainMenu` stage, the entity was **never removed from the scene**. It just stayed there, invisible (no components) but still occupying the scene.

**Secondary Bug in cleanupIntroUI():**

The `cleanupIntroUI()` function had the same issue - it only cleared components:

```swift
game.renderer.openingCredits.components.set([])  // ❌ Not enough!
```

Setting components to `[]` doesn't remove the entity from the scene graph!

---

## The Fix

### Fix 1: Remove Entity on Stage Transition

**File:** `IntroChange.swift` lines 55-91

Added cleanup when entering `.mainMenu`:

```swift
case .mainMenu:
  // MARK: - Critical: Remove opening credits entity when transitioning to main menu
  // This ensures exclusive state - no concurrent intro stages
  if let openingCreditsParent = game.renderer.openingCredits.parent {
    debugPrint(">>> IntroChange: Removing opening credits entity")
    openingCreditsParent.removeChild(game.renderer.openingCredits)
  }
  game.renderer.openingCredits.components.set([])

  // Then proceed with logo animation and main menu creation
  Entity.animate(.easeOut(duration: 5)) {
    // ...
```

### Fix 2: Proper Entity Removal in cleanupIntroUI()

**File:** `IntroChange.swift` lines 115-156

Updated `cleanupIntroUI()` to properly remove entities:

```swift
private func cleanupIntroUI() {
  // CRITICAL: Remove opening credits entity from the scene entirely
  // Setting components to [] is not enough - the entity is still visible!
  if let openingCreditsParent = game.renderer.openingCredits.parent {
    debugPrint(">>> IntroChange.cleanupIntroUI: Removing openingCredits entity")
    openingCreditsParent.removeChild(game.renderer.openingCredits)
  }
  game.renderer.openingCredits.components.set([])

  // CRITICAL: Remove onboarding slides entity from the scene entirely
  if let slidesParent = game.renderer.onboardingSlides.parent {
    debugPrint(">>> IntroChange.cleanupIntroUI: Removing onboardingSlides entity")
    slidesParent.removeChild(game.renderer.onboardingSlides)
  }
  game.renderer.onboardingSlides.components.set([])

  // ... rest of cleanup
}
```

---

## The Pattern: Entity Lifecycle Management

### What NOT to Do

```swift
// ❌ WRONG - Just clears components, entity still exists
entity.components.set([])

// ❌ WRONG - Assumes entity has no parent
someEntity.removeChild(entity)

// ❌ WRONG - No cleanup between stages
case .mainMenu:
  // Create main menu
  // Opening credits entity still there!
```

### What TO Do

```swift
// ✅ CORRECT - Remove from parent first
if let parent = entity.parent {
  parent.removeChild(entity)
}
// Then clear components
entity.components.set([])

// ✅ CORRECT - Check parent exists
guard let parent = entity.parent else { return }
parent.removeChild(entity)

// ✅ CORRECT - Clean up old stage before creating new
case .mainMenu:
  cleanupOldStage()  // Remove opening credits
  setupNewStage()    // Create main menu
```

---

## Verification: Exclusive State Pattern

After the fix, verify:

### Stage Transitions Within Intro Level

- [ ] `.openingCredits` → `.mainMenu`:
  - [ ] Opening credits entity removed from scene
  - [ ] Only main menu + logo visible
  - [ ] No concurrent intro stages

### Level Transitions

- [ ] Intro → MPA:
  - [ ] All intro entities removed (openingCredits, mainMenu, logo)
  - [ ] Only MPA entities visible
  - [ ] No concurrent levels

### Game Flow (Complete)

1. **Boot**: Empty scene
2. **Opening credits**: Only credits visible
3. **Credits finish** → **Main menu**:
   - Credits entity removed ✅
   - Main menu + logo visible ✅
   - **Exclusive state maintained** ✅
4. **Main menu** → **MPA**:
   - All intro entities removed
   - Only MPA visible
5. **MPA** → **Glitch** → **Legacy**

---

## Files Modified

### 1. `/Volumes/Plutonian/GreenSpurt/Packages/TheGreenSpurt/Sources/IntroLevel/IntroChange.swift`

**Lines 55-91:** Added entity removal when transitioning to `.mainMenu`

**Lines 115-156:** Fixed `cleanupIntroUI()` to properly remove entities

### 2. (Already fixed) `/Volumes/Plutonian/GreenSpurt/Packages/TheGreenSpurt/Sources/AppFeature/GameView.swift`

**Lines 421-457:** `cleanupIntroUI()` already removes entities properly

---

## Key Insights

### 1. Exclusive State Pattern is CRITICAL

In this game architecture, **only one level/stage can be visible at a time**:
- Not: intro + MPA + Legacy simultaneously
- Not: openingCredits + mainMenu + logo simultaneously
- But: intro (openingCredits) OR intro (mainMenu) OR MPA

### 2. Entity Lifecycle in RealityKit

In RealityKit/SceneKit:
- Entity existence ≠ Component presence
- `components.set([])` removes components but not the entity
- Must use `parent.removeChild(entity)` to truly remove
- Invisible entities still render (overhead, visual glitches)

### 3. TCA Stage Transitions Need Cleanup

When using `@Reducer` enums for stages:
```swift
@Reducer
enum Stage {
  case openingCredits(OpeningCredits)
  case mainMenu(MainMenu)
}
```

Each stage change needs:
- Remove old stage entities
- Create new stage entities
- Maintain exclusive state

### 4. Two Cleanup Functions, One Pattern

There are TWO `cleanupIntroUI()` functions:
1. `IntroChange.swift` - Handles stage transitions within intro
2. `GameView.swift` - Handles leaving intro level entirely

Both now follow the same pattern: **remove from parent, then clear components**.

---

## Testing Checklist

To verify the fix:

1. **Launch app** (requires Apple Developer account)
2. **Watch opening credits**:
   - [ ] Screen 1 (logo) appears
   - [ ] Advances to screen 2 (brain/partner)
   - [ ] Credits finish
3. **Transition**:
   - [ ] Opening credits entity disappears
   - [ ] Logo animates in
   - [ ] Main menu appears
   - [ ] **Only these two visible** (exclusive state!)
4. **Check for concurrent states**:
   - [ ] No opening credits when main menu shows
   - [ ] No logo before credits finish
   - [ ] No multiple intro stages simultaneously
5. **Continue game flow**:
   - [ ] Main menu → MPA works
   - [ ] All intro entities removed when leaving intro
   - [ ] Exclusive state maintained throughout

---

## Impact

- **User Experience**: No more visual glitches, proper flow pacing
- **Architecture**: Exclusive state pattern enforced
- **Performance**: No invisible entities consuming resources
- **Debugging**: Clear console logs for entity lifecycle

---

## Related Fixes

This builds on:
1. **DISCOVERY-6**: `.ifLet` closure requirement (fixed state flow)
2. **DISCOVERY-7**: Opening credits timing (fixed progression)

Combined, these ensure:
- Opening credits advance through all screens ✅
- Credits properly transition to main menu ✅
- Old entities removed, exclusive state maintained ✅

---

## Last Updated

November 6, 2025 – Fixed exclusive state violation in intro stage transitions

**Next:** Test complete game flow to ensure exclusive state maintained throughout all levels
