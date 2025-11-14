#!/usr/bin/env node

/**
 * Smith Framework - Smart Documentation Router
 * Routes agents to the right documentation based on task classification
 * Implements the 30-second task classification and reading budget logic
 */

const fs = require('fs');

console.log('🔍 Smith Framework: Documentation Router');
console.log('=======================================');

// Task classification and routing rules
const ROUTING_MAP = {
  // Testing patterns
  testing: {
    keywords: ['test', 'Test', '@Test', '#expect', 'TestClock', 'testing'],
    primary: 'QUICK-START.md',
    sections: 'Rules 6-7',
    timeBudget: '2 minutes',
    fallback: 'AGENTS-AGNOSTIC.md lines 75-111',
    description: 'Testing patterns with Swift Testing framework'
  },

  // TCA reducer work
  tcaReducer: {
    keywords: ['reducer', 'Reducer', '@Reducer', 'State', 'Action', 'reduce'],
    primary: 'QUICK-START.md',
    sections: 'Rules 2-4',
    timeBudget: '3 minutes',
    fallback: 'AGENTS-TCA-PATTERNS.md specific pattern',
    description: 'TCA reducer patterns and state management'
  },

  // visionOS entities
  visionOS: {
    keywords: ['visionOS', 'RealityView', 'PresentationComponent', 'Entity', 'Model3D'],
    primary: 'QUICK-START.md',
    sections: 'Rule 9',
    timeBudget: '2 minutes',
    fallback: 'PLATFORM-VISIONOS.md + DISCOVERY-4',
    description: 'visionOS entity patterns and 3D components'
  },

  // Dependencies
  dependencies: {
    keywords: ['dependency', '@Dependency', '@DependencyClient', 'Date()', 'UUID()'],
    primary: 'QUICK-START.md',
    sections: 'Rule 5',
    timeBudget: '2 minutes',
    fallback: 'AGENTS-DECISION-TREES.md Tree 2',
    description: 'Dependency injection patterns'
  },

  // Access control errors
  accessControl: {
    keywords: ['access control', 'public', 'internal', 'private', 'fileprivate'],
    primary: 'QUICK-START.md',
    sections: 'Rule 8 + DISCOVERY-5',
    timeBudget: '5 minutes',
    fallback: 'AGENTS-AGNOSTIC.md lines 443-598',
    description: 'Access control and public API boundaries'
  },

  // Architecture decisions
  architecture: {
    keywords: ['architecture', 'pattern', 'design', 'should I use', 'which approach'],
    primary: 'AGENTS-DECISION-TREES.md',
    sections: 'relevant tree',
    timeBudget: '5 minutes',
    fallback: 'AGENTS-TASK-SCOPE.md',
    description: 'Architecture decision guidance'
  },

  // Bug fixes
  bugFix: {
    keywords: ['bug', 'error', 'fix', 'broken', 'not working', 'compile error'],
    primary: 'Search CaseStudies/',
    sections: 'search by symptom',
    timeBudget: '2 minutes',
    fallback: 'Read matching DISCOVERY',
    description: 'Bug resolution and error fixing'
  },

  // SwiftUI navigation
  navigation: {
    keywords: ['navigation', 'sheet', 'fullScreenCover', 'popover', 'NavigationStack'],
    primary: 'AGENTS-TCA-PATTERNS.md',
    sections: 'Pattern 2 (optional state)',
    timeBudget: '5 minutes',
    description: 'SwiftUI navigation patterns with TCA'
  },

  // Concurrency
  concurrency: {
    keywords: ['Task', 'async', 'await', 'MainActor', 'concurrent'],
    primary: 'AGENTS-AGNOSTIC.md',
    sections: 'lines 24-29 + 162-313',
    timeBudget: '5 minutes',
    description: 'Concurrency patterns and main actor usage'
  },

  // Nested reducers
  nestedReducers: {
    keywords: ['nested reducer', 'child feature', 'extract reducer', 'Scope'],
    primary: 'DISCOVERY-14-NESTED-REDUCER-GOTCHAS.md',
    sections: 'entire document',
    timeBudget: '5 minutes',
    description: 'Nested @Reducer patterns and gotchas'
  },

  // Logging patterns
  logging: {
    keywords: ['print', 'oslog', 'Logger', 'log', 'debug'],
    primary: 'DISCOVERY-15-PRINT-OSLOG-PATTERNS.md',
    sections: 'appropriate section',
    timeBudget: '3 minutes',
    description: 'Print vs OSLog logging patterns'
  }
};

function classifyTask(description) {
  const normalizedDesc = description.toLowerCase();
  const scores = {};

  // Score each routing category
  for (const [category, rules] of Object.entries(ROUTING_MAP)) {
    scores[category] = 0;
    for (const keyword of rules.keywords) {
      if (normalizedDesc.includes(keyword.toLowerCase())) {
        scores[category] += 1;
      }
    }
  }

  // Find best match
  let bestMatch = null;
  let highestScore = 0;

  for (const [category, score] of Object.entries(scores)) {
    if (score > highestScore) {
      highestScore = score;
      bestMatch = category;
    }
  }

  return bestMatch ? { category: bestMatch, ...ROUTING_MAP[bestMatch], score: highestScore } : null;
}

function searchCaseStudies(description) {
  // Simple case study search
  const caseStudyFiles = fs.readdirSync('.').filter(f => f.startsWith('DISCOVERY-') && f.endsWith('.md'));

  for (const file of caseStudyFiles) {
    const content = fs.readFileSync(file, 'utf8').toLowerCase();
    if (description.toLowerCase().split(' ').some(word => content.includes(word) && word.length > 3)) {
      return file;
    }
  }
  return null;
}

function generateReadingPlan(taskDescription) {
  console.log(`\n📋 Task: "${taskDescription}"`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // Step 1: Classify the task
  const classification = classifyTask(taskDescription);

  if (!classification) {
    console.log('❌ Unable to classify task. Using general approach.');
    console.log('📚 Read: QUICK-START.md entire document (5 minutes max)');
    return;
  }

  console.log(`🎯 Task Type: ${classification.description}`);
  console.log(`📊 Confidence Score: ${classification.score}`);
  console.log(`⏱️ Reading Budget: ${classification.timeBudget}`);
  console.log();

  // Step 2: Check for case studies first if it's a bug fix
  if (classification.category === 'bugFix') {
    const caseStudy = searchCaseStudies(taskDescription);
    if (caseStudy) {
      console.log('🔍 Found relevant case study:');
      console.log(`📚 Read: ${caseStudy} (5-10 minutes)`);
      console.log('✅ This is faster than reading general documentation');
      return;
    }
  }

  // Step 3: Generate reading plan
  console.log('📚 Reading Plan:');
  console.log(`1. Primary: ${classification.primary} - ${classification.sections}`);
  console.log(`   ⏱️ Budget: ${classification.timeBudget}`);

  if (classification.fallback && classification.fallback !== classification.primary) {
    console.log(`2. Fallback: ${classification.fallback} (if needed)`);
  }

  // Step 4: Add specific guidance based on category
  console.log();
  console.log('💡 Specific Guidance:');

  switch (classification.category) {
    case 'testing':
      console.log('   • Use @Test and #expect(), never XCTest');
      console.log('   • Mark TCA tests @MainActor');
      console.log('   • Use TestClock() for deterministic time');
      break;

    case 'tcaReducer':
      console.log('   • Check for deprecated WithViewStore');
      console.log('   • Verify @Shared patterns (single owner)');
      console.log('   • Use modern @Reducer macro syntax');
      break;

    case 'navigation':
      console.log('   • Optional state = .sheet(item:) + .scope()');
      console.log('   • Conditional UI = if/else in view');
      console.log('   • NEVER use .sheet() for toolbar items');
      break;

    case 'accessControl':
      console.log('   • Trace transitive dependencies when making public');
      console.log('   • Check cascade failures before assuming type errors');
      break;

    case 'bugFix':
      console.log('   • Search case studies by symptom first');
      console.log('   • Check compilation before pattern analysis');
      break;
  }

  // Step 5: Verification reminder
  console.log();
  console.log('✅ Verification Checklist:');
  console.log('   1. Code compiles (swiftc -typecheck)');
  console.log('   2. Follows Smith patterns (no red flags)');
  console.log('   3. Within reading budget');
  console.log('   4. Passes relevant verification checklist');
}

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: node reading-router.js "task description"');
    console.log('');
    console.log('Example:');
    console.log('  node reading-router.js "Add optional state for settings sheet to LoginFeature"');
    console.log('  node reading-router.js "Fix TCA reducer compilation error with child actions"');
    console.log('  node reading-router.js "Add print logging for debugging UserProfileFeature"');
    process.exit(1);
  }

  const taskDescription = args.join(' ');
  generateReadingPlan(taskDescription);
}

if (require.main === module) {
  main();
}

module.exports = { classifyTask, generateReadingPlan, ROUTING_MAP };