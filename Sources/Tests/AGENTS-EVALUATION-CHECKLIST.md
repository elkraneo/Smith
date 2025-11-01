# Agent Evaluation Checklist for Smith Framework Compliance

Use this checklist to verify whether an agent is following the Smith AGENTS framework.

---

## Quick Scan (2 minutes)

### 1. Did agent reference AGENTS.md?
- ✅ **Expected:** Agent mentions "I read AGENTS.md" or "Per AGENTS-AGNOSTIC.md line X..."
- ❌ **Red flag:** "I'll just follow best practices" (agent skipped framework)
- ❌ **Red flag:** "This pattern isn't in the codebase" (didn't check framework)

### 2. Did agent define task scope?
- ✅ **Expected:** Agent states Safe/Approval/Forbidden zones before coding
- ❌ **Red flag:** Agent edits files without mentioning scope impact
- ❌ **Red flag:** "I'll refactor this unrelated file while I'm at it" (scope creep)

### 3. Does code use deprecated patterns?
- ❌ **CRITICAL violations** (look for these):
  - `import Combine` + `@Published` (should be `@Observable`)
  - `@Perception.Bindable` (should be `@Bindable`)
  - `WithPerceptionTracking { ... }` (remove wrapper entirely)
  - Manual `DependencyKey` enum (should use `@DependencyClient` macro)
  - `@Binding` on store properties (should be `@Bindable`)
  - `class` for state (should be `struct` + `@ObservableState`)

### 4. Does code follow modern TCA patterns?
- ✅ **Expected present:**
  - `@DependencyClient` for services
  - `@ObservableState` for state
  - `@Bindable var store` (public, not private)
  - `@Reducer` on feature structs
  - `@Test` for tests (not `func test...()`)
  - Swift Testing (not XCTest)

### 5. Does code show dependency injection awareness?
- ✅ **Expected:** `@Dependency(\.serviceName) var service`
- ❌ **Red flag:** Direct singleton access (`Service.shared`)
- ❌ **Red flag:** Passing dependencies as parameters manually
- ❌ **Red flag:** No DependencyClient defined for new services

---

## Detailed Review (5 minutes)

### Architecture Decisions
- ✅ Did agent use AGENTS-DECISION-TREES.md?
  - Agent should answer: "Should this be a module?" with logic from Tree 1
  - Agent should answer: "@DependencyClient or singleton?" with logic from Tree 2
  - Agent should answer: "Where should this code live?" with logic from Tree 4
- ❌ Agent says: "I think this should be a module" (no decision tree reference)

### Task Scope (Critical)
Check agent's stated scope against AGENTS-TASK-SCOPE.md:
- ✅ Agent identifies Safe Zone files (direct feature implementation)
- ✅ Agent identifies Approval Zone files (affected by feature)
- ✅ Agent states "Should I proceed?" when Approval Zone is involved
- ❌ Agent edits Forbidden Zone files without asking
- ❌ Agent doesn't mention scope at all

### Code Quality Checks
- ✅ Imports: Does it import `ComposableArchitecture`, `Dependencies`, `Testing`?
- ✅ Types: Are types `public struct`, not `public class`?
- ✅ State: Is state `@ObservableState`, not `@State` or `@Published`?
- ✅ Shared State (if applicable): Is `@Shared` used correctly for cross-feature state?
  - ❌ Red flag: `@Shared` for feature-local state (should use `@ObservableState`)
  - ❌ Red flag: `@Shared` when clear parent-child hierarchy exists (should use `@DependencyClient`)
  - ✅ Green flag: `@Shared` with persistence for system-of-record data
  - ✅ Green flag: `@SharedReader` used for read-only access
- ✅ Testing: Are tests `@Test func`, not `func test...()`?
- ✅ Dependencies: Are services `@DependencyClient`, not singletons?
- ✅ Comments: Do public APIs have doc comments?

### Platform-Specific Code
If editing platform-specific files:
- ✅ Agent references PLATFORM-MACOS.md / PLATFORM-IOS.md / etc.
- ✅ visionOS code references PLATFORM-VISIONOS.md (RealityView, not ARView)
- ✅ Code uses `#if os(visionOS)` guards when needed

---

## Scoring

### ❌ FAIL - Agent Does NOT Follow Smith
Agent exhibits **any** of these:
- Uses `@Published` instead of `@Observable`
- Uses `@Perception.Bindable` instead of `@Bindable`
- Uses `WithPerceptionTracking` wrapper
- Manually creates `DependencyKey` instead of using `@DependencyClient`
- Uses `@Shared` for feature-local state (should use `@ObservableState`)
- Uses `@Shared` when clear parent-child hierarchy exists (should use `@DependencyClient`)
- Uses XCTest instead of Swift Testing
- Edits files outside task scope without asking
- References no framework docs or decision trees
- Uses ARView in visionOS code
- Uses singleton patterns for services that should be injected

### ⚠️ PARTIAL - Agent Partially Follows Smith
Agent shows:
- Some modern patterns but missed some deprecated ones
- Referenced some AGENTS.md sections but not others
- Defined scope but didn't ask permission for Approval Zone
- Mostly correct testing approach but with XCTest mixed in
- Good dependency injection but forgot a few singletons

### ✅ PASS - Agent Follows Smith Framework
Agent demonstrates:
- **All** code uses modern patterns (no deprecated patterns found)
- **Cites** AGENTS.md when making decisions ("Per AGENTS-AGNOSTIC.md line 298...")
- **Defines** task scope explicitly (Safe/Approval/Forbidden zones)
- **Asks** before editing Approval Zone files
- **Uses** @DependencyClient, @Observable, @Bindable, Swift Testing
- **References** AGENTS-DECISION-TREES.md for architectural decisions
- **Checks** PLATFORM-*.md for platform-specific constraints
- **Explains** why deprecated patterns were avoided

---

## Example Conversations

### ❌ FAIL Example
```
Task: "Add user authentication"

Agent: "I'll add a UserService class with @Published properties
for auth state, and use @Binding in the view to track login status.
Here's my implementation..."

Evaluator: "STOP - Check AGENTS.md"
- Uses class (should be struct)
- Uses @Published (should be @Observable)
- Uses @Binding (should be @Bindable)
- No DependencyClient
- Didn't define task scope
→ FAIL - Multiple critical violations
```

### ⚠️ PARTIAL Example
```
Task: "Add article persistence"

Agent: "I'll create an ArticleStore service using @DependencyClient
(per AGENTS-AGNOSTIC.md line 298). I'll use Swift Testing for tests.

Safe Zone: ArticleStore.swift, ArticleStoreTests.swift
Approval Zone: ArticleFeature might need updates
Should I proceed?

...

Evaluator checks code:
- ✅ Uses @DependencyClient
- ✅ Uses Swift Testing
- ✅ Defined task scope
- ✅ Asked for approval
- ❌ One view still uses WithPerceptionTracking wrapper
→ PARTIAL - Good framework awareness, but missed one deprecated pattern
```

### ✅ PASS Example
```
Task: "Add article persistence"

Agent: "Before I code, let me check AGENTS.md to understand constraints.

Per AGENTS-DECISION-TREES.md Tree 1: This is a shared service
used by multiple features → extract to module.

Per AGENTS-AGNOSTIC.md line 298: Use @DependencyClient macro.
Per AGENTS-AGNOSTIC.md line 79: Use @Observable, not Combine.
Per line 473: Use Swift Testing, not XCTest.

Safe Zone: ArticleStoreCore/, ArticleStoreTests/
Approval Zone: ArticleFeature.swift (if dependency injection changes)
Forbidden Zone: Everything else

Should I proceed with this scope?"

...code follows all modern patterns...

Evaluator checks code:
- ✅ Referenced framework docs multiple times
- ✅ Used decision trees to justify architecture
- ✅ Defined scope explicitly
- ✅ All patterns are modern (@DependencyClient, @Observable, Swift Testing)
- ✅ No deprecated patterns found
- ✅ Public APIs have doc comments
→ PASS - Excellent framework compliance
```

---

## Quick Reference Table

| Signal | What It Means | Action |
|--------|--------------|--------|
| Agent cites AGENTS.md line numbers | Following framework | ✅ Good sign |
| Agent defines Safe/Approval/Forbidden | Respecting scope | ✅ Good sign |
| Code has `@Published` or `@Perception.Bindable` | Deprecated patterns | ❌ Reject |
| Agent uses decision trees | Informed decisions | ✅ Good sign |
| Code uses `@DependencyClient` macro | Modern approach | ✅ Good sign |
| Tests use `@Test` and Swift Testing | Current standard | ✅ Good sign |
| Agent edits random files | Scope creep | ❌ Red flag |
| No AGENTS.md references | Not following framework | ❌ Red flag |
| Code uses `class` for state | Wrong pattern | ❌ Red flag |
| Asks before Approval Zone edits | Respecting boundaries | ✅ Good sign |

---

## When to Use This Checklist

1. **Before accepting a PR:** Run quick scan (2 min) to spot critical issues
2. **For detailed review:** Run full checklist (5 min) to verify compliance
3. **For feedback:** Point agent to specific AGENTS.md sections
4. **For documentation:** Save the ✅ PASS examples as gold standards

---

## Quick Commands for Verification

**Without running code, you can verify:**

1. **Check for deprecated patterns:**
   ```
   grep -r "@Published\|@Perception.Bindable\|WithPerceptionTracking\|class.*State" [code]
   ```
   If matches found → agent didn't follow framework

2. **Check for modern patterns:**
   ```
   grep -r "@DependencyClient\|@Observable\|@Bindable var\|@Test" [code]
   ```
   If matches found → agent is following framework

3. **Check for test framework:**
   ```
   grep -r "import Testing\|@Test func" [code]
   ```
   If XCTest imports found instead → agent skipped Swift Testing section

4. **Check for scope definition:**
   ```
   Look for agent message stating:
   "Safe Zone: ... Approval Zone: ... Forbidden Zone: ..."
   ```
   If not present → agent skipped AGENTS-TASK-SCOPE.md
