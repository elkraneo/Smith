#!/bin/bash

# SPM Package Analyzer - Context Efficient JSON Output
# Equivalent to xcsift for SPM analysis
# Usage: ./spm-analyze.sh [package-path] [--verbose]

set -e

PACKAGE_PATH="${1:-.}"
VERBOSE_MODE="${2:-}"
cd "$PACKAGE_PATH" || { echo '{"error":"Directory not found"}'; exit 1; }

# Initialize JSON structure
echo '{'
echo '  "package": "'"$(basename "$PACKAGE_PATH")"'",'
echo '  "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",'

# 1. Package validation
if [ ! -f "Package.swift" ]; then
    echo '  "status": "error",'
    echo '  "error": "Not an SPM package (no Package.swift found)"'
    echo '}'
    exit 1
fi

echo '  "status": "analyzing",'

# 2. External dependencies count
DEP_COUNT=$(swift package show-dependencies 2>/dev/null | grep -c "├─\|└─" 2>/dev/null || echo 0)
echo '  "external_dependencies": '$DEP_COUNT','

# 3. Internal targets
TARGET_COUNT=$(grep -o 'name: "[^"]*"' Package.swift | grep -v "^name: \"$(basename "$PACKAGE_PATH")\"" | sort -u | wc -l)
echo '  "internal_targets": '$TARGET_COUNT','

# 4. Critical issues
echo '  "issues": {'

CIRCULAR_FOUND=0
DEEP_IMPORTS=0
SELF_IMPORTS=0
MUTUAL_IMPORTS=0

if [ -d "Modules" ]; then
    # Check circular imports
    echo '    "circular_imports": ['

    FIRST=true
    for module_dir in Modules/*/Sources; do
        [ -d "$module_dir" ] || continue
        MODULE=$(basename "$(dirname "$module_dir")")

        IMPORTS=$(find "$module_dir" -name "*.swift" -exec grep "^import " {} \; 2>/dev/null | sed 's/^import //' | grep -v "^Darwin\|^Foundation\|^UIKit\|^SwiftUI" | sort -u)

        # Self-import detection
        if echo "$IMPORTS" | grep -q "^$MODULE$"; then
            if [ "$FIRST" = false ]; then echo ','; fi
            echo '      {'
            echo '        "type": "self",'
            echo '        "module": "'$MODULE'",'
            echo '        "severity": "critical"'
            echo -n '      }'
            FIRST=false
            SELF_IMPORTS=$((SELF_IMPORTS + 1))
            CIRCULAR_FOUND=$((CIRCULAR_FOUND + 1))
        fi

        # Mutual import detection
        for imported in $IMPORTS; do
            if [ -d "Modules/$imported/Sources" ]; then
                BACK_IMPORTS=$(find "Modules/$imported/Sources" -name "*.swift" -exec grep "^import $MODULE" {} \; 2>/dev/null)
                if [ -n "$BACK_IMPORTS" ]; then
                    if [ "$FIRST" = false ]; then echo ','; fi
                    echo '      {'
                    echo '        "type": "mutual",'
                    echo '        "modules": ["'$MODULE'", "'$imported'"],'
                    echo '        "severity": "critical"'
                    echo -n '      }'
                    FIRST=false
                    MUTUAL_IMPORTS=$((MUTUAL_IMPORTS + 1))
                    CIRCULAR_FOUND=$((CIRCULAR_FOUND + 1))
                fi
            fi
        done
    done

    if [ "$FIRST" = true ]; then
        echo '      null'
    fi
    echo '    ],'

    # Import depth analysis
    echo '    "deep_imports": ['

    FIRST=true
    for swift_file in $(find Modules -name "*.swift" -type f 2>/dev/null); do
        IMPORT_COUNT=$(grep "^import " "$swift_file" 2>/dev/null | wc -l || echo 0)
        if [ -n "$IMPORT_COUNT" ] && [ "$IMPORT_COUNT" -gt 10 ]; then
            if [ "$FIRST" = false ]; then echo ','; fi
            echo '      {'
            echo '        "file": "'$(basename "$swift_file")'",'
            echo '        "path": "'$(echo "$swift_file" | sed 's/"/\\"/g')'",'
            echo '        "import_count": '$IMPORT_COUNT','
            echo '        "severity": "warning"'
            echo -n '      }'
            FIRST=false
            DEEP_IMPORTS=$((DEEP_IMPORTS + 1))
        fi
    done

    if [ "$FIRST" = true ]; then
        echo '      null'
    fi
    echo '    ]'
else
    echo '    "circular_imports": null,'
    echo '    "deep_imports": null'
fi

echo '  },'

# 5. Large dependencies
echo '  "large_dependencies": {'
if [ -f "Package.resolved" ]; then
    SWIFT_SYNTAX=false
    GRDB=false
    TCA=false

    if grep -q "swift-syntax" Package.resolved 2>/dev/null; then SWIFT_SYNTAX=true; fi
    if grep -q "grdb" Package.resolved 2>/dev/null; then GRDB=true; fi
    if grep -q "ComposableArchitecture" Package.resolved 2>/dev/null; then TCA=true; fi

    echo '    "swift_syntax": '$SWIFT_SYNTAX','
    echo '    "grdb": '$GRDB','
    echo '    "tca": '$TCA
else
    echo '    "resolved": false'
fi
echo '  },'

# 6. Summary metrics
echo '  "metrics": {'
echo '    "circular_imports": '$CIRCULAR_FOUND','
echo '    "self_imports": '$SELF_IMPORTS','
echo '    "mutual_imports": '$MUTUAL_IMPORTS','
echo '    "files_with_deep_imports": '$DEEP_IMPORTS
echo '  },'

# 7. Final status
echo '  "result": '
if [ "$CIRCULAR_FOUND" -gt 0 ]; then
    echo '"CRITICAL"'
elif [ "$DEEP_IMPORTS" -gt 0 ]; then
    echo '"WARNING"'
else
    echo '"PASS"'
fi

echo '}'