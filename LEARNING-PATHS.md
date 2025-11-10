# Smith Learning Paths: Beginner → Expert

**Choose your path based on your role, experience level, and immediate needs.**

---

## Quick Path Selection

| Situation | Start Here | Time |
|-----------|------------|------|
| 🆕 New to Smith | Beginner Path | 15 min |
| 🤖 AI Agent starting task | Quick Start Path | 5 min |
| 👨‍💻 Human developer new to project | Developer Path | 30 min |
| 🏗️ Architect/lead | Architect Path | 60 min |
| 🔧 Fixing specific bug | Problem-Solving Path | Variable |
| 📚 Comprehensive understanding | Expert Path | 4 hours |

---

## Path 1: Beginner (15 minutes)

**Goal:** Get coding quickly with minimal reading.

### Steps

1. **Read QUICK-START.md** (5 min)
   - The 10 critical rules
   - The 5 most common mistakes
   - Quick reference decision trees

2. **Skim your platform guide** (5 min)
   - macOS: PLATFORM-MACOS.md
   - iOS: PLATFORM-IOS.md
   - iPadOS: PLATFORM-IPADOS.md
   - visionOS: PLATFORM-VISIONOS.md

3. **Bookmark for later** (1 min)
   - AGENTS-TCA-PATTERNS.md (for TCA deep dives)
   - AGENTS-AGNOSTIC.md (for universal patterns)
   - CaseStudies/ (for bug examples)

4. **Start coding** (4 min)
   - Reference QUICK-START.md when stuck
   - Use compliance checker: `Scripts/check-compliance.sh .`

### What You'll Know

- ✅ Core patterns (modern TCA, dependencies, testing)
- ✅ Common mistakes to avoid
- ✅ Where to find answers when stuck
- ❌ Architectural decisions (not covered yet)
- ❌ Deep TCA patterns (not covered yet)

### When to Level Up

Move to **Developer Path** when:
- You've written 3-5 features using QUICK-START.md
- You hit a pattern not covered in Quick Start
- You're ready for architectural decisions

---

## Path 2: Quick Start (AI Agents - 5 minutes)

**Goal:** Execute task with minimum context, maximum correctness.

### Steps

1. **Read QUICK-START.md** (3 min)
   - Focus on the 10 Critical Rules
   - Skim the 5 Most Common Mistakes

2. **Scan task-specific pattern** (1 min)
   - TCA reducer: QUICK-START.md Rules 2-4
   - Testing: QUICK-START.md Rule 6-7
   - Dependencies: QUICK-START.md Rule 5
   - visionOS entities: QUICK-START.md Rule 9

3. **Start coding with checklist** (1 min)
   - Use TodoWrite to track sub-tasks
   - Reference QUICK-START.md during implementation
   - Run compliance check before submitting

### Deep Dive When Needed

If you hit complexity, read:
- **TCA issues:** AGENTS-TCA-PATTERNS.md (15 min)
- **Access control errors:** AGENTS-AGNOSTIC.md lines 443-598 (10 min)
- **Concurrency bugs:** AGENTS-AGNOSTIC.md lines 162-313 (15 min)
- **visionOS entity issues:** PLATFORM-VISIONOS.md + DISCOVERY-4 (10 min)

### Submission Checklist

Before marking task complete:
- [ ] Read relevant QUICK-START.md rules
- [ ] Ran `Scripts/check-compliance.sh .`
- [ ] No CRITICAL violations
- [ ] Warnings addressed or documented
- [ ] Tests added (if applicable)

---

## Path 3: Developer (30 minutes)

**Goal:** Understand patterns deeply enough to work independently.

### Steps

1. **Read QUICK-START.md** (5 min)
   - All 10 rules
   - All 5 common mistakes
   - Decision trees

2. **Read AGENTS-AGNOSTIC.md sections** (15 min)
   - Lines 24-79 (State Management, Testing, Tool Usage)
   - Lines 162-313 (Concurrency Patterns)
   - Lines 443-598 (Access Control)
   - Lines 601-735 (Swift Testing Framework)

3. **Read AGENTS-TCA-PATTERNS.md** (10 min)
   - Patterns 1-4 (skip Pattern 5 if not using @Shared)
   - Common Mistakes section
   - Testing section

4. **Skim CaseStudies/** (5 min)
   - DISCOVERY-4 (visionOS)
   - DISCOVERY-5 (Access control)
   - DISCOVERY-6 (.ifLet closure)

### What You'll Know

- ✅ Modern TCA patterns (all 5)
- ✅ Concurrency patterns (all 4)
- ✅ Testing requirements and patterns
- ✅ Access control transitive requirements
- ✅ Tool usage optimization
- ❌ Architectural decisions (when to create modules, etc.)
- ❌ Platform-specific edge cases (unless you read platform guide)

### When to Level Up

Move to **Architect Path** when:
- You're making architectural decisions
- You're creating new modules/packages
- You're establishing team conventions

---

## Path 4: Architect (60 minutes)

**Goal:** Make sound architectural decisions and guide team.

### Steps

1. **Complete Developer Path** (30 min)

2. **Read AGENTS-DECISION-TREES.md** (15 min)
   - Tree 1: When to create a Swift Package module
   - Tree 2: @DependencyClient vs singleton
   - Tree 3: When to refactor into a module
   - Tree 4: Where logic should live (Core/UI/Platform)

3. **Read AGENTS-TASK-SCOPE.md** (10 min)
   - Safe/Approval/Forbidden zones
   - How to define scope for tasks
   - Preventing scope creep

4. **Read DISCOVERY-POLICY.md** (10 min)
   - Severity levels
   - When to document discoveries
   - Consolidation guidelines

5. **Skim VERSIONING.md** (5 min)
   - Semantic versioning strategy
   - Breaking change policy
   - Migration planning

### What You'll Know

- ✅ When to extract modules
- ✅ Where business logic belongs
- ✅ How to scope tasks for agents/team
- ✅ When patterns become discoveries
- ✅ Framework versioning and migration
- ❌ All platform-specific nuances (read platform guides as needed)

### When to Level Up

Move to **Expert Path** when:
- You're maintaining Smith framework itself
- You're evaluating agent/developer work
- You're documenting new patterns

---

## Path 5: Problem-Solving (Variable time)

**Goal:** Fix a specific bug or issue quickly.

### Diagnostic Steps

1. **Identify the symptom** (1 min)
   - Compilation error
   - Runtime crash
   - Wrong behavior
   - Performance issue

2. **Search case studies** (2 min)
   ```bash
   grep -r "your error message" CaseStudies/
   grep -r "symptom keyword" CaseStudies/
   ```

3. **Common issue? Check Quick Start** (3 min)
   - Read relevant rule from QUICK-START.md
   - Check "Common Mistakes" section

4. **Still stuck? Use diagnostic table below**

### Diagnostic Table

| Symptom | Read This | Est. Time |
|---------|-----------|-----------|
| Type mismatch with `Binding<T??>` | AGENTS-AGNOSTIC.md lines 443-598 + DISCOVERY-5 | 10 min |
| Child TCA actions not received | QUICK-START.md Rule 4 + DISCOVERY-6 | 5 min |
| visionOS popup doesn't appear | PLATFORM-VISIONOS.md + DISCOVERY-4 | 10 min |
| Deprecation warnings (TCA) | AGENTS-TCA-PATTERNS.md "Common Mistakes" | 15 min |
| Test flakiness | AGENTS-AGNOSTIC.md lines 601-735 | 10 min |
| Concurrent state bugs | QUICK-START.md Rule 9 + DISCOVERY-8 | 8 min |
| Time-based logic fails | QUICK-START.md Rule 7 | 3 min |
| Singleton vs dependency confusion | AGENTS-DECISION-TREES.md Tree 2 | 5 min |
| Module extraction decision | AGENTS-DECISION-TREES.md Tree 1 | 5 min |
| Access control cascade | AGENTS-AGNOSTIC.md lines 443-598 | 10 min |

### If Issue Not Listed

1. Search main docs:
   ```bash
   grep -r "keyword" Sources/AGENTS-*.md
   ```

2. Check compliance:
   ```bash
   Scripts/check-compliance.sh .
   ```

3. Review recent discoveries:
   ```bash
   ls -lt CaseStudies/DISCOVERY-*.md | head -5
   ```

---

## Path 6: Expert (4 hours)

**Goal:** Comprehensive understanding of entire Smith framework.

### Steps

1. **Complete Architect Path** (60 min)

2. **Read all platform guides** (40 min)
   - PLATFORM-MACOS.md (10 min)
   - PLATFORM-IOS.md (10 min)
   - PLATFORM-IPADOS.md (10 min)
   - PLATFORM-VISIONOS.md (10 min)

3. **Read AGENTS-AGNOSTIC.md completely** (40 min)
   - State Management & Concurrency (lines 24-79)
   - Tool Usage (lines 99-141)
   - Concurrency Patterns (lines 162-313)
   - Dependency Injection (lines 317-415)
   - Access Control (lines 443-598)
   - Swift Testing Framework (lines 601-735)

4. **Read AGENTS-TCA-PATTERNS.md completely** (40 min)
   - All 5 patterns
   - All common mistakes
   - Testing section
   - Verification checklist

5. **Read all CaseStudies/** (30 min)
   - DISCOVERY-4 through DISCOVERY-11
   - Understand root causes
   - Learn prevention strategies

6. **Read evaluation tools** (20 min)
   - Tests/AGENTS-SUBMISSION-TEMPLATE.md
   - Tests/AGENTS-EVALUATION-CHECKLIST.md
   - Tests/DISCOVERY-SUBMISSION-TEMPLATE.md

7. **Read process docs** (30 min)
   - EVOLUTION.md
   - VERSIONING.md
   - DISCOVERY-POLICY.md
   - SYNC-MANIFEST.md

### What You'll Know

- ✅ Every pattern, rule, and decision tree
- ✅ All platform-specific constraints
- ✅ How to evaluate compliance
- ✅ How to document new discoveries
- ✅ How framework evolves over time
- ✅ How to sync framework to projects
- ✅ How to version and migrate

### You're Now Ready To

- Evaluate agent/developer work for Smith compliance
- Document new discoveries
- Update framework patterns
- Lead architectural decisions
- Teach others
- Maintain Smith framework itself

---

## Learning Path Comparison

| Feature | Beginner | Quick Start | Developer | Architect | Expert |
|---------|----------|-------------|-----------|-----------|--------|
| Time | 15 min | 5 min | 30 min | 60 min | 4 hours |
| Can code | ✅ | ✅ | ✅ | ✅ | ✅ |
| Can architect | ❌ | ❌ | ❌ | ✅ | ✅ |
| Can evaluate | ❌ | ❌ | ❌ | ⚠️ | ✅ |
| Can teach | ❌ | ❌ | ⚠️ | ✅ | ✅ |
| Can maintain | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Document Reference Map

### By Role

**AI Agents:**
- Primary: QUICK-START.md
- Deep dive: AGENTS-TCA-PATTERNS.md
- Submission: Tests/AGENTS-SUBMISSION-TEMPLATE.md

**Developers:**
- Primary: QUICK-START.md, AGENTS-AGNOSTIC.md
- Reference: AGENTS-TCA-PATTERNS.md, PLATFORM-*.md
- Problem-solving: CaseStudies/DISCOVERY-*.md

**Architects:**
- Primary: AGENTS-DECISION-TREES.md, AGENTS-TASK-SCOPE.md
- Reference: All AGENTS-*.md
- Planning: VERSIONING.md, DISCOVERY-POLICY.md

**Maintainers:**
- All documents
- Focus: EVOLUTION.md, DISCOVERY-POLICY.md, VERSIONING.md
- Tools: Tests/AGENTS-EVALUATION-CHECKLIST.md

### By Topic

**TCA:**
- QUICK-START.md Rules 2-4
- AGENTS-TCA-PATTERNS.md (complete)
- AGENTS-AGNOSTIC.md lines 24-43

**Testing:**
- QUICK-START.md Rules 6-7
- AGENTS-AGNOSTIC.md lines 75-111
- AGENTS-AGNOSTIC.md lines 601-735

**Concurrency:**
- AGENTS-AGNOSTIC.md lines 24-29
- AGENTS-AGNOSTIC.md lines 162-313

**Dependencies:**
- QUICK-START.md Rule 5
- AGENTS-AGNOSTIC.md lines 317-415
- AGENTS-DECISION-TREES.md Tree 2

**Access Control:**
- QUICK-START.md Rule 8
- AGENTS-AGNOSTIC.md lines 443-598
- DISCOVERY-5

**visionOS:**
- QUICK-START.md Rule 9
- PLATFORM-VISIONOS.md
- DISCOVERY-4

---

## FAQ

### How do I know which path to follow?

- **First time?** → Beginner Path
- **AI agent with task?** → Quick Start Path
- **Daily coding?** → Developer Path
- **Making decisions?** → Architect Path
- **Specific bug?** → Problem-Solving Path
- **Teaching/evaluating?** → Expert Path

### Can I skip ahead?

Yes, but:
- Each path builds on previous ones
- Skipping may leave knowledge gaps
- Better to start lower and move up quickly

### How long until I'm productive?

- **Beginner Path:** Productive in 15 minutes
- **Developer Path:** Fully independent in 30 minutes
- **Architect Path:** Making decisions in 60 minutes

### Do I need to memorize everything?

No:
- Memorize the 10 Critical Rules (QUICK-START.md)
- Bookmark the rest
- Use compliance checker to catch violations
- Reference docs as needed

### What if I find a new pattern?

1. Fix your immediate issue
2. Document in commit message
3. Check DISCOVERY-POLICY.md for severity
4. If CRITICAL/STANDARD: Submit discovery
5. If MINOR: Just note in EVOLUTION.md

---

## Next Steps

1. **Choose your path** (see table at top)
2. **Follow the steps** (don't skip)
3. **Use compliance checker:** `Scripts/check-compliance.sh .`
4. **Reference docs as needed** (bookmark this page)
5. **Level up when ready** (see "When to Level Up" sections)

---

**Last Updated:** November 10, 2025
**Version:** 1.0
**Related:** README.md, QUICK-START.md, AGENTS-FRAMEWORK.md
