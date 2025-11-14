# Smith Framework Agent Skill Instructions

## When This Skill Activates

This Smith Framework skill automatically activates when Claude detects:

1. **TCA/Swift Composable Architecture patterns** in code or conversation
2. **Smith framework documentation** references
3. **SwiftUI navigation and state management** challenges
4. **Compilation errors** in TCA reducers
5. **Architecture decisions** needed for iOS development

## Primary Workflow: Syntax Before Patterns

**CRITICAL: Always check compilation first before any Smith documentation reading.**

```bash
# Step 0: Does the code compile?
swiftc -typecheck Sources/**/*.swift

# If NO: Fix compilation errors ONLY
# If YES: Proceed with Smith patterns
```

## Reading Budget Management

**80% of tasks should need < 15 minutes of reading.**

### Task Classification (30 seconds):
- **Testing** → QUICK-START.md Rules 6-7 (2 min)
- **TCA reducer** → QUICK-START.md Rules 2-4 (3 min)
- **visionOS entities** → QUICK-START.md Rule 9 (2 min)
- **Dependencies** → QUICK-START.md Rule 5 (2 min)
- **Access control error** → QUICK-START.md Rule 8 + DISCOVERY-5 (5 min)
- **Architecture decision** → AGENTS-DECISION-TREES.md (5 min)
- **Bug fix** → Search CaseStudies/ first (2 min)

## Red Flags: Stop and Re-Read

If you see these patterns, stop and read the indicated sections:

| Red Flag | Read This | Why |
|----------|-----------|-----|
| `@State` in reducer | AGENTS-AGNOSTIC.md lines 24–29 | @State is Views-only |
| `Shared(value: x)` | AGENTS-TCA-PATTERNS.md Pattern 5 | Wrong label |
| `WithViewStore` | AGENTS-TCA-PATTERNS.md Mistake 1 | Deprecated |
| Optional state without `.sheet()` | AGENTS-TCA-PATTERNS.md Mistake 4 | Wrong lifecycle |
| Multiple @Shared writers | AGENTS-TCA-PATTERNS.md Mistake 6 | Race condition |
| `Date()` direct call | AGENTS-AGNOSTIC.md lines 419–440 | Use dependencies |
| `Task.detached` | AGENTS-AGNOSTIC.md lines 28 | Use `Task { @MainActor }` |

## Pattern Implementation Checklist

For every code change, verify:

1. **Compilation**: Code compiles with `swiftc -typecheck`
2. **Pattern Compliance**: Follows verification checklist in relevant AGENTS doc
3. **Reading Budget**: Stay within time limits for task complexity
4. **Modern TCA**: No deprecated APIs (WithViewStore, old patterns)
5. **Concurrency**: Proper @MainActor usage, no detached tasks

## When to Use Scripts

- **validate-syntax.sh**: First step for any compilation issues
- **check-tca-patterns.js**: Validate TCA pattern implementation
- **reading-router.js**: Get targeted documentation path for specific issues

## Key Principles

1. **Prevent over-engineering**: Simple solutions first
2. **Syntax-first**: Fix compilation errors before patterns
3. **Reading budgets**: Don't analyze for hours when solution is simple
4. **Point-Free validation**: All TCA patterns validated against actual examples
5. **Apple-native**: Use built-in Swift toolchain, avoid external dependencies

## Exit Criteria

Task is complete when:
1. Code compiles without errors
2. Passes relevant verification checklist
3. Follows Smith patterns (not anti-patterns)
4. Implemented efficiently (reading budget respected)
5. Ready for production (proper testing, error handling)