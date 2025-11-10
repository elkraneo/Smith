# CI/CD Integration for Smith Compliance

**Automate Smith framework compliance checking in your CI/CD pipeline and pre-commit hooks.**

---

## Overview

This guide shows you how to:
1. Add pre-commit hooks to catch violations before committing
2. Integrate compliance checks into CI/CD (GitHub Actions, GitLab CI, etc.)
3. Enforce coverage requirements
4. Track compliance trends over time
5. Block PRs that violate Smith patterns

---

## Pre-Commit Hook (Local Development)

### Quick Setup

```bash
# In your project root
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
#
# Pre-commit hook: Check Smith compliance before allowing commit
#

SMITH_PATH="/path/to/Smith"  # Update this path

echo "🔍 Checking Smith compliance..."

# Run compliance check
if ! "$SMITH_PATH/Scripts/check-compliance.sh" . --strict; then
  echo ""
  echo "❌ Commit blocked: Smith compliance violations found"
  echo ""
  echo "Fix violations or use --no-verify to skip (not recommended)"
  exit 1
fi

echo "✅ Smith compliance check passed"
exit 0
EOF

chmod +x .git/hooks/pre-commit
```

### Bypass When Needed

```bash
# Emergency commits (use sparingly)
git commit --no-verify -m "emergency fix"
```

---

## GitHub Actions Integration

### Workflow File

Create `.github/workflows/smith-compliance.yml`:

```yaml
name: Smith Compliance Check

on:
  pull_request:
    branches: [main, master, develop]
  push:
    branches: [main, master, develop]

jobs:
  compliance:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Checkout Smith framework
        uses: actions/checkout@v4
        with:
          repository: YourOrg/Smith  # Update to your Smith repo
          path: .smith-framework
          ref: v1.1.0  # Pin to specific version

      - name: Run Smith compliance check
        id: compliance
        run: |
          .smith-framework/Scripts/check-compliance.sh . --json > compliance-report.json
          cat compliance-report.json

          # Parse results
          VIOLATIONS=$(cat compliance-report.json | jq -r '.summary.violations // 0')
          WARNINGS=$(cat compliance-report.json | jq -r '.summary.warnings // 0')

          echo "violations=$VIOLATIONS" >> $GITHUB_OUTPUT
          echo "warnings=$WARNINGS" >> $GITHUB_OUTPUT

          if [ "$VIOLATIONS" -gt 0 ]; then
            echo "❌ $VIOLATIONS violations found"
            exit 1
          fi

          if [ "$WARNINGS" -gt 5 ]; then
            echo "⚠️  $WARNINGS warnings found (threshold: 5)"
            exit 1
          fi

          echo "✅ Compliance check passed"

      - name: Generate compliance report
        if: always()
        run: |
          .smith-framework/Scripts/compliance-report.sh . --save compliance-full-report.json

      - name: Upload compliance report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: smith-compliance-report
          path: |
            compliance-report.json
            compliance-full-report.json

      - name: Comment PR with results
        if: github.event_name == 'pull_request' && failure()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = JSON.parse(fs.readFileSync('compliance-report.json', 'utf8'));

            const violations = report.summary.violations || 0;
            const warnings = report.summary.warnings || 0;

            const body = `## ❌ Smith Compliance Check Failed

            **Violations:** ${violations}
            **Warnings:** ${warnings}

            ### Issues Found

            ${report.violations.map(v =>
              `- **${v.level.toUpperCase()}**: ${v.message}
              - File: \`${v.file}\`
              - Line: ${v.line || 'N/A'}
              - Fix: ${v.remedy || 'See QUICK-START.md'}`
            ).join('\n\n')}

            ### Next Steps

            1. Read [QUICK-START.md](https://github.com/YourOrg/Smith/blob/main/QUICK-START.md)
            2. Fix violations listed above
            3. Run \`Smith/Scripts/check-compliance.sh .\` locally
            4. Push fixes

            See [Smith Framework](https://github.com/YourOrg/Smith) for patterns.
            `;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });

  test-coverage:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Run tests with coverage
        run: |
          swift test --enable-code-coverage

      - name: Generate coverage report
        run: |
          xcrun llvm-cov export \
            .build/debug/MyAppPackageTests.xctest/Contents/MacOS/MyAppPackageTests \
            -instr-profile=.build/debug/codecov/default.profdata \
            -format=lcov > coverage.lcov

      - name: Check coverage threshold
        run: |
          COVERAGE=$(xcrun llvm-cov report \
            .build/debug/MyAppPackageTests.xctest/Contents/MacOS/MyAppPackageTests \
            -instr-profile=.build/debug/codecov/default.profdata | \
            grep TOTAL | awk '{print $NF}' | sed 's/%//')

          echo "Coverage: $COVERAGE%"

          if (( $(echo "$COVERAGE < 75" | bc -l) )); then
            echo "❌ Coverage $COVERAGE% below threshold (75%)"
            exit 1
          fi

          echo "✅ Coverage check passed"

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.lcov
          fail_ci_if_error: true
```

---

## GitLab CI Integration

Create `.gitlab-ci.yml`:

```yaml
stages:
  - compliance
  - test
  - report

variables:
  SMITH_VERSION: "v1.1.0"

smith_compliance:
  stage: compliance
  image: macos:latest
  script:
    - git clone --depth 1 --branch $SMITH_VERSION https://github.com/YourOrg/Smith.git .smith
    - .smith/Scripts/check-compliance.sh . --json > compliance-report.json
    - cat compliance-report.json
    - |
      VIOLATIONS=$(jq -r '.summary.violations // 0' compliance-report.json)
      if [ "$VIOLATIONS" -gt 0 ]; then
        echo "❌ $VIOLATIONS violations found"
        exit 1
      fi
  artifacts:
    reports:
      junit: compliance-report.json
    when: always
  only:
    - merge_requests
    - main
    - develop

test_coverage:
  stage: test
  image: macos:latest
  script:
    - swift test --enable-code-coverage
    - |
      COVERAGE=$(xcrun llvm-cov report \
        .build/debug/MyAppPackageTests.xctest/Contents/MacOS/MyAppPackageTests \
        -instr-profile=.build/debug/codecov/default.profdata | \
        grep TOTAL | awk '{print $NF}' | sed 's/%//')
      echo "Coverage: $COVERAGE%"
      if (( $(echo "$COVERAGE < 75" | bc -l) )); then
        exit 1
      fi
  coverage: '/TOTAL.*\s+(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
  only:
    - merge_requests
    - main

compliance_report:
  stage: report
  image: macos:latest
  script:
    - git clone --depth 1 --branch $SMITH_VERSION https://github.com/YourOrg/Smith.git .smith
    - .smith/Scripts/compliance-report.sh . --save report.json
    - .smith/Scripts/compliance-report.sh . --history
  artifacts:
    paths:
      - report.json
      - .smith-compliance-history/
    expire_in: 30 days
  when: always
```

---

## Xcode Cloud Integration

Create `.xcode-cloud/ci_post_clone.sh`:

```bash
#!/bin/bash

set -e

# Clone Smith framework
git clone --depth 1 --branch v1.1.0 https://github.com/YourOrg/Smith.git $CI_WORKSPACE/.smith

# Run compliance check
if ! $CI_WORKSPACE/.smith/Scripts/check-compliance.sh $CI_PRIMARY_REPOSITORY_PATH; then
  echo "❌ Smith compliance check failed"
  exit 1
fi

echo "✅ Smith compliance check passed"

# Generate report
$CI_WORKSPACE/.smith/Scripts/compliance-report.sh $CI_PRIMARY_REPOSITORY_PATH --save compliance-report.json

exit 0
```

Make executable:
```bash
chmod +x .xcode-cloud/ci_post_clone.sh
```

---

## Custom Git Hooks (Team-wide)

### Setup Script

Create `Scripts/setup-hooks.sh` in your project:

```bash
#!/bin/bash
#
# Setup Smith compliance hooks for all developers
#

set -e

SMITH_PATH="${SMITH_PATH:-../Smith}"  # Default to sibling directory
HOOKS_DIR=".git/hooks"

echo "🔧 Setting up Smith compliance hooks..."

# Pre-commit hook
cat > "$HOOKS_DIR/pre-commit" <<EOF
#!/bin/bash
# Auto-generated by setup-hooks.sh

SMITH_PATH="$SMITH_PATH"

echo "🔍 Checking Smith compliance..."

if ! "\$SMITH_PATH/Scripts/check-compliance.sh" . --strict; then
  echo ""
  echo "❌ Commit blocked: Smith compliance violations"
  echo ""
  echo "Run 'Scripts/fix-compliance.sh' or use --no-verify to skip"
  exit 1
fi

echo "✅ Compliance check passed"
exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"

# Pre-push hook (runs tests)
cat > "$HOOKS_DIR/pre-push" <<'EOF'
#!/bin/bash
# Auto-generated by setup-hooks.sh

echo "🧪 Running tests before push..."

if ! swift test; then
  echo ""
  echo "❌ Push blocked: Tests failed"
  echo ""
  echo "Fix tests or use --no-verify to skip (not recommended)"
  exit 1
fi

echo "✅ Tests passed"
exit 0
EOF

chmod +x "$HOOKS_DIR/pre-push"

# Commit-msg hook (enforce commit format)
cat > "$HOOKS_DIR/commit-msg" <<'EOF'
#!/bin/bash
# Auto-generated by setup-hooks.sh

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Check for Smith-style commit message
if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|docs|refactor|test|chore|perf|style|ci|build)(\(.+\))?:'; then
  echo ""
  echo "❌ Commit message must follow conventional commit format:"
  echo ""
  echo "  <type>(<scope>): <description>"
  echo ""
  echo "Types: feat, fix, docs, refactor, test, chore, perf, style, ci, build"
  echo ""
  echo "Examples:"
  echo "  feat(auth): add login flow"
  echo "  fix(api): handle network errors"
  echo "  docs: update README"
  echo ""
  exit 1
fi

echo "✅ Commit message format valid"
exit 0
EOF

chmod +x "$HOOKS_DIR/commit-msg"

echo ""
echo "✅ Git hooks installed successfully"
echo ""
echo "Hooks installed:"
echo "  - pre-commit: Smith compliance check"
echo "  - pre-push: Run tests"
echo "  - commit-msg: Enforce commit format"
echo ""
echo "To bypass: git commit --no-verify"
echo ""
```

### Team Onboarding

Add to your project's README:

```markdown
## Developer Setup

After cloning, run:

```bash
./Scripts/setup-hooks.sh
```

This installs git hooks for:
- Smith compliance checking (pre-commit)
- Test running (pre-push)
- Commit message formatting (commit-msg)
```

---

## Husky Integration (Node/Web Projects)

If using Node.js tooling:

```bash
npm install --save-dev husky
npx husky init
```

Create `.husky/pre-commit`:

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Check Swift code compliance
if [ -d "Sources" ] || [ -d "src" ]; then
  ../Smith/Scripts/check-compliance.sh . --strict || exit 1
fi
```

---

## Compliance Dashboard (Advanced)

### Track Compliance Over Time

Create `Scripts/track-compliance.sh`:

```bash
#!/bin/bash
#
# Track compliance trends and generate dashboard
#

HISTORY_DIR=".smith-compliance-history"
mkdir -p "$HISTORY_DIR"

# Run compliance check with history
../Smith/Scripts/compliance-report.sh . --history

# Generate trend chart (requires gnuplot)
if command -v gnuplot &> /dev/null; then
  cat > /tmp/compliance-trend.gp <<EOF
set terminal png size 800,600
set output 'compliance-trend.png'
set title 'Smith Compliance Trend'
set xlabel 'Date'
set ylabel 'Score'
set xdata time
set timefmt "%Y%m%d_%H%M%S"
set format x "%m/%d"
set yrange [0:100]
set grid
plot '$HISTORY_DIR/*.json' using 1:2 with linespoints title 'Compliance Score'
EOF

  gnuplot /tmp/compliance-trend.gp
  echo "📊 Trend chart saved: compliance-trend.png"
fi

# Generate HTML report
cat > compliance-dashboard.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Smith Compliance Dashboard</title>
  <style>
    body { font-family: system-ui; max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }
    .metric { display: inline-block; margin: 1rem; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; }
    .score { font-size: 3rem; font-weight: bold; }
    .grade-A { color: green; }
    .grade-B { color: orange; }
    .grade-C { color: red; }
  </style>
</head>
<body>
  <h1>Smith Compliance Dashboard</h1>
  <div class="metrics">
    <!-- Populated by JavaScript -->
  </div>
  <img src="compliance-trend.png" alt="Trend" />
</body>
</html>
EOF

echo "📊 Dashboard generated: compliance-dashboard.html"
```

---

## Branch Protection Rules

### GitHub

1. Go to **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require status checks to pass
   - ✅ Require `Smith Compliance Check` check
   - ✅ Require `Test Coverage` check
   - ✅ Require branches to be up to date
4. Save

### GitLab

In `.gitlab-ci.yml`:

```yaml
workflow:
  rules:
    - if: $CI_MERGE_REQUEST_IID
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

compliance_gate:
  stage: .pre
  script:
    - .smith/Scripts/check-compliance.sh . --strict
  allow_failure: false
  only:
    - merge_requests
```

---

## Enforcement Policies

### Strict (Recommended for Production)

```yaml
# .github/workflows/smith-compliance.yml
- name: Strict compliance check
  run: |
    .smith/Scripts/check-compliance.sh . --strict
    # Fails on ANY violation or warning
```

### Lenient (Development)

```yaml
# .github/workflows/smith-compliance.yml
- name: Lenient compliance check
  run: |
    .smith/Scripts/check-compliance.sh .
    # Fails only on violations, warnings allowed
```

### Warning-Only (Transition Period)

```yaml
# .github/workflows/smith-compliance.yml
- name: Warning-only compliance check
  run: |
    .smith/Scripts/check-compliance.sh . || true
    # Never fails, only reports
```

---

## Troubleshooting

### Hook Not Running

```bash
# Check if hook is executable
ls -l .git/hooks/pre-commit

# Make executable
chmod +x .git/hooks/pre-commit
```

### False Positives

```bash
# Run compliance check manually
Smith/Scripts/check-compliance.sh . --strict

# Check specific rule
grep -n "pattern" Sources/MyFile.swift
```

### CI Timeout

```yaml
# Increase timeout
jobs:
  compliance:
    timeout-minutes: 15  # Default is 360
```

### Smith Framework Not Found

```yaml
# Verify Smith path in CI
- run: ls -la .smith-framework
- run: cat .smith-framework/QUICK-START.md
```

---

## Best Practices

### For Individuals

1. ✅ Install pre-commit hook immediately
2. ✅ Run `check-compliance.sh` before pushing
3. ✅ Review violations in QUICK-START.md
4. ✅ Use `--no-verify` only in emergencies

### For Teams

1. ✅ Enforce hooks via setup script in onboarding
2. ✅ Require CI checks on all PRs
3. ✅ Block merge if compliance fails
4. ✅ Track compliance trends monthly
5. ✅ Review new violations in team retrospectives

### For Organizations

1. ✅ Centralize Smith framework (single repo)
2. ✅ Version pin Smith in CI (e.g., v1.1.0)
3. ✅ Automate Smith sync to projects weekly
4. ✅ Generate compliance dashboards
5. ✅ Include compliance score in engineering metrics

---

## Summary

| Integration | Setup Time | Enforcement | Best For |
|-------------|------------|-------------|----------|
| Pre-commit hook | 2 min | Local only | Individual developers |
| GitHub Actions | 15 min | PR + merge | Teams using GitHub |
| GitLab CI | 15 min | PR + merge | Teams using GitLab |
| Xcode Cloud | 10 min | All builds | Apple platform teams |
| Custom hooks | 30 min | Team-wide | Any Git workflow |
| Compliance dashboard | 60 min | Reporting only | Engineering leadership |

---

**Last Updated:** November 10, 2025
**Smith Version:** v1.1.0
**Related:** Scripts/check-compliance.sh, Scripts/compliance-report.sh
