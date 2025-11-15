#!/bin/bash

# Deep Compilation Validation with Root Cause Analysis
# Detects hangs (Building X/Y forever) AND analyzes WHY
# Usage: ./validate-compilation-deep.sh [workspace-path] [scheme] [timeout-seconds]

WORKSPACE="${1:-.}"
SCHEME="${2:-Scroll}"
TIMEOUT="${3:-300}"

echo "🔍 Deep Compilation Validation (Hang Detection + Root Cause Analysis)"
echo "===================================================================="
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Check dependencies
if ! command -v xcsift &> /dev/null; then
    echo "❌ xcsift not found. Install with: brew install xcsift"
    exit 1
fi

# Step 1: Quick typecheck baseline
echo "1️⃣ Typecheck validation..."
TYPECHECK_ERRORS=$(find Sources -name "*.swift" -type f 2>/dev/null | xargs swiftc -typecheck 2>&1 | grep -c "error:" || true)

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

    # Show hang point
    LAST_BUILD=$(grep -oE 'Building [0-9]+/[0-9]+' "$PROGRESS_LOG" | tail -1)
    LAST_STEP=$(grep -E "Compiling |Building " "$PROGRESS_LOG" | tail -1)

    echo "📍 Hang Point:"
    echo "   Step: $LAST_BUILD"
    if [ -n "$LAST_STEP" ]; then
        echo "   Last: $LAST_STEP"
    fi
    echo ""

    # ROOT CAUSE ANALYSIS
    echo "🔬 ROOT CAUSE ANALYSIS:"
    echo ""

    # Check 1: Module dependency graph (what module is stuck?)
    echo "   1️⃣ Module Analysis:"
    if command -v swift &> /dev/null; then
        STUCK_TARGET=$(echo "$LAST_STEP" | grep -oE "Compiling [^ ]+" | head -1 | cut -d' ' -f2)
        if [ -n "$STUCK_TARGET" ]; then
            echo "      Stuck module: $STUCK_TARGET"
            echo "      💡 Check dependencies for: circular imports, missing public types"
        fi
    fi
    echo ""

    # Check 2: Incremental build state (is DerivedData corrupted?)
    echo "   2️⃣ Incremental Build State:"
    DERIVED_DATA_SIZE=$(du -sh ~/Library/Developer/Xcode/DerivedData/Scroll* 2>/dev/null | awk '{print $1}')
    if [ -n "$DERIVED_DATA_SIZE" ]; then
        echo "      DerivedData size: $DERIVED_DATA_SIZE"
        echo "      💡 Try: rm -rf ~/Library/Developer/Xcode/DerivedData/Scroll*"
    fi
    echo ""

    # Check 3: SPM Package dependencies
    echo "   3️⃣ Package Dependency Status:"
    if [ -f "Package.resolved" ] || [ -f "Scroll.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
        PKG_COUNT=$(find . -name "Package.resolved" -exec grep -c "\"identity\"" {} \; 2>/dev/null | tail -1)
        echo "      SPM packages resolved: $PKG_COUNT"
        echo "      💡 Slow packages: swift-syntax, GRDB, swift-composable-architecture"
        echo "      💡 Try: rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages"
    fi
    echo ""

    # Check 4: Build settings that slow down compilation
    echo "   4️⃣ Compilation Settings:"
    echo "      Current: Debug, Onone (optimization level None)"
    echo "      💡 Try without -Onone if using optimization checks"
    echo "      💡 Check: ENABLE_BITCODE, ONLY_ACTIVE_ARCH, SWIFT_OPTIMIZATION_LEVEL"
    echo ""

    # Check 5: Link time analysis
    echo "   5️⃣ Linking Issues:"
    LINKER_WARNINGS=$(grep -c "ld:" "$BUILD_LOG" 2>/dev/null || echo 0)
    if [ "$LINKER_WARNINGS" -gt 0 ]; then
        echo "      Linker warnings detected: $LINKER_WARNINGS"
        echo "      💡 Check for duplicate symbols, missing frameworks"
    else
        echo "      No linker warnings found (likely compilation hang, not linking)"
    fi
    echo ""

    echo "================================================="
    echo ""
    echo "🛠️ SUGGESTED FIXES (in order of likelihood):"
    echo ""
    echo "1. Clean incremental state:"
    echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/Scroll*"
    echo "   xcodebuild clean -workspace '$WORKSPACE' -scheme '$SCHEME'"
    echo ""
    echo "2. Check for circular module dependencies:"
    echo "   Look for: A.swift imports B, B.swift imports A (or transitive)"
    echo "   Use: Xcode → File → Project Settings → Build Phases → Check target dependencies"
    echo ""
    echo "3. Check stuck module dependencies:"
    echo "   Module '$STUCK_TARGET' likely has issue"
    echo "   Check for: @testable imports, public type missing public conformances"
    echo ""
    echo "4. Swift Package Manager cache:"
    echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages"
    echo ""

    rm -f "$BUILD_LOG" "$PROGRESS_LOG"
    exit 1
fi

# Step 4: Parse xcsift result from full output (success case)
echo "📊 BUILD RESULT:"
echo ""
cat "$BUILD_LOG" | xcsift --print-warnings 2>/dev/null | jq '.' 2>/dev/null || {
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
