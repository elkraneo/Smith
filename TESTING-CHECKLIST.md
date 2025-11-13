# Testing Checklist for Developers

**Use this before submitting a PR that touches TCA, state, or reducers**

---

## Pre-Submit Checklist

### Code Changes

- [ ] I understand what state is being managed
- [ ] I've verified the exclusive state pattern (only one level/stage visible)
- [ ] I haven't added any action blockers (`case _: return .none`)
- [ ] I'm using the correct `.ifLet` closure form: `.ifLet(\.$property, action: \.property) { Type.body }`
- [ ] I haven't removed any public APIs without deprecation

### Testing

- [ ] Added tests for the bug I fixed (regression tests)
- [ ] Tests verify behavior, not implementation
- [ ] Tests are in the right file:
  - `OpeningCreditsTests.swift` - OpeningCredits reducer
  - `IntroLevelTests.swift` - IntroLevel stages
  - `AppFeatureIntroLevelTests.swift` - AppFeature flows
- [ ] Run tests locally: `swift test` or Xcode test runner
- [ ] All tests pass (or I documented why they can't run yet)

### Test Patterns to Use

#### Regression Test (if you fixed a bug)
```swift
@Test
func fixRegression_bugDescription() async {
  // Reproduce the bug scenario
  // Verify it's fixed
  // Verify it won't come back
}
```

#### Flow Test (for transitions)
```swift
@Test
func flow_description() async {
  // Test complete user flow
  // Verify all state changes
  // Verify actions route correctly
}
```

#### Exclusive State Test (for levels/stages)
```swift
@Test
func exclusiveState_description() async {
  // Verify only one state is active
  // Verify transitions clean up old state
  // Verify no concurrent states
}
```

---

## Test File Locations

### AppFeature Tests
```
/Volumes/Plutonian/GreenSpurt/Packages/TheGreenSpurt/Tests/AppFeatureTests/
├── AppFeatureWatcherAssistSkipTests.swift
└── AppFeatureIntroLevelTests.swift  ← Add level transition tests here
```

### IntroLevel Tests
```
/Volumes/Plutonian/GreenSpurt/Packages/TheGreenSpurt/Tests/IntroLevelTests/
├── OpeningCreditsTests.swift      ← OpeningCredits reducer tests
└── IntroLevelTests.swift          ← Stage transition tests
```

---

## Quick Test Writing Guide

### 1. Test Setup

```swift
@MainActor
@Suite("Feature Name Tests")
struct FeatureNameTests {

  @Test
  func testName() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.continuousClock = TestClock()  // For timing-dependent tests
    }

    // Your test here
  }
}
```

### 2. Send Actions and Verify State

```swift
await store.send(.someAction) {
  $0.expectedStateChange = true
}
```

### 3. Verify Side Effects

```swift
await store.send(.someAction)
await store.receive(.expectedSideEffect)
```

### 4. Check State Conditions

```swift
#expect(store.state.someValue == expected)
#expect(store.state.anotherValue != nil)
```

---

## Red Flags (Don't Submit PR If You See These)

### Code Red Flags

- [ ] `case .level: return .none` - **This blocks all level actions!**
- [ ] `.ifLet(\.$prop, action: \.prop)` **without closure** - Missing `{ Type.body }`
- [ ] Multiple levels visible simultaneously - Violates exclusive state
- [ ] Calling `Date()` or `UUID()` directly - Should use dependencies
- [ ] `@State` in a reducer - **Wrong! Use `@ObservableState`**

### Test Red Flags

- [ ] "I'll add tests later" - **No tests = bug will come back**
- [ ] Tests only test happy path - Test edge cases too
- [ ] No regression test for bug fix - How do you know it's fixed?
- [ ] Tests test implementation details - Should test behavior
- [ ] Tests are brittle - Should be resilient to refactoring

---

## Testing Critical Patterns

### 1. Opening Credits Timing
```swift
// Must test:
// - Shows screen 1 (index 1)
// - Advances to screen 2 (index 2)
// - Finishes ONLY at index 3 (NOT 2!)
```

### 2. Exclusive State
```swift
// Must test:
// - Opening credits XOR main menu (never both)
// - Intro XOR MPA (never both)
// - No concurrent levels/stages
```

### 3. Action Routing
```must test:
// - Actions reach the correct reducer
// - No `.level: return .none` blockers
// - `.watcherAssist` actions not blocked
```

### 4. Stage Transitions
```swift
// Must test:
// - Old stage cleaned up
// - New stage created
// - Exclusive state maintained
// - No visual glitches
```

---

## Debugging Failed Tests

### Common Issues

**Test times out:**
- Missing `await store.receive(...)`
- Action not sent
- Wrong expectation

**Test fails on state:**
- Check action sends correct state change
- Verify test setup
- Check for concurrency issues

**Test not detecting bug:**
- Test is too shallow
- Missing edge case
- Not testing the actual failure scenario

### Debugging Steps

1. **Run single test** in Xcode
2. **Add print statements** to see state
3. **Check test setup** - right initial state?
4. **Verify action** - does it actually fire?
5. **Check timing** - using TestClock?

---

## When Tests Can't Run

If you can't run tests (platform/dependency issues):

- [ ] Code compiles ✅ (we verified this)
- [ ] Test logic is correct ✅
- [ ] Tests follow TCA patterns ✅
- [ ] Document why tests can't run yet
- [ ] Add ticket to fix test environment
- [ ] **Still write the tests!** (they'll run when env is fixed)

---

## Example: Complete Test

```swift
@MainActor
@Suite("Bug Fix Tests")
struct BugFixTests {

  @Test
  func openingCredits_doesNotFinishAtIndex2() async {
    // REGRESSION TEST for DISCOVERY-7
    // Bug: Finished at >= 2 (skipped screen 2)
    // Fix: Finishes at >= 3 (shows screen 2)

    let store = TestStore(initialState: OpeningCredits.State()) {
      OpeningCredits()
    }

    await store.send(.start)  // Index 1
    await store.send(.advance)  // Index 2

    // Should NOT finish at index 2
    // If we receive didFinish here, bug is back!
    try? await store.skip()

    // Verify still in progress
    #expect(store.state.currentIndex == 2)
    #expect(store.state.currentIndex < 3)

    // Now advance to index 3 - SHOULD finish
    await store.send(.advance)  // Index 3
    await store.receive(.delegate(.didFinish))
  }
}
```

---

## Remember

> **Every bug without a test will come back.**
>
> **Every fix needs a regression test.**
>
> **Tests are not optional - they're how we ensure correctness.**

---

**Last Updated:** November 6, 2025
