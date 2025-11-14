#!/bin/bash

# Smith Framework - Syntax Validation Script
# FIRST LINE OF DEFENSE: Always check compilation before patterns

set -e

echo "🔍 Smith Framework: Syntax Validation"
echo "=================================="

# Find Swift source files first
SOURCES=$(find . -name "*.swift" -type f -not -path "./Build/*" -not -path "./DerivedData/*" 2>/dev/null || true)

if [[ -z "$SOURCES" ]]; then
    echo "❌ No Swift source files found"
    echo "Current directory: $(pwd)"
    echo "Looking for .swift files..."
    find . -name "*.swift" -type f 2>/dev/null | head -5 || echo "No .swift files found anywhere"
    exit 1
fi

# Detect project type
if [[ -f "Package.swift" ]]; then
    echo "📦 Swift Package Manager detected"
elif [[ -n "$(find . -maxdepth 1 -name "*.xcodeproj" -type d)" ]]; then
    echo "🏗️ Xcode project detected"
else
    echo "📝 Swift files found in current directory"
fi


echo "📝 Found Swift files:"
echo "$SOURCES" | head -10
if [[ $(echo "$SOURCES" | wc -l) -gt 10 ]]; then
    echo "... and more"
fi
echo

# Syntax validation with swiftc
echo "🔧 Running syntax validation..."
echo

SYNTAX_ERRORS=0

for file in $SOURCES; do
    echo "Checking: $file"
    if swiftc -typecheck "$file" 2>&1; then
        echo "✅ $file - Syntax OK"
    else
        echo "❌ $file - SYNTAX ERROR"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        echo "   → Fix syntax errors before applying Smith patterns"
        echo "   → Run: swiftc -typecheck $file"
    fi
    echo
done

# Summary
echo "📊 Syntax Validation Summary"
echo "==========================="
if [[ $SYNTAX_ERRORS -eq 0 ]]; then
    echo "✅ All files pass syntax validation"
    echo "🎉 Ready to apply Smith patterns!"
    echo
    echo "Next steps:"
    echo "1. Read Smith documentation for your task type"
    echo "2. Follow verification checklists"
    echo "3. Implement patterns"
    exit 0
else
    echo "❌ $SYNTAX_ERRORS files have syntax errors"
    echo
    echo "⚠️ SMITH FRAMEWORK RULE: Syntax Before Patterns"
    echo "Fix all syntax errors before proceeding with Smith patterns."
    echo
    echo "Common fixes:"
    echo "- Missing imports"
    echo "- Type mismatches"
    echo "- Missing braces/semicolons"
    echo "- Incorrect function signatures"
    exit 1
fi