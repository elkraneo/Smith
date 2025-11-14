#!/usr/bin/env node

/**
 * Smith Framework - TCA Pattern Validation Script
 * Validates Swift Composable Architecture patterns against Smith rules
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Smith Framework: TCA Pattern Validation');
console.log('=========================================');

// Smith TCA Pattern Rules
const SMITH_PATTERNS = {
  // Deprecated patterns that should NOT be used
  deprecated: [
    {
      pattern: /WithViewStore/,
      message: '❌ WithViewStore is deprecated. Use @Bindable instead',
      reference: 'AGENTS-TCA-PATTERNS.md Mistake 1'
    },
    {
      pattern: /ViewStore\(/,
      message: '❌ ViewStore initialization is deprecated. Use @Bindable',
      reference: 'AGENTS-TCA-PATTERNS.md Quick Reference'
    },
    {
      pattern: /@Perception\.Bindable/,
      message: '❌ @Perception.Bindable is deprecated. Use TCA @Bindable',
      reference: 'AGENTS-TCA-PATTERNS.md Quick Reference'
    }
  ],

  // Required patterns for modern TCA
  required: [
    {
      pattern: /@Reducer/,
      message: '✅ Using modern @Reducer macro',
      type: 'positive'
    },
    {
      pattern: /@ObservableState/,
      message: '✅ Using @ObservableState for state',
      type: 'positive'
    },
    {
      pattern: /@Bindable/,
      message: '✅ Using @Bindable for view bindings',
      type: 'positive'
    }
  ],

  // Common anti-patterns
  antiPatterns: [
    {
      pattern: /@State.*var.*State/,
      message: '❌ @State should not be used for TCA State. Use @ObservableState',
      reference: 'AGENTS-AGNOSTIC.md lines 24-29'
    },
    {
      pattern: /Shared\(/,
      message: '❌ Wrong Shared constructor. Use Shared(wrappedValue:)',
      reference: 'AGENTS-TCA-PATTERNS.md Pattern 5, Mistake 5'
    },
    {
      pattern: /Task\.detached/,
      message: '❌ Task.detached is discouraged. Use Task { @MainActor in }',
      reference: 'AGENTS-AGNOSTIC.md lines 28'
    },
    {
      pattern: /Date\(\)/,
      message: '❌ Direct Date() calls. Use dependencies instead',
      reference: 'AGENTS-AGNOSTIC.md lines 419-440'
    }
  ],

  // Pattern-specific validations
  sheetPatterns: [
    {
      pattern: /\.sheet\(item:.*\$\w+\.state/,
      message: '⚠️ .sheet(item:) with state binding - ensure proper lifecycle',
      reference: 'AGENTS-TCA-PATTERNS.md Pattern 2'
    }
  ]
};

function findSwiftFiles(dir) {
  const files = [];

  function traverse(currentDir) {
    const items = fs.readdirSync(currentDir);

    for (const item of items) {
      const fullPath = path.join(currentDir, item);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory() && !item.startsWith('.') && item !== 'Build' && item !== 'DerivedData') {
        traverse(fullPath);
      } else if (stat.isFile() && item.endsWith('.swift')) {
        files.push(fullPath);
      }
    }
  }

  traverse(dir);
  return files;
}

function validateFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const issues = [];
  const positives = [];

  console.log(`\n📝 Validating: ${path.relative(process.cwd(), filePath)}`);

  // Check for deprecated patterns
  for (const rule of SMITH_PATTERNS.deprecated) {
    if (rule.pattern.test(content)) {
      issues.push({
        type: 'deprecated',
        message: rule.message,
        reference: rule.reference
      });
    }
  }

  // Check for anti-patterns
  for (const rule of SMITH_PATTERNS.antiPatterns) {
    if (rule.pattern.test(content)) {
      issues.push({
        type: 'anti-pattern',
        message: rule.message,
        reference: rule.reference
      });
    }
  }

  // Check for required positive patterns
  for (const rule of SMITH_PATTERNS.required) {
    if (rule.pattern.test(content)) {
      positives.push(rule.message);
    }
  }

  // Check sheet patterns if applicable
  if (content.includes('.sheet(')) {
    for (const rule of SMITH_PATTERNS.sheetPatterns) {
      if (rule.pattern.test(content)) {
        issues.push({
          type: 'warning',
          message: rule.message,
          reference: rule.reference
        });
      }
    }
  }

  // Report results
  if (issues.length === 0) {
    console.log('✅ No Smith pattern violations found');
  } else {
    for (const issue of issues) {
      console.log(`${issue.message}`);
      if (issue.reference) {
        console.log(`   📚 See: ${issue.reference}`);
      }
    }
  }

  // Report positive patterns
  if (positives.length > 0) {
    console.log('\n🎯 Modern TCA patterns detected:');
    for (const positive of positives) {
      console.log(`   ${positive}`);
    }
  }

  return issues;
}

function main() {
  const currentDir = process.cwd();

  // Check if we're in a Swift project
  if (!fs.existsSync('Package.swift') && !fs.existsSync('*.xcodeproj')) {
    console.log('❌ Error: Not in a Swift project directory');
    process.exit(1);
  }

  // Find Swift files
  let swiftFiles = [];
  if (fs.existsSync('Sources')) {
    swiftFiles = findSwiftFiles('Sources');
  } else {
    swiftFiles = findSwiftFiles('.');
  }

  if (swiftFiles.length === 0) {
    console.log('❌ No Swift files found');
    process.exit(1);
  }

  console.log(`📁 Found ${swiftFiles.length} Swift file(s)`);

  // Validate all files
  let totalIssues = 0;
  for (const file of swiftFiles) {
    const issues = validateFile(file);
    totalIssues += issues.length;
  }

  // Summary
  console.log('\n📊 TCA Pattern Validation Summary');
  console.log('==================================');

  if (totalIssues === 0) {
    console.log('🎉 All files follow Smith TCA patterns!');
    console.log('✅ Ready for production');
  } else {
    console.log(`⚠️ Found ${totalIssues} pattern issue(s) to address`);
    console.log('\nNext steps:');
    console.log('1. Review the Smith documentation references above');
    console.log('2. Apply the correct patterns');
    console.log('3. Re-run this validation');
    console.log('4. Check compilation with: swiftc -typecheck');
  }
}

if (require.main === module) {
  main();
}

module.exports = { validateFile, SMITH_PATTERNS };