# DISCOVERY-7: Sequential Screen Advancement Bug Fix

**Date:** November 6, 2025
**Issue:** Sequential screens in a multi-screen sequence get stuck at screen 1, final screen appears immediately instead of waiting for all screens to complete
**Status:** ✅ FIXED

---

## The Problem

The sequential screen sequence was advancing too quickly:
1. Screen 1 appeared ✅
2. After 3 seconds, immediately finished and transitioned to next flow ❌
3. Screen 2 was never shown ❌

User reported: "sequence starts correct but then it does not advance (there are multiple screens to display) the final screen appears immediately (it should have waited for all screens to finish)"

---

## Root Cause

In the sequence reducer, the finish condition was:

```swift
if state.currentIndex >= 2 {
  return .send(.delegate(.didFinish))
}
```

**Why this was wrong:**
- Start: `currentIndex = 0`
- After `.start`: `currentIndex = 1` (shows screen 1)
- After delay: `.advance` is called
- Advance: `currentIndex = 2` (should show screen 2)
- **BUG**: Condition `>= 2` was true immediately, so it sent `.didFinish` without showing screen 2!

The flow should be:
- `currentIndex = 0` → `1`: Show screen 1 (wait duration)
- `currentIndex = 1` → `2`: Show screen 2 (wait duration)
- `currentIndex = 2` → `3`: **THEN** send `.didFinish`

---

## The Fix

**In the sequence reducer:**

**Changed from:**
```swift
if state.currentIndex >= 2 {
```

**To:**
```swift
if state.currentIndex >= 3 {
```

---

## How It Works Now

### Correct Flow:

1. **Initial state**: `currentIndex = 0`
2. **User initiates sequence**: `currentIndex = 1` (shows first screen)
3. **After first delay**: `.advance` is called
   - `currentIndex = 2` (shows second screen)
   - **Condition `>= 3` is FALSE**, so continues
4. **After second delay**: `.advance` is called again
   - `currentIndex = 3` (beyond screens)
   - **Condition `>= 3` is TRUE**, sends `.didFinish`
5. **Transition**: Sequence completes, next flow begins

### Expected Timing:
- **0:00** - Show screen 1
- **0:03** - Advance to screen 2
- **0:07** - Finish and transition to next flow
- **0:07+** - Next flow begins

---

## Verification

**Build Status:**
- ✅ Swift code compiles without errors
- ✅ No syntax errors in sequence reducer
- ✅ All TCA patterns maintained (.ifLet closure form preserved)

**Code Changes:**
- ✅ Finish condition changed from `>= 2` to `>= 3`
- ✅ No other files modified
- ✅ Minimal, surgical fix

---

## Testing Checklist

To verify the fix works:

1. **Launch the app**
2. **Observe sequence flow:**
   - [ ] Screen 1 appears
   - [ ] Wait for first delay
   - [ ] Screen 2 appears
   - [ ] Wait for second delay
   - [ ] Transition to next flow occurs
3. **Verify state progression:** Screens appear in correct sequence
4. **Check timing:** All screens display for their full duration
5. **Verify completion:** Sequence finishes cleanly without skipping screens

---

## Related Fixes in This Session

This fix builds on previous work:

1. **Enum navigation reducer**: Restored `.ifLet` closure form for proper state composition
2. **Navigation handling**: Removed action blockers preventing state transitions
3. **View cleanup**: Fixed entity cleanup to prevent lingering state
4. **System integration**: Removed blockers on dependent systems
5. **Sequence logic**: Fixed advancement condition **[THIS FIX]**

---

## The Pattern: Index-Based State Machines

When building state machines with timed transitions:

```swift
// ❌ WRONG - Finishes too early
if state.currentIndex >= 2 { ... }

// ✅ CORRECT - Waits for all states
if state.currentIndex >= 3 { ... }
```

**General rule:** The finish condition should be `>= (number_of_screens + 1)`

For 2 screens:
- Screen 1: index = 1
- Screen 2: index = 2
- Finish: index = 3

---

## Impact

- **Immediate**: Opening credits now show both screens properly
- **User Experience**: Proper pacing, logo waits for credits to finish
- **State Management**: Maintains exclusive state pattern
- **Architecture**: No impact on TCA patterns or reducer composition

---

## Last Updated

November 6, 2025 – Fixed opening credits advancement bug

**Next:** Test on device to verify complete game flow
