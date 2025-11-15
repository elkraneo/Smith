#!/bin/bash

# SPM Quick Check - Minimal Output
# Usage: ./spm-quick.sh [package-path]

set -e

PACKAGE_PATH="${1:-.}"
cd "$PACKAGE_PATH" || { echo "❌ Directory not found: $PACKAGE_PATH"; exit 1; }

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "Package.swift" ]; then
    echo -e "${RED}❌ Not an SPM package${NC}"
    exit 1
fi

CRITICAL=0
WARNINGS=0

# Check circular imports
if [ -d "Modules" ]; then
    for module_dir in Modules/*/Sources; do
        [ -d "$module_dir" ] || continue
        MODULE=$(basename "$(dirname "$module_dir")")

        IMPORTS=$(find "$module_dir" -name "*.swift" -exec grep "^import " {} \; 2>/dev/null | sed 's/^import //' | grep -v "^Darwin\|^Foundation\|^UIKit\|^SwiftUI" | sort -u)

        if echo "$IMPORTS" | grep -q "^$MODULE$"; then
            echo -e "${RED}🔴 SELF-IMPORT: $MODULE${NC}"
            CRITICAL=$((CRITICAL + 1))
        fi

        for imported in $IMPORTS; do
            if [ -d "Modules/$imported/Sources" ]; then
                if find "Modules/$imported/Sources" -name "*.swift" -exec grep "^import $MODULE" {} \; 2>/dev/null | grep -q .; then
                    echo -e "${RED}🔴 MUTUAL: $MODULE ⟷ $imported${NC}"
                    CRITICAL=$((CRITICAL + 1))
                fi
            fi
        done
    done
fi

# Check deep imports
if [ -d "Modules" ]; then
    for swift_file in $(find Modules -name "*.swift" -type f 2>/dev/null); do
        IMPORT_COUNT=$(grep "^import " "$swift_file" 2>/dev/null | wc -l || echo 0)
        if [ -n "$IMPORT_COUNT" ] && [ "$IMPORT_COUNT" -gt 10 ]; then
            echo -e "${YELLOW}⚠️  $(basename "$swift_file"): $IMPORT_COUNT imports${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi

if [ "$CRITICAL" -gt 0 ]; then
    echo -e "${RED}❌ CRITICAL ISSUES ($CRITICAL)${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNINGS ($WARNINGS)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ PASS${NC}"
    exit 0
fi