# Discovery Evaluation Checklist

Use this checklist when reviewing a discovery submission to decide if it should be integrated into the Smith framework.

**Role:** Framework owner or designated reviewer
**Input:** Completed DISCOVERY-SUBMISSION-TEMPLATE.md
**Output:** Accept / Partial / Decline / Request Changes

---

## Quick Assessment

### Is this a discovery or something else?

- [ ] Discovery (new pattern, anti-pattern, or critical gap) → Continue
- [ ] Code review request (should use AGENTS-SUBMISSION-TEMPLATE.md) → DECLINE, redirect
- [ ] Bug report (environmental issue, not systemic) → DECLINE, file as issue
- [ ] Feature request (not yet proven) → REQUEST CHANGES, ask for real-world evidence

**Notes:**

---

## Problem Validation

### Did the submitter clearly describe the problem?

- [ ] Error message or behavior included
- [ ] Reproduction context given (project, feature, file)
- [ ] Time spent debugging mentioned (shows severity)
- [ ] Root cause analysis is clear, not just symptoms

**Issues found:**

- [ ] Problem unclear → REQUEST CHANGES: "Please clarify the exact error and context"
- [ ] Problem is environmental only → DECLINE: "This appears project-specific, not systemic"
- [ ] Problem is one-off edge case → DECLINE: "This is too rare to document in framework"

---

## Root Cause Assessment

### Is the root cause analysis valid?

- [ ] Root cause explained (not just symptom)
- [ ] Explanation is technically sound
- [ ] Solution directly addresses root cause
- [ ] No misconceptions about Swift/TCA behavior

**Concerns:**

- [ ] Root cause unclear → REQUEST CHANGES: "Please dig deeper into why this happened"
- [ ] Explanation seems wrong → REQUEST CHANGES: "This contradicts [framework doc], please verify"
- [ ] Solution doesn't match problem → REQUEST CHANGES: "The fix doesn't address the root cause"

---

## Systemic Pattern Check

### Is this a systemic pattern other agents will encounter?

**Questions to ask:**

1. Could this happen to other agents using the same pattern?
   - [ ] Yes, any agent using @Bindable could hit this
   - [ ] Yes, anyone implementing TCA features
   - [ ] Maybe, depends on project structure
   - [ ] No, very specific to this code
   - [ ] Unknown

2. How many agents might hit this?
   - [ ] All future agents (foundational pattern)
   - [ ] Most agents (common scenario)
   - [ ] Some agents (specific use case)
   - [ ] Few agents (rare edge case)
   - [ ] Just this project

3. Is the pattern documented anywhere else?
   - [ ] No, it's a gap in documentation
   - [ ] Partially, but unclear
   - [ ] Yes, but submitter missed it
   - [ ] It's in external docs (Apple, Point-Free)

**Assessment:**

- [ ] Systemic → Continue to framework integration
- [ ] Possibly systemic → REQUEST CHANGES: "Please provide more evidence of systemic nature"
- [ ] One-off → DECLINE: "This is too specific to integrate into core framework"

---

## Solution Validation

### Is the proposed solution sound?

- [ ] Solution solves the root cause
- [ ] Code example is correct
- [ ] Solution doesn't introduce new problems
- [ ] Solution aligns with existing framework patterns

**Check against framework:**

- [ ] Uses modern patterns (TCA 1.23.0+, Swift 6.2)
- [ ] Doesn't contradict existing guidance
- [ ] Doesn't use deprecated APIs
- [ ] Follows framework conventions

**Issues found:**

- [ ] Solution incomplete → REQUEST CHANGES: "The fix only partially solves the problem"
- [ ] Solution uses deprecated pattern → DECLINE: "Uses [deprecated API], conflicts with AGENTS-AGNOSTIC.md"
- [ ] Better solution exists → REQUEST CHANGES: "Consider using [existing pattern] instead"

---

## Framework Integration Planning

### Is the proposed framework location correct?

**Check proposed document:**

- [ ] Location makes sense (discoverer chose right doc)
- [ ] Content would fit naturally in that section
- [ ] Content doesn't duplicate existing guidance
- [ ] Document scope includes this topic

**Verify against AGENTS-FRAMEWORK.md:**

- [ ] Universal pattern? → AGENTS-AGNOSTIC.md
- [ ] Architectural decision? → AGENTS-DECISION-TREES.md
- [ ] Platform-specific? → PLATFORM-*.md
- [ ] TCA pattern? → AGENTS-TCA-PATTERNS.md or AGENTS-AGNOSTIC.md
- [ ] Submission checklist item? → AGENTS-SUBMISSION-TEMPLATE.md
- [ ] Review verification? → AGENTS-EVALUATION-CHECKLIST.md

**Issues:**

- [ ] Wrong location → REQUEST CHANGES: "This should go in [correct doc] because..."
- [ ] Multiple documents needed → REQUEST CHANGES: "This will require updates to [doc1] and [doc2]"
- [ ] Duplicates existing content → DECLINE: "This is already covered in [existing section]"

---

## Enforcement Level Assessment

### Is the enforcement level correct?

**Proposed level:** [check what submitter chose]

- [ ] [CRITICAL] - Must be non-negotiable?
  - Will code not compile without this knowledge?
  - Will code fail immediate code review?
  - Is this a language/framework requirement?
  - → If yes to all, [CRITICAL] is correct
  - → If no, suggest [STANDARD] instead

- [ ] [STANDARD] - Expected practice?
  - Will most agents hit this pattern?
  - Is this a common scenario?
  - Are there rare exceptions?
  - → If yes to all, [STANDARD] is correct
  - → If niche, suggest [GUIDANCE] instead

- [ ] [GUIDANCE] - Best practice with exceptions?
  - Is this optional/contextual?
  - Can reasonable code violate this?
  - → If yes, [GUIDANCE] is correct
  - → If no exceptions, suggest higher level

**Assessment:**

- [ ] Level is correct → Continue
- [ ] Level is too high → REQUEST CHANGES: "This seems [STANDARD] not [CRITICAL]"
- [ ] Level is too low → REQUEST CHANGES: "Agents should be required to know this ([CRITICAL])"

---

## Case Study Assessment

### Should this have a dedicated case study?

**Use case study if:**
- [ ] Complex investigation with diagnostic trail
- [ ] Multi-step debugging process worth documenting
- [ ] Lessons about prevention strategy
- [ ] Real-world project context valuable

**Use inline doc update if:**
- [ ] Simple pattern (fits in 2-3 paragraphs)
- [ ] Straightforward solution
- [ ] No investigation trail needed
- [ ] Fits naturally in existing section

**Verify case study (if proposed):**

- [ ] Filename follows DISCOVERY-N-*.md convention
- [ ] Investigation process clearly described
- [ ] Prevention strategy included
- [ ] Framework impact explained
- [ ] Proper structure (Executive Summary, Root Cause, Investigation, Solution, Prevention)

**Issues:**

- [ ] Should be case study but isn't proposed → REQUEST CHANGES: "This warrants a case study"
- [ ] Case study unnecessary → REQUEST CHANGES: "This can be a 2-3 paragraph addition instead"

---

## Quality Checks

### Is the submission high quality?

**Writing & clarity:**
- [ ] Clear, concise language
- [ ] No ambiguity in technical explanations
- [ ] Good code examples
- [ ] Proper formatting and structure

**Completeness:**
- [ ] All sections filled out
- [ ] Evidence provided (not just assertions)
- [ ] Example code works
- [ ] References to related framework docs

**Rigor:**
- [ ] Root cause is proven, not assumed
- [ ] Solution tested/verified
- [ ] No speculation without evidence
- [ ] Acknowledges limitations or unknowns

**Issues:**

- [ ] Poorly written → REQUEST CHANGES: "Please clarify [specific section]"
- [ ] Missing evidence → REQUEST CHANGES: "Can you provide proof this is systemic?"
- [ ] Incomplete → REQUEST CHANGES: "Please fill out [missing section]"

---

## Integration Effort Assessment

### How much work is this to integrate?

**Estimate effort:**

- [ ] **Low** - 1 section update, ~100 lines, simple checklist item
- [ ] **Medium** - 2-3 sections, case study, cross-document updates
- [ ] **High** - 4+ documents, major case study, restructuring needed
- [ ] **Very High** - Multiple rewrites, new document structure

**Notes on effort:**

---

## Final Decision

### Make a verdict:

Choose one:

- [ ] **✅ ACCEPT** - Valid discovery, integrate as-is
  - Framework updates needed: [list]
  - Case study: [yes/no]
  - Who will implement: [name or "submitter"]
  - Timeline: [estimate]
  - Notes: [any feedback]

- [ ] **⚠️ PARTIAL** - Valid pattern but needs refinement
  - Requested changes: [list 2-3 items]
  - Can submitter revise and resubmit?
  - Blockers: [if any]

- [ ] **🔄 REQUEST CHANGES** - Good start but incomplete
  - What's missing: [list specific gaps]
  - Questions for submitter: [what to clarify]
  - Resubmission: Ask submitter to address and resubmit

- [ ] **❌ DECLINE** - Not appropriate for framework
  - Reason: [PICK ONE]
    - [ ] One-off edge case, not systemic
    - [ ] Contradicts existing framework guidance
    - [ ] Environmental/project-specific, not universal
    - [ ] Code review issue, not pattern
    - [ ] Already documented elsewhere
  - Suggestion: [what should they do instead]

---

## Implementation Notes (If Accepted)

### Framework updates checklist:

- [ ] Main doc updated (AGENTS-AGNOSTIC.md / AGENTS-DECISION-TREES.md / PLATFORM-*.md)
- [ ] Submission template updated (if new checklist item)
- [ ] Evaluation checklist updated (if new red flag/green flag)
- [ ] EVOLUTION.md updated with discovery entry
- [ ] Case study created (if applicable)
- [ ] AGENTS-FRAMEWORK.md updated (if new section/doc)
- [ ] All internal doc links verified
- [ ] Line number citations verified

### Post-integration:

- [ ] Alert relevant agents about new pattern
- [ ] Add to next team sync agenda
- [ ] Monitor if pattern prevents future issues
- [ ] Collect feedback from agents using new pattern

---

## Reviewer Sign-Off

- **Reviewed by:** [name]
- **Date:** [date]
- **Verdict:** [ACCEPT / PARTIAL / REQUEST CHANGES / DECLINE]
- **Implementation assigned to:** [name]
- **Target date for integration:** [date]

---

## Related Checklists

- **Discovery Submission:** [DISCOVERY-SUBMISSION-TEMPLATE.md](DISCOVERY-SUBMISSION-TEMPLATE.md)
- **Code Submission:** [AGENTS-SUBMISSION-TEMPLATE.md](AGENTS-SUBMISSION-TEMPLATE.md)
- **Code Evaluation:** [AGENTS-EVALUATION-CHECKLIST.md](AGENTS-EVALUATION-CHECKLIST.md)
