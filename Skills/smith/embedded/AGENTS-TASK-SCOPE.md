# Task Scope Definition for Agents

Every task defines **three zones** that determine what agents can and cannot edit without approval.

---

## The Three Zones

### Safe Zone ✅
**Files directly required for this feature. Edit freely, no approval needed.**

These files are essential to the task. Agents can modify them without asking.

**Example Task: "Add article caching"**

Safe Zone:
- `ArticleCache.swift` (the feature itself)
- `ArticleCacheTests.swift` (tests for the feature)
- `Package.swift` (only if adding a new dependency)

Agents can edit these without asking. If something breaks in the Safe Zone, that's part of the task.

---

### Approval Zone ⚠️
**Files affected by this feature but not central to it. Ask before editing.**

These files might need changes to support the feature, but they're not the feature itself. Agents must describe the change and ask for permission.

**Example Task: "Add article caching"**

Approval Zone:
- `ArticleFeature.swift` (if API signature changes to support caching)
- `ArticleQueue.swift` (if it needs to use cache)
- `Docs/ArticleCache.md` (documentation of the feature)
- `AGENTS.md` (if a new pattern needs documenting)

**Agent behavior in Approval Zone:**
```
Agent: "This change requires updating ArticleFeature.swift
because [clear explanation].

Here's the change:
[shows diff]

Should I proceed? Y/N"
```

---

### Forbidden Zone ❌
**Everything else. Stop and report. Only proceed with explicit permission.**

These files are outside the scope of this task. Agents must never edit them without explicit approval from the user.

**Example Task: "Add article caching"**

Forbidden Zone:
- Design system and shared UI components
- Unrelated features (TaggingKit, ArticleSearch)
- Architecture changes unrelated to this task
- Refactoring of unrelated code
- Dependencies not mentioned in the task

**Agent behavior in Forbidden Zone:**
```
Agent: "This change would require editing [Forbidden Zone file]
because [reason].

Is that within scope, or should I find another approach?"
```

The agent **stops and reports**. It does not proceed unless explicitly told to.

---

## Examples

### Example 1: "Fix article queue crash on nil metadata"

**Safe Zone:**
- `ArticleQueueFeature.swift` (fix the crash)
- `ArticleQueueTests.swift` (add test for the crash)

**Approval Zone:**
- `ArticleModels.swift` (if schema changes needed)
- `Docs/ArticleQueue.md` (update docs)

**Forbidden Zone:**
- Design system
- Other features
- Refactoring unrelated code
- Architecture changes

---

### Example 2: "Refactor ArticleReader to use SQLiteData directly"

**Safe Zone:**
- `ArticleReader.swift` (the refactoring)
- `ArticleReaderTests.swift` (update tests)
- `Package.swift` (add SQLiteData dependency)

**Approval Zone:**
- `ArticleFeature.swift` (if API changes affect parent reducer)
- `SPMModuleBoundaries.md` (document the architectural change)

**Forbidden Zone:**
- Other feature modules
- Design system
- Unrelated refactoring

---

### Example 3: "Add dark mode support to design system"

**Safe Zone:**
- `DesignSystem/Theme.swift` (implement dark mode)
- `DesignSystem/ColorTokens.swift` (add dark mode colors)
- `DesignSystemTests.swift` (test dark mode)
- `Package.swift` (if adding dependencies)

**Approval Zone:**
- `ArticleView.swift` (if using new dark mode tokens)
- `Docs/DesignSystem.md` (document the feature)
- Any component that needs dark mode adjustment

**Forbidden Zone:**
- Feature logic (article caching, reading analytics, etc.)
- Platform-specific implementations unrelated to theme
- Architecture changes

---

## How Agents Use Task Scope

### At Task Start
Agent reads the task scope and understands the boundaries.

```
Task: "Add article caching"
Safe Zone: ArticleCache.swift, ArticleCacheTests.swift, Package.swift
Approval Zone: ArticleFeature.swift (if API changes)
Forbidden Zone: Everything else

Agent: "Understood. I'll focus on Safe Zone,
ask before editing Approval Zone,
and report if I need Forbidden Zone."
```

### During Implementation
Agent checks before each edit:

```
About to edit: ArticleFeature.swift
Is this in Safe Zone? No.
Is this in Approval Zone? Yes.
Action: Ask permission before proceeding.
```

### When Blocked
Agent clearly reports what's needed:

```
Change complete for Safe Zone.
However, ArticleQueueFeature.swift needs updates
to use the new cache API.

This is Approval Zone. Should I proceed?
```

---

## When to Define Task Scope

**Always, for any task beyond trivial fixes.**

**Trivial:** "Fix typo in error message" (Safe Zone only)
**Substantial:** Anything requiring multiple file changes (define all three zones)
**Complex:** Features that touch multiple modules (be very specific)

---

## Adjusting Scope During Work

Scope can change if:
- **New information emerges** ("I discovered we need to update the persistence layer")
- **Unforeseen dependencies** ("This requires a design system change")
- **Better approach discovered** ("Instead of editing ArticleFeature, I can solve this in ArticleCache")

When this happens, agent **stops and reports**:

```
Initial scope said ArticleFeature.swift was Approval Zone.
I've discovered it needs more substantial changes than expected.

Should I:
A) Update ArticleFeature significantly (more than anticipated)?
B) Find an alternative approach that avoids ArticleFeature?
C) Expand the scope officially?

What's your preference?
```

---

## Summary

| Zone | Behavior | Approval |
|------|----------|----------|
| **Safe** | Edit freely | None needed |
| **Approval** | Edit with permission | Ask first |
| **Forbidden** | Never edit | Explicit permission required |

Clear scope = focused work. Focused work = better code.
