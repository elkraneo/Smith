# Decision Trees for Common Questions

This document provides **decision trees** to answer the most common architectural questions agents and developers face.

---

## Tree 1: When Should I Create a Swift Package Module?

**Use this tree when deciding whether to extract a feature into a separate Swift Package module or keep it in the monolithic app target.**

```
Feature exists or is planned?
├─ YES → Continue
└─ NO → Not applicable yet

Will this feature be reused across 2+ parent features
or different platform combinations?
├─ YES → Extract to module
│  Why: Reusability is the strongest reason for modularization
│  Example: TaggingKit is used by ArticleReader, ImportExport, and ArticleSearch
│
└─ NO → Continue to next question

Does the reducer action enum have 20+ cases?
├─ YES → Extract to module (likely doing too much)
│  Why: Large action enums indicate feature complexity
│  Suggestion: Break into sub-features with Scope composition
│
└─ NO → Continue to next question

Does the feature have 3+ sub-reducers that need composition?
├─ YES → Extract to module
│  Why: Composition across multiple reducers is clearer in separate module
│  Example: ArticleReader has ReaderPreferences, ReaderCache, ReaderHistory
│
└─ NO → Continue to next question

Is there significant platform-specific code?
├─ YES (macOS-specific OR visionOS-specific) → Extract to module
│  Why: Platform-specific UI/logic is clearer in separate module
│  Structure: ModuleCore (shared) + ModuleUI + ModuleMac + ModuleVision
│
└─ NO → Continue to next question

Is the feature logic 1000+ lines?
├─ YES → Extract to module
│  Why: Monolithic files are harder to maintain
│  Note: This is the last-resort metric; earlier factors are better
│
└─ NO → Keep in monolithic target

Why? At this point:
- Feature is not reusable yet
- Action enum is manageable (< 20 cases)
- No significant sub-feature composition
- Platform-specific code is minimal
- Logic is still manageable in size

You can always extract later when requirements change.
```

### Quick Reference

**EXTRACT to module if ANY of these are true:**
1. ✅ Feature will be reused across 2+ parents OR platforms
2. ✅ Action enum has 20+ cases
3. ✅ Feature has 3+ sub-reducers
4. ✅ Significant platform-specific code exists
5. ✅ Feature logic is 1000+ lines

**KEEP in monolithic target if:**
- ❌ Feature is used in only one place (for now)
- ❌ Action enum is < 20 cases
- ❌ Sub-feature composition is minimal
- ❌ No platform-specific code
- ❌ Feature logic is < 1000 lines
- ✅ You can extract it later without breaking anything

---

## Tree 2: Should I Use @DependencyClient or Singleton?

**Use this tree when deciding whether to inject a service via @DependencyClient or use a direct singleton/static method.**

```
Is this service/capability used in a feature reducer (TCA)?
├─ YES → Continue
└─ NO → Likely singleton; check question 2 below

Does the service need different implementations for testing?
├─ YES → Use @DependencyClient
│  Why: Tests need to override behavior
│  Example: @DependencyClient APIClient (testValue = mock)
│
└─ NO → Continue to next question

Is the service used in multiple features/tests?
├─ YES → Use @DependencyClient
│  Why: Makes dependencies explicit and testable
│  Example: DatabaseService used across 5 features
│
└─ NO → Evaluate case-by-case

────────────────────────────────────────

NOT USED IN REDUCER? (Jump here if answer was NO above)

Is this an Apple framework integration?
├─ YES (AudioSession, URLSession, UserDefaults, etc.)
│  ├─ YES, lifecycle managed → Singleton is fine
│  │  Example: AudioSession.sharedInstance
│  │
│  └─ YES, but needs testing → @DependencyClient wrapper
│     Example: Wrap URLSession behind @DependencyClient for mocking
│
└─ NO → Continue to next question

Does this service have mutable state or lifecycle?
├─ YES → Use @DependencyClient
│  Why: Allows test isolation and state reset
│  Example: AudioService (volume, playback state)
│
└─ NO → Singleton is fine
   Why: Stateless utilities don't need injection
   Example: Logger, JSON decoder, UUID generator

────────────────────────────────────────

DECISION SUMMARY

Use @DependencyClient when:
✅ Service is used in feature reducers
✅ Service needs test overrides
✅ Service is used across multiple features
✅ Service has mutable state or lifecycle

Use singleton when:
✅ Service is a stateless utility
✅ Service is an Apple framework (direct access)
✅ Service has no test-specific implementations
✅ Service is truly static (UUID generator, Logger)

────────────────────────────────────────

CONTEXT: Why This Distinction?

@DependencyClient benefits:
- Explicit: Dependencies are visible in code
- Testable: Easy to mock for tests
- Flexible: Different implementations per context
- Swift 6 friendly: Works with strict concurrency

Singleton benefits:
- Simple: Less boilerplate
- Performance: Direct access, no indirection
- Appropriate: For stateless utilities

Cost of wrong choice:
- Over-injecting: Unnecessary boilerplate (use singleton instead)
- Under-injecting: Testing nightmares, hidden dependencies
  (use @DependencyClient instead)
```

---

## Tree 3: Should I Refactor This Into a Module?

**Use this tree when evaluating whether an existing piece of code in the monolithic target should be extracted into a separate Swift Package module.**

```
Is this feature causing problems RIGHT NOW?
├─ YES → Extract it
│  Why: Pain is a signal to modularize
│  Examples:
│   - Slow compilation? Extract module to parallelize builds.
│   - Hard to test? Extract module to focus testing.
│   - Tangled dependencies? Extract module to clarify boundaries.
│
└─ NO → Continue to next question

Is this feature preventing other work?
├─ YES → Extract it
│  Why: Unblocking other features is worth the effort
│  Example: Can't work on ArticleSearch until ArticleReader
│           is stable (extract ArticleReader to module)
│
└─ NO → Continue to next question

Are you planning to reuse this in a new project?
├─ YES → Extract it now
│  Why: Easier to extract proactively than retrofit later
│  Example: Planning visionOS reading experience; ArticleReader
│           module can be reused across platforms
│
└─ NO → Continue to next question

Is this feature mature and stable?
├─ YES → Extract it
│  Why: Stable features are safe to modularize
│       (Early-stage features change API; harder to modularize)
│
└─ NO → Wait
   Why: APIs will change; modularization can wait
   Plan: Revisit when feature stabilizes

────────────────────────────────────────

REFACTORING DECISION

Extract to module if ANY of these:
✅ Feature is causing problems (slow builds, hard to test)
✅ Feature is blocking other work
✅ Feature will be reused in new projects
✅ Feature is stable with mature API

Keep monolithic if:
❌ Feature is early-stage (API changing)
❌ Feature is causing no pain
❌ Feature is not blocking work
❌ Feature is not reusable

────────────────────────────────────────

EXTRACTION COST vs BENEFIT

Low extraction cost, high benefit:
- Small, well-defined features
- Stable APIs
- Test-driven development (tests exist)
→ Extract now

High extraction cost, low benefit:
- Large, tangled features
- Changing APIs
- No tests
→ Keep monolithic; improve first, extract later

Medium extraction cost, medium benefit:
- Moderate size, some stability
- Occasional reuse
- Partial test coverage
→ Extract if it unblocks work; otherwise keep for now
```

---

## Tree 4: Where Should This Logic Live?

**Use this tree when deciding whether logic belongs in Core module, UI module, or Platform-specific module.**

```
Does this logic reference SwiftUI views or SwiftUI-specific APIs?
├─ YES → UI module
│  Why: Requires SwiftUI framework
│  Example: View state, SwiftUI modifiers, @State
│
└─ NO → Continue to next question

Is this domain/business logic independent of UI?
├─ YES → Core module
│  Why: Domain logic is platform-agnostic
│  Examples: Article CRUD, Tag management, Analytics events
│
└─ NO → Continue to next question

Does this logic use platform-specific frameworks?
├─ YES (macOS-specific, visionOS-specific) → Platform module
│  Why: Platform frameworks vary (NSViewRepresentable vs RealityView)
│  Examples:
│   - macOS: NSViewRepresentable wrapper for WKWebView
│   - visionOS: RealityView rendering
│
└─ NO → Continue to next question

Does this reducer manage feature state?
├─ YES → Core module (reducer + state)
│        UI module (views that use @Bindable)
│  Why: Reducers are domain logic; views are UI presentation
│
└─ NO → Check if it's a helper/utility

Is this a helper function or utility?
├─ YES, used across multiple features → Core module
│  Example: Article formatting, tag validation
│
└─ YES, used only in one feature → Same module as feature
   Example: Internal helper for ArticleReader

────────────────────────────────────────

MODULE STRUCTURE DECISION

Structure your feature like this:

FeatureCore/
├── FeatureFeature.swift (reducer + @ObservableState)
├── FeatureService.swift (@DependencyClient for domain logic)
└── FeatureModels.swift (data structures)

FeatureUI/
├── FeatureView.swift (SwiftUI views with @Bindable)
└── FeatureComponents.swift (reusable UI components)

FeatureMac/ (only if macOS-specific UI)
├── FeatureViewMac.swift (macOS-specific views)
└── FeatureMacComponents.swift

FeatureVision/ (only if visionOS-specific UI)
├── FeatureViewVision.swift (visionOS-specific views)
└── FeatureRealityView.swift

────────────────────────────────────────

DECISION TABLE

| Logic Type | Module | Why |
|-----------|--------|-----|
| Reducer state/actions | Core | Domain logic, platform-agnostic |
| Feature services | Core | Domain logic, easy to mock/test |
| SwiftUI views | UI | Framework-dependent |
| Platform-specific UI | Platform | Can't share across platforms |
| Helpers (single feature) | Same module | Keep together |
| Helpers (multi-feature) | Core | Shared, reusable |
| Models/types | Core | Domain logic, no UI dependency |
| Design tokens | Core | Shared, reusable |
| Tests | Tests/ | Always separate test target |
```

---

## Quick Reference Card

Print this or bookmark it:

```
Q1: When to modularize?
→ Used in 2+ places? Reusable code? 20+ actions?
→ YES to any? Extract module.

Q2: @DependencyClient or singleton?
→ Used in reducer? Needs test mock? YES? Use @DependencyClient.
→ Stateless utility? Singleton is fine.

Q3: Should I refactor to module?
→ Causing pain? Blocking work? Will reuse? Stable?
→ YES to any? Extract. Otherwise wait.

Q4: Where should logic live?
→ SwiftUI views? → UI module
→ Domain logic? → Core module
→ Platform-specific? → Platform module
```

---

## References

- **Tree 1** references: [SPMModuleBoundaries.md](./Scroll/Docs/Architecture/SPMModuleBoundaries.md)
- **Tree 2** references: [AGENTS-AGNOSTIC.md - Dependency Injection](./AGENTS-AGNOSTIC.md#dependency-injection--modern-tca-patterns)
- **Tree 3-4** references: [AGENTS-AGNOSTIC.md - Modularization](./AGENTS-AGNOSTIC.md#modularization-best-practices)
