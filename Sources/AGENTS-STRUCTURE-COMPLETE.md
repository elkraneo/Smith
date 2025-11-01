# AGENTS Framework: Complete Structure

This document ties together all agent behavior guidance documents and explains how they work together to improve agent quality.

---

## Overview

You now have a **three-layer framework** to guide agent behavior:

### Layer 1: Universal Principles (All Projects)
**File:** [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)

Foundation rules that apply to every Apple platform project:
- State management (@Observable, no Combine)
- Concurrency patterns (4 core patterns)
- Dependency injection (@DependencyClient)
- Testing (Swift Testing + TestClock)
- Code style (2-space indent, UpperCamelCase, etc.)

**Each rule is now labeled:**
- `[CRITICAL]` - Will not compile or will fail code review
- `[STANDARD]` - Expected, exceptions rare
- `[GUIDANCE]` - Best practice, use unless better reason

**New addition:** Context explaining **why** rules exist:
- Swift 6.2 strict concurrency requires modern patterns
- visionOS actor isolation is mandatory
- Old patterns literally won't compile with Sendable requirements

---

### Layer 2: Decision-Making Framework
**File:** [DECISION-TREES.md](./DECISION-TREES.md)

Four decision trees answer the most common architectural questions:

1. **When should I create a Swift Package module?**
   - Answers: Reusability? Action enum size? Sub-reducers? Platform-specific?
   - Output: Extract or keep monolithic

2. **Should I use @DependencyClient or singleton?**
   - Answers: Used in reducer? Needs test mock? Lifecycle?
   - Output: Inject or use singleton

3. **Should I refactor this into a module?**
   - Answers: Causing pain? Blocking work? Future reuse? Stable?
   - Output: Extract now or wait

4. **Where should this logic live (Core/UI/Platform)?**
   - Answers: Uses SwiftUI? Domain logic? Platform-specific?
   - Output: Module assignment

**Key insight:** These replace vague guidance ("modularize when appropriate") with clear decision paths.

---

### Layer 3: Scope Management
**File:** [TASK-SCOPE.md](./TASK-SCOPE.md)

Three zones define what agents can edit for each task:

- **Safe Zone ✅** - Edit freely (core feature files)
- **Approval Zone ⚠️** - Ask before editing (supporting files)
- **Forbidden Zone ❌** - Never edit without permission (everything else)

**Key insight:** Prevents agents from "helpfully" refactoring unrelated code.

---

## How These Work Together

### Scenario 1: Agent Gets a Task

**User:** "Add article caching to Scroll"

**Agent workflow:**

```
Step 1: Read TASK-SCOPE.md
  → Identifies Safe Zone: ArticleCache.swift, ArticleCacheTests.swift
  → Identifies Approval Zone: ArticleFeature.swift (if API changes)
  → Identifies Forbidden Zone: Everything else

Step 2: Read AGENTS-AGNOSTIC.md
  → Learns: Use @DependencyClient for services
  → Learns: Use Swift Testing for tests
  → Learns: Use [CRITICAL] rules strictly
  → Learns: [STANDARD] rules expected but can discuss
  → Learns: [GUIDANCE] rules use judgment

Step 3: Consult DECISION-TREES.md if needed
  → "Should I create a module for ArticleCache?"
  → Tree answers: "Reused in 1 place, <20 actions, no platform code
    → Keep in monolithic target for now"

Step 4: Implement
  → Only edits Safe Zone files
  → If needs Approval Zone: Asks first
  → If needs Forbidden Zone: Reports and stops
  → Follows [CRITICAL] rules strictly
  → Uses @DependencyClient pattern
  → Writes Swift Testing tests
```

---

### Scenario 2: Agent Detects Pattern Question

**Agent:** "Should I put this in a module?"

**Agent workflow:**

```
Step 1: Consult DECISION-TREES.md Tree 1
  → Is it reused in 2+ places? No
  → Does action enum have 20+ cases? No
  → Does it have 3+ sub-reducers? No
  → Platform-specific code? No
  → Logic 1000+ lines? No

  → Decision: Keep in monolithic target

Step 2: Continue with task knowing pattern is right
```

---

### Scenario 3: Agent Encounters Rule It Doesn't Understand

**Agent:** "Why can't I use Combine if it works?"

**Agent workflow:**

```
Step 1: Read AGENTS-AGNOSTIC.md "Why Modern Patterns Are Required"
  → Learns: Swift 6.2 strict concurrency requires Sendable
  → Learns: Old patterns won't compile with strict concurrency
  → Learns: visionOS requires actor isolation
  → Learns: This isn't preference—it's platform requirement

Step 2: Understands reason and can explain to users
  → "Combine doesn't satisfy Sendable requirements"
  → "Need @Observable for Swift 6.2 compatibility"
```

---

## Integration with Existing Docs

These new documents **complement** your existing docs:

| Document | Scope | Use It For | Don't Change |
|----------|-------|-----------|--------------|
| **AGENTS-AGNOSTIC.md** | Universal patterns | Agent reference | PLANS.md, CONTRIBUTING.md |
| **DECISION-TREES.md** | Architecture decisions | When to modularize/inject | Feature roadmap, business logic |
| **TASK-SCOPE.md** | Per-task boundaries | Task definition | Code review process, GitHub workflow |
| **WORKFLOW.md** | Project management | GitHub Projects, issue tracking | Principles, patterns, standards |
| **CONTRIBUTING.md** | Human developer onboarding | For people, not agents | Patterns, enforcement, testing |
| **PLANS.md** | Product strategy | Product decisions | Code practices, architecture |
| **Architecture/** | Technical deep-dives | Understanding module design | Universal agent rules |

**Each layer serves a different purpose, and together they form a complete framework.**

---

## For Different Audiences

### For Agents (AI coding assistants)

1. Start with [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md) - Learn universal rules
2. Read task definition (includes TASK-SCOPE)
3. Consult [DECISION-TREES.md](./DECISION-TREES.md) when uncertain
4. Reference [TASK-SCOPE.md](./TASK-SCOPE.md) for edit boundaries

**Key focus:** [CRITICAL] rules, decision trees, scope boundaries

---

### For Human Developers

1. Read [CONTRIBUTING.md](./Scroll/CONTRIBUTING.md) - Onboarding guide
2. Learn patterns from [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
3. Understand architecture from [Architecture docs](./Scroll/Docs/Architecture/)
4. Use [DECISION-TREES.md](./DECISION-TREES.md) when making choices

**Key focus:** Patterns, code review checklist, why things matter

---

### For Project Planning

1. Check [WORKFLOW.md](./Scroll/WORKFLOW.md) - GitHub Projects process
2. Review [PLANS.md](./Scroll/Docs/PLANS.md) - Product strategy
3. Define task scope using [TASK-SCOPE.md](./TASK-SCOPE.md)

**Key focus:** Scope definition, workflow, issue tracking

---

## Creating New Projects

When you create a new project (e.g., a visionOS-exclusive game):

1. **Create project-specific AGENTS.md**
   ```markdown
   # AGENTS - [Project Name]

   See universal principles:
   - [AGENTS-AGNOSTIC.md](../../AGENTS-AGNOSTIC.md)
   - [PLATFORM-VISIONOS.md](../../PLATFORM-VISIONOS.md) (if multi-platform)

   [Project-specific notes]
   ```

2. **Use TASK-SCOPE.md for task definitions**
   ```
   Task: "Implement particle system"
   Safe Zone: ParticleEngine.swift, ParticleTests.swift
   Approval Zone: GameFeature.swift (if API changes)
   Forbidden Zone: Everything else
   ```

3. **Reference DECISION-TREES.md for architecture**
   - When to modularize
   - When to inject vs. singleton
   - Where logic should live

4. **Inherit all [CRITICAL] rules from AGENTS-AGNOSTIC.md**
   - These are non-negotiable platform requirements

---

## What This Solves (From Framework Gaps)

### Gap 1: Task Isolation ✅
**TASK-SCOPE.md** defines safe/approval/forbidden zones.

### Gap 2: Decision Frameworks ✅
**DECISION-TREES.md** provides four clear decision trees.

### Gap 3: Why Context ✅
**AGENTS-AGNOSTIC.md** explains why patterns are required (Swift 6.2, visionOS, strict concurrency).

### Gap 4: Quantitative Constraints ⚠️
**DECISION-TREES.md** provides thresholds (20+ actions = consider module, etc.).

### Gap 5: Enforcement Checkpoints ✅
**AGENTS-AGNOSTIC.md** labels rules [CRITICAL], [STANDARD], [GUIDANCE].

### Gap 6: Pattern Reference ⚠️
**AGENTS-AGNOSTIC.md** has patterns; catalog could be added if needed.

### Gap 7: Enforcement vs Guidance ✅
**AGENTS-AGNOSTIC.md** uses [CRITICAL]/[STANDARD]/[GUIDANCE] labels.

### Gap 8: Project Strategy Link ℹ️
**Project-specific** (Scroll PLANS.md is project-specific, kept separate).

### Gap 9: Common Mistakes ⚠️
**CONTRIBUTING.md** has examples; antipattern gallery could be expanded.

---

## Next Steps: Per-Platform Refactoring

The final step is refactoring WORKFLOWS documents to be per-platform:

```
Smith/
├── AGENTS-AGNOSTIC.md           # ✅ Universal (done)
├── DECISION-TREES.md            # ✅ Done
├── TASK-SCOPE.md                # ✅ Done
├── PLATFORM-MACOS.md            # 🔄 Next: Multi-platform specifics
├── PLATFORM-IOS.md              # 🔄 Next: iOS specifics
├── PLATFORM-IPADOS.md           # 🔄 Next: iPadOS specifics
├── PLATFORM-VISIONOS.md         # ✅ Already exists
└── INTEGRATION-GUIDE.md          # ℹ️ How to use (not replacing existing)
```

Each project links to relevant platform files:

**Scroll (macOS + iOS + iPadOS + visionOS):**
```markdown
# AGENTS - Scroll

[AGENTS-AGNOSTIC.md](../../AGENTS-AGNOSTIC.md)
[PLATFORM-MACOS.md](../../PLATFORM-MACOS.md)
[PLATFORM-IOS.md](../../PLATFORM-IOS.md)
[PLATFORM-IPADOS.md](../../PLATFORM-IPADOS.md)
[PLATFORM-VISIONOS.md](../../PLATFORM-VISIONOS.md)
```

**The Green Spurt (visionOS only):**
```markdown
# AGENTS - The Green Spurt

[AGENTS-AGNOSTIC.md](../../AGENTS-AGNOSTIC.md)
[PLATFORM-VISIONOS.md](../../PLATFORM-VISIONOS.md)
```

---

## Summary

You now have:

✅ **Universal principles** (AGENTS-AGNOSTIC.md)
✅ **Decision frameworks** (DECISION-TREES.md)
✅ **Scope boundaries** (TASK-SCOPE.md)
✅ **Enforcement levels** (CRITICAL/STANDARD/GUIDANCE labels)
✅ **Why context** (Swift 6.2, visionOS, strict concurrency explanation)
✅ **Per-platform guides** (PLATFORM-*.md files)

These documents work together to make agents behave better by providing:
1. Clear rules + explanation of why
2. Decision trees for common choices
3. Scope boundaries to prevent wandering
4. Enforcement levels to distinguish critical from guidance
5. Platform-specific constraints and patterns

**This is a framework for agents to reference, not just documentation to read.**
