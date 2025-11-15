#!/bin/bash

# Deep Compilation Validation with Hang Detection
# Detects compilation hangs (e.g., stuck at "Building 9/49")
# Usage: ./validate-compilation-deep.sh [workspace-path] [scheme] [timeout-seconds]

WORKSPACE="${1:-.}"
SCHEME="${2:-Scroll}"
TIMEOUT="${3:-300}"

echo "🔍 Deep Compilation Validation (Hang Detection)"
echo "=============================================="
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Check if xcsift is available
if ! command -v xcsift &> /dev/null; then
    echo "❌ xcsift not found. Install with: brew install xcsift"
    exit 1
fi

# Step 1: Quick typecheck baseline
echo "1️⃣ Typecheck validation..."
TYPECHECK_ERRORS=$(swiftc -typecheck 'Sources/**/*.swift' 2>&1 | grep -c "error:" || true)

if [ "$TYPECHECK_ERRORS" -gt 0 ]; then
    echo "❌ Typecheck failed with $TYPECHECK_ERRORS errors"
    exit 1
else
    echo "✅ Typecheck passed"
fi

# Step 2: Full workspace build with hang detection
echo ""
echo "2️⃣ Full build validation (${TIMEOUT}s timeout)..."
echo ""

BUILD_LOG="/tmp/smith-build-$$.log"
PROGRESS_LOG="/tmp/smith-progress-$$.log"

# Run build and capture both full output and progress
{
    timeout "$TIMEOUT" xcodebuild build \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -Onone \
        -derivedDataPath /tmp/smith-build-$$ \
        2>&1
} | tee "$BUILD_LOG" | grep -E "Building |Compiling |Linking |error:|fatal error:" | tee "$PROGRESS_LOG"

EXIT_CODE=$?

echo ""

# Step 3: Analyze hang vs. success
if [ $EXIT_CODE -eq 124 ]; then
    echo "================================================="
    echo "❌ COMPILATION HUNG (timeout after ${TIMEOUT}s)"
    echo ""
    echo "Last compilation activity:"
    tail -5 "$PROGRESS_LOG"
    echo ""
    echo "Stuck at step: $(grep -oE 'Building [0-9]+/[0-9]+' "$PROGRESS_LOG" | tail -1)"

    # Find the last thing it was compiling
    LAST_STEP=$(grep -E "Compiling |Building " "$PROGRESS_LOG" | tail -1)
    if [ -n "$LAST_STEP" ]; then
        echo "Last step: $LAST_STEP"
        echo ""
        echo "💡 Try:"
        echo "   - Clean build folder (Cmd+Shift+K in Xcode)"
        echo "   - Delete DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
        echo "   - Check for circular dependencies"
    fi

    rm -f "$BUILD_LOG" "$PROGRESS_LOG"
    exit 1
fi

# Step 4: Parse xcsift result from full output
echo "📊 BUILD RESULT:"
echo ""
echo "$BUILD_LOG" | xcsift --print-warnings 2>/dev/null | jq '.' 2>/dev/null || {
    # Fallback: check for errors in log
    if grep -q "error:" "$BUILD_LOG"; then
        echo "❌ BUILD FAILED (errors detected)"
    else
        echo "✅ BUILD SUCCEEDED"
    fi
}
echo ""

# Step 5: Final verdict
if [ $EXIT_CODE -eq 0 ]; then
    echo "================================================="
    echo "✅ COMPILATION VALID"
    echo "   - Typecheck: PASS"
    echo "   - Full workspace build: PASS"
    echo "   - Ready for production"
    rm -f "$BUILD_LOG" "$PROGRESS_LOG"
    exit 0
else
    echo "================================================="
    echo "❌ COMPILATION FAILED"
    echo "   See BUILD RESULT above"
    rm -f "$BUILD_LOG" "$PROGRESS_LOG"
    exit 1
fi
