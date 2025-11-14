#!/usr/bin/env node

/**
 * Smith Framework - TCA Pattern Validator
 * Validates Swift Composable Architecture patterns against Smith rules
 *
 * Usage: node tca-pattern-validator.js [file-or-directory]
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Smith Framework: TCA Pattern Validator');
console.log('=========================================');

// Smith TCA Pattern Rules
const SMITH_PATTERNS = {
  // Deprecated patterns that should NOT be used
  deprecated: [
    {
      pattern: /WithViewStore/,
      message: '❌ WithViewStore is deprecated. Use @Bindable instead',
      reference: 'AGENTS-TCA-PATTERNS.md Mistake 1',
      severity: 'error'
    },
    {
      pattern: /ViewStore\(/,
      message: '❌ ViewStore initialization is deprecated. Use @Bindable',
      reference: 'AGENTS-TCA-PATTERNS.md Quick Reference',
      severity: 'error'
    },
    {
      pattern: /@Perception\.Bindable/,
      message: '❌ @Perception.Bindable is deprecated. Use TCA @Bindable',
      reference: 'AGENTS-TCA-PATTERNS.md Quick Reference',
      severity: 'error'
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
      reference: 'AGENTS-AGNOSTIC.md lines 24-29',
      severity: 'error'
    },
    {
      pattern: /Shared\(/,
      message: '❌ Wrong Shared constructor. Use Shared(wrappedValue:)',
      reference: 'AGENTS-TCA-PATTERNS.md Pattern 5, Mistake 5',
      severity: 'error'
    },
    {
      pattern: /Task\.detached/,
      message: '❌ Task.detached is discouraged. Use Task { @MainActor in }',
      reference: 'AGENTS-AGNOSTIC.md lines 28',
      severity: 'warning'
    },
    {
      pattern: /Date\(\)/,
      message: '❌ Direct Date() calls. Use dependencies instead',
      reference: 'AGENTS-AGNOSTIC.md lines 419-440',
      severity: 'warning'
    }
  ],

  // Pattern-specific validations
  sheetPatterns: [
    {
      pattern: /\.sheet\(item:.*\$\w+\.state/,
      message: '⚠️ .sheet(item:) with state binding - ensure proper lifecycle',
      reference: 'AGENTS-TCA-PATTERNS.md Pattern 2',
      severity: 'warning'
    }
  ]
};

function findSwiftFiles(dir) {
  const files = [];

  function traverse(currentDir) {
    try {
      const items = fs.readdirSync(currentDir);

      for (const item of items) {
        const fullPath = path.join(currentDir, item);
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory() && !item.startsWith('.') &&
            item !== 'Build' && item !== 'DerivedData' && item !== 'node_modules') {
          traverse(fullPath);
        } else if (stat.isFile() && item.endsWith('.swift')) {
          files.push(fullPath);
        }
      }
    } catch (error) {
      // Skip directories we can't read
    }
  }

  traverse(dir);
  return files;
}

function validateFile(filePath) {
  try {
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
          reference: rule.reference,
          severity: rule.severity
        });
      }
    }

    // Check for anti-patterns
    for (const rule of SMITH_PATTERNS.antiPatterns) {
      if (rule.pattern.test(content)) {
        issues.push({
          type: 'anti-pattern',
          message: rule.message,
          reference: rule.reference,
          severity: rule.severity
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
            reference: rule.reference,
            severity: rule.severity
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
  } catch (error) {
    console.log(`❌ Error reading file: ${error.message}`);
    return [];
  }
}

function main() {
  const args = process.argv.slice(2);
  let targetDir = '.';

  if (args.length > 0) {
    targetDir = args[0];
  }

  // Check if target exists
  if (!fs.existsSync(targetDir)) {
    console.log(`❌ Error: Path "${targetDir}" does not exist`);
    process.exit(1);
  }

  const stat = fs.statSync(targetDir);

  // Handle single file
  if (stat.isFile() && targetDir.endsWith('.swift')) {
    console.log(`📁 Validating single file: ${targetDir}`);
    const issues = validateFile(targetDir);
    process.exit(issues.length > 0 ? 1 : 0);
  }

  // Handle directory
  if (stat.isDirectory()) {
    console.log(`📁 Scanning directory: ${targetDir}`);

    // Find Swift files
    let swiftFiles = [];
    if (fs.existsSync(path.join(targetDir, 'Sources'))) {
      swiftFiles = findSwiftFiles(path.join(targetDir, 'Sources'));
    } else {
      swiftFiles = findSwiftFiles(targetDir);
    }

    if (swiftFiles.length === 0) {
      console.log('❌ No Swift files found');
      process.exit(1);
    }

    console.log(`📝 Found ${swiftFiles.length} Swift file(s)`);

    // Validate all files
    let totalIssues = 0;
    let totalErrors = 0;
    let totalWarnings = 0;

    for (const file of swiftFiles) {
      const issues = validateFile(file);
      totalIssues += issues.length;

      for (const issue of issues) {
        if (issue.severity === 'error') {
          totalErrors += 1;
        } else if (issue.severity === 'warning') {
          totalWarnings += 1;
        }
      }
    }

    // Summary
    console.log('\n📊 TCA Pattern Validation Summary');
    console.log('==================================');

    if (totalIssues === 0) {
      console.log('🎉 All files follow Smith TCA patterns!');
      console.log('✅ Ready for production');
      process.exit(0);
    } else {
      console.log(`⚠️ Found ${totalIssues} pattern issue(s):`);
      console.log(`   - ${totalErrors} error(s) that must be fixed`);
      console.log(`   - ${totalWarnings} warning(s) that should be reviewed`);

      console.log('\nNext steps:');
      console.log('1. Review the Smith documentation references above');
      console.log('2. Apply the correct patterns');
      console.log('3. Re-run this validation');
      console.log('4. Check compilation with: swiftc -typecheck');

      process.exit(totalErrors > 0 ? 1 : 0);
    }
  } else {
    console.log(`❌ Error: "${targetDir}" is not a Swift file or directory`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { validateFile, SMITH_PATTERNS };