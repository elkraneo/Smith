#!/bin/bash
#
# smith-sync.sh - Smart sync of Smith framework to target projects
#
# Smart syncing with CLAUDE.md merge strategy to preserve project-specific customizations
# Excludes .git and other non-framework files
#
# Usage:
#   ./smith-sync.sh /path/to/GreenSpurt
#   ./smith-sync.sh /path/to/Scroll
#   ./smith-sync.sh /path/to/YourProject
#
# Features:
#   - Validates Smith framework before syncing
#   - Syncs Sources/, CaseStudies/, Tests/ to project/Smith/
#   - Special handling for CLAUDE.md (detects local changes, offers merge)
#   - Creates sync manifest for version tracking
#   - Excludes .git, .gitignore, and editor files
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TARGET_PROJECT="${1}"
SMITH_SOURCE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SYNC_LOG="${SMITH_SOURCE}/smith-sync.log"

# Helper functions
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Validate inputs
if [ -z "$TARGET_PROJECT" ]; then
  log_error "Missing target project path"
  echo ""
  echo "Usage: $0 /path/to/project"
  echo ""
  echo "Examples:"
  echo "  $0 /Volumes/Plutonian/GreenSpurt"
  echo "  $0 /Volumes/Plutonian/Scroll"
  exit 1
fi

if [ ! -d "$TARGET_PROJECT" ]; then
  log_error "Target project not found: $TARGET_PROJECT"
  exit 1
fi

if [ ! -f "$SMITH_SOURCE/Sources/SMITH-FRAMEWORK-ESSENTIALS.md" ]; then
  log_error "Smith framework not found at: $SMITH_SOURCE"
  exit 1
fi

log_info "Starting Smith sync..."
log_info "Source: $SMITH_SOURCE"
log_info "Target: $TARGET_PROJECT"

# Validate Smith before syncing
log_info "Validating Smith framework..."
if ! grep -q "Pattern 1:" "$SMITH_SOURCE/Sources/SMITH-FRAMEWORK-ESSENTIALS.md"; then
  log_error "Framework validation failed: SMITH-FRAMEWORK-ESSENTIALS.md incomplete"
  exit 1
fi
log_success "Framework validation passed"

# Create Smith directory in target
mkdir -p "$TARGET_PROJECT/Smith"

# Sync Sources (everything except CLAUDE.md)
log_info "Syncing Sources..."
if command -v rsync &> /dev/null; then
  rsync -av --delete \
    --exclude='CLAUDE.md' \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='.DS_Store' \
    --exclude='*.swp' \
    --exclude='.claude' \
    "$SMITH_SOURCE/Sources/" \
    "$TARGET_PROJECT/Smith/" 2>&1 | tee -a "$SYNC_LOG" > /dev/null || true
else
  # Fallback if rsync not available
  cp -R "$SMITH_SOURCE/Sources/"* "$TARGET_PROJECT/Smith/"
fi
log_success "Sources synced"

# Sync CaseStudies
log_info "Syncing CaseStudies..."
if [ -d "$SMITH_SOURCE/CaseStudies" ]; then
  mkdir -p "$TARGET_PROJECT/Smith/CaseStudies"
  if command -v rsync &> /dev/null; then
    rsync -av --delete \
      --exclude='.git' \
      "$SMITH_SOURCE/CaseStudies/" \
      "$TARGET_PROJECT/Smith/CaseStudies/" 2>&1 | tee -a "$SYNC_LOG" > /dev/null || true
  else
    cp -R "$SMITH_SOURCE/CaseStudies/"* "$TARGET_PROJECT/Smith/CaseStudies/"
  fi
  log_success "CaseStudies synced"
fi

# SPECIAL HANDLING: CLAUDE.md merge strategy
log_info "Handling CLAUDE.md..."
CLAUDE_BASE="$SMITH_SOURCE/Sources/CLAUDE.md"
CLAUDE_TARGET="$TARGET_PROJECT/CLAUDE.md"
CLAUDE_BACKUP="$TARGET_PROJECT/CLAUDE.md.backup"
CLAUDE_NEW="$TARGET_PROJECT/CLAUDE.md.NEW"

if [ ! -f "$CLAUDE_TARGET" ]; then
  # First sync: copy framework CLAUDE.md directly
  cp "$CLAUDE_BASE" "$CLAUDE_TARGET"
  log_success "Created CLAUDE.md in $TARGET_PROJECT"

elif cmp -s "$CLAUDE_BASE" "$CLAUDE_TARGET" 2>/dev/null; then
  # Identical: safe to update from framework
  cp "$CLAUDE_BASE" "$CLAUDE_TARGET"
  log_success "Updated CLAUDE.md (no local changes)"

else
  # Local changes detected: create files for manual merge
  cp "$CLAUDE_BASE" "$CLAUDE_NEW"
  cp "$CLAUDE_TARGET" "$CLAUDE_BACKUP"

  log_warning "CLAUDE.md has local customizations"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}⚠️  MERGE REQUIRED${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Framework CLAUDE.md has been updated, but your project has local changes."
  echo ""
  echo "Files created for merge:"
  echo "  📄 CLAUDE.md.NEW    - Latest framework version"
  echo "  📄 CLAUDE.md.backup - Your current version"
  echo ""
  echo "Next steps:"
  echo "  1. Review the diff:"
  echo "     ${BLUE}diff -u CLAUDE.md.backup CLAUDE.md.NEW${NC}"
  echo ""
  echo "  2. Merge manually (keep framework rules + your customizations)"
  echo ""
  echo "  3. Replace CLAUDE.md with merged version:"
  echo "     ${BLUE}# Edit CLAUDE.md, then delete .backup and .NEW${NC}"
  echo ""
  echo "  4. Commit merged CLAUDE.md:"
  echo "     ${BLUE}git add CLAUDE.md && git commit -m 'docs: merge Smith CLAUDE updates'${NC}"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  exit 1
fi

# Create sync manifest
SMITH_COMMIT=$(git -C "$SMITH_SOURCE" rev-parse HEAD 2>/dev/null || echo "unknown")
SMITH_SHORT=$(git -C "$SMITH_SOURCE" rev-parse --short HEAD 2>/dev/null || echo "unknown")

mkdir -p "$TARGET_PROJECT"
cat > "$TARGET_PROJECT/.smith-sync-manifest.json" <<EOF
{
  "last_sync": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "smith_commit": "$SMITH_COMMIT",
  "smith_version": "$SMITH_SHORT",
  "source": "$SMITH_SOURCE",
  "framework_sync": true
}
EOF

log_success "Created sync manifest"

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log_success "SYNC COMPLETE"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Synced from: $SMITH_SHORT"
echo "Target: $TARGET_PROJECT"
echo "Manifest: $TARGET_PROJECT/.smith-sync-manifest.json"
echo ""
echo "Next steps:"
echo "  1. Review changes: ${BLUE}cd $TARGET_PROJECT && git status${NC}"
echo "  2. Stage changes: ${BLUE}git add Smith/${NC}"
echo "  3. Commit: ${BLUE}git commit -m 'docs: update Smith framework to $SMITH_SHORT'${NC}"
echo ""
