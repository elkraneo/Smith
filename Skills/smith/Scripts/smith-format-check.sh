#!/bin/bash

# Smith Framework - Swift Format Validation with Smith Rules
# Checks Swift formatting and Smith pattern compliance

set -e

echo "🎨 Smith Framework: Format & Pattern Validation"
echo "==============================================="

# Check for Swift Format
if ! command -v swift-format &> /dev/null; then
    echo "⚠️ Swift Format not found"
    echo "Install with: xcode-select --install"
    echo "Or ensure Xcode Command Line Tools are installed"
    exit 1
fi

# Configuration files
SMITH_RULES_PATH="$(dirname "$0")/../Resources/smith-rules.json"
TEMP_CONFIG="/tmp/smith-swift-format.json"

# Create Swift Format config with Smith rules
if [[ -f "$SMITH_RULES_PATH" ]]; then
    echo "📋 Using Smith rules from: $SMITH_RULES_PATH"
    # Extract Swift Format configuration from Smith rules
    cat "$SMITH_RULES_PATH" | jq '.swift_format' > "$TEMP_CONFIG" || echo '{}' > "$TEMP_CONFIG"
else
    echo "📋 Using default Swift Format configuration"
    echo '{}' > "$TEMP_CONFIG"
fi

# Find Swift files
if [[ -f "Package.swift" ]]; then
    SOURCES=$(find Sources -name "*.swift" -type f 2>/dev/null || true)
    echo "📦 Swift Package Manager project"
elif [[ -d "*.xcodeproj" ]]; then
    SOURCES=$(find . -name "*.swift" -type f -not -path "./Build/*" 2>/dev/null || true)
    echo "🏗️ Xcode project"
else
    SOURCES=$(find . -name "*.swift" -maxdepth 3 -type f 2>/dev/null || true)
    echo "📝 Current directory"
fi

if [[ -z "$SOURCES" ]]; then
    echo "❌ No Swift files found"
    rm -f "$TEMP_CONFIG"
    exit 1
fi

echo "📝 Checking Swift files:"
echo "$SOURCES"
echo

# Run Swift Format lint
echo "🔧 Running Swift Format lint..."
echo

FORMAT_ISSUES=0
SMITH_VIOLATIONS=0

# Check formatting and Smith patterns
for file in $SOURCES; do
    echo "Checking: $file"

    # Swift Format linting
    if swift-format lint --configuration "$TEMP_CONFIG" "$file" 2>/dev/null; then
        echo "✅ Formatting OK"
    else
        echo "⚠️ Formatting issues found"
        FORMAT_ISSUES=$((FORMAT_ISSUES + 1))
        echo "   → Run: swift-format format $file"
    fi

    # Smith pattern validation
    echo "   🔍 Checking Smith patterns..."

    # Check for deprecated patterns
    if grep -q "WithViewStore" "$file"; then
        echo "   ❌ Found WithViewStore (deprecated - use @Bindable)"
        SMITH_VIOLATIONS=$((SMITH_VIOLATIONS + 1))
    fi

    if grep -q "@Perception\.Bindable" "$file"; then
        echo "   ❌ Found @Perception.Bindable (deprecated - use @Bindable)"
        SMITH_VIOLATIONS=$((SMITH_VIOLATIONS + 1))
    fi

    if grep -q "Shared(" "$file"; then
        echo "   ❌ Found Shared( constructor (use Shared(wrappedValue:))"
        SMITH_VIOLATIONS=$((SMITH_VIOLATIONS + 1))
    fi

    if grep -q "Task\.detached" "$file"; then
        echo "   ❌ Found Task.detached (use Task { @MainActor in })"
        SMITH_VIOLATIONS=$((SMITH_VIOLATIONS + 1))
    fi

    if grep -q "@State.*State" "$file"; then
        echo "   ❌ Found @State for TCA State (use @ObservableState)"
        SMITH_VIOLATIONS=$((SMITH_VIOLATIONS + 1))
    fi

    if [[ $SMITH_VIOLATIONS -eq 0 ]]; then
        echo "   ✅ No Smith pattern violations"
    fi

    echo
done

# Cleanup
rm -f "$TEMP_CONFIG"

# Summary
echo "📊 Format & Pattern Validation Summary"
echo "====================================="

if [[ $FORMAT_ISSUES -eq 0 && $SMITH_VIOLATIONS -eq 0 ]]; then
    echo "🎉 All checks passed!"
    echo "✅ Swift formatting is correct"
    echo "✅ Smith patterns are followed"
    echo
    echo "Ready for production!"
    exit 0
else
    echo "⚠️ Issues found that need attention:"

    if [[ $FORMAT_ISSUES -gt 0 ]]; then
        echo "  - $FORMAT_ISSUES file(s) have formatting issues"
        echo "    Fix: swift-format format [files]"
    fi

    if [[ $SMITH_VIOLATIONS -gt 0 ]]; then
        echo "  - $SMITH_VIOLATIONS Smith pattern violation(s)"
        echo "    Fix: Review AGENTS-TCA-PATTERNS.md for correct patterns"
    fi

    echo
    echo "📚 References:"
    echo "  - AGENTS-TCA-PATTERNS.md (Pattern guidance)"
    echo "  - CLAUDE.md (Syntax-first rules)"
    echo "  - DISCOVERY case studies (Common issues)"

    exit 1
fi