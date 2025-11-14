# AGENTS Framework: Master Index

This document is the master navigation guide for all agent development guidelines.

**Start here if:** You're an AI agent looking for development patterns, rules, or decisions.

---

## Framework Layers (Read in Order)

### Layer 1: Universal Principles
**[AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)**

Foundation rules applying to all Apple platforms. **Language-level only** (Swift 6.2 strict concurrency, modern TCA patterns), not platform-specific.

**Contains:**
- State management (@Observable, no Combine)
- 4 concurrency patterns with examples
- Dependency injection (@DependencyClient)
- Swift Testing framework requirements
- Code style (2-space indent, UpperCamelCase)
- Accessibility and i18n
- [CRITICAL]/[STANDARD]/[GUIDANCE] enforcement levels
- Why modern patterns are required (Sendable requirements, strict concurrency)

**Key Insight:** These rules apply everywhere. Platform-specific rules go in PLATFORM-*.md.

---

### Layer 2: Architecture Decision Trees
**[AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md)**

Four decision flowcharts replacing vague guidance with clear choices.

**Tree 1: When should I create a Swift Package module?**
- Start: Is this code reused in 2+ places?
- Branches: Reusable? 20+ action cases? 3+ sub-reducers? Platform-specific?
- Output: Extract to module or keep monolithic

**Tree 2: @DependencyClient or singleton?**
- Start: Is this used in a reducer?
- Branches: Used in reducer? Needs test mock? Has lifecycle?
- Output: Inject with @DependencyClient or use singleton

**Tree 3: When to refactor into a module?**
- Start: Is this causing pain?
- Branches: Blocking work? Causes pain? Future reuse likely? Stable?
- Output: Extract now or wait

**Tree 4: Where should this logic live?**
- Start: What type of code?
- Branches: Uses SwiftUI? Domain logic? Platform-specific?
- Output: Core module, UI module, or Platform module

**Key Insight:** Use these instead of asking "is this a good idea?" They give clear outputs.

---

### Layer 3: Task Scope Boundaries
**[AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md)**

Define what you can edit for any given task.

**Three Zones:**
- **Safe Zone** ✅ - Edit freely (core feature files)
- **Approval Zone** ⚠️ - Ask before editing (supporting files)
- **Forbidden Zone** ❌ - Never edit without permission (everything else)

**Key Insight:** Prevents helpful-but-wrong refactoring of unrelated code.

---

## Platform-Specific Constraints

Each platform file documents [CRITICAL] rules specific to that platform. **Only relevant platforms apply** - a macOS project doesn't need to follow visionOS rules.

### [PLATFORM-MACOS.md](./PLATFORM-MACOS.md)
**When:** macOS targets
- Keyboard navigation and focus states
- Window management and multi-window support
- Menu bar integration
- WKWebView (NSViewRepresentable)
- macOS scene lifecycle

### [PLATFORM-IOS.md](./PLATFORM-IOS.md)
**When:** iPhone targets
- Touch interactions (minimum 44pt)
- Share Sheet integration
- Lock Screen widgets
- Background refresh (BGTaskScheduler)
- Haptic feedback
- Dynamic Type support

### [PLATFORM-IPADOS.md](./PLATFORM-IPADOS.md)
**When:** iPad targets (NOT just iOS on bigger screen!)
- Multi-window support (Stage Manager)
- Split view state management (horizontalSizeClass)
- Sidebar + Detail layout pattern
- Popovers (preferred over sheets)
- External keyboard support
- Keyboard shortcuts

### [PLATFORM-VISIONOS.md](./PLATFORM-VISIONOS.md)
**When:** visionOS targets
- **[CRITICAL] Never use ARView** - Always RealityView
- **[CRITICAL] Scene only in App target** - Not in feature modules
- **[CRITICAL] @MainActor for RealityKit mutations**
- RealityView patterns and update handlers
- ImmersiveSpace lifecycle
- Gestures and eye gaze
- Build configuration (external drive required)

---

## Integration Guide
**[AGENTS-STRUCTURE-COMPLETE.md](./AGENTS-STRUCTURE-COMPLETE.md)**

How all pieces work together:
- Layer descriptions in detail
- How to use per-platform
- Scenarios and workflows
- Audience-specific guidance (agents vs humans)
- Creating new projects

---

## Submission & Framework Improvement

### Code & Feature Submission
**[Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](./Tests/AGENTS-SUBMISSION-TEMPLATE.md)**

Use this when submitting code changes or new features for review:
- Task scope (Safe/Approval/Forbidden zones)
- Architecture decisions (citing decision trees)
- Framework compliance verification
- Code pattern checklist
- Access control verification

**Also use for code review:**
- [AGENTS-EVALUATION-CHECKLIST.md](./Tests/AGENTS-EVALUATION-CHECKLIST.md) - Reviewer verification checklist

---

### Discovery & Pattern Submission
**[Sources/Tests/DISCOVERY-SUBMISSION-TEMPLATE.md](./Tests/DISCOVERY-SUBMISSION-TEMPLATE.md)**

Use this when you discover a new pattern, anti-pattern, or critical gap that should be documented:
- Problem description (error, behavior, context)
- Root cause analysis (why it wasn't obvious)
- Solution with code example
- Framework integration plan (where should this live)
- Enforcement level ([CRITICAL]/[STANDARD]/[GUIDANCE])

**Reviewer uses:**
- [DISCOVERY-EVALUATION-CHECKLIST.md](./Tests/DISCOVERY-EVALUATION-CHECKLIST.md) - Assess if discovery is systemic and worthy of framework integration

**Process:**
1. Submit using DISCOVERY-SUBMISSION-TEMPLATE.md
2. Get verdict: ACCEPT / PARTIAL / REQUEST CHANGES / DECLINE
3. If accepted, create case study in CaseStudies/ directory
4. Framework docs updated by reviewer
5. Discovery recorded in EVOLUTION.md

---

### Case Studies (Real-World Evidence)
**[CaseStudies/](../../CaseStudies/)**

Detailed investigations of real bugs and lessons learned:
- What went wrong and why
- Investigation process (debugging trail)
- Solution and prevention strategy
- Framework impact (what was added to Smith)

**Current discoveries:**
- DISCOVERY-4: Popover Entity Creation Gap (visionOS)
- DISCOVERY-5: Access Control Cascade Failure (TCA 1.x)
- DISCOVERY-13: Swift Compiler Crash Patterns in visionOS RealityKit Development
- DISCOVERY-14: Nested @Reducer Macro Gotchas and Extraction Patterns
- DISCOVERY-15: Print vs OSLog Patterns for Agent Logging

**To contribute:** See [CaseStudies/README.md](../../CaseStudies/README.md) for step-by-step process.

---

### Framework Evolution Log
**[EVOLUTION.md](../../EVOLUTION.md)**

Master log of all framework improvements:
- Each discovery recorded with impact
- Framework sections updated (with line numbers)
- Systemic patterns identified
- Prevention strategies documented

---

## Quick Reference: When to Read What

| I want to... | Read this |
|---|---|
| Understand what patterns are required | AGENTS-AGNOSTIC.md |
| Decide if code should be a module | AGENTS-DECISION-TREES.md (Tree 1) |
| Choose @DependencyClient vs singleton | AGENTS-DECISION-TREES.md (Tree 2) |
| Know what I can edit | AGENTS-TASK-SCOPE.md |
| Understand visionOS requirements | PLATFORM-VISIONOS.md |
| Implement iPad split view correctly | PLATFORM-IPADOS.md |
| Add Share Sheet to iOS app | PLATFORM-IOS.md |
| Use WKWebView in macOS | PLATFORM-MACOS.md |
| See how everything fits together | AGENTS-STRUCTURE-COMPLETE.md |

---

## Rule Enforcement Levels

All rules are labeled for clarity:

| Level | Meaning | Example |
|-------|---------|---------|
| **[CRITICAL]** | Won't compile or fail code review | "Never use ARView on visionOS" |
| **[STANDARD]** | Expected, rare exceptions | "Use @Observable for state" |
| **[GUIDANCE]** | Best practice, use judgment | "Prefer popovers over sheets on iPad" |

---

## Project-Specific Usage

Each project links to relevant canonical files:

**Scroll** (macOS + iOS + iPadOS + visionOS):
```markdown
- AGENTS-AGNOSTIC.md (universal)
- PLATFORM-MACOS.md, PLATFORM-IOS.md, PLATFORM-IPADOS.md, PLATFORM-VISIONOS.md
```

**The Green Spurt** (visionOS only):
```markdown
- AGENTS-AGNOSTIC.md (universal)
- PLATFORM-VISIONOS.md (platform specifics)
```

Projects have thin AGENTS.md wrappers that link to these canonical documents.

---

## For Different Readers

### AI Agents 🤖
1. You're reading the right file
2. Next: [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
3. Then: Reference platform files for specific constraints
4. When uncertain: Check [AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md)
5. Before editing: Verify scope in [AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md)

### Human Developers 👥
1. Start with your project's AGENTS.md or CONTRIBUTING.md
2. Learn patterns from [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
3. Use [AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md) for architectural choices
4. Reference platform files for implementation details

### Project Managers 📋
1. Use [AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md) to define task boundaries
2. See [AGENTS-STRUCTURE-COMPLETE.md](./AGENTS-STRUCTURE-COMPLETE.md) for framework overview
3. Reference project-specific WORKFLOW.md and PLANS.md for scheduling

---

## Composition Examples

### "I'm implementing a visionOS app with RealityKit"
Read in order:
1. [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md) - Universal Swift/TCA patterns
2. [PLATFORM-VISIONOS.md](./PLATFORM-VISIONOS.md) - RealityView [CRITICAL] rules
3. [AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md) - When to modularize
4. [AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md) - Task boundaries

### "I'm refactoring an iOS app for iPad split view"
Read in order:
1. [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md) - Patterns (already known)
2. [PLATFORM-IPADOS.md](./PLATFORM-IPADOS.md) - Split view state management
3. [AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md) - If extracting to modules

### "I'm adding macOS menu bar support"
Read in order:
1. [PLATFORM-MACOS.md](./PLATFORM-MACOS.md) - Menu bar patterns
2. [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md) - If needed for dependency injection

---

## Key Files at a Glance

| File | Size | Purpose | Audience |
|------|------|---------|----------|
| AGENTS-AGNOSTIC.md | ~24KB | Universal rules | Everyone |
| AGENTS-DECISION-TREES.md | ~12KB | Architecture decisions | Architects, senior devs, agents |
| AGENTS-TASK-SCOPE.md | ~6KB | Task boundaries | Project managers, agents |
| PLATFORM-VISIONOS.md | ~12KB | visionOS specifics | visionOS developers, agents |
| PLATFORM-IPADOS.md | ~7KB | iPadOS specifics | iPad developers |
| PLATFORM-IOS.md | ~6KB | iOS specifics | iPhone developers |
| PLATFORM-MACOS.md | ~5KB | macOS specifics | macOS developers |
| AGENTS-STRUCTURE-COMPLETE.md | ~10KB | Integration guide | Everyone (overview) |

---

## Document Relationships

```
README.md (traffic director)
    ↓
AGENTS-FRAMEWORK.md (you are here)
    ├─→ AGENTS-AGNOSTIC.md (universal rules)
    ├─→ AGENTS-DECISION-TREES.md (architecture decisions)
    ├─→ AGENTS-TASK-SCOPE.md (task boundaries)
    ├─→ PLATFORM-MACOS.md (macOS specifics)
    ├─→ PLATFORM-IOS.md (iOS specifics)
    ├─→ PLATFORM-IPADOS.md (iPadOS specifics)
    ├─→ PLATFORM-VISIONOS.md (visionOS specifics)
    └─→ AGENTS-STRUCTURE-COMPLETE.md (integration overview)

Each project:
    Scroll/AGENTS.md → links to above
    The Green Spurt/AGENTS.md → links to above
```

---

## Document Status

| Document | Status | Last Updated |
|----------|--------|--------------|
| AGENTS-FRAMEWORK.md | ✅ Core | Nov 1, 2025 |
| AGENTS-AGNOSTIC.md | ✅ Core | Nov 1, 2025 |
| AGENTS-DECISION-TREES.md | ✅ Core | Nov 1, 2025 |
| AGENTS-TASK-SCOPE.md | ✅ Core | Nov 1, 2025 |
| AGENTS-STRUCTURE-COMPLETE.md | ✅ Reference | Nov 1, 2025 |
| PLATFORM-MACOS.md | ✅ Core | Nov 1, 2025 |
| PLATFORM-IOS.md | ✅ Core | Nov 1, 2025 |
| PLATFORM-IPADOS.md | ✅ Core | Nov 1, 2025 |
| PLATFORM-VISIONOS.md | ✅ Core | Nov 1, 2025 |

---

## How to Navigate This Framework

### If you know your platform
→ Read AGENTS-AGNOSTIC.md + your PLATFORM-*.md

### If you're making an architecture decision
→ Go to AGENTS-DECISION-TREES.md, find relevant tree, follow branches

### If you don't know what you can edit
→ Check AGENTS-TASK-SCOPE.md for Safe/Approval/Forbidden zones

### If you're confused about framework organization
→ Read AGENTS-STRUCTURE-COMPLETE.md

### If you want all the context
→ Start here, read in order: Agnostic → Decision Trees → Task Scope → Platforms → Structure Complete

---

## Next Steps

- [ ] Read [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md) for universal patterns
- [ ] Identify your relevant [PLATFORM-*.md](./PLATFORM-VISIONOS.md) file(s)
- [ ] Reference [AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md) when making architecture decisions
- [ ] Check [AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md) before editing files

---

**Last Updated:** November 1, 2025
