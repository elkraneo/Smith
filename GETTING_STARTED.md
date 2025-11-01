# Getting Started with Smith Framework

Welcome to Smith! This guide helps you navigate the framework based on your role.

---

## Quick Navigation

### 👤 I'm a Developer (Writing Code)
1. Read [README.md](README.md) - Understand what Smith is
2. Go to your project's `AGENTS.md` file
3. Reference [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md) for Swift/TCA patterns
4. Check [Sources/PLATFORM-[NAME].md](Sources/) for your platform
5. Use [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md) when stuck on architecture

### 🤖 I'm an AI Agent (Submitting Work)
1. Read [Sources/README.md](Sources/README.md) - Framework overview
2. **BEFORE SUBMITTING:** Fill out [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md)
3. Include checklist in your submission message
4. Reviewer evaluates using framework guidelines
5. See feedback with citations to [Sources/](Sources/) sections

### 👨‍💼 I'm a Project Lead / Code Reviewer
1. Read [README.md](README.md) - Project overview
2. Understand [UPDATING.md](UPDATING.md) - How to evolve the framework
3. Use [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md) to review agent work
4. Track framework changes in [EVOLUTION.md](EVOLUTION.md)
5. Copy Smith to new projects using the structure in [README.md](README.md#using-smith-in-your-projects)

### 🏗️ I'm Starting a New Project
1. Copy `Sources/` folder (skip `Tests/`) to your project:
   ```bash
   cp -r Smith/Sources/ MyProject/Smith/ --exclude=Tests/
   ```
2. Create `MyProject/AGENTS.md` wrapper pointing to Smith/
   - Use [Scroll/AGENTS.md](Sources/../Scroll/AGENTS.md) as template (4 platforms)
   - Or [The Green Spurt/AGENTS.md](Sources/../The%20Green%20Spurt/AGENTS.md) template (1 platform)
3. Update project-specific links in your AGENTS.md
4. Done! Reference framework docs from your project

---

## Document Map

### For Everyone
- **[README.md](README.md)** - What is Smith? How does it work?
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - You are here

### For Code Writers
- **[Sources/README.md](Sources/README.md)** - Framework entry point
- **[Sources/AGENTS-FRAMEWORK.md](Sources/AGENTS-FRAMEWORK.md)** - Master index of all docs
- **[Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md)** - Swift 6.2, TCA patterns (universal)
- **[Sources/PLATFORM-*.md](Sources/)** - macOS / iOS / iPadOS / visionOS specific rules

### For Decision Making
- **[Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md)** - When to create modules, use DI, refactor, etc.

### For Task Planning
- **[Sources/AGENTS-TASK-SCOPE.md](Sources/AGENTS-TASK-SCOPE.md)** - Safe / Approval / Forbidden zones

### For AI Agents
- **[Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md)** - Checklist before submitting
- **[Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md)** - How your work is evaluated (private)
- **[Sources/Tests/AGENTS-REVIEW-FORMAT.md](Sources/Tests/AGENTS-REVIEW-FORMAT.md)** - How to request evaluation

### For Framework Evolution
- **[UPDATING.md](UPDATING.md)** - Step-by-step guide to add new patterns
- **[EVOLUTION.md](EVOLUTION.md)** - Changelog of framework updates
- **[Sources/Tests/](Sources/Tests/)** - Evaluation tools (kept separate for easy project copying)

---

## Common Tasks

### Task: "I need to understand TCA patterns"
→ Read [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md) (lines 24–50 for state management)

### Task: "I need to decide if this should be a module"
→ Use [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md) Tree 1

### Task: "Can I edit this file?"
→ Check [Sources/AGENTS-TASK-SCOPE.md](Sources/AGENTS-TASK-SCOPE.md) (Safe/Approval/Forbidden zones)

### Task: "I'm visionOS and need RealityView guidance"
→ Read [Sources/PLATFORM-VISIONOS.md](Sources/PLATFORM-VISIONOS.md) (look for [CRITICAL] rules)

### Task: "I want to add a new pattern to the framework"
→ Follow [UPDATING.md](UPDATING.md) step-by-step

### Task: "I need to review agent work"
→ Get agent's submission, use [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md)

### Task: "I'm starting a new project"
→ Copy Smith to project, follow [README.md#using-smith-in-your-projects](README.md#using-smith-in-your-projects)

---

## Key Concepts (30-Second Version)

### [CRITICAL] / [STANDARD] / [GUIDANCE]
All rules have an enforcement level:
- **[CRITICAL]** - Code won't compile or fail code review (non-negotiable)
- **[STANDARD]** - Expected practice (exceptions documented)
- **[GUIDANCE]** - Best practice (use your judgment)

### Safe / Approval / Forbidden
Every task has scope boundaries:
- **Safe Zone** - Edit freely (part of your feature)
- **Approval Zone** - Ask before editing (affects other features)
- **Forbidden Zone** - Never edit (out of scope)

### Decision Trees
Use flowcharts instead of vague guidance:
- Tree 1: When to create a module?
- Tree 2: @DependencyClient or singleton?
- Tree 3: When to refactor?
- Tree 4: Where should logic live?

---

## First Time Here? Start Here

1. **New to Apple development?**
   - Read [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md) (focuses on Swift/TCA/modern patterns)
   - Your platform? Read [Sources/PLATFORM-[NAME].md](Sources/)

2. **Joining a project that uses Smith?**
   - Read your project's AGENTS.md
   - It points to which Smith docs you need

3. **Leading a project that uses Smith?**
   - Read [README.md](README.md)
   - Bookmark [UPDATING.md](UPDATING.md) for evolving framework
   - Use [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md) to review work

4. **Building a new AI agent integration?**
   - Read [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md)
   - Agents must check this before submitting work
   - You evaluate using [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md)

---

## File Structure (TL;DR)

```
Smith/
├── README.md                          # What is Smith (start here)
├── GETTING_STARTED.md                 # You are here
├── UPDATING.md                        # How to add new patterns
├── EVOLUTION.md                       # Changelog
├── Sources/                           # All framework documents
│   ├── README.md                      # Framework entry point
│   ├── AGENTS-FRAMEWORK.md            # Master index
│   ├── AGENTS-AGNOSTIC.md             # Universal rules
│   ├── AGENTS-DECISION-TREES.md       # Decision flowcharts
│   ├── AGENTS-TASK-SCOPE.md           # Scope boundaries
│   ├── AGENTS-STRUCTURE-COMPLETE.md   # Integration guide
│   ├── PLATFORM-MACOS.md              # macOS rules
│   ├── PLATFORM-IOS.md                # iOS rules
│   ├── PLATFORM-IPADOS.md             # iPadOS rules
│   ├── PLATFORM-VISIONOS.md           # visionOS rules
│   └── Tests/                         # Evaluation tools
│       ├── AGENTS-SUBMISSION-TEMPLATE.md  # For agents
│       ├── AGENTS-EVALUATION-CHECKLIST.md # For reviewers
│       └── AGENTS-REVIEW-FORMAT.md        # Request format
└── [Projects]/                        # Example projects
    ├── Scroll/
    └── The Green Spurt/
```

---

## Need Help?

**Question:** Which file should I read for [topic]?
→ Use the navigation table in [Sources/AGENTS-FRAMEWORK.md](Sources/AGENTS-FRAMEWORK.md)

**Question:** How do I know if I can edit this file?
→ Check [Sources/AGENTS-TASK-SCOPE.md](Sources/AGENTS-TASK-SCOPE.md)

**Question:** What's the right pattern for [architecture]?
→ Use [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md)

**Question:** I found a new pattern—where do I document it?
→ Follow [UPDATING.md](UPDATING.md)

**Question:** Is my code compliant with Smith?
→ Fill [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md) and submit

---

## Quick Links

| I Want To... | Go To... |
|---|---|
| Understand what Smith is | [README.md](README.md) |
| Read framework docs | [Sources/README.md](Sources/README.md) |
| Check Swift/TCA patterns | [Sources/AGENTS-AGNOSTIC.md](Sources/AGENTS-AGNOSTIC.md) |
| Make an architecture decision | [Sources/AGENTS-DECISION-TREES.md](Sources/AGENTS-DECISION-TREES.md) |
| Know what I can edit | [Sources/AGENTS-TASK-SCOPE.md](Sources/AGENTS-TASK-SCOPE.md) |
| Find platform rules | [Sources/PLATFORM-*.md](Sources/) |
| Submit work as agent | [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md) |
| Review agent work | [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md) |
| Add new pattern | [UPDATING.md](UPDATING.md) |
| See what changed | [EVOLUTION.md](EVOLUTION.md) |

---

## Last Updated
November 1, 2025 - Initial v1.0 framework setup
