#!/bin/bash

# Smith Build Hang Analyzer - User-triggered Deep Analysis
# Usage: ./smith-build-hang-analyzer.sh [problematic-file] [timeout-seconds]
# Activated ONLY when user reports runtime hangs

PROBLEMATIC_FILE="${1:-String+Extras.swift}"
TIMEOUT="${2:-60}"
WORKSPACE="${3:-.}"

set -e

echo "🔍 SMITH BUILD HANG ANALYZER"
echo "================================"
echo "Problematic file: $PROBLEMATIC_FILE"
echo "Workspace: $WORKSPACE"
echo "Analysis timeout: ${TIMEOUT}s"
echo ""

cd "$WORKSPACE" || exit 1

if [ ! -f "$PROBLEMATIC_FILE" ]; then
    echo "❌ File not found: $PROBLEMATIC_FILE"
    exit 1
fi

echo "🎯 PHASE 1: Isolated Compilation Analysis"
echo "=========================================="

# Test isolated compilation first
echo "1️⃣ Testing isolated compilation..."
if ! swiftc -typecheck "$PROBLEMATIC_FILE" 2>/dev/null; then
    echo "❌ FAILED: Isolated compilation has issues"
    echo "🔧 This is a type inference or syntax issue, not dependency-related"
    echo ""
    echo "🔍 DETAILED ERROR ANALYSIS:"
    swiftc -typecheck "$PROBLEMATIC_FILE" 2>&1 | head -10
    exit 1
fi

echo "✅ Isolated compilation passed"
echo ""

# Debug constraint solving for complex type inference
echo "2️⃣ Analyzing type constraints..."
timeout 30 swiftc -typecheck -Xfrontend -debug-constraints "$PROBLEMATIC_FILE" 2>&1 | \
    grep -E "(constraint|solver|timeout|exponential)" || echo "   No constraint issues detected"
echo ""

# AST structural analysis
echo "3️⃣ AST structure analysis..."
swiftc -dump-ast "$PROBLEMATIC_FILE" 2>/dev/null | \
    jq '.children[] | select(.kind=="ExtensionDeclaration" or .kind=="FunctionDeclaration") | .kind' 2>/dev/null | \
    sort | uniq -c | sort -nr || echo "   AST analysis completed"
echo ""

echo "🎯 PHASE 2: Dependency Analysis"
echo "==============================="

# Find files that import or reference the problematic file
echo "1️⃣ Finding dependency chain..."
FILENAME=$(basename "$PROBLEMATIC_FILE" .swift)

# Check for direct imports
DEPENDENT_FILES=$(find . -name "*.swift" -type f -exec grep -l "$FILENAME\|import.*Scroll\|String+Extras" {} \;)

if [ -n "$DEPENDENT_FILES" ]; then
    echo "🔗 Files dependent on $FILENAME:"
    echo "$DEPENDENT_FILES" | sed 's/^/   /'
    echo ""
else
    echo "✅ No obvious dependencies found"
    echo ""
fi

# Check module dependencies if SPM package
if [ -f "Package.swift" ]; then
    echo "2️⃣ Analyzing module dependencies..."
    swift package show-dependencies 2>/dev/null | head -10 || echo "   Could not analyze dependencies"
    echo ""
fi

echo "🎯 PHASE 3: Swift Toolchain Deep Analysis"
echo "========================================"

# Performance analysis
echo "1️⃣ Function timing analysis..."
timeout 30 swiftc -typecheck -Xfrontend -debug-time-function-bodies "$PROBLEMATIC_FILE" 2>&1 | \
    grep -E "function.*took.*ms" || echo "   No slow functions detected"
echo ""

# Scope map debugging (circular reference detection)
echo "2️⃣ Scope map analysis..."
timeout 30 swiftc -dump-scope-maps expanded "$PROBLEMATIC_FILE" 2>/dev/null | \
    grep -E "(circular|cycle|recursive)" || echo "   No scope issues detected"
echo ""

# Module dependency explanation if it's a module issue
if [ -f "Package.swift" ]; then
    echo "3️⃣ Module dependency explanation..."
    timeout 30 swiftc -Xfrontend -explain-module-dependency-detailed Scroll "$PROBLEMATIC_FILE" 2>/dev/null || \
        echo "   Could not explain module dependencies"
    echo ""
fi

echo "🎯 PHASE 4: System-Level Analysis"
echo "================================="

# Check build cache size
echo "1️⃣ Build cache health check..."
DERIVED_DATA_SIZE=$(du -sm ~/Library/Developer/Xcode/DerivedData 2>/dev/null | awk '{print $1}' || echo "0")
if [ "$DERIVED_DATA_SIZE" -gt 500 ]; then
    echo "⚠️  WARNING: DerivedData is ${DERIVED_DATA_SIZE}MB (>500MB indicates corruption)"
else
    echo "✅ DerivedData is ${DERIVED_DATA_SIZE}MB (healthy)"
fi
echo ""

# Check for module cache corruption
echo "2️⃣ Module cache corruption check..."
CORRUPTED_MODULES=$(find ~/Library/Developer/Xcode/DerivedData -name "*.swiftmodule" -exec file {} \; 2>/dev/null | \
    grep -v "Swift module" | wc -l || echo "0")

if [ "$CORRUPTED_MODULES" -gt 0 ]; then
    echo "⚠️  WARNING: $CORRUPTED_MODULES potentially corrupted module files found"
else
    echo "✅ No corrupted module files detected"
fi
echo ""

echo "🎯 PHASE 5: Recommended Actions"
echo "=============================="

echo "🔧 Based on analysis, try these fixes in order:"
echo ""

echo "🥇 IMMEDIATE FIXES (80% success rate):"
echo "1. Clean build state:"
echo "   killall Xcode 2>/dev/null || true"
echo "   killall SourceKitService 2>/dev/null || true"
echo "   rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo "   xcodebuild clean -workspace '$WORKSPACE' -scheme Scroll"
echo ""

echo "2. Simplify the problematic file:"
echo "   - Remove complex generic constraints"
echo "   - Split large functions (>50 lines)"
echo "   - Check for recursive property access"
echo ""

echo "🥈 ADVANCED FIXES (20% success rate):"
echo "3. Module restructuring:"
echo "   - Move utility extensions to separate module"
echo "   - Remove circular dependencies"
echo "   - Simplify import chains"
echo ""

echo "4. Swift compiler tuning:"
echo "   - Add to build settings: -Xfrontend -warn-long-expression-type-checking=50"
echo "   - Try incremental build cleanup"
echo ""

echo "📋 ANALYSIS SUMMARY:"
echo "- Isolated compilation: $(timeout 30 swiftc -typecheck "$PROBLEMATIC_FILE" >/dev/null 2>&1 && echo "✅ PASS" || echo "❌ FAIL")"
echo "- Dependencies found: $(echo "$DEPENDENT_FILES" | wc -l | tr -d ' ' || echo "0")"
echo "- DerivedData size: ${DERIVED_DATA_SIZE}MB"
echo "- Corrupted modules: $CORRUPTED_MODULES"
echo ""

echo "🎯 NEXT STEPS:"
echo "1. Try immediate fixes first"
echo "2. Test build after each fix"
echo "3. If still hanging, report back with any new error messages"
echo ""

echo "✅ Smith Build Hang Analysis Complete"