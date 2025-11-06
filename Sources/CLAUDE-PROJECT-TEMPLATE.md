# CLAUDE - Project Template

This file shows how to extend CLAUDE.md with project-specific customizations.

**How to use:**
1. After syncing Smith framework with `smith-sync.sh`, your project will have `CLAUDE.md` at root
2. That file contains the framework base (from Smith)
3. You can add project-specific sections below the framework content
4. When you sync again, the framework base updates automatically while your customizations remain

---

## Example Customizations for Your Project

### Platform Focus

```markdown
## [PROJECT-SPECIFIC] Platform Focus

This project targets **visionOS/RealityKit**.

### visionOS-Specific Patterns

When working with RealityKit:
- See PLATFORM-VISIONOS.md for full visionOS guidance
- Use ViewAttachmentEntity for SwiftUI in 3D scenes
- Remember: @Reducer enum .ifLet() closure is MANDATORY (DISCOVERY-6)
- Test hint button interactions in both skip paths (solution vs button)

**Key Example:** GreenSpurt hint system (see DISCOVERY-6)
- Broken after solution skip but not button skip
- Root cause: RealityKit attachment lifecycle
- Solution: closure form of .ifLet() ensures proper composition
```

### Local Tool Setup

```markdown
## [PROJECT-SPECIFIC] Local Tools & Setup

This project uses these tools/commands:

```bash
# Build with xcsift for clean output
xcodebuild build -scheme MyScheme 2>&1 | xcsift

# Run tests
xcodebuild test -scheme MyScheme -destination 'platform=iOS Simulator,name=iPhone 16'

# Sync Smith framework (from Smith root)
../Smith/Scripts/smith-sync.sh .
```

### Team Conventions

```markdown
## [PROJECT-SPECIFIC] Team Conventions

### Naming
- Feature reducers: `<FeatureName>Feature` (e.g., `GameEngineFeature`)
- Views: `<FeatureName>View` (e.g., `GameEngineView`)
- State: Always `@ObservableState`

### Code Review Focus
- [ ] All State types have `@ObservableState`
- [ ] @Shared state has single owner pattern (DISCOVERY-5)
- [ ] @Reducer enums use .ifLet() with closure (DISCOVERY-6)
- [ ] No Task.detached, use Task { @MainActor in }

### Common Patterns in This Project
- Optional navigation: .sheet() with .scope() (Pattern 2)
- Multi-level navigation: Enum with @Reducer (Pattern 3)
- Shared state: Single owner in AppFeature (Pattern 4)
```

### Known Gotchas

```markdown
## [PROJECT-SPECIFIC] Known Gotchas

### RealityKit Attachment Lifecycle
When implementing hint buttons in 3D scenes:
- Solution skip + hint button = broken (RealityKit attachment issue)
- Normal skip + hint button = works fine
- Fix: Use .ifLet() closure form MANDATORY
- See DISCOVERY-6 and HINT_SYSTEM_BUG_STATUS_REPORT.md

### @Shared State Mutations
- Only AppFeature owns @Shared
- All other features use @SharedReader
- Multiple writers = data races
- See DISCOVERY-5 for real failure case

### Access Control Cascade
When making a type public:
- Trace ALL transitive dependencies
- Everything referenced by public type must also be public
- Compiler error message will mislead you (shows symptoms)
- See DISCOVERY-5 for debugging strategy
```

### Project-Specific Decision Trees

```markdown
## [PROJECT-SPECIFIC] Decision Tree: When to Extract to Module

For THIS project, also consider:

1. **Will other apps import this?** (GreenSpurt-specific logic vs shared)
   - YES → Extract to module, publish to Swift Package
   - NO → Continue to next question

2. **Is this visionOS-specific?**
   - YES → Use PLATFORM-VISIONOS.md patterns, consider separate module
   - NO → Continue

3. **Does this depend on RealityKit?**
   - YES → Keep in app (tightly coupled to scene)
   - NO → Can extract to module
```

---

## How to Customize CLAUDE.md

**Before Syncing (First Time):**
```
1. Run: ./Scripts/smith-sync.sh .
2. CLAUDE.md is created with framework base
3. Add your customizations below the framework content
```

**After Syncing (Subsequent Times):**
```
1. Run: ./Scripts/smith-sync.sh .
2. If no local changes: CLAUDE.md is updated automatically
3. If local changes: Merge them (script will guide you)
```

**Merging CLAUDE.md Updates:**
```bash
# Script will create:
# - CLAUDE.md.NEW (latest framework)
# - CLAUDE.md.backup (your current version)

# Review diff
diff -u CLAUDE.md.backup CLAUDE.md.NEW

# Merge manually (keep framework rules + your customizations)
# Edit CLAUDE.md to combine both

# Clean up and commit
rm CLAUDE.md.backup CLAUDE.md.NEW
git add CLAUDE.md
git commit -m "docs: merge Smith CLAUDE updates + project customizations"
```

---

## Why This Matters

The Smith framework evolves (new patterns, new DISCOVERY cases). You want those updates automatically. But you also have project-specific guidance that's important locally.

This template shows how to have both:
- ✅ Automatic framework updates (base)
- ✅ Project customizations preserved (local)
- ✅ Conflict detection (merge when both change)

---

## Questions?

See: `Scripts/smith-sync.sh` for full sync strategy
See: `SYNC-MANIFEST.md` for framework distribution tracking
