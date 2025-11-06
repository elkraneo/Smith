#!/bin/bash
#
# validate-smith.sh - Validate Smith framework before syncing
#
# Checks that framework docs are complete and consistent before syncing to projects
#
# Usage:
#   ./validate-smith.sh
#   ./validate-smith.sh --strict   (fail on any warning)
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SMITH_SOURCE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
STRICT_MODE="${1}"
WARNINGS=0
ERRORS=0

log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
  ((WARNINGS++))
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
  ((ERRORS++))
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "🔍 Validating Smith Framework"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check essential documents exist
log_info "Checking essential documents..."

DOCS=(
  "Sources/SMITH-FRAMEWORK-ESSENTIALS.md"
  "Sources/CLAUDE.md"
  "Sources/AGENTS-TCA-PATTERNS.md"
  "Sources/AGENTS-AGNOSTIC.md"
)

for doc in "${DOCS[@]}"; do
  if [ -f "$SMITH_SOURCE/$doc" ]; then
    log_success "$doc exists"
  else
    log_error "$doc MISSING"
  fi
done

# Check SMITH-FRAMEWORK-ESSENTIALS.md content
log_info "Validating SMITH-FRAMEWORK-ESSENTIALS.md..."
ESSENTIALS="$SMITH_SOURCE/Sources/SMITH-FRAMEWORK-ESSENTIALS.md"

if grep -q "Pattern 1:" "$ESSENTIALS" && \
   grep -q "Pattern 2:" "$ESSENTIALS" && \
   grep -q "Pattern 3:" "$ESSENTIALS" && \
   grep -q "Pattern 4:" "$ESSENTIALS" && \
   grep -q "Pattern 5:" "$ESSENTIALS"; then
  log_success "All 5 patterns present"
else
  log_error "Not all 5 patterns found in essentials"
fi

if grep -q "Red Flags" "$ESSENTIALS"; then
  log_success "Red flags section present"
else
  log_warning "Red flags section missing"
fi

if grep -q "Verification" "$ESSENTIALS"; then
  log_success "Verification checklists present"
else
  log_warning "Verification checklists missing"
fi

# Check DISCOVERY case studies
log_info "Checking DISCOVERY case studies..."
DISCOVERIES=(
  "CaseStudies/DISCOVERY-4-POPOVER-ENTITY-GAP.md"
  "CaseStudies/DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md"
  "CaseStudies/DISCOVERY-6-IFLET-CLOSURE-REQUIREMENT.md"
)

for discovery in "${DISCOVERIES[@]}"; do
  if [ -f "$SMITH_SOURCE/$discovery" ]; then
    LINES=$(wc -l < "$SMITH_SOURCE/$discovery")
    log_success "$discovery ($LINES lines)"
  else
    log_warning "$discovery not found"
  fi
done

# Check markdown syntax (if markdownlint available)
log_info "Checking markdown syntax..."
if command -v markdownlint &> /dev/null; then
  if markdownlint "$SMITH_SOURCE/Sources/SMITH-FRAMEWORK-ESSENTIALS.md" \
                  "$SMITH_SOURCE/Sources/CLAUDE.md" 2>&1 | grep -q "error"; then
    log_warning "Markdown syntax issues found (non-critical)"
  else
    log_success "Markdown syntax valid"
  fi
else
  log_info "markdownlint not installed (skipping syntax check)"
fi

# Check for broken links/references
log_info "Checking internal references..."

if grep -q "AGENTS-TCA-PATTERNS.md" "$ESSENTIALS"; then
  log_success "AGENTS-TCA-PATTERNS referenced"
fi

if grep -q "DISCOVERY-" "$ESSENTIALS"; then
  log_success "DISCOVERY case studies referenced"
fi

# Check git status
log_info "Checking git status..."
if [ -d "$SMITH_SOURCE/.git" ]; then
  UNCOMMITTED=$(git -C "$SMITH_SOURCE" status --porcelain | wc -l)
  if [ "$UNCOMMITTED" -eq 0 ]; then
    log_success "All changes committed"
  else
    log_warning "Uncommitted changes: $UNCOMMITTED files"
  fi

  UNPUSHED=$(git -C "$SMITH_SOURCE" rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
  if [ "$UNPUSHED" -eq 0 ]; then
    log_success "All commits pushed"
  else
    log_warning "Unpushed commits: $UNPUSHED"
  fi
else
  log_info "Not a git repository (local testing)"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $ERRORS -eq 0 ]; then
  if [ $WARNINGS -eq 0 ]; then
    log_success "ALL VALIDATIONS PASSED"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Framework is ready to sync to projects."
    echo ""
    echo "Next: ${BLUE}./smith-sync.sh /path/to/project${NC}"
    echo ""
    exit 0
  else
    log_warning "VALIDATIONS PASSED WITH $WARNINGS WARNINGS"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Framework validation passed but with warnings."

    if [ "$STRICT_MODE" == "--strict" ]; then
      echo "Strict mode enabled: treating warnings as errors."
      exit 1
    fi

    echo "Review warnings above and fix if needed."
    echo ""
    echo "You can still sync with: ${BLUE}./smith-sync.sh /path/to/project${NC}"
    echo "Or use strict mode: ${BLUE}./validate-smith.sh --strict${NC}"
    echo ""
    exit 0
  fi
else
  log_error "VALIDATION FAILED - $ERRORS ERROR(S), $WARNINGS WARNING(S)"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Fix the errors above before syncing to projects."
  echo ""
  exit 1
fi
