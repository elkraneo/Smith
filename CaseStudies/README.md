# Smith Framework Case Studies

This directory contains project-specific bug investigations, post-mortems, and lessons learned from real-world development. These are not part of the core Smith framework but are valuable references for understanding how framework patterns apply in practice.

## Current Case Studies

### Case Study 1: RealityKit Popover Entity Infrastructure Gap
**Date:** November 1, 2025
**Scope:** visionOS RealityKit + TCA integration
**Outcome:** Discovered implicit infrastructure dependency in popover implementation

**Files:**
- `DISCOVERY-4-POPOVER-ENTITY-GAP.md` - Complete bug investigation with testing strategy
- `WHY-WE-MISSED-THE-POPOVER-BUG.md` - Root cause analysis of why the bug was hard to catch

**Key Lesson:** Modern TCA patterns are correct but RealityKit entities must be explicitly created and added to the scene graph early. Deferring entity creation until presentation is needed causes synchronization gaps between state management and rendering.

**Framework Impact:** Led to new [CRITICAL] section in `Sources/PLATFORM-VISIONOS.md` documenting the PresentationComponent entity creation pattern.

---

## How to Use Case Studies

### When Planning visionOS Development
- Read the case study before implementing similar features
- Check if your feature has the same infrastructure dependency pattern
- Use as reference for testing strategy

### When Debugging Similar Issues
- Case studies document the investigation process
- Shows how compiler errors can misdirect debugging efforts
- Documents prevention strategies used in real projects

### When Contributing to Framework
- If you discover a new pattern or issue, add a case study
- Link from EVOLUTION.md under appropriate Discovery entry
- Keep case studies separate from framework docs for clarity

---

## Contributing a New Case Study

### Step 1: Submit Your Discovery

Before creating a case study, submit your discovery using the **Discovery Submission Template**:

**File:** `Sources/Tests/DISCOVERY-SUBMISSION-TEMPLATE.md`

This template ensures your discovery:
- Is systemic (not a one-off edge case)
- Has been properly analyzed (root cause, not symptoms)
- Should be documented (worthy of framework integration)
- Is clear and actionable

**Process:**
1. Fill out DISCOVERY-SUBMISSION-TEMPLATE.md completely
2. Get feedback from framework reviewer
3. Only proceed to case study if verdict is **ACCEPT** or **PARTIAL**

### Step 2: Create the Case Study

Once approved, create the case study:

1. **Name consistently:** `DISCOVERY-N-DESCRIPTIVE-NAME.md`
   - N = the discovery number (next available: check EVOLUTION.md)
   - DESCRIPTIVE-NAME = brief but clear (e.g., `DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md`)

2. **Follow this structure:**
   - Executive summary (what went wrong, how was it fixed)
   - Root cause analysis (why it happened)
   - Investigation process (how you debugged it)
   - Solution (what fixed it)
   - Prevention strategy (how to avoid next time)
   - Framework impact (what this teaches the framework)

3. **Use this template outline:**
   ```markdown
   # DISCOVERY-N: [Title]

   **Date:** [Date]
   **Discovery Context:** [Where/when discovered]
   **Impact Level:** LOW / MEDIUM / HIGH
   **Framework Documents Affected:** [Which docs need updates]

   ## Executive Summary
   [1-2 sentences of what happened and fix]

   ## Root Cause Analysis
   [Deep dive: why the issue occurred]

   ## Investigation Process
   [Your debugging steps]

   ## Solution
   [What fixed it]

   ## Prevention Strategy
   [How to avoid in future]

   ## Framework Impact
   [Updates made to Smith framework]
   ```

### Step 3: Link from EVOLUTION.md

Add entry under "Learned Patterns & Updates" in EVOLUTION.md:

```markdown
### Discovery N: [Title] (Nov X, 2025)

**Problem:** [1-2 sentences]

**Solution:** [What was added to framework]

**Citations:**
- Document updated: lines X–Y
- Case Study: [DISCOVERY-N-*.md]
```

Keep the EVOLUTION.md entry concise; detailed analysis goes in the case study.

### Step 4: Update Framework Documents

If case study reveals a missing pattern or [CRITICAL] issue:

1. Add guidance to appropriate framework doc (AGENTS-AGNOSTIC.md, PLATFORM-*.md, etc.)
2. Include checklist item in AGENTS-SUBMISSION-TEMPLATE.md if needed
3. Add red flags to AGENTS-EVALUATION-CHECKLIST.md
4. Reference the case study as evidence

**Example:** Discovery 5 (access control cascade) updated:
- AGENTS-AGNOSTIC.md lines 443–598 (new "Access Control & Public API Boundaries" section)
- AGENTS-SUBMISSION-TEMPLATE.md lines 181–189 (new checklist item)
- EVOLUTION.md (discovery entry with citations)

---

## Quick Reference

| Case Study | Framework Impact | Relevant File |
|-----------|------------------|----------------|
| RealityKit Popover Entity Infrastructure | PresentationComponent pattern added to visionOS | PLATFORM-VISIONOS.md |

---

## Difference Between Framework Docs and Case Studies

**Framework Docs (in `Sources/`):**
- General patterns applicable across multiple projects
- Universal rules and guidance
- Platform-specific constraints
- Verified best practices

**Case Studies (in `CaseStudies/`):**
- Specific to one project and one issue
- Documents the investigation and debugging process
- Shows systemic issues in how patterns are discovered/communicated
- Lessons learned from real development
- Prevention strategies for recurring issues
