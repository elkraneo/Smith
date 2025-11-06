# Smith Framework Sync Scripts

Production-ready scripts for distributing the Smith framework to multiple projects.

---

## Quick Start

### First Time (Initialize a Project)

```bash
/path/to/Smith/Scripts/smith-sync.sh /path/to/YourProject
```

This:
1. ✅ Validates Smith framework
2. ✅ Copies framework to `YourProject/Smith/`
3. ✅ Creates `YourProject/CLAUDE.md` (root level)
4. ✅ Creates version manifest

Then in your project:
```bash
git add Smith/ CLAUDE.md .smith-sync-manifest.json
git commit -m "docs: add Smith framework v1.1"
```

### Regular Updates

When Smith framework is updated:

```bash
/path/to/Smith/Scripts/smith-sync.sh /path/to/YourProject
git add Smith/ CLAUDE.md
git commit -m "docs: update Smith framework"
```

If `CLAUDE.md` has local changes, script will create merge files and guide you.

---

## Scripts

### `smith-sync.sh`

Smart sync script with CLAUDE.md merge strategy.

**Features:**
- ✅ Validates framework before syncing
- ✅ Copies Sources/ → Project/Smith/
- ✅ Copies CaseStudies/ → Project/Smith/CaseStudies/
- ✅ Special handling for CLAUDE.md (detects local changes)
- ✅ Creates .smith-sync-manifest.json for version tracking
- ✅ Colored output with clear next steps

**Usage:**
```bash
./smith-sync.sh /path/to/project
```

**What it syncs:**
```
✅ Sources/*.md (framework docs)
✅ CaseStudies/*.md (case studies)
✅ Tests/*.md (submission templates)
⏸️  CLAUDE.md (special merge handling)
❌ .git/ (independent repos)
```

### `validate-smith.sh`

Pre-sync validation of framework completeness.

**Features:**
- ✅ Checks all documents exist
- ✅ Validates content (5 patterns, red flags, etc.)
- ✅ Checks git status (clean, committed, pushed)
- ✅ Optional --strict mode (fail on warnings)

**Usage:**
```bash
./validate-smith.sh              # Normal (warnings OK)
./validate-smith.sh --strict     # Strict (warnings fail)
```

---

## How CLAUDE.md Merge Works

### Scenario 1: No Local Changes
```
Framework updates CLAUDE.md
  ↓
Script detects identical content
  ↓
Overwrites with framework version
  ✅ Just commit
```

### Scenario 2: Local Customizations Exist
```
Framework updates CLAUDE.md
  AND
Project has added local customizations
  ↓
Script detects conflict
  ↓
Creates:
  - CLAUDE.md.NEW (framework version)
  - CLAUDE.md.backup (your version)
  ↓
You merge manually:
  - Keep framework rules from .NEW
  - Keep project customizations from .backup
  ↓
Replace CLAUDE.md with merged version
Commit merged CLAUDE.md
```

**Merge instructions:**
```bash
# Review the diff
diff -u CLAUDE.md.backup CLAUDE.md.NEW

# Merge manually (edit to combine both)
cat CLAUDE.md.backup CLAUDE.md.NEW > /tmp/merged.txt
# ... edit /tmp/merged.txt in your editor
cp /tmp/merged.txt CLAUDE.md

# Verify and commit
git add CLAUDE.md
git commit -m "docs: merge Smith CLAUDE updates + project customizations"

# Clean up
rm CLAUDE.md.backup CLAUDE.md.NEW
```

---

## Configuration

### What Gets Synced
See `SYNC-MANIFEST.md` for complete list.

### Excluding Files
In `.gitignore`:
```
smith-sync.log           # Sync log
CLAUDE.md.NEW            # Merge temporary
CLAUDE.md.backup         # Merge temporary
.smith-sync-*.tmp        # Sync temp files
```

### Customizing CLAUDE.md
See `CLAUDE-PROJECT-TEMPLATE.md` for examples.

---

## Troubleshooting

### Script Not Found
```bash
cd /path/to/Smith  # NOT a project directory
./Scripts/smith-sync.sh /path/to/project
```

### Permission Denied
```bash
chmod +x Scripts/smith-sync.sh Scripts/validate-smith.sh
```

### Validation Fails
```bash
cd /path/to/Smith
./Scripts/validate-smith.sh
# Fix issues shown, then try sync again
```

### CLAUDE.md Won't Merge
```bash
# If you want framework version only
cp CLAUDE.md.NEW CLAUDE.md
rm CLAUDE.md.backup CLAUDE.md.NEW
git add CLAUDE.md
git commit -m "docs: accept Smith CLAUDE update"
```

---

## For Multiple Projects

Sync all at once:

```bash
#!/bin/bash
SMITH_DIR="/path/to/Smith"
PROJECTS=(
  "/path/to/GreenSpurt"
  "/path/to/Scroll"
  "/path/to/YourProject"
)

echo "Validating Smith..."
$SMITH_DIR/Scripts/validate-smith.sh || exit 1

for project in "${PROJECTS[@]}"; do
  echo "Syncing $project..."
  $SMITH_DIR/Scripts/smith-sync.sh "$project"
done

echo "✅ Done"
```

---

## How This Works (Design)

### Why Not Git Submodule?

Git submodules would require:
- Special `git clone --recursive`
- Locked version (stale in some projects)
- Complex update workflow

Instead, this approach:
- ✅ Simple shell scripts (everyone has bash)
- ✅ Each project controls update timing
- ✅ Preserves local customizations (CLAUDE.md merge)
- ✅ Clear audit trail (sync manifest)

### Why CLAUDE.md Special?

`CLAUDE.md` lives at project root (not in `Smith/`):
- ✅ Agents find it immediately
- ✅ Each project can customize for local needs
- ✅ Framework updates automatically (smart merge)
- ✅ Conflicts detected and handled

### Version Tracking

`.smith-sync-manifest.json` created after each sync:
```json
{
  "last_sync": "2025-11-06T13:34:56Z",
  "smith_commit": "4ad79a3abc123...",
  "smith_version": "4ad79a3"
}
```

This tracks which framework version each project is using.

---

## References

- **SYNC-MANIFEST.md** - Full distribution tracking & documentation
- **CLAUDE-PROJECT-TEMPLATE.md** - How to customize CLAUDE.md
- **SMITH-FRAMEWORK-ESSENTIALS.md** - Core patterns (what gets synced)

---

**Sync Scripts Version:** 1.0
**Framework Version:** v1.1+
**Last Updated:** November 6, 2025
