# Agent Routing Logic: Automatic Learning Path Selection

**For AI agents: How to automatically decide what to read based on the task.**

---

## The Problem

Learning paths in `LEARNING-PATHS.md` assume self-assessment:
- "Are you new to Smith?" → Beginner Path
- "Do you need to architect?" → Architect Path

**Agents can't self-assess.** They need task-based routing.

---

## Solution: Task-Based Routing Rules

### Rule 1: Analyze the Task First

Before reading anything, classify the task:

```
Task arrives
   ↓
Extract keywords: [TCA, reducer, test, visionOS, dependency, etc.]
Extract file types: [*.swift, *Tests.swift, *.md]
Extract complexity: [simple fix, new feature, architecture change]
   ↓
Route to appropriate documents
```

---

## Routing Decision Tree

### Step 1: Identify Task Type

```python
task_keywords = extract_keywords(user_request)

if "test" in task_keywords or "Tests.swift" in files:
    task_type = "TESTING"
elif "TCA" in task_keywords or "reducer" in task_keywords or "Feature" in file_names:
    task_type = "TCA"
elif "visionOS" in task_keywords or "RealityView" in task_keywords:
    task_type = "VISIONOS"
elif "dependency" in task_keywords or "@Dependency" in code:
    task_type = "DEPENDENCIES"
elif "access control" in error_message or "public" in task_keywords:
    task_type = "ACCESS_CONTROL"
elif "module" in task_keywords or "package" in task_keywords:
    task_type = "ARCHITECTURE"
elif "bug" in task_keywords or "fix" in task_keywords:
    task_type = "BUG_FIX"
else:
    task_type = "GENERAL"
```

### Step 2: Route to Specific Documents

#### For TESTING Tasks

**Minimum reading (5 min):**
```
1. QUICK-START.md Rule 6-7 (testing patterns)
2. AGENTS-AGNOSTIC.md lines 75-111 (testing + coverage)
```

**If complex (e.g., @Shared testing, async effects):**
```
3. AGENTS-AGNOSTIC.md lines 601-735 (Swift Testing complete)
4. AGENTS-TCA-PATTERNS.md Testing section
```

**Example:**
```
User: "Write tests for the LoginFeature reducer"
Agent reads:
  ✅ QUICK-START.md Rule 6 (3 min)
  ✅ AGENTS-AGNOSTIC.md lines 75-111 (5 min)
  ⏩ Skip: Architecture docs (not relevant)
Total: 8 minutes
```

---

#### For TCA Tasks

**Minimum reading (5 min):**
```
1. QUICK-START.md Rules 2-4 (TCA patterns)
```

**If involves state management:**
```
2. AGENTS-TCA-PATTERNS.md Pattern 1-2 (10 min)
```

**If involves optional state / navigation:**
```
3. AGENTS-TCA-PATTERNS.md Pattern 2-3 (15 min)
```

**If involves @Shared:**
```
4. AGENTS-TCA-PATTERNS.md Pattern 5 (10 min)
5. AGENTS-AGNOSTIC.md lines 45-73 (@Shared guidance)
```

**If error encountered:**
```
6. AGENTS-TCA-PATTERNS.md "Common Mistakes" section (5 min)
```

**Example:**
```
User: "Add a sheet to show user profile"
Agent reads:
  ✅ QUICK-START.md Rule 3 (optional state navigation) (2 min)
  ✅ AGENTS-TCA-PATTERNS.md Pattern 2 (sheet + .scope) (8 min)
  ⏩ Skip: Dependency docs (not needed)
Total: 10 minutes
```

---

#### For visionOS Tasks

**Minimum reading (3 min):**
```
1. QUICK-START.md Rule 9 (entity lifecycle)
```

**If involves PresentationComponent:**
```
2. PLATFORM-VISIONOS.md lines 120-185 (entity creation)
3. DISCOVERY-4 (popover entity gap)
```

**If involves exclusive state:**
```
4. QUICK-START.md Rule 9 (exclusive state)
5. DISCOVERY-8 (exclusive state violations)
```

**Example:**
```
User: "Fix the hint button popover not appearing"
Agent reads:
  ✅ QUICK-START.md Rule 9 (2 min)
  ✅ DISCOVERY-4 (popover entity gap) (5 min)
  ✅ PLATFORM-VISIONOS.md lines 120-185 (8 min)
Total: 15 minutes
```

---

#### For Dependency Tasks

**Minimum reading (3 min):**
```
1. QUICK-START.md Rule 5 (dependency injection)
```

**If creating new dependency:**
```
2. AGENTS-AGNOSTIC.md lines 317-415 (full DI patterns)
```

**If choosing DI pattern:**
```
3. AGENTS-DECISION-TREES.md Tree 2 (@DependencyClient vs singleton)
```

**Example:**
```
User: "Create an API client for fetching user data"
Agent reads:
  ✅ QUICK-START.md Rule 5 (2 min)
  ✅ AGENTS-AGNOSTIC.md lines 317-415 (15 min)
  ✅ AGENTS-DECISION-TREES.md Tree 2 (3 min)
Total: 20 minutes
```

---

#### For Access Control Errors

**Minimum reading (10 min):**
```
1. QUICK-START.md Rule 8 (access control transitive)
2. DISCOVERY-5 (access control cascade failure)
```

**If still confused:**
```
3. AGENTS-AGNOSTIC.md lines 443-598 (complete access control guide)
```

**Example:**
```
User: "Getting 'Binding<ID??>' type mismatch error"
Agent reads:
  ✅ QUICK-START.md Rule 8 (2 min)
  ✅ DISCOVERY-5 (access control cascade) (8 min)
  (Error likely fixed, no need for more reading)
Total: 10 minutes
```

---

#### For Architecture Tasks

**Minimum reading (5 min):**
```
1. AGENTS-DECISION-TREES.md (scan all trees)
```

**If module decision:**
```
2. AGENTS-DECISION-TREES.md Tree 1 (when to create module)
3. AGENTS-DECISION-TREES.md Tree 3 (when to refactor into module)
```

**If scope definition:**
```
4. AGENTS-TASK-SCOPE.md (Safe/Approval/Forbidden zones)
```

**Example:**
```
User: "Should we extract authentication into a separate module?"
Agent reads:
  ✅ AGENTS-DECISION-TREES.md Tree 1 (5 min)
  ✅ AGENTS-DECISION-TREES.md Tree 3 (5 min)
Total: 10 minutes
```

---

#### For Bug Fixes

**Minimum reading (2 min):**
```
1. Search CaseStudies/ for error message or symptom
   grep -r "error keyword" CaseStudies/
```

**If found:**
```
2. Read relevant DISCOVERY (5-10 min)
3. Read referenced pattern doc section (5-10 min)
```

**If not found:**
```
4. QUICK-START.md "Common Mistakes" section (3 min)
5. Run compliance check:
   Scripts/check-compliance.sh .
```

**Example:**
```
User: "Child actions in TCA reducer aren't being received"
Agent searches:
  ✅ grep -r "action.*not.*received" CaseStudies/
  ✅ Found: DISCOVERY-6 (.ifLet closure requirement)
  ✅ Reads DISCOVERY-6 (5 min)
Total: 5 minutes
```

---

#### For General/Unclear Tasks

**Default reading (5 min):**
```
1. QUICK-START.md (entire document)
```

**Then:**
```
2. Ask clarifying questions to user
3. Re-route based on clarification
```

**Example:**
```
User: "Help with the app"
Agent reads:
  ✅ QUICK-START.md (5 min)
  ❓ Asks: "What specifically needs help? (bug fix, new feature, testing, etc.)"
  ↓
User: "New feature for user login"
  ↓
Agent re-routes to TCA path
```

---

## Routing Algorithm (Pseudocode)

```python
def route_agent_reading(task_description, files_involved, error_messages):
    """
    Automatically determine what the agent should read.
    Returns: List of (document, sections, estimated_time_minutes)
    """

    readings = []

    # 1. Always start with Quick Start for the relevant rule
    quick_start_rules = detect_quick_start_rules(task_description, files_involved)
    if quick_start_rules:
        readings.append(("QUICK-START.md", quick_start_rules, 2))

    # 2. Check for bug patterns in case studies
    if is_bug_fix(task_description):
        matching_discoveries = search_case_studies(error_messages, task_description)
        if matching_discoveries:
            readings.extend([(d, "full", 5) for d in matching_discoveries])
            return readings  # Early exit: bug fix with known pattern

    # 3. Task-specific routing
    task_type = classify_task(task_description, files_involved)

    if task_type == "TCA":
        readings.append(("AGENTS-TCA-PATTERNS.md", detect_patterns(task_description), 10))
        if involves_shared_state(task_description):
            readings.append(("AGENTS-AGNOSTIC.md", "lines 45-73", 5))

    elif task_type == "TESTING":
        readings.append(("AGENTS-AGNOSTIC.md", "lines 75-111", 5))
        if is_complex_test(task_description):
            readings.append(("AGENTS-AGNOSTIC.md", "lines 601-735", 20))

    elif task_type == "VISIONOS":
        readings.append(("PLATFORM-VISIONOS.md", detect_sections(task_description), 10))
        if involves_presentation_component(task_description):
            readings.append(("DISCOVERY-4", "full", 5))

    elif task_type == "ACCESS_CONTROL":
        readings.append(("DISCOVERY-5", "full", 8))
        readings.append(("AGENTS-AGNOSTIC.md", "lines 443-598", 15))

    elif task_type == "ARCHITECTURE":
        readings.append(("AGENTS-DECISION-TREES.md", detect_trees(task_description), 10))
        readings.append(("AGENTS-TASK-SCOPE.md", "full", 10))

    # 4. Estimate total time
    total_time = sum(r[2] for r in readings)

    # 5. If over 30 minutes, prioritize
    if total_time > 30:
        readings = prioritize_readings(readings, task_description)

    return readings


def detect_quick_start_rules(task_description, files_involved):
    """Map task to Quick Start rules"""
    rules = []

    if "test" in task_description.lower():
        rules.extend([6, 7])  # Testing rules
    if "tca" in task_description.lower() or "reducer" in task_description.lower():
        rules.extend([2, 3, 4])  # TCA rules
    if "visionos" in task_description.lower() or any("RealityView" in f for f in files_involved):
        rules.append(9)  # visionOS rule
    if "dependency" in task_description.lower():
        rules.append(5)  # Dependency rule
    if "access control" in task_description.lower() or "public" in task_description.lower():
        rules.append(8)  # Access control rule

    return rules


def classify_task(task_description, files_involved):
    """Classify task type from description and files"""
    keywords = task_description.lower()

    # Test detection
    if "test" in keywords or any("Tests.swift" in f for f in files_involved):
        return "TESTING"

    # TCA detection
    if any(k in keywords for k in ["tca", "reducer", "action", "state", "feature"]):
        return "TCA"

    # visionOS detection
    if any(k in keywords for k in ["visionos", "realityview", "entity", "scene"]):
        return "VISIONOS"

    # Access control detection
    if any(k in keywords for k in ["access", "public", "internal", "binding<"]):
        return "ACCESS_CONTROL"

    # Dependency detection
    if any(k in keywords for k in ["dependency", "inject", "@dependency", "client"]):
        return "DEPENDENCIES"

    # Architecture detection
    if any(k in keywords for k in ["module", "package", "architecture", "refactor", "extract"]):
        return "ARCHITECTURE"

    # Bug fix detection
    if any(k in keywords for k in ["bug", "fix", "error", "crash", "doesn't work"]):
        return "BUG_FIX"

    return "GENERAL"
```

---

## Implementation in CLAUDE.md

Add this section to `Sources/CLAUDE.md`:

```markdown
## Automatic Reading Selection

**Don't read everything. Read what's relevant to YOUR task.**

### Step 1: Classify Your Task

Look at the user's request and identify:
- Keywords: "test", "TCA", "visionOS", "dependency", "bug", etc.
- Files involved: *Tests.swift, *Feature.swift, RealityView files
- Error messages: Type mismatches, deprecation warnings, crashes

### Step 2: Route to Relevant Docs

| Task Type | Read This | Time |
|-----------|-----------|------|
| Testing | QUICK-START.md Rules 6-7 + AGENTS-AGNOSTIC.md lines 75-111 | 8 min |
| TCA reducer | QUICK-START.md Rules 2-4 + AGENTS-TCA-PATTERNS.md relevant pattern | 10 min |
| visionOS entities | QUICK-START.md Rule 9 + PLATFORM-VISIONOS.md + DISCOVERY-4 | 15 min |
| Dependencies | QUICK-START.md Rule 5 + AGENTS-DECISION-TREES.md Tree 2 | 10 min |
| Access control | QUICK-START.md Rule 8 + DISCOVERY-5 | 10 min |
| Architecture | AGENTS-DECISION-TREES.md relevant tree | 10 min |
| Bug fix | Search CaseStudies/, then read matching DISCOVERY | 5-10 min |

### Step 3: Start with Minimum, Expand if Needed

Always start with:
1. QUICK-START.md relevant rule (2-3 min)
2. Search CaseStudies/ if it's a bug (1 min)

Only read deeper docs if:
- Quick Start doesn't cover your specific case
- Error persists after applying Quick Start fix
- Task is complex (multiple patterns involved)

### Step 4: Use Compliance Checker

After implementing, run:
```bash
Scripts/check-compliance.sh .
```

If violations found, the checker tells you which QUICK-START.md rule to read.
```

---

## Example Routing in Practice

### Example 1: Simple TCA Task

```
User: "Add a boolean flag 'isLoading' to the LoginFeature state"

Agent reasoning:
  - Keywords: "TCA", "state", "LoginFeature"
  - Classification: TCA (simple)
  - Route: QUICK-START.md Rule 1 (state management)

Agent reads:
  ✅ QUICK-START.md Rule 1 (2 min)
  ✅ Implements: Add `var isLoading = false` to State struct
  ✅ Done

Total time: 2 minutes
```

### Example 2: Complex TCA Task

```
User: "Add a sheet to show user profile when button tapped"

Agent reasoning:
  - Keywords: "sheet", "TCA"
  - Classification: TCA (optional state navigation)
  - Route: QUICK-START.md Rule 3 + AGENTS-TCA-PATTERNS.md Pattern 2

Agent reads:
  ✅ QUICK-START.md Rule 3 (3 min)
  ✅ AGENTS-TCA-PATTERNS.md Pattern 2 (full example) (8 min)
  ✅ Implements: Optional state + .sheet(item:) + .scope()
  ✅ Runs: Scripts/check-compliance.sh .
  ✅ Done

Total time: 11 minutes
```

### Example 3: Bug Fix

```
User: "Child actions in my TCA reducer aren't being received"

Agent reasoning:
  - Keywords: "actions", "not received", "reducer"
  - Classification: BUG_FIX
  - Search: grep -r "action.*not.*received" CaseStudies/

Agent actions:
  ✅ Search finds: DISCOVERY-6 (.ifLet closure requirement)
  ✅ Reads DISCOVERY-6 (5 min)
  ✅ Identifies issue: Missing closure in .ifLet
  ✅ Fixes: Adds { ChildFeature() } closure
  ✅ Done

Total time: 5 minutes
```

### Example 4: Architecture Decision

```
User: "Should we extract authentication into a separate Swift Package?"

Agent reasoning:
  - Keywords: "extract", "package"
  - Classification: ARCHITECTURE
  - Route: AGENTS-DECISION-TREES.md Tree 1 + Tree 3

Agent reads:
  ✅ AGENTS-DECISION-TREES.md Tree 1 (5 min)
  ✅ Evaluates criteria: 15 actions, 3 files, used in 1 project
  ✅ Decision: NO (threshold is 20+ actions OR 3+ projects)
  ✅ Responds to user with reasoning

Total time: 5 minutes
```

---

## Agent Self-Check

Before starting any task, agent should ask:

1. **What type of task is this?**
   - Testing / TCA / visionOS / Dependencies / Access Control / Architecture / Bug Fix / General

2. **What's the minimum I need to read?**
   - Always: QUICK-START.md relevant rule (2-3 min)
   - Bug? Search CaseStudies/ first (1 min)

3. **Is this complex?**
   - Complex = Multiple patterns, unfamiliar territory, involves @Shared, or multi-step
   - If complex: Read full pattern doc (10-20 min)
   - If simple: Just Quick Start (2-3 min)

4. **Can I verify compliance?**
   - Run `Scripts/check-compliance.sh .` after implementing
   - If violations: Read the rule it points to

---

## Summary: Reading Time Budget

| Task Complexity | Reading Time | Success Rate |
|-----------------|--------------|--------------|
| Simple (flag, property) | 2-3 min | 95% |
| Moderate (sheet, dependency) | 10-15 min | 90% |
| Complex (@Shared, architecture) | 20-30 min | 85% |
| Bug (with DISCOVERY) | 5-10 min | 90% |
| Bug (no DISCOVERY) | 15-20 min | 75% |

**Target: 80%+ of tasks should be < 15 minutes of reading.**

---

**Last Updated:** November 10, 2025
**Version:** 1.0
**Related:** LEARNING-PATHS.md, QUICK-START.md, Sources/CLAUDE.md
