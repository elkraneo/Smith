---
name: smith
description: Smith Framework patterns and modern iOS development discipline. Swift Composable Architecture patterns with syntax-first validation, reading budgets, and Point-Free validated TCA patterns. Prevents over-engineering by ensuring 2-minute fixes stay 2-minute fixes, not 90-minute documentation marathons.
allowed-tools: [Read, Bash, Write, Edit, Grep, Glob]
---

# Smith Framework Skill

A modern iOS development discipline for Swift Composable Architecture that prevents over-engineering and ensures production-ready code.

## Usage Triggers

Use this skill when:
- ✅ User asks about **TCA patterns** (Swift Composable Architecture)
- ✅ User mentions **@Reducer**, **@ObservableState**, **@Shared**
- ✅ User has **SwiftUI navigation** challenges (.sheet, .scope, state management)
- ✅ User encounters **compilation errors** in TCA reducers
- ✅ User mentions **compilation errors** in Swift/TCA code
- ✅ User asks about **dependency injection** patterns
- ✅ User mentions **WithViewStore**, **ViewStore**, or **@Bindable**
- ✅ User needs **visionOS entities** or **RealityView** patterns
- ✅ User asks about **Smith framework**, **AGENTS documentation**
- ✅ User has **access control** cascade failures
- ✅ User needs **testing patterns** for TCA features

Example queries that should trigger this skill:
- "How do I add optional state for a sheet in my TCA feature?"
- "My reducer won't compile, child actions aren't being received"
- "My Swift/TCA code won't compile, what's wrong?"
- "What's the difference between @Shared and regular state?"
- "Should I use WithViewStore or @Bindable?"
- "How do I handle dependencies in TCA?"
- "Fix this TCA compilation error"
- "How do I test my TCA reducer?"
- "What's wrong with this Smith pattern?"

## What This Skill Does

✅ **Syntax-first validation** - Always check compilation before patterns
✅ **Reading budgets** - 80% of tasks need < 15 minutes reading
✅ **Point-Free validated** - All TCA patterns verified against actual examples
✅ **Anti-pattern detection** - Stops common mistakes before implementation
✅ **Smart documentation routing** - 30-second task classification → targeted docs
✅ **Complete framework** - State management, concurrency, testing, architecture

## Core Problem Solved

**Smith addresses the 45x development time increase:**
- **Before:** 2-minute syntax fixes → 90-minute documentation marathons
- **After:** 2-minute fixes + 5-minute targeted reading = **7-minute solutions max**

## Key Framework Principles

### 1. Syntax Before Patterns
```bash
# ALWAYS check compilation first
swiftc -typecheck Sources/**/*.swift
# Fix errors ONLY, then proceed with patterns
```

### 2. Reading Budgets
| Task Type | Budget | Primary Reading |
|-----------|--------|------------------|
| Syntax fix | 5 min | swiftc output |
| Testing | 15 min | QUICK-START.md Rules 6-7 |
| TCA reducer | 15 min | QUICK-START.md Rules 2-4 |
| Navigation | 10 min | AGENTS-TCA-PATTERNS.md Pattern 2 |
| Architecture decision | 25 min | AGENTS-DECISION-TREES.md |

### 3. Red Flags - Stop and Re-read
| Red Flag | Solution |
|----------|----------|
| `@State` in reducer | Use @ObservableState |
| `WithViewStore` | Use @Bindable |
| `Shared(value: x)` | Use Shared(wrappedValue: x) |
| `Task.detached` | Use Task { @MainActor in } |
| `Date()` direct call | Use dependencies |

## Pattern Categories

### TCA Patterns (AGENTS-TCA-PATTERNS.md)
- Pattern 1: Observing state with @Bindable
- Pattern 2: Optional state navigation (.sheet + .scope)
- Pattern 3: Multiple destinations (complex navigation)
- Pattern 4: Bindings for form inputs
- Pattern 5: Shared state (@Shared, @SharedReader)

### Universal Patterns (AGENTS-AGNOSTIC.md)
- State Management & Concurrency (lines 24-313)
- Dependency Injection (lines 38-43, 317-415)
- Access Control & Public APIs (lines 443-598)
- Testing Framework (lines 75-80, 601-735)

### Decision Trees (AGENTS-DECISION-TREES.md)
- Tree 1: When to extract child features
- Tree 2: @DependencyClient vs Singleton
- Tree 3: Navigation patterns for different use cases

## Case Studies Available

- **DISCOVERY-13**: Swift compiler crashes and resolution
- **DISCOVERY-14**: Nested @Reducer patterns (Point-Free validated)
- **DISCOVERY-15**: Print vs OSLog logging patterns
- **DISCOVERY-5**: Access control cascade failures

## Platform-Specific Patterns

- **PLATFORM-VISIONOS**: visionOS entities, RealityView, PresentationComponent
- **PLATFORM-IOS**: iOS-specific patterns and APIs
- **PLATFORM-MACOS**: macOS development patterns

## Syntax-First Recipe (Always Start Here)

**Step 1: Check compilation before any patterns**
```bash
# Primary validation - ALWAYS do this first
swiftc -typecheck Sources/**/*.swift

# If compilation errors → Fix ONLY syntax errors
# If compilation succeeds → Proceed with Smith patterns
```

**Step 2: Apply reading budgets**
- Simple syntax fix: 5 minutes max
- Small feature: 15 minutes max
- Complex task: 30 minutes max
- If over budget → "Is this over-engineering?"

## Common Code Recipes

### Recipe: Optional State for Sheet Navigation
```swift
// ✅ Smith Pattern 2: Optional state
struct LoginFeature: Reducer {
    @ObservableState
    struct State {
        var settingsState: SettingsFeature.State?
        // ... other state
    }

    enum Action {
        case settingsButtonTapped
        case settings(SettingsFeature.Action)
        // ... other actions
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .settingsButtonTapped:
                state.settingsState = SettingsFeature.State()
                return .none
            case .settings(.dismiss):
                state.settingsState = nil
                return .none
            case .settings:
                return .none
            // ... other cases
            }
        }
        .ifLet(\.settingsState, action: \.settings) {
            SettingsFeature()
        }
    }
}

// View implementation
struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>

    var body: some View {
        // ... main content
        .sheet(item: $store.settingsState) { settingsState in
            NavigationStack {
                SettingsView(store: store.scope(state: \.settingsState,
                                               action: \.settings))
            }
        }
    }
}
```

### Recipe: Proper @Shared Usage (Single Owner Pattern)
```swift
// ✅ Correct @Shared constructor
struct ParentFeature: Reducer {
    @ObservableState
    struct State {
        @Shared(wrappedValue: "shared data") var sharedData
        var childState: ChildFeature.State
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.childState, action: \.child) {
            ChildFeature()
        }
    }
}

// Child feature reads @Shared, never writes
struct ChildFeature: Reducer {
    @ObservableState
    struct State {
        @SharedReader var sharedData: String  // Note: @SharedReader, not @Shared
    }
    // ... reducer body that only reads sharedData
}
```

### Recipe: Testing TCA Reducers
```swift
@Test
func loginFeature() async {
    let store = TestStore(initialState: LoginFeature.State()) {
        LoginFeature()
    }

    await store.send(.settingsButtonTapped) {
        $0.settingsState = SettingsFeature.State()
    }

    await store.send(.settings(.dismiss)) {
        $0.settingsState = nil
    }
}
```

## Anti-Pattern Detection (Stop and Fix)

| Anti-Pattern | Correct Pattern | Why |
|--------------|----------------|-----|
| `@State var state: State` | `@ObservableState` | @State is Views-only |
| `WithViewStore(store)` | `@Bindable var store` | WithViewStore is deprecated |
| `Shared(value: data)` | `Shared(wrappedValue: data)` | Wrong constructor |
| `Task.detached { }` | `Task { @MainActor in }` | Detached tasks break main actor |
| `Date()` in reducer | `@Dependency(\.date) var date` | Use dependencies |
| `.sheet(isPresented:)` | `.sheet(item:)` + `.scope()` | Wrong lifecycle handling |

## Available Tools & Scripts

The Smith skill includes executable scripts that Claude can run directly:

### Syntax Validation
```bash
Scripts/validate-syntax.sh
```
- Swift compilation checking with `swiftc -typecheck`
- First line of defense: fix syntax errors before patterns
- Detects compilation issues across all Swift files

### Format & Pattern Validation
```bash
Scripts/smith-format-check.sh
```
- Swift Format validation with Smith-specific rules
- Checks for deprecated patterns (WithViewStore, @Perception.Bindable)
- Validates @Shared constructors and anti-patterns
- Uses Apple-native Swift Format (no external dependencies)

### TCA Pattern Validation
```bash
Scripts/tca-pattern-validator.js [file-or-directory]
```
- Deep TCA pattern analysis
- Detects modern @Reducer vs deprecated patterns
- Validates @Shared usage and concurrency patterns
- Provides specific fix recommendations with references

### Deep Compilation Validation
```bash
Scripts/validate-compilation-deep.sh [workspace-path] [scheme] [timeout-seconds]
```
- **Full workspace compilation** (not just syntax validation)
- Detects mid-build hangs (e.g., stuck at "Building 9/49 forever")
- Shows exact progress: Which target got stuck (Compiling X, Linking Y, Building Z/N)
- Timeout detection: 300s default (workspace builds are slower than single schemes)
- Uses xcsift for structured output, falls back to error checking
- **Critically:** Catches hangs hidden by `swiftc -typecheck` that only manifest in full build
- Returns: Hang point + suggested fixes (clean build, DerivedData, check circular deps)

**When to use:** After `validate-syntax.sh` passes, BEFORE reporting success to user

**Agent usage:** Required when user has reported build hangs in their workspace

## Script Execution Protocol

Agents using this skill follow a **Smart Conditional** approach to script execution:

### Step 1: Context Detection (Mandatory)

Evaluate whether code validation is applicable:
- **Swift files in working directory?** (YES/NO)
- **User provided code snippet?** (YES/NO)
- **Compilation error mentioned?** (YES/NO)

### Step 2: Script Execution (Conditional Mandatory)

**IF any answer is YES from Step 1:**
- Execute validation scripts **in order**:
  1. `validate-syntax.sh` (quick syntax check)
  2. `validate-compilation-deep.sh` (full compilation, catches hangs)
  3. `tca-pattern-validator.js` (pattern analysis)
- Use script output to inform fixes
- If scripts fail: Note the failure, proceed with pattern analysis
- **Never bail out** due to script failures—patterns guide fixes even without script output
- **Critical:** If deep validation hangs → Do NOT report success until hang is resolved

**IF all answers are NO from Step 1:**
- Skip scripts entirely
- Provide pattern/knowledge guidance directly
- No loss of capability for conceptual questions

### Step 3: Analysis (Always Mandatory)

**With script output:** Use objective errors + patterns for precise fixes
**Without script output:** Use pattern knowledge + best practices for guidance
**Either way:** Always provide actionable guidance

## Smith Workflow (Agents & Scripts)

When you work on Swift/iOS development:

1. **Detect context**: Is there code to validate? (Step 1 above)
2. **Execute conditionally**: If YES, run scripts; if NO, skip
3. **Route to recipe**: 30-second classification → targeted guidance
4. **Apply recipe**: Use provided code patterns and steps
5. **Verify**: If scripts ran, re-validate after fixes
6. **Complete**: Within reading budget, with production-ready code

### Example: Script-Applied Workflow
```
Agent: "Fix my TCA reducer - it has compilation errors"
    ↓
Step 1 Detection: Swift files present? YES → errors mentioned? YES
    ↓
Step 2: Run validate-syntax.sh
    ↓
Script output: "3 syntax errors in LoginFeature.swift"
    ↓
Agent: Fixes syntax based on script output
    ↓
Run tca-pattern-validator.js
    ↓
Script: "Detected WithViewStore usage (deprecated)"
    ↓
Agent: Replaces with @Bindable using recipe
    ↓
All scripts pass → Task complete
```

### Example: Conceptual-Only Workflow
```
Agent: "What's the difference between @Shared and @SharedReader?"
    ↓
Step 1 Detection: Swift files? NO → code provided? NO
    ↓
Step 2: Scripts skipped (not applicable)
    ↓
Agent: Provides pattern explanation + recipes
    ↓
Task complete (no validation needed)
```

## File Structure

```
smith/
├── SKILL.md                  (This file)
├── embedded/                 (Core Smith documentation)
│   ├── AGENTS-AGNOSTIC.md
│   ├── AGENTS-TCA-PATTERNS.md
│   ├── AGENTS-DECISION-TREES.md
│   ├── CLAUDE.md
│   ├── DISCOVERY-*.md
│   └── PLATFORM-*.md
└── references/
    ├── MANIFEST.md           (Complete content inventory)
    └── reading-guide.md      (Documentation routing logic)
```

## Cost

**Total cost: $0/month**
- Skill file: ~15KB (minimal)
- Embedded content: ~400KB (complete framework)
- Token overhead: Minimal (smart routing only loads what's needed)

## Verification Checklists

Every implementation includes verification checklists:

### TCA Reducer Checklist
- [ ] Uses @Reducer macro (modern syntax)
- [ ] State uses @ObservableState
- [ ] No WithViewStore usage
- [ ] Proper @Shared patterns (single owner)
- [ ] Actions use enum, not struct
- [ ] Reducer signature: `reduce(into:action:)`

### Testing Checklist
- [ ] Uses @Test and #expect()
- [ ] TCA tests marked @MainActor
- [ ] Uses TestClock() for time
- [ ] Proper dependency mocking

### Access Control Checklist
- [ ] Traced transitive dependencies
- [ ] All referenced types are public
- [ ] No cascade failures

## For the Future

You can ask Claude anytime to:
- ✅ Add new case studies to the skill
- ✅ Update patterns for new iOS versions
- ✅ Explain any Smith concept or pattern
- ✅ Validate code against Smith rules

Example: "Add a case study for SwiftUI navigation patterns"

## Questions?

Ask Claude directly about any Smith pattern, TCA implementation, or iOS architecture challenge. The skill will provide targeted guidance with reading budgets and verification checklists.

---

**Framework Version:** 1.1.1
**Last Updated:** November 14, 2025
**Validated Against:** Point-Free Swift Composable Architecture examples