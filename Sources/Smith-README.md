# ⚠️ Smith Framework - Auto-Managed

This directory is **automatically managed** by the Smith sync system.

```
smith-sync.sh → syncs → Smith/
```

**DO NOT EDIT FILES HERE** (they will be overwritten on next sync)

---

## What This Directory Contains

```
Smith/
├── SMITH-FRAMEWORK-ESSENTIALS.md  ← Read this (5 core patterns)
├── AGENTS-TCA-PATTERNS.md         ← Reference (deep dive)
├── AGENTS-AGNOSTIC.md             ← Reference (universal rules)
├── AGENTS-DECISION-TREES.md       ← Reference (decisions)
├── AGENTS-*.md                    ← Reference (other patterns)
├── PLATFORM-*.md                  ← Reference (iOS/macOS/visionOS)
├── CLAUDE-PROJECT-TEMPLATE.md     ← How to customize CLAUDE.md
├── CaseStudies/                   ← Real failure cases & solutions
├── Tests/                         ← Submission templates
└── README.md                      ← This file
```

---

## How to Work With This Framework

### Read These (Mandatory)

1. **SMITH-FRAMEWORK-ESSENTIALS.md** (5-minute read)
   - 5 core patterns
   - Red flags
   - Verification checklists

2. **../CLAUDE.md** (root level)
   - Your project's framework discipline rules
   - Where you add customizations
   - Smart-merged on updates

### Reference These (As Needed)

- **AGENTS-TCA-PATTERNS.md** - Deep dive on TCA patterns
- **AGENTS-AGNOSTIC.md** - Universal state/concurrency rules
- **PLATFORM-{iOS,macOS,visionOS}.md** - Platform-specific guidance
- **CaseStudies/DISCOVERY-*.md** - Learn from real bugs

---

## If You Need to Modify Patterns

**Don't edit Smith/ files.** Instead:

1. Submit a DISCOVERY case study: See `Smith/Tests/DISCOVERY-SUBMISSION-TEMPLATE.md`
2. Document the pattern gap you found
3. Reference your code examples
4. Submit to Smith repo
5. When merged, run sync to get the update

---

## Syncing Updates

When Smith framework improves (new patterns, DISCOVERY cases):

```bash
# From your project root
/path/to/Smith/Scripts/smith-sync.sh .
```

This:
- ✅ Validates Smith framework
- ✅ Updates all Smith/ files
- ✅ Merges CLAUDE.md intelligently
- ✅ Updates version manifest

---

## Version Info

Check `../.smith-sync-manifest.json` to see:
- Last sync date
- Smith commit version
- Source (Smith repo location)

---

## Structure Changed?

**Old structure (before v1.1):**
```
Smith/
├── Sources/AGENTS-*.md
├── Sources/PLATFORM-*.md
└── CaseStudies/
```

**New structure (v1.1+):**
```
Smith/
├── AGENTS-*.md (moved to root)
├── PLATFORM-*.md (moved to root)
├── SMITH-FRAMEWORK-ESSENTIALS.md (NEW)
├── CLAUDE-PROJECT-TEMPLATE.md (NEW)
└── CaseStudies/
```

If you synced from old structure, the sync script handles the migration automatically.

---

## Questions?

See:
- `../CLAUDE.md` - Framework discipline
- `/path/to/Smith/SYNC-MANIFEST.md` - Distribution tracking
- `/path/to/Smith/Scripts/README.md` - How sync works

---

**Auto-managed by smith-sync.sh**
**Last synced:** Check `../.smith-sync-manifest.json`
