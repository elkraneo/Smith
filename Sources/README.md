# Smith: Agent Development Guidelines & Platform Standards

This repository contains canonical development guidelines and platform-specific patterns for multi-platform Apple development.

---

## For AI Agents 🤖

All agent behavior guidelines are in root-level **AGENTS-*** files. Start here:

### Framework Entry Point
- **[AGENTS-FRAMEWORK.md](./AGENTS-FRAMEWORK.md)** - Master index and navigation guide

### Core Framework (Read in Order)
1. **[AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)** - Universal rules for all platforms
   - State management, concurrency patterns, dependency injection, testing
   - [CRITICAL]/[STANDARD]/[GUIDANCE] enforcement levels
   - Why modern patterns are required (Swift 6.2 strict concurrency)

2. **[AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md)** - Architecture decision flowcharts
   - When to create Swift Package modules
   - @DependencyClient vs singleton patterns
   - Where logic should live (Core/UI/Platform)

3. **[AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md)** - Task boundary management
   - Safe Zone (edit freely), Approval Zone (ask first), Forbidden Zone (never edit)
   - Prevents scope creep and unauthorized changes

### Platform-Specific Constraints
- **[PLATFORM-MACOS.md](./PLATFORM-MACOS.md)** - macOS window management, keyboard, menu bar
- **[PLATFORM-IOS.md](./PLATFORM-IOS.md)** - Touch, share extension, widgets, haptics
- **[PLATFORM-IPADOS.md](./PLATFORM-IPADOS.md)** - Split view, sidebar+detail, stage manager
- **[PLATFORM-VISIONOS.md](./PLATFORM-VISIONOS.md)** - RealityView, ImmersiveSpace, spatial interactions

### Integration & Structure
- **[AGENTS-STRUCTURE-COMPLETE.md](./AGENTS-STRUCTURE-COMPLETE.md)** - How framework pieces work together

---

## For Humans 👥

### Project Documentation
- **Scroll/** - [AGENTS.md](./Scroll/AGENTS.md), [WORKFLOW.md](./Scroll/WORKFLOW.md), [CONTRIBUTING.md](./Scroll/CONTRIBUTING.md)
- **The Green Spurt/** - [AGENTS.md](./The%20Green%20Spurt/AGENTS.md), project-specific patterns

### Project-Level Links
Each project has a thin AGENTS.md wrapper that links to relevant canonical documents and platform-specific files.

### General Guidance
- **[AGENTS-STRUCTURE-COMPLETE.md](./AGENTS-STRUCTURE-COMPLETE.md)** - Explanation of framework organization

---

## Quick Navigation

### "I'm implementing a feature for iOS"
→ [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md) + [PLATFORM-IOS.md](./PLATFORM-IOS.md)

### "I need to decide if this should be a module"
→ [AGENTS-DECISION-TREES.md](./AGENTS-DECISION-TREES.md) (Tree 1)

### "I don't know if I can edit this file"
→ [AGENTS-TASK-SCOPE.md](./AGENTS-TASK-SCOPE.md)

### "I need to understand the architecture"
→ [AGENTS-STRUCTURE-COMPLETE.md](./AGENTS-STRUCTURE-COMPLETE.md)

---

## File Organization

```
Smith/                                 # Root - canonical frameworks
├── README.md                         # This file
├── AGENTS-FRAMEWORK.md               # Master index
├── AGENTS-AGNOSTIC.md               # Universal rules
├── AGENTS-DECISION-TREES.md         # Architecture decisions
├── AGENTS-TASK-SCOPE.md             # Task boundaries
├── AGENTS-STRUCTURE-COMPLETE.md     # Integration guide
├── PLATFORM-MACOS.md                # macOS specifics
├── PLATFORM-IOS.md                  # iOS specifics
├── PLATFORM-IPADOS.md               # iPadOS specifics
├── PLATFORM-VISIONOS.md             # visionOS specifics
├── Tests/                           # Evaluation & review tools (skip when copying)
│   ├── AGENTS-SUBMISSION-TEMPLATE.md   # Agent submission checklist
│   ├── AGENTS-EVALUATION-CHECKLIST.md  # Your private evaluation tool
│   └── AGENTS-REVIEW-FORMAT.md         # How to request evaluation
├── Scroll/                          # Multi-platform project
│   ├── AGENTS.md                    # Thin wrapper (links to canonical)
│   ├── WORKFLOW.md
│   ├── CONTRIBUTING.md
│   └── ...
└── The Green Spurt/                 # visionOS-only project
    ├── AGENTS.md                    # Thin wrapper (links to visionOS)
    └── ...
```

**When copying Smith to new projects, skip the `Tests/` folder** (it's for evaluation only).

---

## How to Use This Framework

### For Projects
Each project links to relevant canonical documents and adapts them locally. Files link both ways:
- Project AGENTS.md → links to canonical files
- Canonical files → reference projects

### For Agents
1. Read README.md (you are here)
2. Follow the "For AI Agents" section above
3. Reference specific platform files as needed
4. When uncertain about scope, check AGENTS-TASK-SCOPE.md
5. When uncertain about architecture, check AGENTS-DECISION-TREES.md

### For Humans
1. Start with project-specific AGENTS.md or CONTRIBUTING.md
2. Reference canonical documents for principles and patterns
3. Use decision trees for architectural choices
4. Check AGENTS-STRUCTURE-COMPLETE.md to understand the overall framework

---

## Key Principles

- **Composability** - Pick platforms you need (Scroll uses 4, Green Spurt uses 1)
- **Clarity** - [CRITICAL] rules are non-negotiable; [STANDARD] expected; [GUIDANCE] use judgment
- **Discoverability** - Root-level files with AGENTS-* naming are accessible without navigation
- **Separation of Concerns** - Agnostic = language-level; Platform = framework-level
- **Decision Making** - Use decision trees instead of vague guidance

---

## Quick Definitions

| Term | Definition |
|------|-----------|
| **[CRITICAL]** | Won't compile or will fail code review - non-negotiable |
| **[STANDARD]** | Expected practice, rare exceptions |
| **[GUIDANCE]** | Best practice, use your judgment |
| **Safe Zone** | Edit freely without approval |
| **Approval Zone** | Notify first, ask before editing |
| **Forbidden Zone** | Never edit without permission |

---

## Last Updated
November 1, 2025 - Consolidated from multi-project guidance into canonical framework
