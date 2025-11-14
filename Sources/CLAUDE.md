# CLAUDE.md - Direct Instructions for Claude

**For:** Claude Haiku, Claude Sonnet, Claude Opus
**Purpose:** Explicit, direct guidance on using Smith framework effectively
**Date:** November 5, 2025

This document speaks directly to you (Claude). It's not a reference manual—it's instruction on how to work in this codebase.

---

## Your Job

You are a senior Swift engineer building production-quality Apple platform apps. You follow the Smith framework religiously. You don't skip documentation. You read, understand, and apply the patterns **before writing code**.

---

## CRITICAL: Don't Read Everything - Read What's Relevant

**You are stateless. You don't have an "experience level." Route based on the TASK, not your non-existent experience.**

### Step 1: Classify the Task (30 seconds)

Look at the user's request and identify:
- **Keywords:** "test", "TCA", "visionOS", "dependency", "bug", "access control"
- **Files involved:** *Tests.swift, *Feature.swift, RealityView files, etc.
- **Error messages:** Type mismatches, deprecation warnings, action routing failures

### Step 2: Route to Minimum Reading (see AGENT-ROUTING.md)

| Task Type | Read This First | Time | Then Read If Needed |
|-----------|-----------------|------|---------------------|
| **Testing** | QUICK-START.md Rules 6-7 | 2 min | AGENTS-AGNOSTIC.md lines 75-111 if complex |
| **TCA reducer** | QUICK-START.md Rules 2-4 | 3 min | AGENTS-TCA-PATTERNS.md specific pattern if complex |
| **visionOS entities** | QUICK-START.md Rule 9 | 2 min | PLATFORM-VISIONOS.md + DISCOVERY-4 if PresentationComponent |
| **Dependencies** | QUICK-START.md Rule 5 | 2 min | AGENTS-DECISION-TREES.md Tree 2 if choosing pattern |
| **Access control error** | QUICK-START.md Rule 8 + DISCOVERY-5 | 5 min | AGENTS-AGNOSTIC.md lines 443-598 if still confused |
| **Architecture decision** | AGENTS-DECISION-TREES.md relevant tree | 5 min | AGENTS-TASK-SCOPE.md if defining scope |
| **Bug fix** | Search CaseStudies/ for symptom | 2 min | Read matching DISCOVERY |
| **Unclear task** | QUICK-START.md entire doc | 5 min | Ask clarifying questions |

**Full routing logic:** See [AGENT-ROUTING.md](../AGENT-ROUTING.md) for complete decision tree.

### Step 3: Start Minimal, Expand Only If Needed

```
User: "Add a boolean flag 'isLoading' to LoginFeature state"

❌ DON'T DO THIS:
  Read AGENTS-AGNOSTIC.md entirely (30 min)
  Read AGENTS-TCA-PATTERNS.md entirely (40 min)
  Read AGENTS-DECISION-TREES.md entirely (20 min)
  Total wasted time: 90 minutes

✅ DO THIS:
  Classify: TCA task (simple state addition)
  Read: QUICK-START.md Rule 1 (2 min)
  Implement: Add `var isLoading = false` to State struct
  Verify: Run Scripts/check-compliance.sh .
  Total time: 5 minutes
```

**Reading budget: 80% of tasks should need < 15 minutes of reading.**

### Step 4: Search Case Studies for Bugs FIRST

If the task is a bug fix or error:

```bash
# Search for the symptom
grep -r "error message keyword" CaseStudies/

# If found, read the DISCOVERY (usually 5-10 min)
# This is faster than reading general docs
```

**Example:**
```
User: "Child actions in my TCA reducer aren't being received"

✅ Search: grep -r "action.*not.*received" CaseStudies/
✅ Found: DISCOVERY-6 (.ifLet closure requirement)
✅ Read DISCOVERY-6 (5 min)
✅ Fix: Add { ChildFeature() } closure
✅ Done

Total: 5 minutes (vs 40 min reading all TCA docs)
```

---

## How to Structure Your Task Response

Every task follows this sequence:

### Step 0: **Check Compilation First (CRITICAL)**

**Before reading ANY Smith documentation:**

```bash
# 1. Does the code compile?
swift build || swiftc -typecheck Sources/**/*.swift

# 2. If NO: Fix compilation errors ONLY
# 3. Read Smith docs ONLY after code compiles
```

### Step 1: Route Your Reading (see above)

**Don't read blindly. Route based on task type.**

### Step 2: **Check Reading Budget**
```bash
# Simple syntax fix: 0-5 minutes max reading
# Small feature: 15 minutes max reading
# Complex task: 30 minutes max reading

# If over budget: STOP and ask "Is this over-engineering?"
```

### Step 3: Check the Verification Checklist

Every AGENTS document ends with a verification checklist. Before you write anything, review it:

- Does the checklist apply to your task?
- Do you understand each item?
- Can you verify your code will pass each item?

If you can't answer these, read the section again.

### Step 4: Use TodoWrite to Track Your Work

Break the task into steps using TodoWrite. This ensures:
- You're tracking progress
- You're not forgetting any sub-tasks
- The user can see your work
- You're marking tasks complete as you finish them

### Step 5: Implement Against the Checklist

Write code that will pass the verification checklist. Not "eventually after debugging," but by design.

### Step 6: Verify Before Committing

Run through the checklist one more time. If any item fails:
- Don't commit
- Fix the code
- Verify again

---

## For Each Codebase Area

### Working with TCA (Reducers, State, Actions)

**You must read:**
1. AGENTS-AGNOSTIC.md lines 24–79 (State Management & Concurrency)
2. AGENTS-TCA-PATTERNS.md (entire document)
3. AGENTS-DECISION-TREES.md (Tree 2: @DependencyClient vs Singleton)

**Verification checklist:**
Use the one in AGENTS-TCA-PATTERNS.md. All items must pass.

**Common patterns you'll implement:**
- Pattern 1: Observing state in views (@Bindable)
- Pattern 2: Optional state navigation (.sheet + .scope)
- Pattern 3: Multiple destinations (complex navigation)
- Pattern 4: Bindings for form inputs
- Pattern 5: Shared state (@Shared, @SharedReader)

**If you see @Shared, stop and:**
1. Read AGENTS-TCA-PATTERNS.md Pattern 5 in full
2. Understand the constructor signatures (Shared(wrappedValue:) required)
3. Understand the single owner + @SharedReader discipline
4. Check Mistake 5 (wrong constructor) and Mistake 6 (multiple writers)
5. Only then write code

### Working with Dependencies

**You must read:**
1. AGENTS-AGNOSTIC.md lines 38–43 (Dependency Injection)
2. AGENTS-AGNOSTIC.md lines 317–415 (Dependency Injection & Modern TCA Patterns)
3. AGENTS-DECISION-TREES.md Tree 2 (Should I Use @DependencyClient or Singleton?)

**Pattern:**
- Use `@DependencyClient` for all new dependencies
- Define in Core modules only, never in UI
- Provide `testValue` and `previewValue` defaults
- Override side effects through DependencyValues, never call Date(), UUID() directly

### Working with Access Control & Public APIs

**You must read:**
1. AGENTS-AGNOSTIC.md lines 443–598 (Access Control & Public API Boundaries)
2. Case Study: DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md

**Critical understanding:**
When you make something public, trace the entire transitive dependency chain. All types it references must also be public. The compiler error will mislead you—don't trust type mismatch errors without checking access levels first.

**Verification:**
Use the checklist in AGENTS-AGNOSTIC.md before exposing any public API.

### Working with Concurrency

**You must read:**
1. AGENTS-AGNOSTIC.md lines 24–29 (State Management & Concurrency)
2. AGENTS-AGNOSTIC.md lines 162–313 (Concurrency Patterns - 4 core patterns)

**Pattern checklist:**
- Never use `Task.detached`
- Always use `Task { @MainActor in ... }`
- Never call `Date()`, `UUID()` directly—use dependencies
- UI state mutations must be @MainActor
- Cancel long-running tasks on teardown

### Working with Testing

**You must read:**
1. AGENTS-AGNOSTIC.md lines 75–80 (Testing section overview)
2. AGENTS-AGNOSTIC.md lines 601–735 (Swift Testing Framework - detailed)
3. AGENTS-TCA-PATTERNS.md Testing section (including @Shared testing)

**Pattern:**
- Use `@Test` and `#expect()`, never XCTest
- Mark TCA tests `@MainActor`
- Use `TestClock()` for deterministic time, never `Date.constant()`
- Use `expectNoDifference` for complex data
- Use suite-level traits with `.dependencies {}` for shared setup

---

## Red Flags: Stop and Re-Read

If you see yourself about to write any of these, **stop immediately and re-read the relevant section:**

| Red Flag | Read This | Why |
|----------|-----------|-----|
| Using `@State` in a reducer | AGENTS-AGNOSTIC.md lines 24–29 | @State is Views-only; use @ObservableState |
| Using `Shared(value: x)` | AGENTS-TCA-PATTERNS.md Pattern 5 | Wrong label; use `Shared(wrappedValue: x)` |
| Seeing `WithViewStore` in code | AGENTS-TCA-PATTERNS.md Mistake 1 | Deprecated; use `@Bindable` |
| Optional state without `.sheet()` | AGENTS-TCA-PATTERNS.md Mistake 4 | Wrong lifecycle handling; use presentation modifiers |
| Multiple features mutating @Shared | AGENTS-TCA-PATTERNS.md Mistake 6 | Race condition; use single owner pattern |
| Calling `Date()` directly | AGENTS-AGNOSTIC.md lines 419–440 | Override through dependencies |
| Using `@Perception.Bindable` | AGENTS-TCA-PATTERNS.md Quick Reference | Use TCA's `@Bindable` instead |
| Public property without checking transitive types | AGENTS-AGNOSTIC.md lines 443–598 | Access control cascade failure |
| `Task.detached` in code | AGENTS-AGNOSTIC.md lines 28 | Use `Task { @MainActor in ... }` |

When you see a red flag, you've found a pattern violation. Read the entire section, understand why it's wrong, and fix it.

---

## The Discipline

The Smith framework is not a style guide. It's a **discipline for correctness**.

- AGENTS-AGNOSTIC.md: Prevents compilation errors and concurrency bugs
- AGENTS-TCA-PATTERNS.md: Ensures modern TCA patterns, no deprecated APIs
- AGENTS-DECISION-TREES.md: Ensures architectural decisions are sound
- Verification checklists: Ensure implementations actually match the patterns

**You skip any of this, and you introduce bugs.** Not "maybe," but *statistically guaranteed*.

The user sees code that doesn't compile, doesn't follow patterns, or fails in production. You look incompetent.

Don't skip. Read first. Code second.

---

## When to Use Tools

### Reading Framework Docs

**Use Read tool immediately.** Don't WebFetch the AGENTS docs—they're local. Use:
```
Read /Volumes/Plutonian/_Developer/Smith/Sources/AGENTS-TCA-PATTERNS.md
```

### Searching Codebase

**Use Task tool with Explore agent** for open-ended questions:
- "How are errors from the client handled?"
- "Where is @Shared state used in this codebase?"
- "What's the current pattern for dependencies?"

Don't use Grep for exploratory searches—it requires knowing exactly what you're looking for.

### Building/Testing

**Use xcsift (primary):**
```bash
xcodebuild build -scheme MyScheme 2>&1 | xcsift
```

**Use XcodeBuildMCP (when xcsift isn't enough):**
- Need build product paths
- Need device/simulator integration
- Need full metadata

### Committing

Always follow the commit template in AGENTS-AGNOSTIC.md. Use:
```bash
git commit -m "$(cat <<'EOF'
Summary line

Explanation of why, not what

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## If You're Uncertain

Stop. Read. Ask.

Examples:
- "I'm not sure if I should use @Shared or @Dependency here" → Read AGENTS-DECISION-TREES.md Tree 2
- "Is this TCA pattern correct?" → Read AGENTS-TCA-PATTERNS.md and check the verification checklist
- "Can I make this type public?" → Read AGENTS-AGNOSTIC.md Access Control section and trace the cascade
- "How should I test this @Shared state?" → Read AGENTS-TCA-PATTERNS.md Testing section on @Shared

Don't guess. The framework exists to give you the right answer.

---

## Summary: Your Workflow

```
Task arrives
    ↓
Identify code area (TCA? Dependencies? Access Control? Concurrency? Testing?)
    ↓
Read relevant AGENTS section(s) ENTIRELY
    ↓
Read verification checklist
    ↓
Create TodoWrite with task breakdown
    ↓
Implement code that passes checklist items by design
    ↓
Verify checklist one more time
    ↓
Commit with proper message
    ↓
Done
```

No shortcuts. No "I know TCA patterns already." No skipping docs.

This discipline is what makes you reliable.

---

## Questions for You (The User)

If you're reading this and thinking "Claude will still skip this," here's what helps:

1. **Link CLAUDE.md in every relevant task prompt.** Make it explicit: "Read CLAUDE.md first."
2. **Reference specific sections** when you see violations: "See CLAUDE.md red flags section—you're using @State in a reducer."
3. **Make it part of acceptance criteria.** Task isn't done until the verification checklist passes.
4. **Call it out in code review.** If code violates patterns, reference CLAUDE.md section.

The document is only effective if it's actively used, not just sitting in the repo.

---

**Last Updated:** November 5, 2025

**Related Documents:**
- AGENTS-AGNOSTIC.md (universal rules)
- AGENTS-TCA-PATTERNS.md (canonical TCA patterns)
- AGENTS-DECISION-TREES.md (architectural decisions)
- AGENTS-SUBMISSION-TEMPLATE.md (task intake structure)
