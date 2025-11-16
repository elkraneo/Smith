---
name: smith
description: Smith Framework patterns and modern iOS development discipline. Swift Composable Architecture patterns with syntax-first validation, reading budgets, and Point-Free validated TCA patterns. Prevents over-engineering by ensuring 2-minute fixes stay 2-minute fixes, not 90-minute documentation marathons.
allowed-tools: [Read, Bash, Write, Edit, Grep, Glob]
---

# Smith Framework Skill

A modern Swift development discipline that prevents over-engineering and ensures production-ready code through modular patterns.

## Quick Start - Choose Your Approach

### **Easy Mode** (Always Works)
```
"Use Smith skill for my code"
```
→ Loads all Smith patterns automatically

### **Efficient Mode** (Recommended for Agents)
```
"Use smith-core for dependency injection"
"Use smith-tca for reducer patterns"
"Use smith-platforms for visionOS"
"Use smith-core + smith-tca for TCA with dependencies"
```

## Smart Module Detection

**Smith automatically detects which modules to load based on your request:**

| Module | Auto-Load Keywords | Content |
|--------|------------------|---------|
| **smith-core** | "Swift", "dependency", "testing", "concurrency", "access control" | Universal Swift patterns |
| **smith-tca** | "TCA", "@Reducer", "@ObservableState", "ComposableArchitecture" | Swift Composable Architecture |
| **smith-platforms** | "iOS", "macOS", "visionOS", "RealityKit", "UIKit", "AppKit" | Platform-specific patterns |

## Usage Triggers

**Use smith-core when:**
- ✅ User asks about **dependency injection** (@Dependency, DependencyClient)
- ✅ User mentions **concurrency** (async/await, @MainActor, Task)
- ✅ User needs **testing patterns** (@Test, Swift Testing)
- ✅ User has **access control** issues (public, internal cascade)
- ✅ User wants **general Swift** patterns and best practices

**Use smith-tca when:**
- ✅ User asks about **TCA patterns** (Swift Composable Architecture)
- ✅ User mentions **@Reducer**, **@ObservableState**, **@Shared**
- ✅ User has **SwiftUI navigation** challenges (.sheet, .scope)
- ✅ User encounters **TCA compilation errors**
- ✅ User mentions **WithViewStore**, **ViewStore**, or **@Bindable**

**Use smith-platforms when:**
- ✅ User needs **visionOS entities** or **RealityView** patterns
- ✅ User mentions **iOS**, **macOS**, or platform-specific APIs
- ✅ User asks about **UIKit**, **AppKit**, or platform frameworks

**Examples:**
- "How do I add dependency injection to my Swift code?" → smith-core
- "My TCA reducer won't compile, what's wrong?" → smith-tca
- "How do I create RealityKit entities for visionOS?" → smith-platforms
- "Use Smith for my entire TCA app with visionOS" → smith-core + smith-tca + smith-platforms

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

### SPM Package Analysis Tools

**spmsift-Based Analyzer (ultra-efficient):**
```bash
Scripts/spm-spmsift-simple.sh [package-path]
```
- **Uses spmsift** (xcsift-equivalent for SPM) for maximum context efficiency
- **96% context savings** vs raw swift package output (~1.5KB vs 40KB+)
- Structured JSON with metrics: targets, dependencies, circular imports
- **Dependency:** Requires `spmsift` tool (install via `brew install elkraneo/tap/spmsift`)
- **Output format:** Clean JSON analysis for Claude processing

**Context-Efficient Analyzer (JSON output):**
```bash
Scripts/spm-analyze.sh [package-path]
```
- **JSON-structured output** equivalent to xcsift for SPM analysis
- Detects circular imports, deep imports, large dependencies
- **87% less context** than verbose validator (~471 bytes vs 2KB)
- Metrics: external_dependencies, internal_targets, issues, result status
- **Output format:** Machine-readable JSON for Claude processing

**Quick Validation (minimal output):**
```bash
Scripts/spm-quick.sh [package-path]
```
- **Single-line results:** ✅ PASS / ⚠️ WARNINGS / ❌ CRITICAL
- **95% less context** than verbose validator (3 lines vs 50+ lines)
- Exit codes for automation: 0 (pass/warning), 1 (critical)
- Zero explanatory text - pure diagnostic output

**Full Validator (detailed analysis):**
```bash
Scripts/spm-validate.sh [package-path] [--verbose]
```
- **Detects circular imports** (self-imports and mutual imports)
- Analyzes import depth (flags files with >10 imports)
- Checks for large dependencies (swift-syntax, GRDB, TCA)
- Three-tier exit status:
  - Exit 1: Circular imports found (CRITICAL - must fix)
  - Exit 0 (with warnings): Deep imports detected (refactor recommended)
  - Exit 0: Package structure healthy
- **Verbose mode:** `--verbose` flag shows detailed import chains
- **Critical for:** Debugging Xcode indexing hangs, 1.8GB+ index stores, "Processing files" stuck states

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
Scripts/validate-compilation-deep.sh [workspace-path] [scheme] [timeout-seconds] [--verbose]
```
- **Full workspace compilation** with **root cause analysis** - Context-efficient version
- **Smart early-exit detection:** Checks DerivedData size first (>500MB = corruption alert, exits immediately)
- Detects mid-build hangs (e.g., stuck at "Building 9/49 forever")
- **Primary diagnostic:** Index store corruption (most common cause of Xcode hangs)
- **Root cause analysis** (triggered with `--verbose` flag):
  - Module analysis: Which target is stuck, what are its dependencies
  - SPM cache: Which packages are slow (swift-syntax, GRDB, TCA)
- Timeout detection: 300s default (workspace builds are slower than single schemes)
- **Smart tool selection:** Uses sbsift for SPM projects, xcsift for Xcode projects (automatic detection)
- **Context-efficient output:** Uses sbsift/xcsift for structured JSON, not raw logs
- **Sequential execution:** No parallel processes (previous context drain fixed)
- **SPM optimization:** When `Package.swift` detected, uses `swift build` + sbsift (43% context savings)
- **Xcode compatibility:** Falls back to `xcodebuild` + xcsift for traditional projects
- **Tool installation:** sbsift via `brew install elkraneo/tap/sbsift`, xcsift via `brew install xcsift`
- **Critically:** Catches hangs hidden by `swiftc -typecheck` that only manifest in full build
- Returns: Hang point + actionable fixes + optional verbose diagnostics

**Normal mode (default):** Fast, focused output on index corruption
**Verbose mode:** `./validate-compilation-deep.sh . Scroll 300 --verbose` for detailed module analysis

**When to use:** After `validate-syntax.sh` passes, BEFORE reporting success to user

**Agent usage:** Required when user has reported build hangs in their workspace

## SPM Tool Selection Protocol

**Agents choose SPM analysis tools based on context budget and analysis depth:**

### Decision Matrix for SPM Analysis

| Context Situation | Use Tool | Why |
|-------------------|----------|-----|
| **Ultra-low context budget** (< 500 tokens) | `spm-spmsift-simple.sh` | Maximum efficiency (96% savings) if spmsift available |
| **Low context budget** (< 1K tokens) | `spm-quick.sh` | Single-line output (95% savings) |
| **Need machine-readable data** | `spm-spmsift-simple.sh` or `spm-analyze.sh` | JSON output for programmatic processing |
| **Investigating indexing hangs** | `spm-spmsift-simple.sh` | Precise metrics + circular import detection |
| **User wants detailed explanation** | `spm-validate.sh` | Human-readable with explanations |
| **User mentions "context" concerns** | `spm-spmsift-simple.sh` | Maximum efficiency (if available) |
| **Integration with other tools** | `spm-spmsift-simple.sh` or `spm-analyze.sh` | JSON can be piped to jq/other tools |
| **First-time analysis** | `spm-spmsift-simple.sh` → `spm-quick.sh` → `spm-analyze.sh` | Progressive triage workflow |

### Default Agent Behavior

```bash
# Standard workflow for SPM packages detection:
if [ -f "Package.swift" ]; then
    # Step 1: Try spmsift for maximum efficiency (if available)
    if command -v spmsift &> /dev/null; then
        ./Scripts/spm-spmsift-simple.sh .
        SPM_RESULT=$?
    else
        # Fallback to built-in tools
        ./Scripts/spm-quick.sh .
        SPM_RESULT=$?
    fi

    # Step 2: If issues found, get structured data
    if [ $SPM_RESULT -ne 0 ]; then
        ./Scripts/spm-analyze.sh .
    fi

    # Step 3: Only use verbose if user requests detailed analysis
    if user_asked_for_detailed; then
        ./Scripts/spm-validate.sh . --verbose
    fi
fi
```

**Key principle:** Start with most efficient tool, escalate only as needed.

## Script Execution Protocol

Agents using this skill follow a **Smart Conditional** approach to script execution:

### Step 1: Context Detection (Mandatory)

Evaluate whether code validation is applicable:
- **Swift files in working directory?** (YES/NO)
- **User provided code snippet?** (YES/NO)
- **Compilation error mentioned?** (YES/NO)
- **SPM package present?** (YES/NO) ← Check for Package.swift
- **Build performance issues?** (YES/NO) ← Indexing hangs, slow builds

### Step 2: Script Execution (Conditional Mandatory)

**IF any answer is YES from Step 1:**

**SPM Package Analysis (if Package.swift found):**
1. `spm-spmsift-simple.sh` (ultra-efficient - 96% context savings, requires spmsift)
2. **OR spm-quick.sh** (fallback triage - 95% context savings)
3. **IF issues found** → `spm-analyze.sh` (structured data - 87% savings)
4. **IF detailed analysis needed** → `spm-validate.sh` (verbose - only when requested)
5. **Reality Check (context-efficient):**
   - `swiftc -typecheck **/*.swift` (syntax validation, minimal context)
   - **IF claiming "compilable"** → Only then run `validate-compilation-deep.sh`

**Traditional Swift Analysis (if no Package.swift):**
1. `validate-syntax.sh` (quick syntax check)
2. `validate-compilation-deep.sh` (full compilation, catches hangs)
3. `tca-pattern-validator.js` (pattern analysis)

**Critical Rules:**
- ALWAYS start with most efficient tool (spm-quick.sh)
- ESCALATE only when issues found
- NEVER start with verbose tools (context conservation)
- **Reality Validation**: `swiftc -typecheck` before claiming "compilable"
- **Deep Build Only**: Run `validate-compilation-deep.sh` ONLY if user reports build issues
- **Never Assume**: Analysis tools ≠ compilation success
- Use script output to inform fixes

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

### Example: SPM Package Auto-Discovery Workflow
```
Agent: "Use Smith skill for Scroll performance issues"
    ↓
Step 1 Detection: Package.swift found? YES → performance issues? YES
    ↓
Step 2: Auto-run spm-quick.sh (context-efficient triage)
    ↓
Script: "⚠️ ReadingLibraryFeature.swift: 17 imports"
    ↓
Auto-escalate: Run spm-analyze.sh for structured data
    ↓
Script: JSON output with specific metrics
    ↓
Agent: Applies Smith dependency injection patterns
    ↓
All scripts pass → Task complete with minimal context usage
```

### Example: Traditional Swift Workflow
```
Agent: "Fix my TCA reducer - it has compilation errors"
    ↓
Step 1 Detection: Swift files present? YES → errors mentioned? YES → Package.swift? NO
    ↓
Step 2: Run traditional Swift workflow (validate-syntax.sh, etc.)
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

## Smith Module Navigation

### Available Modules

**smith-core** - Universal Swift Patterns
[📖 Read SMITH-CORE.md] - Always loaded for dependency injection, concurrency, testing, access control
- **Content**: Dependency injection, async/await patterns, testing framework, access control
- **When to read**: General Swift development, dependency injection, testing, concurrency
- **Key patterns**: @DependencyClient, @MainActor, Swift Testing, access control boundaries

**smith-tca** - Swift Composable Architecture
[📖 Read SMITH-TCA.md] - Load for TCA reducers, state management, navigation
- **Content**: @Reducer patterns, @ObservableState, @Shared, TCA navigation, testing
- **When to read**: TCA features, SwiftUI state management, Composable Architecture
- **Key patterns**: @Bindable store, .sheet/.scope navigation, @Shared discipline

**smith-platforms** - Platform-Specific Patterns
[📖 Read SMITH-PLATFORMS.md] - Load for iOS, macOS, visionOS development
- **Content**: RealityKit, UIKit/AppKit integration, cross-platform patterns
- **When to read**: Platform-specific development, visionOS AR, iOS/macOS APIs
- **Key patterns**: RealityView vs ARView, platform abstractions, conditional compilation

### How to Use Modules

**Smart Agent Approach:**
1. **Identify keywords** in user request
2. **Load relevant modules** based on keyword detection
3. **Start with smith-core** for universal patterns
4. **Add specialized modules** as needed

**Example Workflow:**
```
User: "Fix my TCA reducer with dependency injection for visionOS"

Agent detection:
- "TCA reducer" → load smith-tca
- "dependency injection" → load smith-core
- "visionOS" → load smith-platforms

Reading order:
1. SMITH-CORE.md (dependency injection patterns)
2. SMITH-TCA.md (reducer patterns)
3. SMITH-PLATFORMS.md (visionOS considerations)
```

### Context Efficiency Benefits

**Modular Loading:**
- **smith-core only**: ~3KB vs 20KB monolithic
- **smith-core + smith-tca**: ~8KB vs 20KB monolithic
- **All modules**: ~12KB vs 20KB monolithic

**Smart Loading Saves:**
- **40-60% context** reduction for focused tasks
- **Faster pattern matching** with less noise
- **Better relevance** - only read applicable patterns

## File Structure

```
smith/
├── SKILL.md                  (This file - main navigation)
├── embedded/                 (Modular documentation)
│   ├── SMITH-CORE.md         (Universal Swift patterns)
│   ├── SMITH-TCA.md          (TCA patterns)
│   ├── SMITH-PLATFORMS.md    (Platform patterns)
│   ├── AGENTS-*.md           (Legacy docs - kept for reference)
│   └── CLAUDE.md             (Direct agent instructions)
├── Scripts/                  (Analysis tools)
│   ├── spm-*.sh              (SPM analysis tools)
│   ├── validate-*.sh         (Compilation tools)
│   └── tca-pattern-validator.js (TCA validation)
└── README.md                 (Dependencies and installation)
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