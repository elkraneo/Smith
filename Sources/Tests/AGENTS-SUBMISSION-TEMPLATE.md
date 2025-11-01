# Agent Work Submission Template

Use this template when submitting code or architectural decisions for review.

---

## Before You Submit

**DO NOT submit without completing all sections below.** This template ensures your work is framework-compliant.

---

## 1. Framework Verification

Before submitting, verify you've read the relevant AGENTS.md sections:

- [ ] Read [AGENTS-FRAMEWORK.md](AGENTS-FRAMEWORK.md) - Master overview
- [ ] Read [AGENTS-AGNOSTIC.md](AGENTS-AGNOSTIC.md) - Universal Swift/TCA patterns
- [ ] Read [AGENTS-DECISION-TREES.md](AGENTS-DECISION-TREES.md) - Architecture decisions
- [ ] Read [AGENTS-TASK-SCOPE.md](AGENTS-TASK-SCOPE.md) - Scope boundaries
- [ ] Read relevant PLATFORM-*.md if your task is platform-specific

---

## 2. Task Scope Definition

**State your scope explicitly:**

### Safe Zone (Edit freely)
List files you created/modified that are directly part of this feature:
```
- FeatureName/FeatureService.swift
- FeatureName/FeatureTests.swift
- Package.swift (if adding dependencies)
```

### Approval Zone (Ask before editing)
List files affected by this feature that you modified:
```
- ParentFeature.swift (if dependency injection changes)
- Docs/FeatureName.md (documentation)
```

### Forbidden Zone (Report if needed)
List files you discovered need changes but did NOT modify:
```
- (None discovered) OR
- Architecture change needed in XYZ (requires separate discussion)
```

**Question for reviewer:** Does this scope look correct? Should I proceed?

---

## 3. Architecture Decisions

**Answer these questions using AGENTS-DECISION-TREES.md:**

### Q: Should this be a module or stay in monolithic target?
**Reference:** AGENTS-DECISION-TREES.md Tree 1

My answer: [STATE YOUR DECISION AND WHY]

Example:
```
Stay in monolithic because:
- Single use (only in ArticleQueue, not reused)
- <20 action cases (reducer has 12 cases)
- <500 lines of logic
- No platform-specific code
```

### Q: Should I use @DependencyClient or singleton?
**Reference:** AGENTS-DECISION-TREES.md Tree 2

My answer: [STATE YOUR DECISION AND WHY]

Example:
```
Use @DependencyClient because:
- Used in ArticleQueueFeature reducer
- Needs test mocking (cache can be replaced with testValue)
- Used across multiple features (ArticleQueue + ArticleSearch)
```

### Q: Where should this logic live (Core/UI/Platform)?
**Reference:** AGENTS-DECISION-TREES.md Tree 4

My answer: [STATE YOUR DECISION AND WHY]

Example:
```
In Core module because:
- Domain logic independent of UI (caching, invalidation)
- No SwiftUI imports
- No platform-specific code
```

---

## 4. Code Patterns - Self-Check

Before submitting, verify your code uses modern patterns:

### Dependency Injection
- [ ] All new services use `@DependencyClient` macro (not manual DependencyKey)
- [ ] Services are injected via `@Dependency(\.serviceName)` in reducers
- [ ] No singleton access (no `Service.shared` or static methods)

**Citation:** AGENTS-AGNOSTIC.md, lines 253–465 (@DependencyClient Macro section)

### State Management
- [ ] State uses `@ObservableState` (not `@Published`)
- [ ] Reducers use `@Reducer` macro
- [ ] Views use `@Bindable var store` (not `@Perception.Bindable` or `@State`)
- [ ] No `class` for state (only `struct`)

**Citation:** AGENTS-AGNOSTIC.md, lines 79–207 (State Management section)

### Shared State (if applicable)
- [ ] `@Shared` used only for cross-feature state (not feature-local state)
- [ ] Used with persistence (`.appStorage`, `.fileStorage`) when appropriate
- [ ] `@SharedReader` used for read-only access (not `@Shared` for mutations)
- [ ] Exhaustive tests cover mutations from multiple features accessing same state
- [ ] Not used when clear parent-child hierarchy exists (use `@DependencyClient` instead)

**Citation:** AGENTS-AGNOSTIC.md, lines 45–73 (@Shared section)

### Testing
- [ ] Tests use `@Test func` (not `func test...()`)
- [ ] Tests use Swift Testing (not XCTest)
- [ ] Uses `TestStore` with `withDependencies` for mocking
- [ ] Tests check both success and failure paths

**Citation:** AGENTS-AGNOSTIC.md, lines 469–751 (Swift Testing section)

### Tool Usage - Documentation & Web
- [ ] Used SosumiDocs MCP for Apple documentation (not curl or WebFetch)
- [ ] No repeated curl calls to developer.apple.com
- [ ] WebFetch used only for general web content (not Apple docs)
- [ ] curl used only for testing APIs directly (rarely needed)

**Citation:** AGENTS-AGNOSTIC.md, lines 69–77 (Tool Usage - Documentation & Web section)

### Tool Usage - Building & Testing
- [ ] Used XcodeBuildMCP for all builds (not raw xcodebuild)
- [ ] Used appropriate MCP tool: `build_sim`, `test_device`, `build_macos`, etc.
- [ ] No raw `xcodebuild` commands run directly
- [ ] Error output is structured and actionable

**Citation:** AGENTS-AGNOSTIC.md, lines 79–83 (Tool Usage - Building & Testing section)

### Tool Usage - Repository Operations
- [ ] Used `gh` CLI for simple operations (create/update issues, PRs)
- [ ] Used GitHub MCP only for complex queries (search_code, filtering)
- [ ] Used raw `git` only for local operations (git log, git diff, git add)
- [ ] No unnecessary MCP calls when `gh` is faster

**Citation:** AGENTS-AGNOSTIC.md, lines 85–94 (Tool Usage - Repository Operations section)

### Code Style
- [ ] 2-space indentation (not 4)
- [ ] UpperCamelCase for types, lowerCamelCase for variables
- [ ] Public APIs have doc comments (///)
- [ ] No type erasure (no `AnyView`, `AnyObject`)

**Citation:** AGENTS-AGNOSTIC.md, lines 1262–1284 (Latest Swift & Frameworks)

### Platform-Specific (if applicable)
- [ ] visionOS code uses `RealityView` (not `ARView`)
- [ ] Code uses `#if os(visionOS)` guards where needed
- [ ] References PLATFORM-VISIONOS.md constraints

**Citation:** PLATFORM-VISIONOS.md (if visionOS task)

---

## 5. Submission Summary

Paste this section in your submission message:

```
## SUBMISSION SUMMARY

**Task:** [Brief description of what you implemented]

**Scope:**
- Safe: [list files]
- Approval: [list files]
- Forbidden: [list files or "none"]

**Architecture Decisions:**
- Module vs. monolithic: [decision + reason]
- Dependency injection: [decision + reason]
- Code location: [decision + reason]

**Framework Compliance:**
- ✅ Read AGENTS-AGNOSTIC.md (cite specific sections)
- ✅ Defined task scope explicitly
- ✅ Verified modern patterns (cite examples)
- ✅ Used decision trees (cite which trees)

**Code Pattern Check:**
- ✅ @DependencyClient for services
- ✅ @Observable for state (no @Published)
- ✅ Swift Testing (no XCTest)
- ✅ @Bindable views (no @Perception.Bindable)
- ✅ No deprecated patterns found

**Questions for reviewer:**
[Any architectural questions or concerns?]
```

---

## Example Submission

```
## SUBMISSION SUMMARY

**Task:** Add article caching with 24-hour invalidation

**Scope:**
- Safe: ArticleCacheService.swift, ArticleCacheTests.swift
- Approval: ArticleQueueFeature.swift (added cache dependency)
- Forbidden: None

**Architecture Decisions:**
- Module vs. monolithic: Stay monolithic (single use, <20 actions, <500 lines)
  Reference: AGENTS-DECISION-TREES.md Tree 1

- Dependency injection: Use @DependencyClient (used in ArticleQueue reducer, needs test mock)
  Reference: AGENTS-DECISION-TREES.md Tree 2, lines 90–102

- Code location: Core module (domain logic, no SwiftUI, no platform-specific code)
  Reference: AGENTS-DECISION-TREES.md Tree 4, lines 259–263

**Framework Compliance:**
- ✅ Read AGENTS-AGNOSTIC.md lines 253–326 (@DependencyClient section)
- ✅ Defined task scope (Safe/Approval/Forbidden zones)
- ✅ Used AGENTS-DECISION-TREES.md Trees 1, 2, 4
- ✅ Verified modern patterns in code

**Code Pattern Check:**
- ✅ ArticleCacheService uses @DependencyClient macro (line 10 of code)
- ✅ ArticleQueueFeature uses @Dependency(\.articleCacheService) (line 25)
- ✅ State uses @ObservableState, no @Published
- ✅ Tests use @Test func with Swift Testing (ArticleCacheTests.swift)
- ✅ Views use @Bindable var store (no @Perception.Bindable)
- ✅ No deprecated patterns found

**Questions:**
- Should cache invalidation happen in a background task or only on app launch?
- Is SQLiteData the right persistence choice, or would you prefer KeychainSwift?
```

---

## When Reviewer Asks for Changes

If reviewer requests changes, **cite the specific AGENTS.md section** in your response:

**DON'T:**
```
"I'll fix that."
```

**DO:**
```
"Per AGENTS-AGNOSTIC.md lines 253–326, I've replaced the manual
DependencyKey with @DependencyClient macro. Here's the updated code..."
```

This shows you understand the framework, not just following orders.

---

## Red Flags - Don't Submit If:

❌ You haven't read the relevant AGENTS.md sections
❌ You didn't define task scope (Safe/Approval/Forbidden)
❌ You didn't use decision trees for architectural choices
❌ Your code contains `@Published`, `@Perception.Bindable`, or `WithPerceptionTracking`
❌ Your code uses `class` for state
❌ Tests use XCTest instead of Swift Testing
❌ You used singletons instead of `@Dependency`
❌ You edited files outside your stated scope without asking
❌ Your submission doesn't cite any AGENTS.md sections

If any of these apply, fix the code and re-read the relevant sections before submitting.

---

## Questions?

- **Where's the framework?** Read [AGENTS-FRAMEWORK.md](AGENTS-FRAMEWORK.md) for master overview
- **What's the decision?** Check [AGENTS-DECISION-TREES.md](AGENTS-DECISION-TREES.md)
- **What's in scope?** Check [AGENTS-TASK-SCOPE.md](AGENTS-TASK-SCOPE.md)
- **What's the pattern?** Check [AGENTS-AGNOSTIC.md](AGENTS-AGNOSTIC.md)
