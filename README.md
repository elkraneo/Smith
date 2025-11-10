# Smith - Agent Development Framework for Multi-Platform Apple Development

Smith is a **canonical framework** for guidance on AI agent behavior, code patterns, and architectural decisions in multi-platform Apple development (macOS, iOS, iPadOS, visionOS).

This is a **living document framework** that evolves as you discover new patterns, constraints, and best practices.

---

## The Smith Philosophy

> **Smith is opinionated, dense, and evolving. That's not a flaw—that's exactly how a discipline should work. Rather than unlimited freedom with no safety net, Smith provides constraints that prevent bugs before they happen.**

---

## What Is Smith?

Smith consolidates:
- **Universal patterns** - Swift 6.2, TCA 1.23.0+, modern concurrency patterns
- **Platform constraints** - visionOS (RealityView), macOS (window management), iOS/iPadOS (responsive design)
- **Architectural decisions** - When to create modules, use dependency injection, refactor code
- **Task scope management** - What agents can/cannot edit without approval
- **Tool optimization** - Which MCP tools and CLI commands are most efficient
- **Agent evaluation** - How to verify agent work follows the framework

---

## Key Concepts

### [CRITICAL] / [STANDARD] / [GUIDANCE]

All rules use three enforcement levels:
- **[CRITICAL]** - Non-negotiable. Code won't compile or will fail review.
- **[STANDARD]** - Expected practice. Exceptions documented.
- **[GUIDANCE]** - Best practice. Use judgment.

### Safe / Approval / Forbidden Zones

For every task, define:
- **Safe Zone** - Edit freely (part of feature)
- **Approval Zone** - Ask before editing (affected by feature)
- **Forbidden Zone** - Never edit (out of scope)

### Decision Trees

Instead of vague guidance, use clear decision flowcharts:
- Tree 1: When to create a Swift Package module
- Tree 2: @DependencyClient vs singleton
- Tree 3: When to refactor into a module
- Tree 4: Where logic should live (Core/UI/Platform)

---

## Project Structure

```
Smith/
├── README.md                           # This file - project overview
├── Sources/                            # All framework documentation
│   ├── README.md                       # For AI Agents & Humans
│   ├── AGENTS-FRAMEWORK.md            # Master navigation index
│   ├── AGENTS-AGNOSTIC.md             # Universal rules (Swift 6.2, TCA)
│   ├── AGENTS-DECISION-TREES.md       # Architecture decision flowcharts
│   ├── AGENTS-TASK-SCOPE.md           # Safe/Approval/Forbidden zones
│   ├── AGENTS-STRUCTURE-COMPLETE.md   # How framework pieces fit together
│   ├── PLATFORM-MACOS.md              # macOS specifics
│   ├── PLATFORM-IOS.md                # iOS specifics
│   ├── PLATFORM-IPADOS.md             # iPadOS specifics
│   ├── PLATFORM-VISIONOS.md           # visionOS specifics
│   └── Tests/                         # Evaluation tools (not deployed to projects)
│       ├── AGENTS-SUBMISSION-TEMPLATE.md  # What agents fill out before submitting
│       ├── AGENTS-EVALUATION-CHECKLIST.md # How you verify compliance
│       └── AGENTS-REVIEW-FORMAT.md        # How to request evaluation
├── Scroll/                            # Example project wrapper
└── The Green Spurt/                   # Example project wrapper
```

---

## For Different Audiences

### AI Agents 🤖
1. Start with [Sources/README.md](Sources/README.md) - Framework entry point
2. Read [Sources/AGENTS-FRAMEWORK.md](Sources/AGENTS-FRAMEWORK.md) - Master index
3. Follow the decision trees and architecture guidance
4. Use [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md) before submitting work

### Project Leads / Architects
1. Read this README first
2. Review [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md) - Universal patterns
3. Review [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md) - Decision logic
4. Understand [Sources/AGENTS-TASK-SCOPE.md](Sources/AGENTS-TASK-SCOPE.md) - Scope boundaries
5. Use [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md) to review agent work

### Developers (Humans)
1. Read your project's AGENTS.md (e.g., Scroll/AGENTS.md)
2. Reference relevant [Sources/PLATFORM-*.md](Sources/) for your platform
3. Use [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md) for architectural questions
4. Check [Sources/AGENTS-TASK-SCOPE.md](Sources/AGENTS-TASK-SCOPE.md) to understand task boundaries

---

## Core Principles

**1. Composability**
- Projects link to only the platforms they need
- Scroll: 4 platforms (macOS, iOS, iPadOS, visionOS)
- Green Spurt: 1 platform (visionOS only)
- New Project X: N platforms as needed

**2. Single Source of Truth**
- Canonical framework in Smith/Sources/
- Projects point to canonical, never duplicate
- Updates to framework propagate automatically

**3. Clear Decision Making**
- Vague guidance replaced with decision trees
- Quantitative thresholds (20+ actions = module, 3+ sub-reducers = extract)
- Objective criteria, not subjective judgment

**4. Scope Boundaries**
- Every task has Safe/Approval/Forbidden zones
- Agents can't edit outside approved scope
- Prevents scope creep and unauthorized changes

**5. Tool Optimization**
- SosumiDocs MCP for Apple docs (not curl)
- XcodeBuildMCP for builds (not raw xcodebuild)
- `gh` CLI for simple operations (not slow MCP calls)
- Agents learn which tool is most efficient per task

---

## Using Smith in Your Projects

### Option 1: Copy Framework (Recommended for Portability)
```bash
cp -r Smith/Sources/ MyNewProject/Smith/ --exclude=Tests/
# Project MyNewProject now has self-contained framework
```

### Option 2: Reference Framework (Recommended for Consistency)
```bash
# MyNewProject/AGENTS.md points to ../Smith/Sources/
# Single source of truth, easier to update
```

### Create Project AGENTS.md Wrapper
Every project needs a thin `AGENTS.md` stub:
```markdown
# AGENTS - [Project Name]

This project uses the **canonical AGENTS framework** from Smith.

## Quick Links
- [Smith/AGENTS-FRAMEWORK.md](Smith/AGENTS-FRAMEWORK.md)
- [Smith/AGENTS-AGNOSTIC.md](Smith/AGENTS-AGNOSTIC.md)
- [Smith/PLATFORM-IOS.md](Smith/PLATFORM-IOS.md)
...
```

---

## Iterating on Smith

As you discover new patterns, constraints, and learnings, update Smith:

### When to Update

1. **New Platform Constraint Discovered**
   - Example: "visionOS requires RealityView, not ARView"
   - Update: [Sources/PLATFORM-VISIONOS.md](Sources/PLATFORM-VISIONOS.md)
   - Mark as [CRITICAL] if code won't compile without it

2. **New Pattern Becomes Standard**
   - Example: "@DependencyClient is now preferred over manual DependencyKey"
   - Update: [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md)
   - Citation: Add line numbers to other documents

3. **New Decision Tree Needed**
   - Example: "When to use async/await vs completion handlers"
   - Add to: [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md)
   - Reference: Update [Sources/AGENTS-FRAMEWORK.md](Sources/AGENTS-FRAMEWORK.md)

4. **Agent Inefficiency Discovered**
   - Example: "Agents running repeated curl calls to docs"
   - Update: [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md) + [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md)
   - Rationale: Add [STANDARD] rule + checklist item

5. **Code Review Patterns Emerge**
   - Example: "We keep rejecting code with @Published instead of @Observable"
   - Update: [Sources/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md)
   - Add: New evaluation criteria or red flag

---

## Best Practices for Framework Evolution

### 1. Document the "Why"
Don't just say "use @Observable". Explain:
```markdown
- **[CRITICAL] Use @Observable** for state management (not @Published)
  - Why: Swift 6.2 strict concurrency requires Sendable compliance
  - Impact: @Published won't compile; @Observable works with modern TCA
  - Reference: Swift evolution SE-XXXX, TCA 1.23.0 migration guide
```

### 2. Add Citations to Line Numbers
When referencing across documents:
```markdown
For more on dependency injection, see [AGENTS-AGNOSTIC.md lines 253–326](#dependency-injection)
```

### 3. Keep Examples in Submission Template
If agents keep making the same mistake, add a checklist:
```markdown
### Tool Usage - Documentation & Web
- [ ] Used SosumiDocs MCP (not curl to developer.apple.com)
- [ ] No repeated API calls to same endpoint
```

### 4. Version Updates (Optional)
Add to end of each document:
```markdown
## Last Updated
- Nov 1, 2025 - Added XcodeBuildMCP optimization guidance
- Oct 28, 2025 - Clarified @Observable vs @Published for Swift 6.2
- Oct 15, 2025 - Added PLATFORM-VISIONOS constraints
```

### 5. Create "Evolution Log" (Optional)
Document major framework changes:
```markdown
# Smith Framework Evolution Log

## Latest Changes
- Added Tool Usage optimization section (SosumiDocs, XcodeBuildMCP, gh CLI)
- Separated Tests/ folder for easier project copying
- Expanded decision trees with quantitative thresholds

## Next Areas to Refine
- Error handling patterns (async/throws vs Result)
- Networking layer patterns (API client design)
- State synchronization across modules
```

---

## Recommended Update Process

### When You Discover a New Pattern

1. **Document in a new issue/task**
   ```
   Title: "[DISCOVERY] visionOS requires RealityView, not ARView"
   Description: Evidence, impact, which document to update
   ```

2. **Write the guidance**
   ```markdown
   Update AGENTS-AGNOSTIC.md or PLATFORM-VISIONOS.md with:
   - Clear rule statement
   - [CRITICAL]/[STANDARD]/[GUIDANCE] level
   - Why (rationale, reference)
   - What to do instead
   - Example code (optional)
   ```

3. **Update related sections**
   - Add checklist item to AGENTS-SUBMISSION-TEMPLATE.md
   - Update AGENTS-EVALUATION-CHECKLIST.md if needed
   - Add citation to AGENTS-FRAMEWORK.md if new section

4. **Test with next agent submission**
   - Agent fills submission template
   - New rule appears in checklist
   - Evaluate compliance

5. **Document in Evolution Log**
   - Record what changed and why
   - Link to related documents

---

## Quick Links

### 🚀 Getting Started (v1.1.0)
- **⚡ Start Here:** [QUICK-START.md](QUICK-START.md) - 5-minute crash course (NEW!)
- **📚 Learning Paths:** [LEARNING-PATHS.md](LEARNING-PATHS.md) - Choose your path: Beginner → Expert (NEW!)
- **🔍 Framework Overview:** [Sources/AGENTS-FRAMEWORK.md](Sources/AGENTS-FRAMEWORK.md)

### 📖 Core Documentation
- **For AI Agents:** [Sources/README.md](Sources/README.md)
- **Universal Patterns:** [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md)
- **TCA Patterns:** [Sources/AGENTS-TCA-PATTERNS.md](Sources/AGENTS-TCA-PATTERNS.md)
- **Architecture Decisions:** [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md)

### 🛠️ Tools & Automation (NEW!)
- **Compliance Checker:** [Scripts/check-compliance.sh](Scripts/check-compliance.sh) - Automated violation detection
- **Compliance Report:** [Scripts/compliance-report.sh](Scripts/compliance-report.sh) - Generate compliance score
- **CI/CD Integration:** [CI-CD-INTEGRATION.md](CI-CD-INTEGRATION.md) - GitHub Actions, GitLab CI, pre-commit hooks
- **Framework Sync:** [Scripts/smith-sync.sh](Scripts/smith-sync.sh)

### 📋 Process & Policy (NEW!)
- **Versioning:** [VERSIONING.md](VERSIONING.md) - Semantic versioning, migration guides
- **Discovery Policy:** [DISCOVERY-POLICY.md](DISCOVERY-POLICY.md) - When to document patterns
- **Evolution Log:** [EVOLUTION.md](EVOLUTION.md) - Framework history and changes

### ✅ Evaluation & Submission
- **Agent Submission:** [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md)
- **Agent Evaluation:** [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md)

---

## Example Projects

- **Scroll** - Multi-platform (macOS, iOS, iPadOS, visionOS)
- **The Green Spurt** - Single platform (visionOS only)

Both reference Smith framework and demonstrate composability.

---

## Questions?

This is a **living framework**. As you iterate on projects and discover patterns:
1. Document the pattern in appropriate Smith document
2. Add enforcement level ([CRITICAL]/[STANDARD]/[GUIDANCE])
3. Update submission template if agent verification needed
4. Record in Evolution Log for future reference

Smith evolves with your projects.
