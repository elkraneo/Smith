#!/bin/bash

# Deep Compilation Validation - Context-Efficient Version
# Detects hangs with root cause analysis
# Usage: ./validate-compilation-deep.sh [workspace-path] [scheme] [timeout-seconds] [--verbose]

WORKSPACE="${1:-.}"
SCHEME="${2:-Scroll}"
TIMEOUT="${3:-300}"
VERBOSE_MODE="${4:-}"

echo "🔍 Deep Compilation Validation (Context-Efficient)"
echo "=================================================="
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo "Timeout: ${TIMEOUT}s"
if [ "$VERBOSE_MODE" = "--verbose" ]; then
    echo "Mode: VERBOSE (detailed diagnostics enabled)"
fi
echo ""

# Check dependencies
if ! command -v xcsift &> /dev/null; then
    echo "❌ xcsift not found. Install with: brew install xcsift"
    exit 1
fi

# EARLY EXIT CHECK: Index store corruption (BEFORE compilation attempt)
echo "1️⃣ Checking index store health..."
BUILD_DIR=$(xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "BUILD_DIR = " | head -1 | awk '{print $3}')

if [ -n "$BUILD_DIR" ]; then
    DERIVED_DATA_ROOT=$(dirname "$BUILD_DIR")
    DERIVED_DATA_SIZE_RAW=$(du -sh "$DERIVED_DATA_ROOT" 2>/dev/null | awk '{print $1}')
    DERIVED_DATA_SIZE_MB=$(du -sm "$DERIVED_DATA_ROOT" 2>/dev/null | awk '{print $1}')

    # CRITICAL: Index store > 500MB indicates corruption
    if [ "$DERIVED_DATA_SIZE_MB" -gt 500 ]; then
        echo "⚠️  CRITICAL: DerivedData size is ${DERIVED_DATA_SIZE_RAW} (${DERIVED_DATA_SIZE_MB}MB)"
        echo "   This indicates index corruption (normal: <300MB)"
        echo ""
        echo "🛠️ IMMEDIATE FIX:"
        echo "   1. killall Xcode"
        echo "   2. rm -rf '$DERIVED_DATA_ROOT'/Scroll-*"
        echo "   3. rm -rf ~/Library/Caches/com.apple.dt.Xcode"
        echo "   4. xcodebuild clean -workspace '$WORKSPACE' -scheme '$SCHEME'"
        echo "   5. Reopen Xcode and wait for reindexing to complete"
        echo ""
        echo "⏱️ Reindexing typically takes 5-15 minutes. Monitor Activity Monitor → Xcode."
        echo ""
        exit 1
    else
        echo "✅ DerivedData size: ${DERIVED_DATA_SIZE_RAW} (healthy)"
    fi
else
    echo "⚠️  Could not determine DerivedData location"
fi
echo ""

# Step 1: Typecheck validation
echo "2️⃣ Typecheck validation..."
TYPECHECK_ERRORS=$(find Sources -name "*.swift" -type f 2>/dev/null | xargs swiftc -typecheck 2>&1 | grep -c "error:" || true)

if [ "$TYPECHECK_ERRORS" -gt 0 ]; then
    echo "❌ Typecheck failed with $TYPECHECK_ERRORS errors"
    exit 1
else
    echo "✅ Typecheck passed"
fi
echo ""

# Step 2: Full build with xcsift output (structured, minimal context)
echo "3️⃣ Full build validation (${TIMEOUT}s timeout)..."
echo ""

TEMP_LOG="/tmp/smith-build-$$.log"
timeout "$TIMEOUT" xcodebuild build \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -Onone \
    -derivedDataPath "/tmp/smith-build-$$" \
    2>&1 > "$TEMP_LOG"

EXIT_CODE=$?

# Step 3: Analyze with xcsift (structured output only)
if [ $EXIT_CODE -eq 124 ]; then
    echo "================================================="
    echo "❌ COMPILATION HUNG (timeout after ${TIMEOUT}s)"
    echo ""
    echo "🔬 ROOT CAUSE ANALYSIS:"
    echo ""

    # Only show last 5 build lines from log
    LAST_STEPS=$(grep -E "Building |Compiling " "$TEMP_LOG" | tail -5)
    if [ -n "$LAST_STEPS" ]; then
        echo "📍 Last compilation steps:"
        echo "$LAST_STEPS" | sed 's/^/   /'
        echo ""
    fi

    # Check for verbose diagnostics if requested
    if [ "$VERBOSE_MODE" = "--verbose" ]; then
        echo "🔬 VERBOSE DIAGNOSTICS:"
        echo ""

        # Module analysis
        STUCK_TARGET=$(grep -oE "Compiling [^ ]+" "$TEMP_LOG" | tail -1 | cut -d' ' -f2)
        if [ -n "$STUCK_TARGET" ]; then
            echo "   Stuck module: $STUCK_TARGET"
            echo "   💡 Check: circular imports, missing public types"
            echo ""
        fi

        # SPM packages
        if [ -f "Package.resolved" ] || [ -f "Scroll.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
            echo "   💡 Slow packages: swift-syntax, GRDB, swift-composable-architecture"
            echo "   💡 Try: rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages"
            echo ""
        fi
    fi

    echo "🛠️ SUGGESTED FIXES (in order of likelihood):"
    echo ""
    echo "1. Clean incremental state:"
    if [ -n "$BUILD_DIR" ]; then
        echo "   rm -rf '$DERIVED_DATA_ROOT'/Scroll-*"
    else
        echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/Scroll*"
    fi
    echo "   xcodebuild clean -workspace '$WORKSPACE' -scheme '$SCHEME'"
    echo ""
    echo "2. Index corruption (if size > 500MB):"
    echo "   killall Xcode"
    echo "   rm -rf ~/Library/Caches/com.apple.dt.Xcode"
    echo ""
    echo "3. Run again with --verbose for module-level diagnostics:"
    echo "   $0 '$WORKSPACE' '$SCHEME' $TIMEOUT --verbose"
    echo ""

    rm -f "$TEMP_LOG"
    exit 1
fi

# Step 4: Parse xcsift output (success case - structured only)
echo "📊 BUILD RESULT:"
echo ""

# Only output xcsift errors, not full build log
XCSIFT_OUTPUT=$(cat "$TEMP_LOG" | xcsift 2>/dev/null | jq '.errors // empty' 2>/dev/null)

if [ -n "$XCSIFT_OUTPUT" ]; then
    echo "❌ BUILD FAILED"
    echo "$XCSIFT_OUTPUT" | jq '.' 2>/dev/null || echo "$XCSIFT_OUTPUT"
else
    # Fallback check
    if grep -q "error:" "$TEMP_LOG"; then
        echo "❌ BUILD FAILED (errors detected)"
    else
        echo "✅ BUILD SUCCEEDED"
    fi
fi
echo ""

# Final verdict
if [ $EXIT_CODE -eq 0 ]; then
    echo "================================================="
    echo "✅ COMPILATION VALID"
    echo "   - Typecheck: PASS"
    echo "   - Full workspace build: PASS"
    echo "   - Ready for production"
    rm -f "$TEMP_LOG"
    exit 0
else
    echo "================================================="
    echo "❌ COMPILATION FAILED"
    if [ "$VERBOSE_MODE" != "--verbose" ]; then
        echo "   Run with --verbose for detailed diagnostics"
    fi
    rm -f "$TEMP_LOG"
    exit 1
fi
