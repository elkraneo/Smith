# How to Update Smith Framework with New Requirements & Learnings

This guide explains the best practices for introducing new patterns, constraints, and learnings into the Smith framework.

---

## When to Update Smith

Update Smith when you discover:

1. **New Platform Constraints** - visionOS, macOS, iOS, iPadOS specific requirements
2. **New Code Patterns** - Architectural improvements, TCA patterns, concurrency approaches
3. **New Tool Optimizations** - Faster/better MCP tools or CLI commands
4. **Agent Inefficiencies** - Repeated violations or ineffective approaches
5. **Code Review Patterns** - Consistent rejections or rework requirements

---

## Before You Update: Decision Tree

```
Does the change affect...?

├─ All Apple platforms (Swift, TCA, concurrency)
│  └─ Update: AGENTS-AGNOSTIC.md
│
├─ One platform (macOS, iOS, iPadOS, visionOS)
│  └─ Update: PLATFORM-[NAME].md
│
├─ How agents make decisions
│  └─ Update: AGENTS-DECISION-TREES.md (or add new tree)
│
├─ What agents can/cannot edit
│  └─ Update: AGENTS-TASK-SCOPE.md
│
├─ Tool usage or optimization
│  └─ Update: AGENTS-AGNOSTIC.md (Tool Usage section)
│
├─ Agent submission verification
│  └─ Update: AGENTS-SUBMISSION-TEMPLATE.md
│
└─ How to review agent work
   └─ Update: AGENTS-EVALUATION-CHECKLIST.md
```

---

## Step-by-Step Update Process

### Step 1: Document the Discovery

Create a task/issue with:

```markdown
## Discovery: [Title]

### Evidence
- Where did you encounter this?
- What code/pattern triggered this?
- Is this a one-off or a common pattern?

### Impact
- How many projects affected?
- How many agents need to know this?
- Is this [CRITICAL], [STANDARD], or [GUIDANCE]?

### Document to Update
- [ ] AGENTS-AGNOSTIC.md
- [ ] PLATFORM-[NAME].md
- [ ] AGENTS-DECISION-TREES.md
- [ ] AGENTS-TASK-SCOPE.md
- [ ] Other: ___

### Related Tasks
- Links to code reviews, issues, discussions
```

### Step 2: Write the Guidance

For **AGENTS-AGNOSTIC.md** or **PLATFORM-*.md**, use this template:

```markdown
### [New Topic/Pattern Name]

**[Enforcement Level] [Rule Statement]** - Brief explanation

- **Why:** Rationale, language/framework requirement, or principle
- **When:** When does this rule apply?
- **Not:** What NOT to do (anti-pattern)
- **Example:**
  ```swift
  // ✅ CORRECT
  @ObservableState
  struct State { }

  // ❌ WRONG
  class State: ObservableObject { }
  ```
- **Reference:** Links to Swift evolution, TCA docs, Apple HIG, etc.
```

**Example:**
```markdown
### Use @Observable for State

**[CRITICAL] Use `@Observable`** for mutable state instead of `class` with `@Published`.

- **Why:** Swift 6.2 strict concurrency requires `Sendable` compliance.
  Classes are harder to make `Sendable`; `@Observable` works with modern TCA.
- **When:** Any mutable state that updates SwiftUI
- **Not:** Never use `class StateHolder: ObservableObject`
- **Example:**
  ```swift
  @ObservableState
  struct MyState {
    var count = 0
  }
  ```
- **Reference:** Swift SE-0418, TCA 1.23.0 migration guide, WWDC24 session 412
```

### Step 3: Update Submission Template

If agents need to verify this, add a checklist:

**In AGENTS-SUBMISSION-TEMPLATE.md**, find the relevant section (Dependency Injection, State Management, Testing, Tool Usage, Platform-Specific, Code Style):

```markdown
### [New Category or Existing Category]
- [ ] [Specific checklist item about new rule]
- [ ] [Related item]
- [ ] [Anti-pattern to avoid]

**Citation:** AGENTS-AGNOSTIC.md, lines X–Y ([Section Name])
```

**Example:**
```markdown
### State Management
- [ ] State uses `@ObservableState` (not `@Published` or `class`)
- [ ] Reducers use `@Reducer` macro
- [ ] Views use `@Bindable var store` (not `@Perception.Bindable`)

**Citation:** AGENTS-AGNOSTIC.md, lines 24–50 (State Management section)
```

### Step 4: Update Evaluation Checklist

In **AGENTS-EVALUATION-CHECKLIST.md**, add to appropriate section:

```markdown
### Code Pattern Review
- [ ] [New pattern check - what to look for]
  - ❌ Red flag: [anti-pattern example]
  - ✅ Green flag: [correct pattern example]
```

**Example:**
```markdown
### Code Pattern Review
- [ ] No `@Published` or `class` for state
  - ❌ Red flag: `class State: ObservableObject { @Published var count }`
  - ✅ Green flag: `@ObservableState struct State { var count: Int }`
```

### Step 5: Link from Master Index

If adding a NEW section (not updating existing), update **AGENTS-FRAMEWORK.md**:

```markdown
## New Section
- **[AGENTS-AGNOSTIC.md lines X–Y]** - Description of new guidance
```

### Step 6: Update Evolution Log

Add to **EVOLUTION.md** under "Learned Patterns & Updates":

```markdown
### Discovery N: [Pattern Name] (Nov X, 2025)

**Problem:** [What issue did you encounter?]

**Solution:**
- Added "[Topic]" section to [DOCUMENT].md (lines X–Y)
- Updated submission template with [N] checklist items
- Updated evaluation checklist to catch [violation type]

**Example:** [Code example showing the pattern]

**Result:** [How is this better now? Who benefits?]

**Citations:**
- AGENTS-AGNOSTIC.md lines X–Y
- AGENTS-SUBMISSION-TEMPLATE.md lines X–Y
- AGENTS-EVALUATION-CHECKLIST.md section [Name]
```

### Step 7: Deploy Updates

Copy updated files to all project copies:

```bash
# Copy to all projects that have Smith
cp /Users/elkraneo/Desktop/Smith/Sources/AGENTS-AGNOSTIC.md \
   /Volumes/Plutonian/_Developer/Scroll/source/Scroll/Smith/

cp /Users/elkraneo/Desktop/Smith/Sources/AGENTS-AGNOSTIC.md \
   /Volumes/Plutonian/GreenSpurt/Smith/

# And for submission template if updated
cp /Users/elkraneo/Desktop/Smith/Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md \
   /Volumes/Plutonian/_Developer/Scroll/source/Scroll/Smith/Tests/

cp /Users/elkraneo/Desktop/Smith/Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md \
   /Volumes/Plutonian/GreenSpurt/Smith/Tests/
```

### Step 8: Test with Next Agent Submission

First agent to submit after update will:
- See new rule in submission template checklist
- Self-verify their code follows new pattern
- You evaluate using updated evaluation checklist
- If violation: cite the new section in feedback

---

## Examples of Common Updates

### Example 1: New Platform Constraint

**Scenario:** You discover visionOS requires `RealityView` with specific attachment patterns.

**Process:**
1. Document in PLATFORM-VISIONOS.md, mark as [CRITICAL]
2. Add to AGENTS-SUBMISSION-TEMPLATE.md:
   ```markdown
   ### Platform-Specific (if visionOS)
   - [ ] RealityView used (never ARView)
   - [ ] ViewAttachmentComponent pattern correct
   - [ ] @MainActor on RealityKit mutations
   ```
3. Add to AGENTS-EVALUATION-CHECKLIST.md:
   ```markdown
   ### visionOS Red Flags
   - [ ] Uses ARView ❌
   - [ ] ViewAttachment not properly injected ❌
   - [ ] No @MainActor on RealityKit ❌
   ```
4. Update EVOLUTION.md
5. Deploy to all project Smith copies

### Example 2: Agent Inefficiency

**Scenario:** Agents repeatedly running `curl` loops to developer.apple.com instead of SosumiDocs.

**Process:**
1. Add [STANDARD] rule to AGENTS-AGNOSTIC.md (Tool Usage section):
   ```markdown
   - **[STANDARD] Use SosumiDocs MCP for Apple documentation**
     - Not: `curl` to developer.apple.com (slow, rate-limited)
   ```
2. Add to AGENTS-SUBMISSION-TEMPLATE.md:
   ```markdown
   ### Tool Usage - Documentation
   - [ ] Used SosumiDocs MCP for Apple docs
   - [ ] No repeated curl calls to developer.apple.com
   ```
3. Add to AGENTS-EVALUATION-CHECKLIST.md:
   ```markdown
   ❌ Red flag: `curl` called multiple times to same Apple docs URL
   → Point agent to AGENTS-AGNOSTIC.md Tool Usage section
   ```
4. Next agent submission: Sees checklist, avoids inefficiency
5. Update EVOLUTION.md with discovery date and result

### Example 3: New Decision Tree

**Scenario:** You notice unclear decisions about "when to use async/await vs completion handlers"

**Process:**
1. Create new Tree 5 in AGENTS-DECISION-TREES.md:
   ```markdown
   ## Tree 5: Async/Await vs Completion Handlers

   Does the operation need cancellation?
   ├─ Yes → Use async/await (modern)
   └─ No → Still use async/await (always preferred)
   ```
2. Reference in AGENTS-FRAMEWORK.md
3. Add to AGENTS-SUBMISSION-TEMPLATE.md:
   ```markdown
   - [ ] Async functions use async/await (not completion handlers)
     Reference: AGENTS-DECISION-TREES.md Tree 5
   ```
4. Update EVOLUTION.md

---

## Rules for Updates

### DO:
- ✅ Cite line numbers in AGENTS-AGNOSTIC.md
- ✅ Explain the "why" not just "what"
- ✅ Include code examples (✅ correct, ❌ wrong)
- ✅ Mark enforcement level ([CRITICAL]/[STANDARD]/[GUIDANCE])
- ✅ Add to submission template checklist
- ✅ Add to evaluation checklist
- ✅ Update EVOLUTION.md
- ✅ Deploy to all project copies

### DON'T:
- ❌ Create rules without explanation
- ❌ Mark everything [CRITICAL] (lose clarity)
- ❌ Update framework without updating templates
- ❌ Forget to update EVOLUTION.md (breaks history)
- ❌ Deploy to canonical only (projects get out of sync)
- ❌ Leave old patterns uncommented (confusing)

---

## Review Checklist Before Publishing

Before you consider the update complete:

- [ ] Rule is written in AGENTS-AGNOSTIC.md or PLATFORM-*.md with:
  - [ ] Enforcement level ([CRITICAL]/[STANDARD]/[GUIDANCE])
  - [ ] Clear "why" statement
  - [ ] Specific line numbers cited
  - [ ] Code example (✅ and ❌)

- [ ] AGENTS-SUBMISSION-TEMPLATE.md updated with:
  - [ ] New checklist item for agents
  - [ ] Citation to framework section

- [ ] AGENTS-EVALUATION-CHECKLIST.md updated with:
  - [ ] Red flag to catch violation
  - [ ] Green flag showing correct pattern

- [ ] AGENTS-FRAMEWORK.md updated (if new major section)

- [ ] EVOLUTION.md updated with:
  - [ ] Date
  - [ ] Problem → Solution → Result
  - [ ] Citations to updated sections

- [ ] Deployed to all project copies:
  - [ ] `/Volumes/Plutonian/_Developer/Scroll/source/Scroll/Smith/`
  - [ ] `/Volumes/Plutonian/GreenSpurt/Smith/`
  - [ ] Canonical: `/Users/elkraneo/Desktop/Smith/Sources/`

- [ ] Team/agents notified of update

---

## Version Bumping

**When to bump version** in EVOLUTION.md:

- **Patch (v1.0 → v1.0.1):** Small clarifications, typo fixes, line number corrections
- **Minor (v1.0 → v1.1):** New sections, new decision trees, new tool optimizations
- **Major (v1.0 → v2.0):** Framework restructure, significant methodology change, incompatible updates

---

## Quick Reference: What Goes Where

| Type of Change | Document to Update | Also Update |
|---|---|---|
| New pattern (macOS, iOS, etc.) | PLATFORM-[NAME].md | Template, Checklist, EVOLUTION |
| New universal pattern | AGENTS-AGNOSTIC.md | Template, Checklist, EVOLUTION |
| New architectural decision | AGENTS-DECISION-TREES.md | AGENTS-FRAMEWORK.md, EVOLUTION |
| New scope boundary rule | AGENTS-TASK-SCOPE.md | Template, EVOLUTION |
| Agent inefficiency | AGENTS-AGNOSTIC.md (Tool Usage) | Template, Checklist, EVOLUTION |
| Documentation clarification | Relevant document | (only if significant) |

---

## Support & Questions

When documenting new patterns, ask yourself:

1. **Is this [CRITICAL], [STANDARD], or [GUIDANCE]?**
   - Can't compile without it? → [CRITICAL]
   - Should always do this? → [STANDARD]
   - Consider doing this? → [GUIDANCE]

2. **Who needs to know this?**
   - Agents? → Add to submission template
   - Reviewers? → Add to evaluation checklist
   - Everyone? → Add to AGENTS-FRAMEWORK.md

3. **What's the simplest explanation?**
   - Avoid jargon
   - Link to references (Swift evolution, TCA docs, Apple HIG)
   - Provide code examples

4. **How do I prevent this mistake in the future?**
   - Add to checklist for agents
   - Add to red flags for reviewers
   - Track in EVOLUTION.md for pattern recognition

---

## Last Updated
November 1, 2025 - Initial v1.0 framework completion
