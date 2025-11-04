# DISCOVERY-5: Access Control Cascade Failure in TCA Binding Patterns

**Date:** November 4, 2025
**Discovery Context:** ScrollApp compilation errors during TCA 1.x binding pattern implementation
**Impact Level:** HIGH - Affects any feature exposing state types with transitive dependencies
**Framework Documents Affected:** AGENTS-AGNOSTIC.md, AGENTS-SUBMISSION-TEMPLATE.md

---

## Executive Summary

When implementing TCA 1.x `@Bindable` binding patterns, a type mismatch error (`Cannot convert value of type 'Binding<Article.ID??>' to expected argument type 'Binding<Article.ID?>'`) masked the real issue: **cascading access control violations in transitive type dependencies**.

**The Lesson:** Exposing a public property forces all transitive type dependencies to become public. The compiler's error messages often hide this, reporting symptoms instead of root causes.

**Prevention:** Check the full dependency chain **before** making any type or property public. Use the access control cascade checklist when expanding public API surface.

---

## Root Cause Analysis

### The Apparent Error

```swift
// ScrollApp.swift, line 156
windowGroup("Article Reader") {
  ArticleReaderView(store: $store.articleSelection)
    // ERROR: Cannot convert value of type 'Binding<Article.ID??>'
    //        to expected argument type 'Binding<Article.ID?>'
}
```

**Initial diagnosis:** Double-optional mismatch. Attempted fix: unwrap binding with `??`.

**Why this failed:** The actual problem was `articleSelection` property was `internal`, not exposed to the App module. The compiler couldn't even tell us that—it gave us a symptom instead.

### The Cascade

Making `articleSelection` public revealed a chain of hidden violations:

```
articleSelection: Article.ID?
  ↓ depends on type
Article.ID (already public) ✅

primarySelection: ArticleSidebarDestination?
  ↓ depends on type
ArticleSidebarDestination (was internal) ❌
  ↓ depends on type
ArticleLibraryCategory (was internal) ❌
  ↓ all conformance methods must be public
Hashable.hash(into:) (was internal) ❌
Equatable.== (was internal) ❌
```

**Each public property must expose all its transitive type dependencies.**

### Why Compiler Hid the Real Error

Swift's access control system validates visibility at **declaration time**, not **type reference time**. When you use `$store.articleSelection` binding:

1. Compiler checks: "Can app see `articleSelection`?" → No (internal)
2. Compiler tries to build type signature anyway for error reporting
3. Compiler can't fully construct `Binding<Article.ID?>` due to missing types
4. Reports incomplete/misleading error about optionals instead of access control

**This is a compiler UX limitation, not a Swift design flaw.** But it means access control bugs manifest as strange type errors.

---

## Investigation Process

### Step 1: Reproduce the Error

```swift
// In ScrollApp.swift
@Bindable var store = Store(initialState: ScrollState())
// ...
windowGroup("Article Reader") {
  ArticleReaderView(store: $store.articleSelection)
  //                         ^^^^^^^^ Error here
}
```

### Step 2: Check Property Declaration

```swift
// ArticleQueueFeature.swift line 251
@ObservableState
struct State {
  var primarySelection: ArticleSidebarDestination? = nil
  // ^^^ internal by default—not public
}
```

### Step 3: Make Property Public

```swift
// Fix attempt:
public var articleSelection: Article.ID?
```

**Result:** New cascade of errors about `ArticleSidebarDestination` not being public.

### Step 4: Trace Transitive Dependencies

Check each public property's full type chain:
- Property type itself (must be public)
- Any enum/struct it depends on (must be public)
- Any protocols it conforms to (must expose conformance publicly)

### Step 5: Verify No Circular Access Issues

After making types public, ensure:
- No circular module dependencies introduced
- Public types don't leak internal implementation details
- Access control boundaries still make sense architecturally

---

## Solution

### Minimal Changes Required

**ArticleQueueFeature.swift:**

1. Make `ArticleLibraryCategory` enum public (line 17)
2. Make `ArticleSidebarDestination` enum public (line 89)
3. Make `articleSelection` property public (line 251)
4. Ensure all `Hashable` and `Equatable` conformance methods are public

```swift
// Line 17 - ArticleLibraryCategory
public enum ArticleLibraryCategory: Hashable, Equatable {
  case all
  case favorites
  case reading
  // ...

  public func hash(into hasher: inout Hasher) { /* ... */ }
  public static func == (lhs: Self, rhs: Self) -> Bool { /* ... */ }
}

// Line 89 - ArticleSidebarDestination
public enum ArticleSidebarDestination: Hashable, Equatable {
  case detail(Article.ID)
  case settings
  // ...

  public func hash(into hasher: inout Hasher) { /* ... */ }
  public static func == (lhs: Self, rhs: Self) -> Bool { /* ... */ }
}

// Line 251 - State property
@ObservableState
public struct State {
  public var articleSelection: Article.ID?
  // ...
}
```

**ScrollApp.swift:**

```swift
// Line 32 - Add @Bindable as provided by linter
@Bindable var store = Store(initialState: ScrollState())

// Line 156 - Direct binding projection now works
windowGroup("Article Reader") {
  ArticleReaderView(store: $store.articleSelection)
  // ✅ Now compiles: articleSelection is public, binding projection works
}
```

### Why This Solution Is Correct

Per **AGENTS-AGNOSTIC.md lines 253–326** (TCA 1.x Binding Patterns):

> "When using `@Bindable`, the property being bound must be public and accessible from the calling scope. All types in the property's type signature must also be public."

The solution:
- ✅ Respects TCA 1.x binding patterns
- ✅ Maintains `@ObservableState` for automatic observation
- ✅ Uses `@Bindable` for binding projection (modern pattern, not manual `Binding(get:set:)`)
- ✅ No deprecated patterns (no `WithViewStore`, `@Perception.Bindable`)
- ✅ No circular dependencies introduced

---

## Prevention Strategy

### Checklist: Before Making Any Type/Property Public

Use this when you encounter access control errors:

```markdown
- [ ] Is the property itself public (or do you need to make it public)?
- [ ] Is the property's base type public (or must it be)?
  - [ ] Check: enum or struct that holds the property
  - [ ] Check: any generic type parameters

- [ ] Do all transitive types need to be public?
  - [ ] Direct type (ArticleSidebarDestination)
  - [ ] Types used by that type (ArticleLibraryCategory)
  - [ ] Protocol conformances (Hashable.hash, Equatable.==)

- [ ] Does this violate module boundaries?
  - [ ] Is the type now visible outside its intended scope?
  - [ ] Does a higher-level module now depend on lower-level internals?
  - [ ] Could this create a circular dependency?

- [ ] Is there an alternative?
  - [ ] Could you use a protocol instead of concrete type?
  - [ ] Could you move the type to a shared module?
  - [ ] Could you use a wrapper type at the boundary?
```

### How to Debug Access Control Errors

1. **Don't trust the error message.** If you see type mismatch or binding errors, check access levels first.

2. **Trace the full chain:**
   ```swift
   // Not just checking the property...
   public var state: State  // ← Must be public

   // ...but everything it depends on
   struct State { var item: Item? }  // Item must be public
   struct Item { var id: ID }        // ID must be public (or be a basic type)
   ```

3. **Use Xcode's Quick Help** to check what's public/internal:
   - Option-click on a type in Xcode
   - See the access level in the generated interface
   - If "internal" is shown, you found a hidden violation

4. **When adding @Bindable**, assume all bound properties need public types.

---

## Framework Impact

### Updates Made

1. **AGENTS-AGNOSTIC.md** (new section added)
   - Access Control & Public API Boundaries
   - Checklist for exposing types/properties
   - Anti-pattern: Exposing too much (leaking internals)
   - Anti-pattern: Missing transitive public declarations

2. **AGENTS-SUBMISSION-TEMPLATE.md** (new checklist item)
   - Code Pattern Check section:
     - "[ ] Verified transitive access control (all types in dependency chain are public)"
     - Citation to this case study

3. **EVOLUTION.md** (Discovery entry)
   - Recorded as Discovery 5
   - Links to this case study and AGENTS-AGNOSTIC.md sections

---

## Key Learnings

### For Agents

1. **Access control errors masquerade as type errors.**
   - When you see `Cannot convert Binding<X>` errors, check access levels first.
   - Make the property public, then chase each compiler error up the chain.

2. **Think in transitive dependencies, not just immediate types.**
   - Public properties force their entire type signature to be public.
   - This includes transitive enums, structs, and protocol conformances.

3. **Document why types are public.**
   - If you're making an internal type public, add a comment explaining why.
   - Future refactors might reconsider this boundary.

### For Framework

1. **Access control is part of module design.**
   - Module boundaries should be enforced by Swift's access control, not just documentation.
   - When designing feature modules, consider what's worth exposing publicly.

2. **The compiler's error messages can mislead.**
   - Always run a full build and check the error sequence.
   - Fix the first error (usually access control), then see what remains.

3. **Add access control checks to submission reviews.**
   - Reviewers should verify that public APIs have public dependencies.
   - This is as important as pattern verification.

---

## Related Patterns

- **AGENTS-DECISION-TREES.md Tree 4** (Core/UI/Platform placement): Where should state types live?
- **AGENTS-AGNOSTIC.md lines 79–207** (State Management): Using `@ObservableState` and `@Bindable`
- **AGENTS-AGNOSTIC.md lines 253–326** (TCA Binding Patterns): Modern binding with `@Bindable`

---

## References

- **Swift Language Guide**: [Access Control](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol)
- **ComposableArchitecture**: [State Management & Bindings](https://pointfreeco.github.io/swift-composable-architecture/)
- **Case Study**: [WHY-WE-MISSED-THE-POPOVER-BUG.md](WHY-WE-MISSED-THE-POPOVER-BUG.md) - Similar pattern discovery in visionOS
