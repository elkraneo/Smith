#!/bin/bash

# SPM Build Diagnostics - Find why targets aren't building
# Checks dependency graph, missing targets, compilation errors
# Usage: ./spm-diagnose-build.sh [workspace-path] [scheme]

WORKSPACE="${1:-.}"
SCHEME="${2:-Scroll}"

cd "$WORKSPACE" || exit 1

echo "📊 SPM Build Diagnostics"
echo "=================================================="
echo "Workspace: $WORKSPACE"
echo "Scheme: $SCHEME"
echo ""

# 1. Check if target exists
echo "1️⃣ Checking if ArticleReader is defined..."
if grep -q "ArticleReader" ScrollModules/Package.swift; then
    echo "✅ ArticleReader found in Package.swift"
    grep "ArticleReader" ScrollModules/Package.swift | grep "name:" | head -5
else
    echo "❌ ArticleReader NOT found in Package.swift"
fi

echo ""

# 2. Check if target has directory
echo "2️⃣ Checking if ArticleReader source directory exists..."
if [ -d "ScrollModules/Modules/ArticleReader/Sources" ]; then
    echo "✅ ArticleReader source directory exists"
    echo "   Contents:"
    ls -la ScrollModules/Modules/ArticleReader/Sources/ | tail -n +4
else
    echo "❌ ArticleReader source directory missing"
fi

echo ""

# 3. Try to resolve dependencies
echo "3️⃣ Resolving Package.swift..."
cd ScrollModules
swift package describe 2>&1 | grep -E "Name:|Products:|Targets:" -A 5 | head -30
cd ..

echo ""

# 4. Show scheme targets
echo "4️⃣ Checking Scroll scheme configuration..."
xcodebuild -workspace Scroll.xcodeproj/project.xcworkspace -scheme "$SCHEME" -showBuildSettings 2>&1 | grep -E "PRODUCT_NAME|EXECUTABLE_NAME|EXECUTABLE_PATH" | head -10

echo ""

# 5. Check for ArticleReader compilation errors
echo "5️⃣ Checking for compilation errors in ArticleReader..."
if [ -f "build.log" ]; then
    if grep -q "ArticleReader" build.log; then
        echo "⚠️  ArticleReader mentioned in build log:"
        grep -i "articlereader" build.log | grep -i "error" | head -5
    else
        echo "ℹ️  ArticleReader not mentioned in build.log"
    fi
else
    echo "ℹ️  No build.log found"
fi

echo ""
echo "=================================================="
echo "Diagnosis complete. Check results above."
