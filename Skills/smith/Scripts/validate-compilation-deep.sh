#!/bin/bash

# Deep Compilation Validation with xcsift
# Purpose: Detect compilation hangs and hidden issues without context bloat
# Usage: ./validate-compilation-deep.sh [scheme] [timeout-seconds]
# Output: Structured JSON summary via xcsift (minimal context overhead)

SCHEME="${1:-.}"
TIMEOUT="${2:-120}"

echo "🔍 Deep Compilation Validation (xcsift-powered)"
echo "================================================="

# Check if xcsift is available
if ! command -v xcsift &> /dev/null; then
    echo "❌ xcsift not found. Install with: brew install xcsift"
    exit 1
fi

# Step 1: Quick typecheck baseline (fast pre-flight check)
echo ""
echo "1️⃣ Typecheck validation (syntax check)..."
TYPECHECK_ERRORS=$(swiftc -typecheck 'Sources/**/*.swift' 2>&1 | grep -c "error:" || true)

if [ "$TYPECHECK_ERRORS" -gt 0 ]; then
    echo "❌ Typecheck failed with $TYPECHECK_ERRORS errors"
    swiftc -typecheck 'Sources/**/*.swift' 2>&1 | grep "error:" | head -3
    exit 1
else
    echo "✅ Typecheck passed"
fi

# Step 2: Full compilation with timeout, piped through xcsift
echo ""
echo "2️⃣ Full build validation (${TIMEOUT}s timeout)..."
echo ""

XCSIFT_OUTPUT=$(timeout "$TIMEOUT" xcodebuild build \
    -scheme "$SCHEME" \
    -configuration Debug \
    -Onone \
    -derivedDataPath /tmp/smith-build-$$\
    2>&1 | xcsift --print-warnings)

EXIT_CODE=$?

# Step 3: Parse and display xcsift result
echo "📊 BUILD RESULT:"
echo ""
echo "$XCSIFT_OUTPUT" | jq '.' 2>/dev/null || echo "$XCSIFT_OUTPUT"
echo ""

# Step 4: Determine outcome
if [ $EXIT_CODE -eq 124 ]; then
    echo "❌ COMPILATION HUNG (timeout after ${TIMEOUT}s)"
    echo "   This indicates circular dependencies or module boundary issues"
    exit 1
fi

if echo "$XCSIFT_OUTPUT" | jq -e '.status == "success"' >/dev/null 2>&1; then
    echo "================================================="
    echo "✅ COMPILATION VALID"
    echo "   - Typecheck: PASS"
    echo "   - Full build: PASS"
    echo "   - Ready for production"
    exit 0
else
    echo "================================================="
    echo "❌ COMPILATION FAILED"
    echo "   See BUILD RESULT above for details"
    exit 1
fi
