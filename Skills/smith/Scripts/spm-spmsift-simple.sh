#!/bin/bash

# Simple SPM Analyzer using spmsift - Ultra Context Efficient
# Usage: ./spm-spmsift-simple.sh [package-path]

set -e

PACKAGE_PATH="${1:-.}"
cd "$PACKAGE_PATH" || { echo '{"error":"Directory not found"}'; exit 1; }

# Validation
if [ ! -f "Package.swift" ]; then
    echo '{"error":"Not an SPM package"}'
    exit 1
fi

if ! command -v spmsift &> /dev/null; then
    echo '{"error":"spmsift not found. Install with: brew install elkraneo/tap/spmsift"}'
    exit 1
fi

# Simple analysis using spmsift
echo '{'
echo '  "package": "'"$(basename "$PACKAGE_PATH")"'",'
echo '  "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",'
echo '  "tool": "spmsift",'
echo '  "analysis": '

# Use spmsift and embed its output directly
swift package dump-package 2>&1 | spmsift

echo '}'