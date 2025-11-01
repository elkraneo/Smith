# Smith Framework Sync Strategy

**Implemented:** November 1, 2025

## Problem Solved

Projects using Smith framework need to be:
1. **Portable** - Work in any environment without hard-coded paths
2. **In sync** - Reflect latest framework updates automatically
3. **Collaborative** - Allow colleagues to clone and work without setup

The previous approach (relative paths to canonical Smith location) broke when projects were cloned in different environments because the canonical Smith folder structure didn't exist.

## Solution: Embedded Copies + Automated Sync

Each project now has:
- ✅ **Embedded copy** of complete Smith framework in `./Smith/` directory
- ✅ **GitHub Actions workflow** that automatically syncs with canonical Smith weekly
- ✅ **Local file references** in AGENTS.md (always portable)
- ✅ **.gitignore safeguards** preventing manual edits to Smith/

## Architecture

```
Canonical Smith (source of truth)
    ↓ (automated sync via GitHub Actions)
├── GreenSpurt/Smith/ (embedded copy)
├── Scroll/Smith/ (embedded copy)
└── (any future projects)
```

## How It Works

### For Developers

1. Clone any project (GreenSpurt, Scroll, etc.)
2. Read AGENTS.md for framework guidance (local paths work everywhere)
3. Smith framework docs are already included and up-to-date

```bash
git clone https://github.com/Reality2713/escape-space.git
cd escape-space
open Smith/AGENTS-FRAMEWORK.md  # Works immediately
```

### For Framework Updates

1. Update canonical Smith at `/Volumes/Plutonian/_Developer/Smith/Sources/`
2. Push to https://github.com/elkraneo/Smith
3. GitHub Actions workflows in GreenSpurt and Scroll automatically:
   - Run weekly (Mondays at 00:00 UTC)
   - Can be triggered manually via GitHub Actions tab
   - Create PR if changes detected
   - Developers review and merge

## File Structure

### GreenSpurt
```
GreenSpurt/
├── .github/workflows/sync-smith-framework.yml  (automation)
├── .gitignore  (safeguards + notes)
├── AGENTS.md  (updated to use ./Smith/)
└── Smith/  (embedded framework)
    ├── AGENTS-*.md  (13 framework documents)
    ├── PLATFORM-*.md  (4 platform guides)
    └── Tests/  (evaluation tools)
```

### Scroll
```
Scroll/source/Scroll/
├── .github/workflows/sync-smith-framework.yml  (automation)
├── .gitignore  (safeguards + notes)
├── AGENTS.md  (updated to use ./Smith/)
└── Smith/  (embedded framework)
    ├── AGENTS-*.md  (13 framework documents)
    ├── PLATFORM-*.md  (4 platform guides)
    └── Tests/  (evaluation tools)
```

## GitHub Actions Workflow Details

**File:** `.github/workflows/sync-smith-framework.yml`

**Triggers:**
- Manual: Via GitHub Actions UI ("Run workflow" button)
- Scheduled: Weekly (every Monday at 00:00 UTC)

**What it does:**
1. Checks out project and Smith repository
2. Copies latest Smith/Sources/* → project/Smith/
3. Checks for changes
4. If changes exist:
   - Commits with message: "chore: sync Smith framework to latest"
   - Creates pull request with details
   - Developers review and merge

**Advantages:**
- ✅ No manual intervention needed
- ✅ Creates audit trail (PRs show what changed)
- ✅ Developers must explicitly approve updates
- ✅ Can be triggered immediately when needed
- ✅ Works with GitHub's native GITHUB_TOKEN (no secrets needed)

## Sync Status

| Project | Status | Last Sync | Files |
|---------|--------|-----------|-------|
| GreenSpurt | ✅ Embedded | Nov 1, 2025 | 13 docs |
| Scroll | ✅ Embedded | Nov 1, 2025 | 13 docs |

## Manual Sync Commands (for local development)

If you need to manually sync locally before pushing:

```bash
# From /Volumes/Plutonian/
cp -r _Developer/Smith/Sources/* GreenSpurt/Smith/
cp -r _Developer/Smith/Sources/* _Developer/Scroll/source/Scroll/Smith/

# Then commit and push
cd GreenSpurt && git add Smith/ && git commit -m "chore: sync Smith framework"
```

## Preventing Accidental Edits

Both projects have `.gitignore` comments:

```
# Smith Framework - AUTO-SYNCED
# Do not manually edit Smith/ directory
# It is kept in sync via GitHub Actions workflow
# To update Smith framework: update canonical Smith repo, then this will auto-sync
```

And comments in files warn that edits will be overwritten on next sync.

## Future Projects

When adding a new project that uses Smith framework:

1. Create `.github/workflows/sync-smith-framework.yml` (copy from GreenSpurt or Scroll)
2. Embed Smith: `cp -r /Volumes/Plutonian/_Developer/Smith/Sources/ ./Smith/`
3. Update AGENTS.md: `[./Smith/AGENTS-FRAMEWORK.md]` (local references)
4. Add .gitignore comment about Smith/
5. Commit and push
6. Workflow will auto-sync weekly thereafter

## Benefits

✅ **Portable** - Works in any environment, no hard-coded paths
✅ **Collaborative** - Colleagues clone and work immediately
✅ **Maintainable** - Single source of truth (canonical Smith)
✅ **Automated** - Weekly syncs, no manual intervention
✅ **Auditable** - PRs show framework changes
✅ **Safe** - Developers review updates before merging
✅ **Offline** - Projects work completely offline after clone

## Troubleshooting

### Workflow doesn't run

Check `.github/workflows/sync-smith-framework.yml` exists in project root.

### Changes not syncing

1. Manual trigger: Go to GitHub Actions tab → "Sync Smith Framework" → "Run workflow"
2. Or wait for Monday 00:00 UTC (weekly schedule)

### Need immediate sync

```bash
# Manual from your machine
cp -r /Volumes/Plutonian/_Developer/Smith/Sources/* ./Smith/
git add Smith/
git commit -m "chore: sync Smith framework"
git push
```

### Merge conflicts on sync PR

Unlikely (we're only copying docs), but if it happens:
1. Pull latest main: `git pull origin main`
2. Rebase workflow: `git rebase -i origin/main`
3. Take all incoming changes (workflow version is correct)
4. Merge PR

## Next Steps

- Monitor first weekly sync (November 8, 2025)
- Verify PRs are created and mergeable
- Add note to Smith README about embedded copies in dependent projects

## References

- **Canonical Smith:** `/Volumes/Plutonian/_Developer/Smith`
- **Smith Repository:** https://github.com/elkraneo/Smith
- **GreenSpurt:** https://github.com/Reality2713/escape-space
- **Scroll:** https://github.com/elkraneo/Scroll
