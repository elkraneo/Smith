# DISCOVERY-14: Nested @Reducer Macro Gotchas and Actual Point-Free Patterns

**Date**: 2025-11-13
**Impact**: CRITICAL - Agent confidence destruction, compilation failure cascades
**Status**: RESOLVED - Documented correct Point-Free patterns (validated against official TCA examples)

## Problem Summary

Nested @Reducer macros create catastrophic failure cascades where agents:
1. Create complex patterns that don't match Point-Free usage
2. Face endless compilation errors from incorrect syntax
3. Resort to trial-and-error debugging
4. Make syntax mistakes from frustration
5. Lose all confidence in TCA patterns

**Root Cause**: Agents create overly complex solutions instead of following Point-Free's simple, proven patterns.

---

## 🚨 **CORRECTED: Actual Point-Free Patterns (VALIDATED)**

Based on analysis of actual Point-Free TCA examples from `/Examples/CaseStudies/SwiftUICaseStudies/`:

### Pattern 1: Child Reducer Extraction (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN
@Reducer
struct ParentFeature {
    @ObservableState
    struct State {
        var childState: ChildFeature.State
        var destination: Destination?
    }

    enum Action {
        case child(ChildFeature.Action)      // ✅ NO = ChildFeature.body needed
        case destination(PresentationAction<Destination.Action>)
        case otherAction
    }

    @Reducer(state: .equatable)
    enum Destination {
        case modal(ChildFeature.State)      // ✅ NO = ChildFeature.body needed
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
        .ifLet(\.$destination, action: \.destination)  // ✅ NO CLOSURE NEEDED
    }
}
```

### Pattern 2: Navigation Stack (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN
@Reducer
struct SignUpFeature {
    @Reducer
    enum Path {
        case basics(BasicsFeature)           // ✅ NO = BasicsFeature.body
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
        case path(StackActionOf<Path>)       // ✅ NO = Path.body needed
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
        .forEach(\.path, action: \.path)     // ✅ NO CLOSURE NEEDED
    }
}
```

### Pattern 3: Multiple Destinations (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN
@Reducer
struct MultipleDestinations {
    @Reducer
    enum Destination {
        case drillDown(Counter)              // ✅ NO = Counter.body
        case popover(Counter)                // ✅ SIMPLE DECLARATION
        case sheet(Counter)
    }

    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>) // ✅ NO EXTRACTION
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
        .ifLet(\.$destination, action: \.destination)  // ✅ NO CLOSURE NEEDED
    }
}
```

### Pattern 4: Simple Child Feature (CORRECT)

```swift
// ✅ POINT-FREE ACTUAL PATTERN
@Reducer
struct Root {
    struct State {
        var focus = Focus.State()
    }

    enum Action {
        case focus(Focus.Action)             // ✅ NO = Focus.body needed
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.focus, action: \.focus) {
            Focus()
        }
    }
}
```

---

## 🔧 **CRITICAL: What Agents Get Wrong**

### ❌ Agent Anti-Patterns (DON'T DO THESE)

**Based on actual agent mistakes observed:**

```swift
// ❌ AGENT MISTAKE 1: Over-complicating enum cases
@Reducer
enum Destination {
    case modal(ChildFeature.State = ChildFeature.body)  // ❌ WRONG: .body not needed
}

// ❌ AGENT MISTAKE 2: Over-complicating actions
enum Action {
    case child(ChildFeature.Action = ChildFeature.body) // ❌ WRONG: .body not needed
}

// ❌ AGENT MISTAKE 3: Adding unnecessary closures
.ifLet(\.$destination, action: \.destination) {
    Destination()  // ❌ WRONG: Closure not needed
}

// ❌ AGENT MISTAKE 4: Adding unnecessary extensions
extension ChildFeature.State: Equatable {}  // ❌ OFTEN UNNECESSARY
extension ChildFeature.Action: Sendable {}  // ❌ OFTEN UNNECESSARY
```

### ✅ Agent Correct Patterns (DO THESE)

```swift
// ✅ CORRECT: Keep it simple like Point-Free
@Reducer
enum Destination {
    case modal(ChildFeature.State)          // ✅ SIMPLE: no .body
}

enum Action {
    case child(ChildFeature.Action)         // ✅ SIMPLE: no .body
}

.ifLet(\.$destination, action: \.destination)  // ✅ SIMPLE: no closure
```

---

## 📋 **CRITICAL: Agent Simplification Rules**

### Rule 1: Follow Point-Free Examples Literally

**When in doubt, copy exactly from Point-Free examples:**

```swift
// ✅ COPY THIS PATTERN EXACTLY:
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

### Rule 2: Don't Add Complexity Unless Required

**Agents tend to over-engineer. Keep it simple:**

- ✅ **Simple enum cases**: `case child(ChildFeature)`
- ✅ **Simple actions**: `case child(ChildFeature.Action)`
- ✅ **Simple composition**: `.ifLet(\.$destination, action: \.destination)`

### Rule 3: Only Add Extensions When Actually Needed

**Don't add extensions proactively:**

```swift
// ❌ DON'T ADD THIS BY DEFAULT:
extension ChildFeature.State: Equatable {}
extension ChildFeature.Action: Sendable {}

// ✅ ONLY ADD WHEN COMPILER COMPLAINS:
// If you get "Type 'ChildFeature.State' does not conform to Equatable"
// THEN add the extension, not before
```

---

## 🎯 **CRITICAL: Agent Workflow for Nested @Reducer**

### Step 1: Start with Point-Free Template

```swift
@Reducer
struct MyFeature {
    @Reducer
    enum Destination {
        case child(ChildFeature)            // ✅ Start simple
    }

    @ObservableState
    struct State {
        @Presents var destination: Destination.State?
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>) // ✅ Start simple
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)  // ✅ Start simple
    }
}
```

### Step 2: Compile and Check Errors

```bash
# Build first, see what actually breaks
xcodebuild build -scheme MyScheme

# If it compiles: ✅ YOU'RE DONE
# If you get errors: fix ONLY what breaks
```

### Step 3: Fix Only What Breaks

**If you get "Equatable" error:**
```swift
// THEN add this, not before:
extension MyFeature.State: Equatable {}
```

**If you get "Sendable" error:**
```swift
// THEN add this, not before:
extension MyFeature.Action: Sendable {}
```

### Step 4: Test Preview Construction

```swift
#Preview {
    MyFeature(
        initialState: MyFeature.State(
            destination: .child(ChildFeature.State())  // ✅ Should work
        )
    )
}
```

---

## 📊 **Complexity Comparison: Agent Mistakes vs Point-Free**

| Aspect | ❌ Agent Over-Engineering | ✅ Point-Free Simple |
|--------|-------------------------|----------------------|
| **Enum Cases** | `case child(ChildFeature.State = ChildFeature.body)` | `case child(ChildFeature.State)` |
| **Actions** | `case child(ChildFeature.Action = ChildFeature.body)` | `case child(ChildFeature.Action)` |
| **Composition** | `.ifLet(\.$dest, action: \.dest) { Destination() }` | `.ifLet(\.$dest, action: \.dest)` |
| **Extensions** | Always add proactively | Add only when compiler complains |
| **Result** | Compilation errors, frustration | Works first time |

---

## 🔍 **Validation: How We Know These Patterns Are Correct**

### Source: Point-Free TCA Examples

1. **`04-Navigation-Multiple-Destinations.swift`**: Multiple destinations without `.body` syntax
2. **`02-SharedState-Onboarding.swift`**: Navigation stack without closure forms
3. **`tvOSCaseStudies/Core.swift`**: Simple child composition without extensions
4. **`ReducerTests.swift`**: Basic @Reducer patterns without extra complexity

### Key Validation Points

✅ **No `= .body` syntax** found in any Point-Free examples
✅ **No closure forms** used with `.ifLet` or `.forEach`
✅ **Simple enum declarations** work perfectly
✅ **Extensions only when needed** for specific protocol conformance

---

## 🚨 **CRITICAL: Why Agents Over-Engineer**

1. **Fear of errors**: Add extensions proactively to prevent compilation failures
2. **Misunderstanding**: Think `.body` extraction is required for child routing
3. **Complexity bias**: Assume complex problems require complex solutions
4. **Pattern confusion**: Mix patterns from different TCA versions or sources

**The truth**: Point-Free patterns are intentionally simple and work perfectly as-is.

---

## ✅ **CORRECTED: Verification Checklist**

Before committing nested @Reducer code:

- [ ] **Simple enum cases**: `case child(ChildFeature.State)` (no `= .body`)
- [ ] **Simple actions**: `case child(ChildFeature.Action)` (no `= .body`)
- [ ] **Simple composition**: `.ifLet(\.$destination, action: \.destination)` (no closure)
- [ ] **Extensions only when needed**: Add only if compiler complains
- [ ] **Preview constructible**: Can create state without compilation errors
- [ ] **Follows Point-Free examples**: Looks like official TCA examples

---

## 🎯 **Key Insights (CORRECTED)**

1. **Point-Free patterns are simple**: Don't add complexity unless needed
2. **`= .body` syntax is not used**: Simple enum declarations work perfectly
3. **Closure forms are not required**: `.ifLet` works without `{ Destination() }`
4. **Extensions are reactive**: Add only when compiler complains, not proactively
5. **Copy Point-Free literally**: When in doubt, copy exactly from their examples

**This prevents the catastrophic agent confidence destruction cascade by using proven Point-Free patterns that work.**

---

## Framework Integration

**Update**: AGENTS-TCA-PATTERNS.md
- ✅ Corrected Pattern 6 with validated Point-Free patterns
- ✅ Added agent anti-patterns to avoid
- ✅ Added simplification rules and workflow
- ✅ Updated verification checklist with correct items

**Enforcement**: [CRITICAL] - Violations cause compilation failures

---

**Last Updated**: November 13, 2025
**Validation**: Confirmed against Point-Free TCA examples in `/Examples/CaseStudies/`