# Smith Framework Evolution Log

This document tracks major changes, discoveries, and improvements to the Smith framework over time.

---

## Version History

### v1.0 - Initial Framework (November 1, 2025)

**Major Components Created:**
- ✅ AGENTS-AGNOSTIC.md - Universal Swift 6.2 / TCA 1.23.0+ patterns
- ✅ AGENTS-DECISION-TREES.md - 4 architectural decision flowcharts
- ✅ AGENTS-TASK-SCOPE.md - Safe/Approval/Forbidden zone framework
- ✅ AGENTS-FRAMEWORK.md - Master navigation index
- ✅ AGENTS-STRUCTURE-COMPLETE.md - Integration guide
- ✅ PLATFORM-MACOS.md, PLATFORM-IOS.md, PLATFORM-IPADOS.md, PLATFORM-VISIONOS.md - Platform-specific constraints
- ✅ AGENTS-SUBMISSION-TEMPLATE.md - Agent submission checklist
- ✅ AGENTS-EVALUATION-CHECKLIST.md - Framework compliance verification
- ✅ AGENTS-REVIEW-FORMAT.md - How to request evaluation

**Enforcement Levels Introduced:**
- [CRITICAL] - Non-negotiable rules (won't compile or fail review)
- [STANDARD] - Expected practice (exceptions rare)
- [GUIDANCE] - Best practice (use judgment)

**Key Decisions:**
- Separate framework docs from project stubs (2KB wrappers per project)
- Tests/ folder excluded from project copies (evaluation tools only)
- Per-platform files for composability (projects link only platforms they need)

---

## Learned Patterns & Updates

### Discovery 1: Tool Usage Optimization (Nov 1, 2025)

**Problem:** Agents running repeated `curl` calls to developer.apple.com instead of using cached SosumiDocs MCP.

**Solution:**
- Added "Tool Usage - MCP & CLI Tools" section to AGENTS-AGNOSTIC.md (lines 69–94)
- Three subsections:
  - Documentation & Web (SosumiDocs [STANDARD])
  - Building & Testing (XcodeBuildMCP [CRITICAL])
  - Repository Operations (gh CLI [STANDARD] vs GitHub MCP [GUIDANCE])
- Updated AGENTS-SUBMISSION-TEMPLATE.md with three Tool Usage checklists
- **Result:** Agents now check tool usage before submitting

**Citations:**
- AGENTS-AGNOSTIC.md lines 69–94
- AGENTS-SUBMISSION-TEMPLATE.md lines 128–150

---

### Discovery 2: @Shared Pattern for Cross-Feature State (Nov 1, 2025)

**Problem:** Complex modular apps need shared state across unrelated features (authentication, user info, feature flags). @DependencyClient alone becomes cumbersome with deep prop drilling; @Shared offers cleaner alternative when used wisely.

**Solution:**
- Added "Shared State (@Shared)" section to AGENTS-AGNOSTIC.md (lines 45–73)
- Marked as [STANDARD] with clear use cases and anti-patterns:
  - ✅ When: Cross-feature state (auth, user, flags), leaf reducers need access, persistence needed
  - ❌ When: Feature-local state (use @ObservableState), clear parent-child hierarchy (use @DependencyClient)
- Added `@SharedReader` guidance for read-only access
- Included code example showing leaf reducers accessing shared auth state
- Updated AGENTS-SUBMISSION-TEMPLATE.md with 5-item "Shared State (if applicable)" checklist
- Updated AGENTS-EVALUATION-CHECKLIST.md with red flags and green flags for @Shared usage
- Added to FAIL criteria: Using @Shared for feature-local or when hierarchy exists

**Example Benefit:** Two unrelated features (SettingsFeature, ProfileFeature) both need current user data without explicit prop passing or complex dependency chains. @Shared at root + @Shared in both reducers = instant synchronization across both.

**Testing:** @Shared requires exhaustive testing because reference semantics mean mutations are instantly visible across all holders. Added to submission checklist.

**Citation:** Point-Free blog post 135 "Shared State in the Composable Architecture" (https://www.pointfree.co/blog/posts/135-shared-state-in-the-composable-architecture)

**Citations:**
- AGENTS-AGNOSTIC.md lines 45–73 (@Shared section)
- AGENTS-SUBMISSION-TEMPLATE.md lines 120–127 (Shared State checklist)
- AGENTS-EVALUATION-CHECKLIST.md lines 66–70 (Code Quality: @Shared check)
- AGENTS-EVALUATION-CHECKLIST.md lines 91–92 (FAIL criteria)

---

### Discovery 3: Modern TCA 1.5+ Patterns (Avoiding Deprecated APIs) (Nov 1, 2025)

**Problem:** When implementing medium-complexity TCA features, agents and developers fall back to deprecated patterns (WithViewStore, IfLetStore, @Perception.Bindable) when unsure about modern approaches. This leads to:
- Cascading compilation errors that mask real issues
- Solution-chasing without verification (trying API after API)
- Building unnecessary host bridges and wrapper components
- Features that don't work despite "correct" TCA syntax

Example: A 1-hour session implementing a WatcherAssist popover feature resulted in 5+ different attempted fixes, deprecation warnings, visionOS incompatibilities, and a feature that still didn't appear—all because the correct modern pattern (direct `@Bindable` + `.sheet(item:)`) was unclear.

**Solution:**
- Created `AGENTS-TCA-PATTERNS.md` documenting canonical patterns for TCA 1.5+ (Swift Composable Architecture)
- Four core patterns with full examples:
  1. Observing state in views (@Bindable, direct property access)
  2. Optional state navigation (.sheet(item:), .scope())
  3. Multiple destinations (enum Destination, @Reducer macro)
  4. Form bindings (BindableAction, BindingReducer)
- Clear anti-patterns section showing what NOT to do and why
- Platform-agnostic: all patterns work on iOS, macOS, iPadOS, visionOS, watchOS
- Verification checklist for agents implementing TCA features

**Key Insight:** Modern TCA requires zero bridges, zero hosts, and zero manual observation. If code is complex, the pattern is likely wrong.

**Examples Given:**
- ❌ WithViewStore (deprecated) → ✅ @Bindable + direct access
- ❌ Host bridge for optional state → ✅ .sheet(item: $store.scope(...))
- ❌ Manual .onReceive() observation → ✅ @Bindable automatic observation
- ❌ If-let rendering of optional state → ✅ Navigation modifiers

**Impact:** Prevents agents from:
- Using deprecated APIs that trigger warnings
- Building overly complex workarounds
- Chasing compilation errors in wrong files
- Spending hours on trial-and-error API changes

**Testing:** Modern patterns are transparent to TestStore—no special utilities needed. Verification is simple: feature appears/disappears when optional state changes.

**Citations:**
- AGENTS-TCA-PATTERNS.md (entire document)
- Updated AGENTS-SUBMISSION-TEMPLATE.md (TCA Patterns checklist added)
- Discovery applied to GameEngine.watcherAssistPopover issue (GreenSpurt real-world validation)

**Recommended Follow-Up:**
- Monitor if this prevents cascading-error antipattern in future agent work
- Track most-cited sections in AGENTS-TCA-PATTERNS.md
- Update with visionOS-specific gotchas if discovered

---

## Framework Areas Under Development

### Next: Error Handling Patterns
- When to use `async throws` vs `Result<T, Error>`
- When to use `TaskResult` (TCA)
- Error recovery patterns
- User-facing error messages vs logging

### Next: Networking Layer
- HTTP client design (URLSession vs custom)
- Request/response models
- Retry logic and exponential backoff
- API error mapping

### Next: State Synchronization
- Sharing state across modules
- Reducer composition patterns
- When to lift state up vs keep local
- Testing multi-module state changes

### Next: Database & Persistence
- Core Data vs SQLite vs in-memory
- Dependency injection for persistence
- Testing with deterministic stores
- Data migrations

### Next: Concurrency Patterns
- Task management and cancellation
- Backpressure handling
- Rate limiting
- Timeout strategies

---

## How to Contribute New Patterns

### Step 1: Document the Discovery
Create a task or note:
```
Title: "[PATTERN] RealityView integration with SwiftUI state"
Description:
- Evidence: Used in GreenSpurt successfully
- Impact: Patterns applicable to all visionOS development
- Document to Update: PLATFORM-VISIONOS.md or AGENTS-AGNOSTIC.md
- Rule Level: [STANDARD] or [CRITICAL]?
```

### Step 2: Write the Guidance
Add to appropriate document:
```markdown
### RealityView State Management

- **[STANDARD]** Use @Observable for RealityView state (not @State in SwiftUI)
  - Why: RealityKit requires fine-grained updates; @State causes unnecessary re-renders
  - Pattern: Define state in reducer, use @Dependency to inject into RealityView
  - Example: [Link to code example]
```

### Step 3: Update Submission Template
Add checklist item:
```markdown
### Platform-Specific (visionOS)
- [ ] RealityView state uses @Observable (not @State)
- [ ] ViewAttachmentComponent correctly injected
```

### Step 4: Update Evaluation Checklist
Add red flag:
```markdown
❌ **No violations found:**
- No @State in RealityView (correct: @Observable)
```

### Step 5: Record in EVOLUTION.md
Add discovery to this log with date and impact.

---

## Known Gaps & TODOs

- [ ] Offline-first synchronization patterns
- [ ] Animation and gesture handling
- [ ] Accessibility (A11y) enforcement levels
- [ ] Internationalization (i18n) best practices
- [ ] Performance profiling guidelines
- [ ] Security patterns (auth, encryption, secrets)
- [ ] Testing complex side effects
- [ ] Debugging tools and techniques
- [ ] Documentation generation patterns

---

## Metrics to Track

**Future: Consider tracking:**
- Number of projects using Smith
- Average agent compliance score (PASS / PARTIAL / FAIL)
- Most-cited framework sections
- Most-updated areas
- Common violations found during review

---

## Version Roadmap

**v1.0** (Current)
- Core framework complete
- 8 platform + agnostic documents
- 3 evaluation tools
- Deployed to 2 projects

**v1.1** (Planned)
- Error handling patterns
- Networking layer guide
- Enhanced decision trees
- Performance profiling

**v1.2** (Planned)
- Database patterns
- Security guidelines
- Advanced concurrency
- Offline-first sync

**v2.0** (Future)
- Automated framework validation
- Agent compliance scoring
- Framework metrics dashboard
- Multi-platform library templates

---

## How to Update This Log

When you discover a new pattern:

1. **Add to "Learned Patterns & Updates" section** above
   - Date: YYYY-MM-DD
   - Title: Descriptive name
   - Problem: What was the issue?
   - Solution: What did you add/change?
   - Citations: Links to updated documents
   - Result: What's better now?

2. **Update "Known Gaps & TODOs"** if new area discovered

3. **Add to "Version Roadmap"** if pattern requires version bump

---

## Last Updated
November 1, 2025 - Initial v1.0 framework completion

**Next Scheduled Review:** November 15, 2025
