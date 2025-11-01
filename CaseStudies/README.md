# Smith Framework Case Studies

This directory contains project-specific bug investigations, post-mortems, and lessons learned from real-world development. These are not part of the core Smith framework but are valuable references for understanding how framework patterns apply in practice.

## Current Case Studies

### Case Study 1: GreenSpurt WatcherAssist Popover Entity Gap
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

1. **Name your case study** consistently: `DISCOVERY-N-DESCRIPTIVE-NAME.md`
2. **Follow this structure:**
   - Executive summary (what went wrong, how was it fixed)
   - Root cause analysis (why it happened)
   - Investigation process (how you debugged it)
   - Solution (what fixed it)
   - Prevention strategy (how to avoid next time)
   - Framework impact (what this teaches the framework)

3. **Link from EVOLUTION.md:**
   - Add entry under "Learned Patterns & Updates" in EVOLUTION.md
   - Reference the case study files for detailed analysis
   - Keep EVOLUTION.md entry concise; details go in case study

4. **Update framework if needed:**
   - If case study reveals a missing pattern or [CRITICAL] issue, update framework docs
   - Add to appropriate platform-specific file or AGENTS-AGNOSTIC.md
   - Reference the case study as evidence

---

## Quick Reference

| Case Study | Framework Impact | Relevant File |
|-----------|------------------|----------------|
| GreenSpurt Popover Entity Gap | PresentationComponent pattern added to visionOS | PLATFORM-VISIONOS.md |

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
