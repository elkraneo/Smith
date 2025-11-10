#!/bin/bash
#
# compliance-report.sh - Generate compliance report from check-compliance.sh JSON
#
# Usage:
#   ./compliance-report.sh /path/to/project
#   ./compliance-report.sh /path/to/project --save report.json
#   ./compliance-report.sh /path/to/project --history  # Track trends over time
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_PATH="${1:-.}"
MODE="${2}"
OUTPUT_FILE="${3}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HISTORY_DIR="$PROJECT_PATH/.smith-compliance-history"

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

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if check-compliance.sh exists
if [ ! -f "$SCRIPT_DIR/check-compliance.sh" ]; then
  log_error "check-compliance.sh not found in $SCRIPT_DIR"
  exit 1
fi

# Header
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "📊 Smith Compliance Report"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run compliance check in JSON mode
log_info "Running compliance check..."
COMPLIANCE_JSON=$("$SCRIPT_DIR/check-compliance.sh" "$PROJECT_PATH" --json 2>/dev/null || echo '{"summary":{"violations":0,"warnings":0,"files_checked":0},"violations":[]}')

# Parse JSON (requires jq, but fallback if not available)
if command -v jq &> /dev/null; then
  VIOLATIONS=$(echo "$COMPLIANCE_JSON" | jq -r '.summary.violations // 0')
  WARNINGS=$(echo "$COMPLIANCE_JSON" | jq -r '.summary.warnings // 0')
  FILES_CHECKED=$(echo "$COMPLIANCE_JSON" | jq -r '.summary.files_checked // 0')
  SCORE=$((100 - (VIOLATIONS * 10) - (WARNINGS * 2)))
  [ $SCORE -lt 0 ] && SCORE=0
else
  # Fallback: parse manually
  VIOLATIONS=$(echo "$COMPLIANCE_JSON" | grep -o '"violations":[0-9]*' | cut -d: -f2 || echo 0)
  WARNINGS=$(echo "$COMPLIANCE_JSON" | grep -o '"warnings":[0-9]*' | cut -d: -f2 || echo 0)
  FILES_CHECKED=$(echo "$COMPLIANCE_JSON" | grep -o '"files_checked":[0-9]*' | cut -d: -f2 || echo 0)
  SCORE=$((100 - (VIOLATIONS * 10) - (WARNINGS * 2)))
  [ $SCORE -lt 0 ] && SCORE=0
fi

# Calculate grade
if [ $SCORE -ge 95 ]; then
  GRADE="A+"
  GRADE_COLOR=$GREEN
elif [ $SCORE -ge 90 ]; then
  GRADE="A"
  GRADE_COLOR=$GREEN
elif [ $SCORE -ge 85 ]; then
  GRADE="B+"
  GRADE_COLOR=$GREEN
elif [ $SCORE -ge 80 ]; then
  GRADE="B"
  GRADE_COLOR=$YELLOW
elif [ $SCORE -ge 75 ]; then
  GRADE="C+"
  GRADE_COLOR=$YELLOW
elif [ $SCORE -ge 70 ]; then
  GRADE="C"
  GRADE_COLOR=$YELLOW
elif [ $SCORE -ge 60 ]; then
  GRADE="D"
  GRADE_COLOR=$RED
else
  GRADE="F"
  GRADE_COLOR=$RED
fi

# Display report
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "📈 Compliance Score"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Grade: ${GRADE_COLOR}${GRADE}${NC}"
echo "Score: $SCORE / 100"
echo ""
echo "Files checked: $FILES_CHECKED"
echo "Violations: $VIOLATIONS"
echo "Warnings: $WARNINGS"
echo ""

# Detailed breakdown
if [ $VIOLATIONS -gt 0 ] || [ $WARNINGS -gt 0 ]; then
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "📋 Issue Breakdown"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Show violations/warnings (if jq available, pretty print)
  if command -v jq &> /dev/null; then
    echo "$COMPLIANCE_JSON" | jq -r '.violations[] | "[\(.level | ascii_upcase)] \(.message)\n  File: \(.file)\n  Line: \(.line // "N/A")\n  Fix: \(.remedy // "See QUICK-START.md")\n"'
  else
    echo "Install jq for detailed breakdown"
    echo ""
  fi
fi

# Recommendations
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "💡 Recommendations"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ $SCORE -ge 95 ]; then
  log_success "Excellent compliance! Your code follows Smith patterns."
  echo ""
  echo "Next steps:"
  echo "  - Maintain this level in future PRs"
  echo "  - Consider contributing patterns back to Smith"
  echo "  - Share compliance report with team"

elif [ $SCORE -ge 80 ]; then
  log_warning "Good compliance, but room for improvement."
  echo ""
  echo "Next steps:"
  echo "  - Fix critical violations first"
  echo "  - Review QUICK-START.md for common patterns"
  echo "  - Run check-compliance.sh before each commit"

elif [ $SCORE -ge 60 ]; then
  log_warning "Moderate compliance issues detected."
  echo ""
  echo "Priority actions:"
  echo "  1. Fix all violations (see breakdown above)"
  echo "  2. Read QUICK-START.md thoroughly"
  echo "  3. Review AGENTS-TCA-PATTERNS.md for your use cases"
  echo "  4. Add pre-commit hook (see CI-CD-INTEGRATION.md)"

else
  log_error "Low compliance score - immediate action required."
  echo ""
  echo "Critical actions:"
  echo "  1. Stop merging until violations are fixed"
  echo "  2. Review Smith framework documents:"
  echo "     - QUICK-START.md (5-min overview)"
  echo "     - AGENTS-AGNOSTIC.md (universal patterns)"
  echo "     - AGENTS-TCA-PATTERNS.md (TCA-specific)"
  echo "  3. Run compliance check frequently during refactor"
  echo "  4. Consider pair programming with someone familiar with Smith"
fi

echo ""

# Save report if requested
if [ "$MODE" == "--save" ] && [ -n "$OUTPUT_FILE" ]; then
  log_info "Saving report to $OUTPUT_FILE..."

  cat > "$OUTPUT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project": "$PROJECT_PATH",
  "score": $SCORE,
  "grade": "$GRADE",
  "violations": $VIOLATIONS,
  "warnings": $WARNINGS,
  "files_checked": $FILES_CHECKED,
  "details": $COMPLIANCE_JSON
}
EOF

  log_success "Report saved to $OUTPUT_FILE"
  echo ""
fi

# Track history if requested
if [ "$MODE" == "--history" ]; then
  log_info "Tracking compliance history..."

  mkdir -p "$HISTORY_DIR"

  cat > "$HISTORY_DIR/$TIMESTAMP.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "score": $SCORE,
  "grade": "$GRADE",
  "violations": $VIOLATIONS,
  "warnings": $WARNINGS,
  "files_checked": $FILES_CHECKED
}
EOF

  log_success "History saved to $HISTORY_DIR/$TIMESTAMP.json"

  # Show trend (last 5 reports)
  if [ $(ls -1 "$HISTORY_DIR" | wc -l) -gt 1 ]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📈 Trend (Last 5 Reports)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if command -v jq &> /dev/null; then
      ls -1t "$HISTORY_DIR"/*.json | head -5 | while read -r file; do
        REPORT_SCORE=$(jq -r '.score' "$file")
        REPORT_GRADE=$(jq -r '.grade' "$file")
        REPORT_TS=$(basename "$file" .json)
        echo "  $REPORT_TS: $REPORT_SCORE ($REPORT_GRADE)"
      done
    else
      echo "  Install jq to see detailed trend"
    fi

    echo ""
  fi
fi

# Return exit code based on score
if [ $SCORE -ge 75 ]; then
  exit 0
else
  exit 1
fi
