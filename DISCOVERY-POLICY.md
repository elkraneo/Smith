# Discovery Policy: When & How to Document Patterns

**Not every bug deserves a DISCOVERY. This document defines thresholds, severity levels, and consolidation guidelines.**

---

## The Problem

With 11 DISCOVERY documents already, we risk:
- **Discovery inflation** - Documenting minor bugs as discoveries
- **Documentation bloat** - Too many files to navigate
- **Pattern dilution** - Important discoveries buried in noise
- **Maintenance burden** - Keeping outdated discoveries updated

---

## Discovery Severity Levels

### Level 1: CRITICAL DISCOVERY (Document Immediately)

**Criteria - Must meet ALL:**
1. ✅ Affects **2+ projects** or likely to affect future projects
2. ✅ Causes **complete feature failure** (not just degraded behavior)
3. ✅ **Non-obvious root cause** (takes >1 hour to diagnose)
4. ✅ Requires **new pattern** not currently documented in Smith
5. ✅ Has **systemic impact** (affects architecture, not just one function)

**Examples:**
- DISCOVERY-4: Popover entity creation gap (affects all visionOS PresentationComponent usage)
- DISCOVERY-5: Access control cascade (compiler masks real error, affects all public API boundaries)
- DISCOVERY-6: .ifLet closure requirement (silent action routing failure across all TCA nested reducers)

**Action:** Create full DISCOVERY-N document immediately

**Template:** `CaseStudies/DISCOVERY-SUBMISSION-TEMPLATE.md`

---

### Level 2: STANDARD DISCOVERY (Document if Recurring)

**Criteria - Must meet 3 of 5:**
1. ⚠️ Affects **1 project** but pattern is reusable
2. ⚠️ Causes **degraded behavior** (feature works but incorrectly)
3. ⚠️ **Moderately obvious** root cause (takes 30-60 min to diagnose)
4. ⚠️ Refines **existing pattern** in Smith (not entirely new)
5. ⚠️ Has **localized impact** (specific to one feature type)

**Examples:**
- DISCOVERY-7: Opening credits timing (>= 2 vs >= 3) - localized to one feature
- DISCOVERY-8: Exclusive state violations - refinement of existing state management pattern

**Action:**
- **First occurrence:** Add to EVOLUTION.md as "Learned Pattern"
- **Second occurrence:** Promote to full DISCOVERY document
- **If no recurrence in 3 months:** Keep in EVOLUTION.md only

---

### Level 3: MINOR ISSUE (Don't Document as DISCOVERY)

**Criteria - Any of:**
1. 🔵 Affects **single file** or **single function**
2. 🔵 **Obvious root cause** (syntax error, typo, wrong variable)
3. 🔵 **Already covered** by existing Smith patterns
4. 🔵 **No reusable pattern** emerges
5. 🔵 **One-time mistake** unlikely to recur

**Examples:**
- Typo in variable name
- Forgot to call a method
- Wrong parameter passed to function
- Missing import statement
- Copy-paste error

**Action:**
- ✅ Fix the bug
- ✅ Add regression test
- ✅ Brief note in commit message
- ❌ Do NOT create DISCOVERY document
- ❌ Do NOT add to EVOLUTION.md

---

## Decision Tree: Should This Be a DISCOVERY?

```
Bug found and fixed
   ├─ Does it affect 2+ projects or likely to? ──→ NO ──┐
   │                                                     │
   └─ YES                                                │
      ├─ Is the root cause non-obvious (>1hr)?          │
      │  ├─ YES                                          │
      │  │  ├─ Does it require new Smith pattern?       │
      │  │  │  ├─ YES → [CRITICAL] Full DISCOVERY       │
      │  │  │  └─ NO → [STANDARD] Add to EVOLUTION.md   │
      │  │  │                                            │
      │  └─ NO → [MINOR] Just fix + test                │
      │                                                  │
      └─ [STANDARD] Add to EVOLUTION.md ←───────────────┘
         Watch for recurrence
```

---

## Consolidation Policy

### When to Consolidate Discoveries

**Trigger Conditions:**
1. **Related discoveries:** 3+ discoveries covering similar patterns
2. **Age:** Discoveries older than 6 months with <3 references
3. **Obsolescence:** Pattern deprecated or superseded by framework changes
4. **Redundancy:** Discovery duplicates content in main docs

### Consolidation Process

#### Step 1: Identify Candidates

Look for:
```bash
# Find old discoveries
find CaseStudies/ -name "DISCOVERY-*.md" -mtime +180

# Check reference count
grep -r "DISCOVERY-7" Sources/ CaseStudies/ | wc -l
```

**Consolidate if:**
- Older than 6 months AND referenced <3 times
- Related to 2+ other discoveries (merge possible)
- Pattern now in AGENTS-AGNOSTIC.md or AGENTS-TCA-PATTERNS.md

#### Step 2: Archive or Merge

**Option A: Archive (if obsolete)**
```bash
mkdir -p CaseStudies/Archive/
mv CaseStudies/DISCOVERY-7-*.md CaseStudies/Archive/

# Add to Archive/README.md:
# - Discovery number and title
# - Archived date
# - Reason (obsolete/superseded/merged)
# - Superseded by (if applicable)
```

**Option B: Merge (if related)**
```bash
# Example: Merge DISCOVERY-6, 7, 8 into one
# Create: DISCOVERY-6-8-INTRO-LEVEL-BUGS.md
# Delete: Individual DISCOVERY-7, DISCOVERY-8
# Update: All references to point to merged doc
```

#### Step 3: Update References

```bash
# Find all references
grep -r "DISCOVERY-7" Sources/ CaseStudies/ README.md

# Update to point to:
# - Merged document, OR
# - Archive location, OR
# - Main pattern doc (if pattern moved to AGENTS-AGNOSTIC.md)
```

#### Step 4: Document in EVOLUTION.md

```markdown
### Consolidation: DISCOVERY-7, 8 → DISCOVERY-6-8-INTRO-LEVEL-BUGS (Date)

**Reason:** Related bugs in intro level implementation
**Action:** Merged 3 discoveries into one comprehensive guide
**Impact:** Easier to find all intro-level patterns in one place
**References Updated:** 14 locations
```

---

## Discovery Lifecycle

```
Bug Found
   ↓
Severity Assessment (use decision tree)
   ↓
┌──────────────┬──────────────────┬──────────────┐
│ CRITICAL     │ STANDARD         │ MINOR        │
├──────────────┼──────────────────┼──────────────┤
│ Full DISCOVERY│ EVOLUTION.md    │ Just fix it  │
│ document     │ note            │ + test       │
└──────────────┴──────────────────┴──────────────┘
   ↓              ↓
   │              Watch for recurrence (3 months)
   │              ↓
   │          Recurs? → Promote to full DISCOVERY
   │              ↓
   │          No recurrence → Keep in EVOLUTION.md
   │
   ↓
After 6 months:
   ├─ Referenced <3 times → Archive
   ├─ Related to 2+ others → Merge
   ├─ Pattern in main docs → Archive (link to main doc)
   └─ Still relevant → Keep
```

---

## Current Discovery Audit (As of November 10, 2025)

| # | Title | Date | Refs | Status | Action |
|---|-------|------|------|--------|--------|
| 4 | Popover Entity Gap | Nov 1 | 5 | Active | Keep (visionOS critical pattern) |
| 5 | Access Control Cascade | Nov 4 | 8 | Active | Keep (affects all public APIs) |
| 6 | .ifLet Closure | Nov 5 | 12 | Active | Keep (TCA critical pattern) |
| 7 | Opening Credits Fix | Nov 5 | 2 | Review | Merge candidate (related to #8) |
| 8 | Exclusive State Intro | Nov 5 | 4 | Active | Keep (state management pattern) |
| 9 | Test Strategy | Nov 6 | 3 | Active | Keep (testing guide) |
| 10 | Smith Testing Compliance | Nov 6 | 6 | Active | Keep (compliance reference) |
| 11 | MPA Onboarding Display | Nov 6 | 1 | Review | Watch for recurrence |

**Consolidation Candidates:**
- **DISCOVERY-7 + DISCOVERY-8** - Both involve intro level bugs, could merge into "Intro Level Patterns"
- **DISCOVERY-9 + DISCOVERY-10** - Both testing-related, could merge into "Smith Testing Guide"

**Action Plan:**
- Review in 3 months (Feb 2026)
- If DISCOVERY-11 not referenced again, archive
- Consider merging 7+8 and 9+10 in v1.2.0

---

## Anti-Patterns to Avoid

### ❌ Don't Document These as DISCOVERIES:

1. **One-off bugs** with no reusable pattern
   ```
   Bad: "DISCOVERY-12: Forgot to set button.isEnabled = true"
   Good: Just fix it
   ```

2. **Already documented patterns** in main docs
   ```
   Bad: "DISCOVERY-13: Need to use @MainActor on TCA tests"
   Good: Already in AGENTS-AGNOSTIC.md lines 601-735
   ```

3. **Project-specific quirks** not applicable elsewhere
   ```
   Bad: "DISCOVERY-14: Our custom API client needs timeout"
   Good: Document in project docs, not Smith
   ```

4. **Obvious mistakes** anyone would catch in review
   ```
   Bad: "DISCOVERY-15: Typo in function name"
   Good: Fix and move on
   ```

5. **External library bugs** out of your control
   ```
   Bad: "DISCOVERY-16: RealityKit crashes on Scene.anchor"
   Good: Report to Apple, work around, document in PLATFORM-VISIONOS.md
   ```

---

## Quality Standards for DISCOVERY Documents

Every DISCOVERY must have:

### Required Sections

1. **Problem Statement** (2-3 sentences)
   - What was broken?
   - What was the symptom?
   - Why was it hard to diagnose?

2. **Root Cause Analysis** (1-2 paragraphs)
   - What was the actual problem?
   - Why did it happen?
   - What was misleading about the error?

3. **Solution** (code examples + explanation)
   - What pattern fixes it?
   - Why does this work?
   - What are the tradeoffs?

4. **Smith Pattern Added** (where in framework)
   - Which document updated? (AGENTS-AGNOSTIC.md, PLATFORM-VISIONOS.md, etc.)
   - What line numbers?
   - What enforcement level? ([CRITICAL], [STANDARD], [GUIDANCE])

5. **Prevention** (how to avoid in future)
   - What checklist item added?
   - What compliance check added?
   - What test pattern added?

6. **Impact Assessment**
   - How many projects affected?
   - What features broken?
   - Time to diagnose + fix?

7. **References**
   - Point-Free blog posts
   - Apple documentation
   - Related discoveries
   - GitHub issues

### Quality Checklist

- [ ] Title is descriptive (not just "Bug Fix #7")
- [ ] Problem is non-obvious (not a simple typo)
- [ ] Pattern is reusable (not project-specific)
- [ ] Root cause explained (not just symptom)
- [ ] Solution is actionable (with code examples)
- [ ] Smith docs updated (with line numbers)
- [ ] Compliance check added (if applicable)
- [ ] Test pattern added (prevents regression)
- [ ] References cited (sources linked)

---

## Naming Conventions

### Discovery Numbering

- **Sequential:** DISCOVERY-4, DISCOVERY-5, DISCOVERY-6, ...
- **Never reuse numbers** (even if archived)
- **Gaps okay** (if some merged/archived)

### Discovery Titles

**Format:** `DISCOVERY-N-BRIEF-DESCRIPTION.md`

**Good titles:**
- `DISCOVERY-4-POPOVER-ENTITY-GAP.md` (clear, specific)
- `DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md` (describes problem)
- `DISCOVERY-6-IFLET-CLOSURE-REQUIREMENT.md` (pattern name)

**Bad titles:**
- `DISCOVERY-7-BUG-FIX.md` (too vague)
- `DISCOVERY-8-NOVEMBER-5-ISSUE.md` (date not helpful)
- `DISCOVERY-9-THING-DOESNT-WORK.md` (not descriptive)

### Merged Discovery Titles

**Format:** `DISCOVERY-N-M-COMBINED-TOPIC.md`

**Examples:**
- `DISCOVERY-6-8-INTRO-LEVEL-PATTERNS.md` (merged 6, 7, 8)
- `DISCOVERY-9-10-SMITH-TESTING-GUIDE.md` (merged 9, 10)

---

## Review Schedule

### Quarterly Discovery Audit

**When:** Last week of each quarter (Mar, Jun, Sep, Dec)

**Process:**
1. List all discoveries
2. Count references: `grep -r "DISCOVERY-N" Sources/ CaseStudies/ | wc -l`
3. Check age: `ls -l CaseStudies/DISCOVERY-*.md`
4. Identify consolidation candidates
5. Archive/merge as needed
6. Update EVOLUTION.md

**Report Template:**
```markdown
## Q4 2025 Discovery Audit

**Date:** December 31, 2025
**Total Discoveries:** 13
**Active:** 10
**Archived:** 2
**Merged:** 1 (7+8 → 6-8)

**Actions Taken:**
- Archived DISCOVERY-11 (not referenced in 3 months)
- Merged DISCOVERY-7, 8 → DISCOVERY-6-8-INTRO-LEVEL-PATTERNS
- Updated 14 references

**Next Review:** March 31, 2026
```

---

## Summary: The Rules

1. **Not every bug is a DISCOVERY** - Use severity levels
2. **Quality over quantity** - Better to have 10 great discoveries than 50 mediocre ones
3. **Consolidate aggressively** - Merge related discoveries after 6 months
4. **Archive obsolete discoveries** - Don't delete, but move to Archive/
5. **Update main docs** - Patterns should eventually live in AGENTS-AGNOSTIC.md, not just DISCOVERY docs
6. **Quarterly reviews** - Keep discovery list lean and relevant

---

**Last Updated:** November 10, 2025
**Next Review:** February 10, 2026 (3 months)
**Policy Version:** 1.0
