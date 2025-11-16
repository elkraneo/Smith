#!/bin/bash

# SPM Package Analyzer using spmsift - Ultra Context Efficient
# Uses spmsift for xcsift-equivalent SPM analysis
# Usage: ./spm-spmsift.sh [package-path]

set -e

PACKAGE_PATH="${1:-.}"
cd "$PACKAGE_PATH" || { echo '{"error":"Directory not found"}'; exit 1; }

# Check if spmsift is available
if ! command -v spmsift &> /dev/null; then
    echo '{"error":"spmsift not found - install from https://github.com/your-org/spmsift"}'
    exit 1
fi

# Package validation
if [ ! -f "Package.swift" ]; then
    echo '{"error":"Not an SPM package (no Package.swift found)"}'
    exit 1
fi

# Use spmsift for analysis
echo '{'
echo '  "package": "'"$(basename "$PACKAGE_PATH")"'",'
echo '  "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",'
echo '  "analysis_method": "spmsift",'

# Get package analysis
PACKAGE_ANALYSIS=$(swift package dump-package 2>&1 | spmsift 2>/dev/null)
DEPS_ANALYSIS=$(swift package show-dependencies 2>&1 | spmsift 2>/dev/null)

# Extract metrics from spmsift output (with fallback)
if command -v jq &> /dev/null; then
    DEP_COUNT=$(echo "$DEPS_ANALYSIS" | jq -r '.dependencies.count // 0' 2>/dev/null || echo 0)
    TARGET_COUNT=$(echo "$PACKAGE_ANALYSIS" | jq -r '.targets.count // 0' 2>/dev/null || echo 0)
    CIRCULAR=$(echo "$DEPS_ANALYSIS" | jq -r '.dependencies.circularImports // false' 2>/dev/null || echo false)
    PACKAGE_SUCCESS=$(echo "$PACKAGE_ANALYSIS" | jq -r '.success // false' 2>/dev/null || echo false)
    DEPS_SUCCESS=$(echo "$DEPS_ANALYSIS" | jq -r '.success // false' 2>/dev/null || echo false)
else
    # Fallback without jq
    DEP_COUNT=$(echo "$DEPS_ANALYSIS" | grep -o '"count":[0-9]*' | head -1 | cut -d':' -f2 || echo 0)
    TARGET_COUNT=$(echo "$PACKAGE_ANALYSIS" | grep -o '"count":[0-9]*' | head -1 | cut -d':' -f2 || echo 0)
    CIRCULAR=$(echo "$DEPS_ANALYSIS" | grep -o '"circularImports":true' | head -1 > /dev/null && echo "true" || echo "false")
    PACKAGE_SUCCESS=$(echo "$PACKAGE_ANALYSIS" | grep -o '"success":true' | head -1 > /dev/null && echo "true" || echo "false")
    DEPS_SUCCESS=$(echo "$DEPS_ANALYSIS" | grep -o '"success":true' | head -1 > /dev/null && echo "true" || echo "false")
fi

echo '  "external_dependencies": '$DEP_COUNT','
echo '  "internal_targets": '$TARGET_COUNT','

# Combine issues from both analyses
echo '  "issues": {'
echo '    "circular_imports": '$CIRCULAR','
echo '    "package_errors": '$(echo "$PACKAGE_ANALYSIS" | jq '.issues // []' 2>/dev/null || echo "[]")','
echo '    "dependency_errors": '$(echo "$DEPS_ANALYSIS" | jq '.issues // []' 2>/dev/null || echo "[]")'
echo '  },'

# Calculate result
if [ "$CIRCULAR" = "true" ] || [ "$PACKAGE_SUCCESS" != "true" ] || [ "$DEPS_SUCCESS" != "true" ]; then
    echo '  "result": "CRITICAL"'
else
    echo '  "result": "PASS"'
fi

echo '  "spmsift_analysis": {'
echo '    "package": '$PACKAGE_ANALYSIS','
echo '    "dependencies": '$DEPS_ANALYSIS
echo '  }'

echo '}'