# Smith Framework Sync Manifest

This file tracks distribution of the Smith framework to projects.

**Last Updated:** 2025-11-06
**Framework Version:** v1.1+
**Latest Sync Commit:** e85e0e3
**Synced Projects:** 2/2 (GreenSpurt + Scroll)

---

## Synced Projects

| Project | Location | Last Sync | Smith Commit | Status |
|---------|----------|-----------|--------------|--------|
| GreenSpurt | `/Volumes/Plutonian/GreenSpurt` | 2025-11-06 13:36 UTC | 5a6c006 | ✅ Current |
| Scroll | `/Volumes/Plutonian/_Developer/Scroll/source/Scroll` | 2025-11-06 13:40 UTC | e85e0e3 | ✅ Current |
| Your Project | - | - | - | ⏳ To Be Synced |

---

## What Gets Synced

### ✅ Synced (Overwritten on Update)

```
Smith/
├── SMITH-FRAMEWORK-ESSENTIALS.md
├── CLAUDE-PROJECT-TEMPLATE.md
├── AGENTS-TCA-PATTERNS.md
├── AGENTS-AGNOSTIC.md
├── AGENTS-DECISION-TREES.md
├── AGENTS-FRAMEWORK.md
├── AGENTS-*.md (all AGENTS documents)
├── PLATFORM-*.md (all platform guides)
├── Tests/
│   ├── DISCOVERY-SUBMISSION-TEMPLATE.md
│   ├── DISCOVERY-EVALUATION-CHECKLIST.md
│   ├── AGENTS-*.md (submission templates)
│   └── README.md
└── CaseStudies/
    ├── DISCOVERY-4-POPOVER-ENTITY-GAP.md
    ├── DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md
    ├── DISCOVERY-6-IFLET-CLOSURE-REQUIREMENT.md
    └── README.md
```

### ⏸️ Handled Specially (Smart Merge)

```
Project/CLAUDE.md
- Framework base synced automatically
- Project customizations preserved
- Conflict detection if both sides change
- Manual merge workflow provided
```

### ❌ NOT Synced (Project-Specific)

```
.git/                 - Independent repositories
.gitignore            - Project-specific ignores
.DS_Store             - Editor files
Scripts/              - In Smith, not synced (projects have own)
.claude/              - Local Claude settings
smith-sync.log        - Local sync logs
CLAUDE.md.backup      - Merge temporary files
CLAUDE.md.NEW         - Merge temporary files
```

---

## How to Sync

### Quick Start (First Time)

```bash
cd /path/to/your/project
/path/to/Smith/Scripts/smith-sync.sh .
```

This:
1. ✅ Validates Smith framework
2. ✅ Copies Sources/ → Smith/
3. ✅ Copies CaseStudies/ → Smith/CaseStudies/
4. ✅ Creates/updates CLAUDE.md (root level)
5. ✅ Creates .smith-sync-manifest.json

Then in your project:
```bash
git add Smith/ CLAUDE.md .smith-sync-manifest.json
git commit -m "docs: add Smith framework v1.1 (commit 573fc84)"
```

### Regular Updates

When Smith framework updates (new patterns, DISCOVERY cases):

```bash
cd /path/to/your/project

# Run sync script from Smith root
/path/to/Smith/Scripts/smith-sync.sh .

# If CLAUDE.md has no conflicts:
git add Smith/ CLAUDE.md
git commit -m "docs: update Smith framework"

# If CLAUDE.md has conflicts:
# Script will create CLAUDE.md.NEW and CLAUDE.md.backup
# Merge manually following the script's instructions
```

### Pre-Sync Validation

Before syncing to multiple projects, validate the framework:

```bash
cd /path/to/Smith
./Scripts/validate-smith.sh

# Or strict mode (fail on any warning)
./Scripts/validate-smith.sh --strict
```

---

## Sync Strategy Explained

### Why Scripts Are Not Submodules

Smith isn't a git submodule because:
- ✅ Each project controls when to update (no dependency locking)
- ✅ Projects can have local customizations (CLAUDE.md merge strategy)
- ✅ Framework changes don't require special git commands
- ✅ Easier to review what changed in each sync
- ✅ No "submodule update" confusion

### Why CLAUDE.md Is Special

CLAUDE.md lives at project root (not in Smith/) because:
- ✅ Agents find it immediately (not buried in subdirectory)
- ✅ Each project can customize it (visionOS vs iOS specific notes)
- ✅ Framework updates automatically (smart merge strategy)
- ✅ No conflicts forced (merge only if both sides change)

### Why .smith-sync-manifest.json

Created after each sync to track:
```json
{
  "last_sync": "2025-11-06T12:34:56Z",
  "smith_commit": "573fc84abc123...",
  "smith_version": "573fc84",
  "source": "/path/to/Smith"
}
```

Helps you:
- Know which framework version you're running
- Audit when last update was
- Debug mismatches between projects

---

## Merging CLAUDE.md Changes

### Scenario 1: No Local Changes
```
Framework updates CLAUDE.md
  ↓
Script detects no local changes
  ↓
Overwrites with framework version
  ✅ Done, just commit
```

### Scenario 2: Local Customizations Exist
```
Framework updates CLAUDE.md
  AND
Project has added local customizations
  ↓
Script detects conflict
  ↓
Creates CLAUDE.md.NEW (framework)
Creates CLAUDE.md.backup (your version)
  ↓
You manually merge:
  - Keep framework rules from .NEW
  - Keep project notes from .backup
  ↓
Replace CLAUDE.md with merged version
Remove .NEW and .backup
Commit merged CLAUDE.md
```

### Example Merge

```bash
# Script ran, detected conflict
# Review changes
diff -u CLAUDE.md.backup CLAUDE.md.NEW

# Merge: Keep framework patterns + your customizations
# Option 1: Manual edit
cat CLAUDE.md.backup CLAUDE.md.NEW > /tmp/merged.txt
# ... edit /tmp/merged.txt in editor
cp /tmp/merged.txt CLAUDE.md

# Option 2: Take framework, re-add your customizations
cp CLAUDE.md.NEW CLAUDE.md
# ... manually add project-specific sections

# Verify and commit
git add CLAUDE.md
git commit -m "docs: merge Smith CLAUDE updates + project customizations"

# Clean up
rm CLAUDE.md.backup CLAUDE.md.NEW
```

---

## Sync Workflow Diagram

```
Your Project (GreenSpurt)
        ↑
        │ (smith-sync.sh copies framework)
        │
     Smith ← Agents make improvements (DISCOVERY cases, patterns)
        │
        ├─→ GreenSpurt (syncs)
        ├─→ Scroll (syncs)
        └─→ Your Project (syncs)
```

---

## Troubleshooting

### Script Not Found
```bash
# Make sure you're running from Smith root, not a project
cd /path/to/Smith
./Scripts/smith-sync.sh /path/to/project
```

### Permission Denied
```bash
# Make scripts executable
chmod +x Scripts/smith-sync.sh Scripts/validate-smith.sh
```

### CLAUDE.md Won't Update
```bash
# Check if local changes exist
diff CLAUDE.md.backup CLAUDE.md.NEW

# If you want framework version only
cp CLAUDE.md.NEW CLAUDE.md
rm CLAUDE.md.backup CLAUDE.md.NEW
git add CLAUDE.md
git commit -m "docs: accept Smith CLAUDE update"
```

### Sync Script Fails Validation
```bash
# Run pre-sync validation
cd /path/to/Smith
./Scripts/validate-smith.sh

# Fix issues shown, then try sync again
./Scripts/smith-sync.sh /path/to/project
```

---

## For Multi-Project Teams

If you're syncing Smith to multiple projects:

```bash
#!/bin/bash
# sync-all-projects.sh - Sync Smith to all projects

SMITH_DIR="/path/to/Smith"
PROJECTS=(
  "/Volumes/Plutonian/GreenSpurt"
  "/Volumes/Plutonian/Scroll"
  "/path/to/YourProject"
)

echo "Validating Smith framework..."
$SMITH_DIR/Scripts/validate-smith.sh || exit 1

echo ""
for project in "${PROJECTS[@]}"; do
  echo "Syncing to $project..."
  $SMITH_DIR/Scripts/smith-sync.sh "$project"
  echo ""
done

echo "✅ All syncs complete"
echo "Next: Review changes in each project and commit"
```

---

## How to Get Started

### Step 1: First Sync

```bash
# In your project
/path/to/Smith/Scripts/smith-sync.sh .
```

### Step 2: Review & Commit

```bash
git status
git add Smith/ CLAUDE.md .smith-sync-manifest.json
git commit -m "docs: add Smith framework"
```

### Step 3: Read CLAUDE.md

```bash
# Your team reads the framework (with project customizations)
cat CLAUDE.md
```

### Step 4: Stay Updated

Periodically sync when Smith updates:

```bash
/path/to/Smith/Scripts/smith-sync.sh .
git add Smith/ CLAUDE.md
git commit -m "docs: update Smith framework"
```

---

## Contact & Feedback

Smith framework is living documentation. If you:
- 🆕 Discover a new pattern → Submit to Smith (DISCOVERY-SUBMISSION-TEMPLATE.md)
- 🐛 Find a bug caused by pattern violation → Document as DISCOVERY case
- ✨ Have improvements → Make a PR or discuss

This keeps the framework current for everyone.

---

**Framework Version:** v1.1+
**Sync Scripts Version:** 1.0
**Last Updated:** November 6, 2025
