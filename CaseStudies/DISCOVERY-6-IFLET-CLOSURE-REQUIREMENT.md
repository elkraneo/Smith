# DISCOVERY-6: The .ifLet Closure Requirement - _EphemeralState and @Reducer Enums

**Date:** November 6, 2025
**Discovery Context:** GreenSpurt compilation/runtime errors after recent reducer changes
**Impact Level:** CRITICAL - Breaks enum-based navigation in TCA, causes empty state
**Framework Documents Affected:** AGENTS-TCA-PATTERNS.md (Pattern 3 section)

---

## Executive Summary

When using `@Reducer` enum cases for navigation (e.g., `.intro(IntroLevel)`, `.mpa(MPALevel)`), removing the closure from `.ifLet()` breaks the app. The error `_EphemeralState requirement` is a red herring—the real issue is **the closure form is mandatory for @Reducer enums**.

**The Fix:** Always use the closure form:
```swift
.ifLet(\.level, action: \.level) { Level.body }
```

**Not this (broken):**
```swift
.ifLet(\.level, action: \.level)  // ❌ Missing closure
```

---

## Root Cause Analysis

### The Symptom

A recent change to `AppFeature.swift` removed the closure from `.ifLet`, resulting in:

1. **Compilation error:**
   ```
   Type 'AppFeature.Level.State' does not conform to protocol '_EphemeralState'
   ```

2. **Runtime error:**
   - App shows empty volumetric window
   - No game flow: intro → opening credits → menu → MPA
   - State changes not applying

### The Debugging Journey

**Initial attempt:** Added manual `_EphemeralState` conformance (line 793)
```swift
extension AppFeature.Level.State: _EphemeralState {}
```
**Failed:** `_EphemeralState` is an internal protocol (underscore prefix), not available in public API.

**Second attempt:** Created `LevelAction` enum to wrap actions manually
**Failed:** Caused cascade of type errors, overcomplicated the architecture.

**Third attempt:** Changed `Level` enum from containing reducer instances to state types
**Failed:** Broke the parent-child composition pattern.

**The real fix:** Restored the closure form of `.ifLet`.

### Why The Closure Form Works

When you write:
```swift
.ifLet(\.level, action: \.level) { Level.body }
```

The macro generates the appropriate state composition **and** the `_EphemeralState` conformance **automatically**.

The closure `Level.body` tells the macro:
1. How to compose the child reducers
2. That this is an enum-based navigation, not optional state
3. The proper state management strategy

Without the closure, the macro cannot infer this intent and requires manual conformance (which we can't provide because `_EphemeralState` is internal).

---

## The Working Code

### AppFeature.swift (lines 30-36)

```swift
@Reducer
public enum Level {
  case intro(IntroLevel)
  case mpa(MPALevel)
  case glitch(GlitchLevel)
  case legacy(LegacyLevel)
}
```

### AppFeature.swift (lines 875-877)

```swift
.ifLet(\.level, action: \.level) {
  Level.body
}
```

**This is the ONLY form that works with @Reducer enums.**

---

## Why Pattern 3 Documentation is Correct

Looking at AGENTS-TCA-PATTERNS.md Pattern 3 (lines 254-294), the example shows:

```swift
@Reducer
public enum Destination {
  case addItem(ItemFormFeature)
  case editItem(ItemFormFeature)
  // ...
}

var body: some ReducerOf<Self> {
  // ...
  .ifLet(\.$destination, action: \.destination) {
    Destination()
  }
}
```

**Note the closure** `{ Destination() }` is essential. This wasn't explicitly called out in the documentation, but it's the correct pattern.

---

## Common Mistakes

### Mistake 1: Removing the Closure
```swift
// ❌ BROKEN
.ifLet(\.level, action: \.level)
```
**Result:** `_EphemeralState` requirement, empty state

### Mistake 2: Using Optional Type Directly
```swift
// ❌ This doesn't route actions properly
@Presents public var level: Level?
```
**Result:** Actions don't reach the child reducers

### Mistake 3: Missing @Reducer Macro
```swift
// ❌ Broke the composition
public enum Level {
  case intro(IntroLevel.State)  // State, not reducer!
}
```
**Result:** All state access becomes manual, breaks the pattern

---

## Verification Checklist

Use this checklist when using `.ifLet` with @Reducer enums:

- [ ] @Reducer macro present on enum (line 31)
- [ ] Enum contains reducer instances, not state (line 32-35)
- [ ] State property is `Level.State?` not `Level?` (line 71)
- [ ] Action type is `Level.Action` (line 131)
- [ ] `.ifLet` includes closure with `Level.body` (line 875-877)
- [ ] No manual `_EphemeralState` conformance needed
- [ ] Actions route properly: `case .level(.intro(.showOpeningCredits)):`

---

## Impact on Existing Code

This pattern applies to:
- ✅ Any enum-based navigation (Pattern 3)
- ✅ Multi-level game flows
- ✅ Multi-destination presentation
- ✅ Parent-child reducer composition

This does **not** apply to:
- ❌ Optional primitive state (String?, Int?, etc.)
- ❌ Optional struct state (no @Reducer macro)
- ❌ Simple `.sheet()` presentations (use Pattern 2)

---

## Action Items

1. **Update AGENTS-TCA-PATTERNS.md** to explicitly note the closure requirement for @Reducer enums in Pattern 3
2. **Add verification to Pattern 3**:
   ```markdown
   ⚠️ CRITICAL: The closure form is mandatory for @Reducer enums.
   Write: .ifLet(\.$destination, action: \.destination) { Destination() }
   Not:   .ifLet(\.$destination, action: \.destination)  // ❌ Breaks
   ```
3. **Update the case study example** (lines 290-292) to include a comment emphasizing the closure

---

## References

- **AGENTS-TCA-PATTERNS.md:** Pattern 3 - Multiple Destinations (Complex Navigation)
- **TCA Documentation:** `.ifLet` operator with enum reducers
- **GreenSpurt AppFeature.swift:** Line 875 - Correct .ifLet usage
- **Original working commit:** Before the closure was removed

---

## The Lesson

**The Composable Architecture relies on macros to reduce boilerplate and ensure correctness.** When you remove a macro-generated piece (the closure), you're fighting the system.

**Trust the pattern.** The closure form exists for a reason—it's how TCA knows you're using enum-based navigation, not optional state.

**When in doubt, check the examples in Pattern 3.** They show the correct form.
