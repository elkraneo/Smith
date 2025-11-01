# Smith Framework - Conversation Resumption Guide

This file helps you resume work on Smith framework after moving to this location.

**Location:** `/Volumes/Plutonian/_Developer/Smith`
**Moved:** November 1, 2025
**Framework Version:** v1.0 (Complete)

---

## Current State

### ✅ Completed

**Core Framework (v1.0):**
- ✅ AGENTS-AGNOSTIC.md - Universal Swift 6.2 / TCA patterns
- ✅ AGENTS-DECISION-TREES.md - 4 architectural decision flowcharts
- ✅ AGENTS-TASK-SCOPE.md - Safe/Approval/Forbidden zones
- ✅ AGENTS-FRAMEWORK.md - Master navigation index
- ✅ AGENTS-STRUCTURE-COMPLETE.md - Integration guide
- ✅ PLATFORM-MACOS.md, PLATFORM-IOS.md, PLATFORM-IPADOS.md, PLATFORM-VISIONOS.md - Platform-specific rules
- ✅ ROOT: README.md, GETTING_STARTED.md, UPDATING.md, EVOLUTION.md

**Agent Evaluation Tools:**
- ✅ AGENTS-SUBMISSION-TEMPLATE.md - Agent submission checklist
- ✅ AGENTS-EVALUATION-CHECKLIST.md - Framework compliance verification
- ✅ AGENTS-REVIEW-FORMAT.md - How to request evaluation

**Project Integration:**
- ✅ Scroll/AGENTS.md - Multi-platform wrapper (4 platforms)
- ✅ The Green Spurt/AGENTS.md - visionOS wrapper (1 platform)
- ✅ Both project copies updated with framework
- ✅ Links updated to point to canonical Smith at new location

### 📝 Latest Discoveries

**Discovery 1 (Nov 1):** Tool Usage Optimization
- Added SosumiDocs MCP, XcodeBuildMCP, gh CLI guidance
- See EVOLUTION.md for details

**Discovery 2 (Nov 1):** @Shared Pattern for Cross-Feature State
- Added @Shared/@SharedReader guidance for modular architectures
- Documented canonical patterns in AGENTS-AGNOSTIC.md

**Discovery 3 (Nov 1):** Modern TCA 1.23.0+ Patterns
- Created AGENTS-TCA-PATTERNS.md with 4 canonical patterns
- Covers: @Bindable observation, optional state navigation, multiple destinations, form bindings
- Prevents deprecated API usage (WithViewStore, IfLetStore, @Perception.Bindable)
- Real-world validation via GreenSpurt WatcherAssist implementation

**Discovery 4 (Nov 1):** Popover Entity Creation Gap (visionOS)
- Identified RealityKit infrastructure dependency in visionOS UI
- Added [CRITICAL] section to PLATFORM-VISIONOS.md
- Case studies in CaseStudies/ directory document bug investigation

---

## Quick Links for Resumption

### To Continue Framework Development
1. Read [EVOLUTION.md](EVOLUTION.md) - See what's been done
2. Read [UPDATING.md](UPDATING.md) - Process for adding new patterns
3. Check "Framework Areas Under Development" in EVOLUTION.md for next steps

### Next Tasks (Suggested Order)

1. **Error Handling Patterns** (next)
   - When to use `async throws` vs `Result<T, Error>`
   - When to use `TaskResult` (TCA)
   - Error recovery patterns
   - User-facing errors vs logging

2. **Networking Layer** (after error handling)
   - HTTP client design
   - Request/response models
   - Retry logic and backoff
   - API error mapping

3. **State Synchronization** (future)
   - Sharing state across modules
   - Reducer composition patterns
   - Data migrations

### To Review Framework
- Start: [README.md](README.md) (project overview)
- Navigate: [GETTING_STARTED.md](GETTING_STARTED.md) (by role)
- Reference: [Sources/README.md](Sources/README.md) (framework entry point)

### To Use Framework
- Agent submitting work: [Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md](Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md)
- Reviewer evaluating: [Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md](Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md)
- Want to update framework: [UPDATING.md](UPDATING.md)

---

## Move Summary

**From:** `/Users/elkraneo/Desktop/Smith`
**To:** `/Volumes/Plutonian/_Developer/Smith`
**Date:** November 1, 2025

**What Moved:**
- ✅ All framework documents (Sources/)
- ✅ All evaluation tools (Sources/Tests/)
- ✅ All root-level guides (README.md, GETTING_STARTED.md, UPDATING.md, EVOLUTION.md)
- ✅ Project wrappers (Scroll/, The Green Spurt/)
- ✅ Conversation context (.claude/ folder)

**What Changed:**
- Scroll/AGENTS.md links updated to point to canonical Smith at new location (../../Smith/Sources/)
- The Green Spurt/AGENTS.md links updated to point to canonical Smith at new location (../Smith/Sources/)
- Both projects now reference `/Volumes/Plutonian/_Developer/Smith`

---

## Project Link Updates

### Scroll
**Location:** `/Volumes/Plutonian/_Developer/Scroll/source/Scroll/`
**Links:** `../../Smith/Sources/[FILE]` (goes up to _Developer, then into Smith)

### The Green Spurt
**Location:** `/Volumes/Plutonian/GreenSpurt/`
**Links:** `../Smith/Sources/[FILE]` (goes up to Plutonian, then into Smith)

### Canonical Smith
**Location:** `/Volumes/Plutonian/_Developer/Smith/`
**Structure:**
```
Smith/
├── Sources/           (all framework docs)
├── Tests/             (evaluation tools in Sources/Tests/)
├── README.md
├── GETTING_STARTED.md
├── UPDATING.md
├── EVOLUTION.md
└── RESUMPTION.md (this file)
```

---

## How to Resume in New Conversation

When starting a new Claude Code session at this location:

1. Open this file (RESUMPTION.md)
2. Say: "I've moved Smith to /Volumes/Plutonian/_Developer/Smith. Last work: completed v1.0 framework with @Shared pattern integration (see EVOLUTION.md Discovery 2). Ready to work on error handling patterns."
3. I'll have full context from EVOLUTION.md and can continue development

---

## Key Files to Know

| File | Purpose | When to Read |
|------|---------|--------------|
| EVOLUTION.md | Changelog of all discoveries | Before any work (get context) |
| UPDATING.md | How to add new patterns | When adding framework updates |
| Sources/AGENTS-AGNOSTIC.md | Universal rules | When building features |
| Sources/PLATFORM-*.md | Platform-specific rules | When targeting specific platform |
| Sources/Tests/AGENTS-SUBMISSION-TEMPLATE.md | Agent checklist | Before agent submits work |
| Sources/Tests/AGENTS-EVALUATION-CHECKLIST.md | Reviewer checklist | When reviewing agent work |

---

## Conversation History

**Original Location:** `/Users/elkraneo/Desktop/Smith`
**Original Conversation:** Will not resume automatically due to location change

**Solution:** This RESUMPTION.md file + EVOLUTION.md preserve all context needed to continue work without losing technical progress.

---

## Version Status

- **v1.0:** Complete (Framework, 8 documents, 3 evaluation tools, 2 project wrappers)
- **v1.1:** In progress (TCA Patterns added, visionOS patterns enhanced, 4 discoveries documented)
- **v1.2:** Planned (Error handling, networking, state sync)
- **v2.0:** Future (Automated validation, compliance scoring)

---

## Last Updated
November 1, 2025 - Completed Discoveries 1-4, added AGENTS-TCA-PATTERNS.md, created CaseStudies directory
