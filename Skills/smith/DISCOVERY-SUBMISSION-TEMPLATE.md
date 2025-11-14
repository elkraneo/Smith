# Discovery Submission Template

Use this template when you discover a new pattern, anti-pattern, or critical lesson that should be documented in the Smith framework.

**This is for framework improvement, not code review.** You're proposing that future agents should know about this pattern.

---

## Before You Submit

**DO NOT submit without completing all sections below.** This ensures your discovery is:
- Clear and replicable
- Actionable for other agents
- Properly integrated into framework documents
- Backed by real-world evidence

---

## 1. Discovery Classification

### What type of discovery is this?

- [ ] **New Pattern** - A technique that works well and should be standard practice
- [ ] **Anti-Pattern** - Something to avoid with explanation of why
- [ ] **Critical Gap** - A missing piece of guidance that caused a real problem
- [ ] **Error Masking** - A compiler/framework behavior that hides the real issue
- [ ] **Best Practice Refinement** - An update to existing guidance with nuance

### Impact Scope

- [ ] **All Platforms** (iOS, macOS, iPadOS, visionOS, watchOS)
- [ ] **Specific Platform** (which one: visionOS / macOS / iOS?)
- [ ] **TCA-Specific** (applies to Composable Architecture patterns)
- [ ] **Module Design** (architecture, dependencies, boundaries)
- [ ] **Testing** (test patterns, verification strategies)
- [ ] **Other** (specify)

---

## 2. The Problem

### What issue did you encounter?

Describe the symptom/error you hit:

```
[Paste error message, unexpected behavior, or confusion here]
```

### Why was it not obvious?

Explain why the problem was hard to spot:
- Compiler error message was misleading?
- Documentation was silent/unclear?
- Pattern was undocumented?
- Error appeared in unexpected place?

### Real-world context

Where did this happen?
- Project/file: `[path]`
- Feature: `[name]`
- Approximate time spent debugging: `[X hours/minutes]`

---

## 3. Root Cause Analysis

### What was actually happening?

Explain the root cause clearly and concisely:

```
[1-3 sentences explaining the real issue]
```

### Why did agents/developers miss this?

- Was there incomplete documentation?
- Was the error message misleading?
- Was it a gap in the framework?
- Was the pattern not taught?

### Is this a one-off or systemic?

- [ ] One-off edge case (unlikely to affect others)
- [ ] Systemic pattern (many agents could hit this)
- [ ] Environmental (specific to one project setup)
- [ ] Undiscovered pattern (framework gap)

---

## 4. The Solution

### What fixed it?

Describe the solution concisely:

```
[2-4 sentences explaining what worked]
```

### Code example (if applicable)

Show the fix:

```swift
// ❌ WRONG
[incorrect code]

// ✅ CORRECT
[correct code]
```

### Is this a code fix or framework guidance?

- [ ] **Code fix** (agents need to change their code to avoid this)
- [ ] **Framework guidance** (agents need to know this pattern to make better decisions)
- [ ] **Both** (code change + new pattern to teach)

---

## 5. Framework Integration

### Where should this live in the framework?

Which document should be updated?

- [ ] AGENTS-AGNOSTIC.md (universal patterns)
- [ ] AGENTS-DECISION-TREES.md (architectural decision)
- [ ] AGENTS-SUBMISSION-TEMPLATE.md (submission checklist item)
- [ ] AGENTS-EVALUATION-CHECKLIST.md (reviewer verification)
- [ ] PLATFORM-*.md (platform-specific, which: visionOS / macOS / iOS / etc)
- [ ] AGENTS-TCA-PATTERNS.md (TCA pattern or anti-pattern)
- [ ] Other (specify)

### What enforcement level should this be?

- [ ] **[CRITICAL]** - Non-negotiable, code won't compile or will fail review without this
- [ ] **[STANDARD]** - Expected practice, exceptions rare and documented
- [ ] **[GUIDANCE]** - Best practice, use judgment

**Justification:** Why this level?

```
[1-2 sentences explaining the enforcement level]
```

### Suggested framework text

Write 2-3 paragraphs of what should be added to the framework:

```markdown
### [Title of Pattern/Anti-Pattern]

[Paragraph 1: What and why]

[Paragraph 2: How to do it correctly]

[Paragraph 3: Example or reference case study]
```

---

## 6. Submission Checklist

- [ ] Described the problem clearly (error message, unexpected behavior)
- [ ] Explained why it wasn't obvious (compiler hiding root cause, doc gap, etc.)
- [ ] Analyzed the root cause (not just the symptom)
- [ ] Provided a working solution with code example
- [ ] Identified where this should live in framework
- [ ] Chose appropriate enforcement level with justification
- [ ] Wrote suggested framework text
- [ ] Identified if this is one-off or systemic pattern

---

## 7. Case Study (Optional but Recommended)

### Should this have a dedicated case study file?

- [ ] **Yes, create DISCOVERY-N-*.md** - Complex discovery with investigation trail worth documenting
- [ ] **No, update existing doc** - Simple pattern that fits in existing section
- [ ] **Maybe, depends on reviewer** - Unclear, let reviewer decide

**If yes, provide:**

- **Proposed filename:** `DISCOVERY-N-[DESCRIPTIVE-NAME].md`
- **Investigation summary:** What steps did you take to uncover this?
- **Prevention strategy:** How should agents avoid this in future?

---

## Example Submission

```markdown
## DISCOVERY SUBMISSION

### Classification
- [x] Critical Gap
- [x] Error Masking
- Impact: All Platforms (TCA-specific)

### The Problem
**Error encountered:**
```
Cannot convert value of type 'Binding<Article.ID??>'
to expected argument type 'Binding<Article.ID?>'
```

**Why not obvious:** The compiler reported the symptom (type mismatch) instead of
the root cause (access control violations). The error appeared in binding projection
code, not in the actual access level declaration.

**Real-world context:**
- Project: ScrollApp (ArticleQueue feature)
- Time spent: ~1 hour debugging the wrong thing
- File: ArticleQueueFeature.swift, ScrollApp.swift

### Root Cause Analysis

**What was actually happening:**
When exposing a public property (`articleSelection`) for binding projection, all
transitive type dependencies must also be public. The compiler validates this but
reports it as a type error, not an access control error.

**Why missed:** Documentation didn't explain that exposing one property forces
transitive types to be public. Compiler's error message directed debugging toward
optional handling instead of access control.

**Systemic?** Yes—any agent using TCA 1.x @Bindable binding patterns could hit this.

### The Solution

**What fixed it:**
Traced the full dependency chain of the property being exposed:
- articleSelection: Article.ID? (needs public)
- ArticleSidebarDestination (was internal → must be public)
- ArticleLibraryCategory (was internal → must be public)
- All protocol conformances (Hashable, Equatable methods must be public)

**Code example:**
```swift
// ❌ WRONG
internal enum ArticleSidebarDestination { ... }
// When you try: $store.articleSelection → HIDDEN ERROR

// ✅ CORRECT
public enum ArticleSidebarDestination: Hashable {
  // ...
  public func hash(into hasher: inout Hasher) { ... }
  public static func == (lhs: Self, rhs: Self) -> Bool { ... }
}
// Now $store.articleSelection works
```

### Framework Integration

**Where:** AGENTS-AGNOSTIC.md (new section "Access Control & Public API Boundaries")

**Level:** [STANDARD] - Expected practice for anyone using @Bindable patterns

**Justification:** Every agent using modern TCA 1.x with binding projections needs
to understand transitive access control. This prevents hours of debugging compiler
errors.

**Suggested text:**

```markdown
### Access Control & Public API Boundaries

When you expose a property for binding projection ($store.property), all transitive
type dependencies must also be public. The Swift compiler validates this but may
report misleading error messages about type mismatches instead of access control.

**Checklist before making anything public:**
- Is the property itself public?
- Is the property's base type public?
- Are all transitive dependencies public?
- Does this violate module boundaries?
```

**Case Study:** Yes, create DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md with full
investigation trail and debugging checklist.
```

---

## Submission Process

1. **Fill out this template completely**
2. **Paste the completed form** in a message or file
3. **Mention who should review** (framework owner, platform expert, etc.)
4. **Wait for feedback:**
   - ✅ **ACCEPT** - Discovery is valid, framework will be updated
   - ⚠️ **PARTIAL** - Good pattern but needs refinement before adding
   - ❌ **DECLINE** - One-off edge case, not systemic enough to document
   - 🔄 **REQUEST CHANGES** - Clarify root cause, improve example, etc.

---

## Questions?

- **Is my discovery systemic or one-off?** Ask the framework reviewer
- **Which document should I update?** Read [AGENTS-FRAMEWORK.md](AGENTS-FRAMEWORK.md) for navigation
- **How do I write a case study?** See [CaseStudies/README.md](../../CaseStudies/README.md)
- **What's the difference between this and code submission?** This is framework improvement; code submission is feature/fix review

---

## Red Flags - Don't Submit If:

❌ You're just asking for code review (use AGENTS-SUBMISSION-TEMPLATE.md instead)
❌ You haven't verified this is systemic (not just a one-off edge case)
❌ You can't articulate why agents should know this
❌ The compiler message is actually clear (not masking the real issue)
❌ This is environment-specific (Xcode version, project setup only)
❌ You haven't tried the suggested solution yourself

---

## Related Templates

- **Code/Feature Submission:** [AGENTS-SUBMISSION-TEMPLATE.md](AGENTS-SUBMISSION-TEMPLATE.md)
- **Case Study Guidelines:** [CaseStudies/README.md](../../CaseStudies/README.md)
- **Framework Evaluation:** [AGENTS-EVALUATION-CHECKLIST.md](AGENTS-EVALUATION-CHECKLIST.md)
