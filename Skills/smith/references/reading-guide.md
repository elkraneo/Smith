# Smith Framework - Documentation Routing Guide

This guide implements the smart routing logic that prevents over-engineering by directing agents to the exact documentation needed for their specific task.

## Task Classification (30 seconds)

### Step 1: Identify Keywords
Analyze the user's request for these keyword patterns:

| Category | Keywords | Route |
|----------|----------|-------|
| **Testing** | "test", "Test", "@Test", "#expect", "TestClock" | QUICK-START.md Rules 6-7 (2 min) |
| **TCA reducer** | "reducer", "@Reducer", "State", "Action" | QUICK-START.md Rules 2-4 (3 min) |
| **visionOS** | "visionOS", "RealityView", "PresentationComponent" | QUICK-START.md Rule 9 (2 min) |
| **Dependencies** | "dependency", "@Dependency", "Date()", "UUID()" | QUICK-START.md Rule 5 (2 min) |
| **Access control** | "access control", "public", "internal" | QUICK-START.md Rule 8 + DISCOVERY-5 (5 min) |
| **Architecture** | "architecture", "pattern", "design decision" | AGENTS-DECISION-TREES.md (5 min) |
| **Bug fix** | "bug", "error", "fix", "not working" | Search CaseStudies/ first (2 min) |

### Step 2: Check for Case Studies (Bug Fix Priority)
For bug-related requests, search case studies first:

```bash
# Search strategy by symptom
grep -r "error message keyword" CaseStudies/
# Found matching DISCOVERY? Read that instead of general docs
```

**Examples:**
- "Child actions not received" → DISCOVERY-6 (if exists) or DISCOVERY-14
- "Compiler crashes" → DISCOVERY-13
- "Access control errors" → DISCOVERY-5

### Step 3: Apply Reading Budgets

| Task Complexity | Max Reading | When to Stop |
|-----------------|-------------|--------------|
| Simple syntax fix | 5 minutes | If over budget → "Is this over-engineering?" |
| Small feature | 15 minutes | If reading entire docs → Use targeted sections |
| Complex task | 30 minutes | If over budget → Break into smaller tasks |

## Red Flag Detection - Stop and Re-read

If you see these patterns, STOP and read the indicated sections:

| Red Flag Pattern | Immediate Action | Required Reading |
|------------------|------------------|------------------|
| `@State` in TCA reducer | Stop implementation | AGENTS-AGNOSTIC.md lines 24-29 |
| `WithViewStore` usage | Replace with @Bindable | AGENTS-TCA-PATTERNS.md Mistake 1 |
| `Shared(value: x)` constructor | Fix constructor | AGENTS-TCA-PATTERNS.md Pattern 5 |
| `Task.detached` | Replace with proper Task | AGENTS-AGNOSTIC.md lines 28 |
| `Date()` direct call | Use dependencies | AGENTS-AGNOSTIC.md lines 419-440 |
| Optional state without `.sheet()` | Wrong lifecycle | AGENTS-TCA-PATTERNS.md Mistake 4 |
| Multiple @Shared writers | Race condition | AGENTS-TCA-PATTERNS.md Mistake 6 |

## Routing Examples

### Example 1: TCA Navigation
```
User: "Add optional state for settings sheet to LoginFeature"

Routing:
1. Keywords: "optional state" + "sheet" + "LoginFeature"
2. Category: TCA reducer (navigation)
3. Route: AGENTS-TCA-PATTERNS.md Pattern 2
4. Budget: 5 minutes
5. Expected: .sheet(item:) + .scope() pattern
```

### Example 2: Compilation Error
```
User: "My reducer won't compile, child actions aren't being received"

Routing:
1. Keywords: "reducer" + "compile" + "child actions"
2. Category: Bug fix
3. Priority: Search CaseStudies first
4. Found: DISCOVERY-14 (Nested Reducer patterns)
5. Budget: 5 minutes
6. Expected: .ifLet closure or proper child feature setup
```

### Example 3: Testing
```
User: "How do I test my TCA reducer?"

Routing:
1. Keywords: "test" + "TCA reducer"
2. Category: Testing
3. Route: QUICK-START.md Rules 6-7
4. Budget: 2 minutes
5. If complex: AGENTS-AGNOSTIC.md lines 601-735
6. Expected: @Test, #expect, TestClock, @MainActor
```

## Verification Checklists

After reading and implementing, verify:

### Syntax Verification (Always First)
```bash
swiftc -typecheck Sources/**/*.swift
```

### Pattern Verification
- [ ] No deprecated APIs (WithViewStore, @Perception.Bindable)
- [ ] Proper TCA patterns (@Reducer, @ObservableState, @Bindable)
- [ ] Correct dependency usage (@DependencyClient)
- [ ] Proper concurrency (@MainActor, no Task.detached)
- [ ] Access control compliance (cascade check)

### Budget Verification
- [ ] Task completed within reading budget
- [ ] No over-analysis of simple problems
- [ ] Solution is appropriately scoped to request

## Anti-Over-Engineering Rules

1. **Simple solutions first** - Don't architecture for problems that don't exist
2. **Compilation before patterns** - Fix syntax errors before architectural changes
3. **Targeted reading only** - Read specific sections, not entire documents
4. **Budget enforcement** - Stop and reassess if time limits exceeded
5. **Validation checklists** - Use provided checklists, don't invent new patterns

## Exit Criteria

Task is complete when:
1. ✅ Code compiles without errors
2. ✅ Follows Smith patterns (no red flags)
3. ✅ Implemented within reading budget
4. ✅ Passes verification checklist
5. ✅ Addresses user's specific request

---

**Remember:** 80% of Smith tasks should complete in under 15 minutes. The goal is efficient, correct implementations, not comprehensive documentation analysis.