#!/bin/bash

# Deep Compilation Validation - Context-Efficient Version
# Detects hangs with root cause analysis
# Usage: ./validate-compilation-deep.sh [workspace-path] [scheme] [timeout-seconds] [--verbose] [--platform PLATFORM]

WORKSPACE="${1:-.}"
SCHEME="${2:-Scroll}"
TIMEOUT="${3:-300}"
VERBOSE_MODE=""
PLATFORM_SPECIFIED=""

# Parse arguments
shift 3
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE_MODE="--verbose"
            shift
            ;;
        --platform)
            PLATFORM_SPECIFIED="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

echo "🔍 Deep Compilation Validation (Context-Efficient)"
echo "=================================================="
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo "Timeout: ${TIMEOUT}s"
if [ -n "$PLATFORM_SPECIFIED" ]; then
    echo "Platform: $PLATFORM_SPECIFIED (forced validation)"
fi
if [ "$VERBOSE_MODE" = "--verbose" ]; then
    echo "Mode: VERBOSE (detailed diagnostics enabled)"
fi
echo ""

# Check dependencies
BUILDER_AVAILABLE=false
BUILD_TOOL=""
BUILD_TOOL_NAME=""

if command -v sbsift &> /dev/null; then
    BUILD_TOOL="sbsift"
    BUILD_TOOL_NAME="sbsift"
    BUILDER_AVAILABLE=true
    echo "🔧 Using build analysis tool: sbsift"
elif command -v xcsift &> /dev/null; then
    BUILD_TOOL="xcsift"
    BUILD_TOOL_NAME="xcsift"
    BUILDER_AVAILABLE=true
    echo "🔧 Using build analysis tool: xcsift"
fi

if [ "$BUILDER_AVAILABLE" = false ]; then
    echo "❌ No build analysis tool found. Install one of:"
    echo "   sbsift: brew install elkraneo/tap/sbsift"
    echo "   xcsift: brew install xcsift"
    echo ""
    echo "📖 For sbsift: https://github.com/elkraneo/sbsift"
    echo "📖 For xcsift: https://github.com/ldomaradzki/xcsift"
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

# Step 2: Full build with sbsift/xcsift output (structured, minimal context)
echo "3️⃣ Full build validation (${TIMEOUT}s timeout)..."
echo ""

TEMP_LOG="/tmp/smith-build-$$.log"
if [ "$BUILD_TOOL" = "sbsift" ]; then
    # For SPM projects, use swift build with sbsift
    if [ -f "Package.swift" ]; then
        echo "🏗️ Building SPM package with sbsift analysis..."
        if [ -n "$PLATFORM_SPECIFIED" ]; then
            echo "🔍 Testing platform-specific dependencies for $PLATFORM_SPECIFIED..."
            timeout "$TIMEOUT" swift build \
                -c debug \
                --enable-code-coverage OFF \
                -Xswiftc -target \
                -Xswiftc "${PLATFORM_SPECIFIED}-apple" \
                2>&1 | sbsift > "$TEMP_LOG"
        else
            timeout "$TIMEOUT" swift build \
                -c debug \
                --enable-code-coverage OFF \
                2>&1 | sbsift > "$TEMP_LOG"
        fi
    else
        # Fallback to xcodebuild for Xcode projects
        echo "🏗️ Building Xcode project with sbsift analysis..."
        BUILD_DEST=""
        if [ -n "$PLATFORM_SPECIFIED" ]; then
            case "$PLATFORM_SPECIFIED" in
                "visionOS")
                    BUILD_DEST="-destination 'platform=visionOS Simulator,name=Apple Vision Pro'"
                    ;;
                "iOS")
                    BUILD_DEST="-destination 'platform=iOS Simulator,name=iPhone 15 Pro'"
                    ;;
                "macOS")
                    BUILD_DEST="-destination 'platform=macOS'"
                    ;;
            esac
            echo "🔍 Testing platform-specific build for $PLATFORM_SPECIFIED..."
        fi

        timeout "$TIMEOUT" xcodebuild build \
            -workspace "$WORKSPACE" \
            -scheme "$SCHEME" \
            -configuration Debug \
            -Onone \
            -derivedDataPath "/tmp/smith-build-$$" \
            $BUILD_DEST \
            2>&1 | sbsift > "$TEMP_LOG"
    fi
else
    # Use xcsift for Xcode projects
    echo "🏗️ Building Xcode project with xcsift analysis..."
    BUILD_DEST=""
    if [ -n "$PLATFORM_SPECIFIED" ]; then
        case "$PLATFORM_SPECIFIED" in
            "visionOS")
                BUILD_DEST="-destination 'platform=visionOS Simulator,name=Apple Vision Pro'"
                ;;
            "iOS")
                BUILD_DEST="-destination 'platform=iOS Simulator,name=iPhone 15 Pro'"
                ;;
            "macOS")
                BUILD_DEST="-destination 'platform=macOS'"
                ;;
        esac
        echo "🔍 Testing platform-specific build for $PLATFORM_SPECIFIED..."
    fi

    timeout "$TIMEOUT" xcodebuild build \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -Onone \
        -derivedDataPath "/tmp/smith-build-$$" \
        $BUILD_DEST \
        2>&1 | "$BUILD_TOOL" > "$TEMP_LOG"
fi

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
    # Build result analysis based on tool used
    if [ "$BUILD_TOOL" = "sbsift" ]; then
        # sbsift provides JSON success/failure
        BUILD_SUCCESS=$(cat "$TEMP_LOG" | jq -r '.success // false' 2>/dev/null)
        if [ "$BUILD_SUCCESS" = "true" ]; then
            echo "✅ BUILD SUCCEEDED"
        else
            echo "❌ BUILD FAILED"
            # Show errors from sbsift output
            BUILD_ERRORS=$(cat "$TEMP_LOG" | jq '.errors // []' 2>/dev/null)
            if [ -n "$BUILD_ERRORS" ] && [ "$BUILD_ERRORS" != "[]" ]; then
                echo "$BUILD_ERRORS"
            fi
        fi
    else
        # Fallback check for xcsift
        if grep -q "error:" "$TEMP_LOG"; then
            echo "❌ BUILD FAILED (errors detected)"
        else
            echo "✅ BUILD SUCCEEDED"
        fi
    fi
fi
echo ""

# CRITICAL: Verify actual build success, not filtered output
echo "4️⃣ Verifying actual build success..."
ACTUAL_BUILD_SUCCESS=false

# Check if we have sbsift/xcsift structured output
if [ -f "$TEMP_LOG" ] && [ -s "$TEMP_LOG" ]; then
    if [ "$BUILD_TOOL" = "sbsift" ]; then
        # sbsift provides JSON with success field
        BUILD_SUCCESS_JSON=$(cat "$TEMP_LOG" | jq -r '.success // false' 2>/dev/null)
        if [ "$BUILD_SUCCESS_JSON" = "true" ]; then
            ACTUAL_BUILD_SUCCESS=true
        fi
    else
        # xcsift - check for errors in structured output
        if grep -q '"status" : "failed"' "$TEMP_LOG" 2>/dev/null; then
            ACTUAL_BUILD_SUCCESS=false
        elif grep -q '"status" : "passed"' "$TEMP_LOG" 2>/dev/null; then
            ACTUAL_BUILD_SUCCESS=true
        # Fallback: check raw exit code if structured parsing fails
        elif [ $EXIT_CODE -eq 0 ] && ! grep -q "error:" "$TEMP_LOG"; then
            ACTUAL_BUILD_SUCCESS=true
        fi
    fi
fi

# Final verdict - based on actual build status, not just exit code
if [ "$ACTUAL_BUILD_SUCCESS" = "true" ] && [ $EXIT_CODE -eq 0 ]; then
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
    echo "   - Actual build: FAILED"
    echo "   - Exit code: $EXIT_CODE"
    if [ "$VERBOSE_MODE" != "--verbose" ]; then
        echo "   Run with --verbose for detailed diagnostics"
    fi
    echo ""
    echo "🔍 Filtered build analysis:"
    if [ -f "$TEMP_LOG" ] && [ -s "$TEMP_LOG" ]; then
        head -10 "$TEMP_LOG"
    fi
    rm -f "$TEMP_LOG"
    exit 1
fi
