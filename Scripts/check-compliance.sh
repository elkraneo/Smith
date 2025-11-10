#!/bin/bash
#
# check-compliance.sh - Check project code for Smith framework violations
#
# Scans Swift code for common Smith violations:
# - Deprecated TCA patterns (WithViewStore, IfLetStore, etc.)
# - XCTest instead of Swift Testing
# - @Published instead of @Observable
# - Missing @MainActor on TCA tests
# - Date.constant() instead of TestClock
# - Missing await store.finish() in tests
#
# Usage:
#   ./check-compliance.sh /path/to/project
#   ./check-compliance.sh /path/to/project --strict
#   ./check-compliance.sh /path/to/project --json > report.json
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_PATH="${1:-.}"
MODE="${2}"
VIOLATIONS=0
WARNINGS=0
FILES_CHECKED=0

# Helper functions
log_info() {
  [ "$MODE" != "--json" ] && echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  [ "$MODE" != "--json" ] && echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  if [ "$MODE" == "--json" ]; then
    echo "{\"level\":\"warning\",\"message\":\"$1\",\"file\":\"$2\",\"line\":\"$3\"}" >> /tmp/smith-violations.json
  else
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    echo -e "   ${BLUE}File: $2${NC}"
    [ -n "$3" ] && echo -e "   ${BLUE}Line: $3${NC}"
  fi
  ((WARNINGS++))
}

log_violation() {
  if [ "$MODE" == "--json" ]; then
    echo "{\"level\":\"error\",\"message\":\"$1\",\"file\":\"$2\",\"line\":\"$3\",\"remedy\":\"$4\"}" >> /tmp/smith-violations.json
  else
    echo -e "${RED}❌ VIOLATION: $1${NC}"
    echo -e "   ${BLUE}File: $2${NC}"
    [ -n "$3" ] && echo -e "   ${BLUE}Line: $3${NC}"
    [ -n "$4" ] && echo -e "   ${YELLOW}Fix: $4${NC}"
  fi
  ((VIOLATIONS++))
}

# Initialize JSON output
if [ "$MODE" == "--json" ]; then
  echo '{"violations":[' > /tmp/smith-violations.json
fi

# Header
if [ "$MODE" != "--json" ]; then
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "🔍 Smith Compliance Check"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  log_info "Scanning: $PROJECT_PATH"
  echo ""
fi

# Check if project path exists
if [ ! -d "$PROJECT_PATH" ]; then
  log_violation "Project path not found" "$PROJECT_PATH" "" "Provide valid project path"
  exit 1
fi

# Find all Swift files
SWIFT_FILES=$(find "$PROJECT_PATH" -name "*.swift" -not -path "*/Build/*" -not -path "*/.build/*" -not -path "*/DerivedData/*" 2>/dev/null)

# Rule 1: Check for deprecated WithViewStore
log_info "Rule 1: Checking for deprecated WithViewStore..."
while IFS= read -r file; do
  [ -z "$file" ] && continue
  ((FILES_CHECKED++))

  if grep -n "WithViewStore" "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "WithViewStore" "$file" | head -1 | cut -d: -f1)
    log_violation "Using deprecated WithViewStore" "$file" "$LINE" "Use @Bindable var store instead (see QUICK-START.md Rule 2)"
  fi
done <<< "$SWIFT_FILES"

# Rule 2: Check for deprecated IfLetStore
log_info "Rule 2: Checking for deprecated IfLetStore..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if grep -n "IfLetStore" "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "IfLetStore" "$file" | head -1 | cut -d: -f1)
    log_violation "Using deprecated IfLetStore" "$file" "$LINE" "Use .sheet(item:) with .scope() (see QUICK-START.md Rule 3)"
  fi
done <<< "$SWIFT_FILES"

# Rule 3: Check for @Published instead of @Observable
log_info "Rule 3: Checking for @Published (should use @Observable)..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if grep -n "@Published" "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "@Published" "$file" | head -1 | cut -d: -f1)
    log_warning "@Published found (consider @Observable for Swift 6 strict concurrency)" "$file" "$LINE"
  fi
done <<< "$SWIFT_FILES"

# Rule 4: Check for XCTest in test files
log_info "Rule 4: Checking for XCTest (should use Swift Testing)..."
TEST_FILES=$(echo "$SWIFT_FILES" | grep -i "test")
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if grep -n "XCTestCase\|XCTAssert\|func test.*().*{" "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "XCTestCase\|XCTAssert" "$file" | head -1 | cut -d: -f1)
    log_violation "Using XCTest instead of Swift Testing" "$file" "$LINE" "Use @Test and #expect() (see QUICK-START.md Rule 6)"
  fi
done <<< "$TEST_FILES"

# Rule 5: Check for missing @MainActor on TCA tests
log_info "Rule 5: Checking for missing @MainActor on TCA tests..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Check if file has TestStore but @Test without @MainActor
  if grep -q "TestStore" "$file" && grep -q "@Test" "$file"; then
    # Find @Test declarations without @MainActor on same or previous line
    RESULT=$(awk '/@Test/ && !/@MainActor/ {print NR": "$0}' "$file")
    if [ -n "$RESULT" ]; then
      LINE=$(echo "$RESULT" | head -1 | cut -d: -f1)
      log_violation "TCA test missing @MainActor" "$file" "$LINE" "Add @MainActor before @Test (see QUICK-START.md Rule 6)"
    fi
  fi
done <<< "$TEST_FILES"

# Rule 6: Check for Date.constant() in tests
log_info "Rule 6: Checking for Date.constant() (should use TestClock)..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if grep -n "Date\.constant" "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "Date\.constant" "$file" | head -1 | cut -d: -f1)
    log_violation "Using Date.constant() instead of TestClock" "$file" "$LINE" "Use TestClock() for deterministic time (see QUICK-START.md Rule 7)"
  fi
done <<< "$TEST_FILES"

# Rule 7: Check for missing await store.finish()
log_info "Rule 7: Checking for missing await store.finish()..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  # If file has TestStore but no store.finish()
  if grep -q "TestStore" "$file" && grep -q "await store.send" "$file"; then
    if ! grep -q "await store.finish()" "$file"; then
      log_warning "Test has store.send() but no store.finish()" "$file" ""
    fi
  fi
done <<< "$TEST_FILES"

# Rule 8: Check for .ifLet without closure
log_info "Rule 8: Checking for .ifLet without closure (causes action routing failures)..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Look for .ifLet(...) followed by newline or }, not followed by {
  if grep -Pzo '\.ifLet\([^)]+\)\s*(?!\s*\{)' "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "\.ifLet" "$file" | head -1 | cut -d: -f1)
    log_violation ".ifLet missing closure (actions won't route)" "$file" "$LINE" "Add closure: .ifLet(...) { ChildFeature() } (see QUICK-START.md Rule 4)"
  fi
done <<< "$SWIFT_FILES"

# Rule 9: Check for singleton patterns in services
log_info "Rule 9: Checking for singleton patterns (should use @DependencyClient)..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  if grep -n "static let shared\|static var shared" "$file" >/dev/null 2>&1; then
    LINE=$(grep -n "static let shared\|static var shared" "$file" | head -1 | cut -d: -f1)
    log_warning "Singleton pattern found (consider @DependencyClient for testability)" "$file" "$LINE"
  fi
done <<< "$SWIFT_FILES"

# Rule 10: Check for async tests without await store.finish()
log_info "Rule 10: Checking for incomplete effect verification..."
while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Tests that send actions but never call finish()
  if grep -q "@Test.*async" "$file" && grep -q "TestStore" "$file"; then
    SENDS=$(grep -c "await store.send" "$file" || echo 0)
    FINISHES=$(grep -c "await store.finish()" "$file" || echo 0)

    if [ "$SENDS" -gt 0 ] && [ "$FINISHES" -eq 0 ]; then
      log_violation "Test sends actions but never calls store.finish()" "$file" "" "Add 'await store.finish()' at end of test"
    fi
  fi
done <<< "$TEST_FILES"

# Generate summary
if [ "$MODE" == "--json" ]; then
  echo ']}' >> /tmp/smith-violations.json
  sed -i '' '2s/^/{"summary":{"violations":'$VIOLATIONS',"warnings":'$WARNINGS',"files_checked":'$FILES_CHECKED'},/' /tmp/smith-violations.json
  cat /tmp/smith-violations.json
  rm /tmp/smith-violations.json
else
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "📊 Summary"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Files checked: $FILES_CHECKED"
  echo "Violations: $VIOLATIONS"
  echo "Warnings: $WARNINGS"
  echo ""

  if [ $VIOLATIONS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log_success "ALL CHECKS PASSED - 100% Smith Compliant"
    echo ""
    echo "Your code follows Smith framework patterns."
    exit 0
  elif [ $VIOLATIONS -eq 0 ]; then
    log_warning "PASSED WITH $WARNINGS WARNINGS"
    echo ""
    echo "No critical violations, but consider addressing warnings."

    if [ "$MODE" == "--strict" ]; then
      echo "Strict mode: treating warnings as errors."
      exit 1
    fi
    exit 0
  else
    log_violation "COMPLIANCE CHECK FAILED" "" "" ""
    echo ""
    echo "Fix violations above to become Smith compliant."
    echo "See QUICK-START.md for patterns and fixes."
    exit 1
  fi
fi
