# How to Evaluate Agent Submissions

**Workflow:**

1. Agent completes work using [AGENTS-SUBMISSION-TEMPLATE.md](AGENTS-SUBMISSION-TEMPLATE.md)
2. Agent pastes their submission summary in response
3. You copy their summary here (below)
4. **I evaluate it** against the checklist and give you a verdict

---

## Evaluation Template (Copy Agent's Submission Here)

**Agent's SUBMISSION SUMMARY:**

[PASTE AGENT'S SUBMISSION HERE]

---

## I Will Evaluate:

### ✅ Framework Compliance
- [ ] Agent cited AGENTS.md sections (specific line numbers)
- [ ] Agent defined task scope (Safe/Approval/Forbidden)
- [ ] Agent answered decision tree questions
- [ ] Agent verified modern patterns before submitting

### ✅ Code Pattern Review
- [ ] No `@Published` (should be `@Observable`)
- [ ] No `@Perception.Bindable` (should be `@Bindable`)
- [ ] No `WithPerceptionTracking` wrapper
- [ ] No manual `DependencyKey` (should use `@DependencyClient`)
- [ ] No `class` for state (should be `struct`)
- [ ] Uses Swift Testing (not XCTest)

### ✅ Architecture Decisions
- [ ] Tree 1 answer (module vs. monolithic) - justified
- [ ] Tree 2 answer (DependencyClient vs. singleton) - justified
- [ ] Tree 4 answer (Core/UI/Platform placement) - justified

### ✅ Scope Boundaries
- [ ] Safe Zone clearly defined
- [ ] Approval Zone clearly defined
- [ ] Forbidden Zone reported if discovered

---

## Example: How You'd Ask Me

You copy agent's submission and message me:

```
Agent submission for review:

## SUBMISSION SUMMARY

**Task:** Add article caching with 24-hour invalidation

**Scope:**
- Safe: ArticleCacheService.swift, ArticleCacheTests.swift
- Approval: ArticleQueueFeature.swift
- Forbidden: None

**Architecture Decisions:**
- Module: Stay monolithic (single use, <20 actions)
  Ref: AGENTS-DECISION-TREES.md Tree 1

- Dependency: @DependencyClient (needs testing, used in reducer)
  Ref: AGENTS-DECISION-TREES.md Tree 2

- Location: Core module
  Ref: AGENTS-DECISION-TREES.md Tree 4

**Code checks:**
- ✅ @DependencyClient for ArticleCacheService
- ✅ @Observable state, no @Published
- ✅ Swift Testing, no XCTest
- ✅ @Bindable views

Is this compliant?
```

I'll respond:

```
✅ PASS - Framework Compliant

**Strengths:**
- Cited correct AGENTS.md sections with line numbers
- Defined scope clearly (Safe/Approval/Forbidden)
- Used decision trees to justify all 3 architectural choices
- Verified modern patterns before submitting

**No violations found:**
- No @Published, @Perception.Bindable, or WithPerceptionTracking
- Using @DependencyClient macro (modern pattern)
- Using Swift Testing (current standard)
- Task scope respected

**Ready to merge.** Code review can focus on logic, not patterns.
```

---

## Quick Evaluation Script

When agent submits, check:

1. **Does submission have all 5 sections?**
   - ✅ Framework Verification (checkboxes)
   - ✅ Task Scope Definition
   - ✅ Architecture Decisions
   - ✅ Code Patterns - Self-Check
   - ✅ Submission Summary

2. **Count citations to AGENTS.md**
   - 0 citations = ❌ FAIL (didn't read framework)
   - 1-2 citations = ⚠️ PARTIAL (minimal engagement)
   - 3+ citations = ✅ PASS (following framework)

3. **Look for red flags**
   - Any `@Published` mentioned? ❌
   - Any `@Perception.Bindable` mentioned? ❌
   - Any manual `DependencyKey` mentioned? ❌
   - Any XCTest mentioned? ❌
   - Any scope creep (editing Forbidden Zone)? ❌

4. **Check decision tree answers**
   - Are all 3 decisions answered?
   - Are they justified with specific reasons?
   - Do reasons match the decision tree logic?

---

## Verdict Templates

### ✅ PASS Template
```
✅ PASS - Framework Compliant

**What went well:**
- [Specific pattern citations]
- [Correct architectural decisions]
- [Clear scope definition]

**Ready to merge.** Code review can focus on functionality.
```

### ⚠️ PARTIAL Template
```
⚠️ PARTIAL - Mostly Compliant, Minor Issues

**What went well:**
- [Good things]

**Minor issues:**
- [Specific pattern that needs attention]
- Reference: AGENTS-AGNOSTIC.md line X

**Fix needed before merge:** [What to correct]
```

### ❌ FAIL Template
```
❌ FAIL - Not Framework Compliant

**Critical issues:**
- [Deprecated pattern used]
- [No scope definition]
- [Decision not justified]

**Citations:**
- AGENTS-AGNOSTIC.md line X
- AGENTS-DECISION-TREES.md Tree Y
- AGENTS-TASK-SCOPE.md section Z

**Rejected.** Please re-read sections above and resubmit.
```

---

## Next Steps After Evaluation

**If ✅ PASS:**
- Proceed with code review (functionality, logic, testing)
- Approve PR

**If ⚠️ PARTIAL:**
- Request specific fixes
- Quote AGENTS.md section in your request
- Resubmit for quick re-evaluation

**If ❌ FAIL:**
- Return submission with links to AGENTS.md sections
- Do not merge until compliant
- Ask agent to re-read and resubmit

---

## Summary

This creates a **feedback loop:**

1. **Agent uses template** → Thinks through framework before submitting
2. **You evaluate** → Copy submission to me
3. **I check compliance** → Give you verdict (PASS/PARTIAL/FAIL)
4. **You give feedback** → Agent re-reads, improves, resubmits
5. **Loop until PASS** → Then proceed to code review

This ensures **framework compliance BEFORE code review**, not after.
