#!/bin/bash

# SPM Package Structure Validator - Production Ready
# Detects circular imports, deep chains, problematic patterns
# Usage: ./spm-validate.sh [package-path] [--verbose]

set -e

PACKAGE_PATH="${1:-.}"
VERBOSE_MODE="${2:-}"
cd "$PACKAGE_PATH" || { echo "❌ Directory not found: $PACKAGE_PATH"; exit 1; }

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 SPM Package Structure Validator${NC}"
echo "=================================================="
echo "Package: $(basename "$PACKAGE_PATH")"
echo ""

# 1. Verify SPM package
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}❌ Not an SPM package (no Package.swift found)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SPM Package detected${NC}"
echo ""

# 2. Show external dependency graph (summary)
echo -e "${BLUE}1️⃣ External Dependency Graph:${NC}"
echo ""
swift package show-dependencies 2>/dev/null | head -40 || echo "⚠️  Could not resolve dependencies"
echo ""

# 3. Count internal targets
echo -e "${BLUE}2️⃣ Internal Target Structure:${NC}"
TARGET_COUNT=$(grep -o 'name: "[^"]*"' Package.swift | grep -v "^name: \"$(basename "$PACKAGE_PATH")\"" | sort -u | wc -l)
echo "Total targets: $TARGET_COUNT"
echo ""

# 4. CRITICAL: Detect circular imports
echo -e "${BLUE}3️⃣ Circular Import Detection (CRITICAL):${NC}"
echo ""

CIRCULAR_FOUND=0
CIRCULAR_LIST=""

if [ -d "Modules" ]; then
    for module_dir in Modules/*/Sources; do
        [ -d "$module_dir" ] || continue
        MODULE=$(basename "$(dirname "$module_dir")")

        # Get all imports from this module
        IMPORTS=$(find "$module_dir" -name "*.swift" -exec grep "^import " {} \; 2>/dev/null | sed 's/^import //' | grep -v "^Darwin\|^Foundation\|^UIKit\|^SwiftUI" | sort -u)

        # Check for self-imports first (most critical)
        if echo "$IMPORTS" | grep -q "^$MODULE$"; then
            echo -e "${RED}   🔴 SELF-IMPORT: $MODULE imports itself${NC}"
            CIRCULAR_FOUND=$((CIRCULAR_FOUND + 1))
            CIRCULAR_LIST="$CIRCULAR_LIST\n   - $MODULE (self)"
            if [ "$VERBOSE_MODE" = "--verbose" ]; then
                echo "      Files importing $MODULE:"
                find "$module_dir" -name "*.swift" -exec grep -l "^import $MODULE" {} \; | sed 's/^/         /'
            fi
        fi

        # Check for mutual imports (A imports B, B imports A)
        for imported in $IMPORTS; do
            if [ -d "Modules/$imported/Sources" ]; then
                BACK_IMPORTS=$(find "Modules/$imported/Sources" -name "*.swift" -exec grep "^import $MODULE" {} \; 2>/dev/null)
                if [ -n "$BACK_IMPORTS" ]; then
                    echo -e "${RED}   🔴 MUTUAL: $MODULE ⟷ $imported${NC}"
                    CIRCULAR_FOUND=$((CIRCULAR_FOUND + 1))
                fi
            fi
        done
    done

    if [ "$CIRCULAR_FOUND" -eq 0 ]; then
        echo -e "${GREEN}   ✅ No circular imports detected${NC}"
    else
        echo ""
        echo -e "${RED}   Found $CIRCULAR_FOUND problematic circular patterns${NC}"
    fi
else
    echo "   ℹ️  No Modules/ directory found"
fi

echo ""

# 5. Import depth analysis (high import counts slow indexing)
echo -e "${BLUE}4️⃣ Import Depth Analysis:${NC}"
echo ""

DEEP_IMPORTS=0
if [ -d "Modules" ]; then
    for swift_file in $(find Modules -name "*.swift" -type f 2>/dev/null); do
        IMPORT_COUNT=$(grep "^import " "$swift_file" 2>/dev/null | wc -l || echo 0)
        if [ -n "$IMPORT_COUNT" ] && [ "$IMPORT_COUNT" -gt 10 ]; then
            echo -e "${YELLOW}   ⚠️  $(basename "$swift_file"): $IMPORT_COUNT imports${NC}"
            DEEP_IMPORTS=$((DEEP_IMPORTS + 1))
            if [ "$VERBOSE_MODE" = "--verbose" ]; then
                echo "      Imports:"
                grep "^import " "$swift_file" | sed 's/^/         /'
            fi
        fi
    done

    if [ "$DEEP_IMPORTS" -eq 0 ]; then
        echo -e "${GREEN}   ✅ No excessive import depth detected (all files < 10 imports)${NC}"
    else
        echo ""
        echo -e "${YELLOW}   Found $DEEP_IMPORTS files with high import counts${NC}"
        echo "   💡 Refactor into smaller, focused files"
    fi
else
    echo "   ℹ️  No Modules/ directory found"
fi

echo ""

# 6. Large dependency warnings
echo -e "${BLUE}5️⃣ Dependency Size Warnings:${NC}"
echo ""

if [ -f "Package.resolved" ]; then
    if grep -q "swift-syntax" Package.resolved 2>/dev/null; then
        echo -e "${YELLOW}   ⚠️  swift-syntax detected (slow indexing, ~150MB)${NC}"
        echo "   💡 Ensure only in build tools, not runtime dependencies"
    fi

    if grep -q "grdb" Package.resolved 2>/dev/null; then
        echo -e "${YELLOW}   ℹ️  GRDB detected (large but typically necessary)${NC}"
    fi

    if grep -q "ComposableArchitecture" Package.resolved 2>/dev/null; then
        echo -e "${YELLOW}   ℹ️  TCA detected (large but typically necessary)${NC}"
    fi
else
    echo "   ℹ️  No Package.resolved found"
fi

echo ""

# 7. Final Summary
echo "=================================================="
if [ "$CIRCULAR_FOUND" -gt 0 ]; then
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo ""
    echo "Critical issues found:"
    echo -e "$CIRCULAR_LIST"
    echo ""
    echo "Action required:"
    echo "1. Remove self-imports and circular dependencies"
    echo "2. Restructure module hierarchy if needed"
    echo "3. Re-run this validator to confirm fixes"
    exit 1
elif [ "$DEEP_IMPORTS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  VALIDATION PASSED (WITH WARNINGS)${NC}"
    echo ""
    echo "No circular imports, but refactoring recommended:"
    echo "- Split files with >10 imports into smaller modules"
    echo "- Consider @_exported import to reduce re-exports"
    exit 0
else
    echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
    echo ""
    echo "Package structure is healthy:"
    echo "- No circular imports"
    echo "- Reasonable import depth"
    echo "- Ready for production"
    exit 0
fi
