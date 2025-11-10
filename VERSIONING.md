# Smith Framework Versioning & Migration Guide

**How Smith evolves, how versions work, and how to upgrade your projects.**

---

## Semantic Versioning

Smith follows semantic versioning: **MAJOR.MINOR.PATCH**

### Version Format

```
v1.2.3
 │ │ └─ PATCH: Bug fixes, typos, clarifications (backward compatible)
 │ └─── MINOR: New patterns, new platform guides (backward compatible)
 └───── MAJOR: Breaking changes to existing patterns (requires migration)
```

### Current Version

**v1.1.0** (November 10, 2025)

---

## Version History

### v1.1.0 (Current)
**Release Date:** November 10, 2025

**New Features:**
- ✅ Quick Start guide (QUICK-START.md)
- ✅ Automated compliance checker (Scripts/check-compliance.sh)
- ✅ Versioning and migration system (this document)
- ✅ Discovery severity thresholds (DISCOVERY-POLICY.md)
- ✅ Test coverage requirements added to AGENTS-AGNOSTIC.md
- ✅ Compliance metrics infrastructure

**Improvements:**
- Enhanced sync script with better error messages
- Added tiered documentation references
- Updated EVOLUTION.md with all discoveries through #11

**Breaking Changes:** None (backward compatible with v1.0)

**Migration Required:** No

---

### v1.0.0 (Initial Release)
**Release Date:** November 1, 2025

**Initial Components:**
- AGENTS-AGNOSTIC.md (Universal patterns)
- AGENTS-TCA-PATTERNS.md (TCA 1.23.0+ patterns)
- AGENTS-DECISION-TREES.md (4 decision trees)
- AGENTS-TASK-SCOPE.md (Safe/Approval/Forbidden zones)
- PLATFORM-*.md (4 platform guides)
- DISCOVERY case studies (1-5)
- Submission and evaluation templates
- smith-sync.sh (sync automation)

---

## What Triggers Version Bumps?

### MAJOR Version (v2.0.0, v3.0.0, ...)

**Breaking changes that require code updates:**

1. **Deprecated pattern removal**
   - Example: "Remove all WithViewStore references" (requires project code changes)

2. **Enforcement level changes (GUIDANCE → CRITICAL)**
   - Example: "Using @Shared is now CRITICAL" (requires compliance)

3. **TCA/Swift version requirements change**
   - Example: "Require TCA 2.0+ / Swift 7.0+" (requires dependency updates)

4. **Framework structure reorganization**
   - Example: "All platform docs moved to Platforms/ folder" (requires path updates)

**Migration Guide:** Required (see "Migration Guides" section below)

---

### MINOR Version (v1.1.0, v1.2.0, ...)

**New features and backward-compatible additions:**

1. **New pattern documentation**
   - Example: "Add networking patterns guide"

2. **New platform support**
   - Example: "Add PLATFORM-WATCHOS.md"

3. **New decision trees**
   - Example: "Tree 5: When to use async/await vs completion handlers"

4. **New DISCOVERY case studies**
   - Example: "DISCOVERY-12: State synchronization bug"

5. **New tools and scripts**
   - Example: "Add coverage-report.sh"

**Migration Guide:** Optional (projects can upgrade without changes)

---

### PATCH Version (v1.0.1, v1.0.2, ...)

**Bug fixes and clarifications:**

1. **Documentation typos**
   - Example: "Fix typo in AGENTS-TCA-PATTERNS.md line 234"

2. **Example code fixes**
   - Example: "Correct binding syntax in Quick Start"

3. **Script bug fixes**
   - Example: "Fix smith-sync.sh path handling"

4. **Link/reference corrections**
   - Example: "Update broken DISCOVERY-5 reference"

**Migration Guide:** None (projects can sync without review)

---

## How to Check Your Version

### In Your Project

Check `.smith-sync-manifest.json` in your project root:

```json
{
  "last_sync": "2025-11-10T14:30:00Z",
  "smith_commit": "abc123def456...",
  "smith_version": "abc123d",
  "framework_version": "v1.1.0"
}
```

### In Smith Repository

Check `VERSIONING.md` (this file) for current version, or:

```bash
git tag | grep '^v[0-9]' | sort -V | tail -1
```

---

## Migration Guides

### Upgrading from v1.0.0 → v1.1.0

**Breaking Changes:** None

**New Features You Should Adopt:**

1. **Quick Start Guide**
   - Point new team members to QUICK-START.md first
   - Add link to your project's onboarding docs

2. **Compliance Checker**
   - Run `Scripts/check-compliance.sh /path/to/your/project`
   - Fix any violations found
   - Add to CI/CD pipeline (see CI-CD-INTEGRATION.md)

3. **Test Coverage Requirements**
   - Review AGENTS-AGNOSTIC.md lines 75-80
   - Aim for 80%+ coverage on TCA reducers
   - Use coverage tool: `swift test --enable-code-coverage`

**Optional Improvements:**

- Add pre-commit hook to run compliance checker
- Update your CLAUDE.md to reference QUICK-START.md
- Review DISCOVERY-POLICY.md for severity guidelines

**Time Estimate:** 30 minutes

**Steps:**

```bash
# 1. Sync to v1.1.0
cd /path/to/your/project
/path/to/Smith/Scripts/smith-sync.sh .

# 2. Check compliance
/path/to/Smith/Scripts/check-compliance.sh . --strict

# 3. Fix any violations
# (See QUICK-START.md for fixes)

# 4. Add to CI (optional)
# (See CI-CD-INTEGRATION.md)

# 5. Commit
git add Smith/ CLAUDE.md .smith-sync-manifest.json
git commit -m "chore: upgrade Smith framework to v1.1.0"
```

---

## Future Versions (Planned)

### v1.2.0 (Planned: December 2025)

**Planned Features:**
- Networking patterns guide
- Error handling decision trees
- SwiftData/CoreData persistence patterns
- watchOS platform support
- Enhanced metrics dashboard

**Breaking Changes:** None expected

---

### v2.0.0 (Planned: Q1 2026)

**Potential Breaking Changes:**
- TCA 2.0 requirement (if released)
- Swift 7.0 strict concurrency changes
- Deprecation of v1.0 patterns (with migration guide)
- Framework structure reorganization

**Migration Guide:** Will be comprehensive with automated tools

---

## Deprecation Policy

### How We Deprecate Patterns

1. **Announce in Release Notes**
   - Pattern marked as deprecated in documentation
   - Alternative pattern provided
   - Deprecation date set (minimum 3 months)

2. **Update Enforcement Levels**
   - STANDARD → GUIDANCE (soft deprecation)
   - Warnings added to compliance checker

3. **Migration Period (3-6 months)**
   - Both old and new patterns documented
   - Projects can migrate at their own pace
   - Migration guide provided

4. **Removal in Next MAJOR Version**
   - Old pattern removed from docs
   - Compliance checker treats as violation
   - Projects must migrate to upgrade

### Example Deprecation Timeline

```
v1.1.0 (Nov 2025)  - Pattern X marked deprecated, Pattern Y recommended
v1.2.0 (Dec 2025)  - Both patterns documented, warnings issued
v1.3.0 (Jan 2026)  - Final migration reminders
v2.0.0 (Mar 2026)  - Pattern X removed, only Pattern Y supported
```

---

## How to Propose Version Changes

### For Framework Maintainers

**PATCH Release:**
```bash
# Fix bug, commit
git commit -m "fix: correct typo in QUICK-START.md"

# Tag
git tag v1.1.1
git push --tags

# Update VERSIONING.md
```

**MINOR Release:**
```bash
# Add feature, commit
git commit -m "feat: add networking patterns guide"

# Tag
git tag v1.2.0
git push --tags

# Update VERSIONING.md with migration notes if needed
```

**MAJOR Release:**
```bash
# Make breaking change, commit
git commit -m "feat!: require TCA 2.0 (BREAKING CHANGE)"

# Create migration guide in MIGRATIONS/
# Update VERSIONING.md

# Tag
git tag v2.0.0
git push --tags
```

---

## Version Compatibility Matrix

| Smith Version | Swift Version | TCA Version | Xcode Version | Platforms |
|---------------|---------------|-------------|---------------|-----------|
| v1.0.0 - v1.1.x | 6.2+ | 1.23.0+ | 16.0+ | macOS 14+, iOS 17+, iPadOS 17+, visionOS 2.0+ |
| v1.2.x (planned) | 6.2+ | 1.23.0+ | 16.0+ | + watchOS 11+ |
| v2.0.x (future) | 7.0+ | 2.0+ | 17.0+ | TBD |

---

## Branching Strategy

### Main Branch
- **`master`** - Always contains latest stable release
- Tagged with version numbers (v1.0.0, v1.1.0, etc.)

### Development
- **`develop`** - Next minor version in progress
- Feature branches: `feature/networking-patterns`
- Discovery branches: `discovery/12-state-sync`

### Releases
- **`release/v1.2.0`** - Release candidate branches
- Merged to master when ready
- Tagged after merge

### Hotfixes
- **`hotfix/v1.1.1`** - Critical bug fixes
- Merged to master and develop
- Tagged immediately

---

## Changelog Format

All changes documented in EVOLUTION.md using this format:

```markdown
### Discovery N: Title (Date)

**Problem:** What was broken or missing
**Solution:** What was added/changed
**Impact:** What projects need to do
**Version:** When this was added (v1.X.Y)
**Migration Required:** Yes/No
**Breaking Change:** Yes/No

**Citations:**
- Document lines updated
- Related discoveries

**References:**
- Point-Free blog posts
- Apple documentation
- GitHub issues
```

---

## FAQ

### Q: How often should I upgrade?

**A:**
- **PATCH releases:** Optional, upgrade when convenient
- **MINOR releases:** Every 1-2 releases (stay within 2 versions)
- **MAJOR releases:** Required if you want new features

### Q: Can I stay on v1.0 forever?

**A:** Yes, but:
- No new features
- No new discoveries
- Security/bug fixes only in PATCH releases
- Eventually unsupported (deprecated)

### Q: What if I have local customizations?

**A:** smith-sync.sh handles this:
- CLAUDE.md merges intelligently
- Smith/ files overwritten (as designed)
- Keep customizations in project files, not Smith/

### Q: Do I need to sync immediately after Smith updates?

**A:** No, sync when:
- You need a new pattern
- You hit a bug covered by a DISCOVERY
- You're starting a new feature
- During quarterly maintenance

### Q: How do I know if a sync will break my code?

**A:** Check:
1. VERSIONING.md "Breaking Changes" section
2. MAJOR version bump (v1.x → v2.0)
3. Migration guide exists (MIGRATIONS/v1-to-v2.md)

---

## Version Support Policy

| Version | Status | Support Until | Updates |
|---------|--------|---------------|---------|
| v1.1.x | Current | Indefinite | All updates |
| v1.0.x | Maintenance | v2.0 release | Security + critical bugs only |
| v0.x | Deprecated | N/A | None |

---

## Contact & Feedback

Questions about versioning?
- Check VERSIONING.md (this file)
- Review EVOLUTION.md for change history
- Check .smith-sync-manifest.json for your current version

---

**Last Updated:** November 10, 2025
**Current Stable Version:** v1.1.0
**Next Planned Release:** v1.2.0 (December 2025)
