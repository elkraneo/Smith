#!/bin/bash

# Platform Dependency Validation - Critical Missing Piece
# Validates that SPM dependencies are available for target platforms
# Usage: ./spm-platform-deps.sh [package-path] [target-platform]

PACKAGE_PATH="${1:-.}"
TARGET_PLATFORM="${2:-visionOS}"  # Default to most problematic platform

set -e

echo "🔍 Platform Dependency Validation"
echo "================================="
echo "Package: $PACKAGE_PATH"
echo "Target Platform: $TARGET_PLATFORM"
echo ""

# Validation
if [ ! -f "$PACKAGE_PATH/Package.swift" ]; then
    echo "❌ Not an SPM package"
    exit 1
fi

cd "$PACKAGE_PATH" || exit 1

echo "1️⃣ Scanning for platform-conditioned dependencies..."
echo ""

# Find all platform-conditioned dependencies
PLATFORM_DEPS=$(awk '
/condition: \.when\(platforms: \[/ {
    in_condition = 1
    platforms_line = $0
    next
}
in_condition && /\]/ {
    print platforms_line $0
    in_condition = 0
    next
}
in_condition {
    platforms_line = platforms_line $0
}
' Package.swift)

if [ -z "$PLATFORM_DEPS" ]; then
    echo "✅ No platform-conditioned dependencies found"
    exit 0
fi

echo "📋 Platform-Conditioned Dependencies Found:"
echo "$PLATFORM_DEPS"
echo ""

# Check for missing platform support
MISSING_PLATFORMS=""

while IFS= read -r line; do
    if echo "$line" | grep -q "condition: .when(platforms:"; then
        # Extract platforms from the condition
        platforms=$(echo "$line" | sed 's/.*condition: .when(platforms: \[\([^]]*\)\].*/\1/')

        # Clean up platform names
        platforms=$(echo "$platforms" | sed 's/\.\([a-zA-Z]*\)/\1/g' | sed 's/^ *//;s/ *$//')

        # Check if target platform is missing
        if ! echo "$platforms" | grep -q "\b$TARGET_PLATFORM\b"; then
            product_name=$(echo "$line" | sed 's/.*name: "\([^"]*\)".*/\1/')
            MISSING_PLATFORMS="$MISSING_PLATFORMS$product_name (missing: $TARGET_PLATFORM)\n"
        fi
    fi
done <<< "$PLATFORM_DEPS"

if [ -n "$MISSING_PLATFORMS" ]; then
    echo "❌ CRITICAL: Dependencies missing for $TARGET_PLATFORM:"
    echo -e "$MISSING_PLATFORMS"
    echo ""
    echo "🛠️ LIKELY FIX:"
    echo "   Add .$TARGET_PLATFORM to the condition array in Package.swift"
    echo "   Example: condition: .when(platforms: [.iOS, .macOS, .$TARGET_PLATFORM])"
    echo ""
    echo "⚠️  This WILL cause build failures on $TARGET_PLATFORM"
    exit 1
else
    echo "✅ All platform-conditioned dependencies support $TARGET_PLATFORM"
fi

echo ""
echo "2️⃣ Checking import usage vs dependency availability..."
echo ""

# Find all import statements in Swift files
IMPORTS=$(find . -name "*.swift" -type f -exec grep -h "^import " {} \; | sort -u | sed 's/^import //')

CRITICAL_IMPORTS=""

for import_module in $IMPORTS; do
    # Check if this import has a corresponding dependency
    if echo "$PLATFORM_DEPS" | grep -q "name: \"$import_module\""; then
        # This is a platform-conditioned dependency
        dep_line=$(echo "$PLATFORM_DEPS" | grep "name: \"$import_module\"")
        if ! echo "$dep_line" | grep -q "\b$TARGET_PLATFORM\b"; then
            # Find files using this import
            FILES_USING_IMPORT=$(find . -name "*.swift" -type f -exec grep -l "^import $import_module$" {} \; | head -3)
            CRITICAL_IMPORTS="$CRITICAL_IMPORTS$import_module imported in: $(echo $FILES_USING_IMPORT | tr '\n' ', ' | sed 's/,$//')\n"
        fi
    fi
done

if [ -n "$CRITICAL_IMPORTS" ]; then
    echo "❌ CRITICAL: Files importing modules unavailable on $TARGET_PLATFORM:"
    echo -e "$CRITICAL_IMPORTS"
    echo ""
    echo "🔥 These files WILL cause compilation failures on $TARGET_PLATFORM"
    exit 1
fi

echo ""
echo "✅ Platform dependency validation PASSED"
echo "   All imports have corresponding dependencies for $TARGET_PLATFORM"