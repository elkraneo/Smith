# Smith Framework Agent Skill

**Version:** 1.1.1
**Purpose:** Swift Composable Architecture patterns and modern iOS development framework

## Quick Overview

Smith is a **discipline for correctness**, not a style guide. This skill provides agents with:

- **Syntax-first validation** - Fix compilation errors before patterns
- **Reading budgets** - 80% of tasks need < 15 minutes of reading
- **Point-Free validated TCA patterns** - No deprecated APIs
- **Anti-pattern detection** - Stop common mistakes before they happen
- **Apple-native approach** - Zero external dependencies

## Core Problem Solved

**Before Smith:** 2-minute syntax fixes become 90-minute documentation marathons
**After Smith:** 2-minute syntax fixes stay 2-minute fixes + appropriate pattern reading

## How This Skill Works

1. **Auto-detection**: Claude loads this skill when TCA/Swift patterns are detected
2. **Task routing**: 30-second classification → targeted documentation path
3. **Reading budgets**: Built-in time limits prevent over-analysis
4. **Pattern validation**: Checklists ensure implementations follow Smith rules
5. **Syntax-first**: Always fix compilation errors before pattern application

## Key Documents

- **[QUICK-START.md](QUICK-START.md)** - 5-minute survival guide
- **[AGENTS-AGNOSTIC.md](AGENTS-AGNOSTIC.md)** - Universal Swift patterns (state, concurrency, testing)
- **[AGENTS-TCA-PATTERNS.md](AGENTS-TCA-PATTERNS.md)** - Canonical TCA patterns with verification checklists
- **[AGENTS-DECISION-TREES.md](AGENTS-DECISION-TREES.md)** - Architecture decision guidance
- **[CLAUDE.md](CLAUDE.md)** - Direct instructions for Claude agents

## Case Studies

- **[DISCOVERY-14](DISCOVERY-14-NESTED-REDUCER-GOTCHAS.md)** - Nested @Reducer patterns (Point-Free validated)
- **[DISCOVERY-15](DISCOVERY-15-PRINT-OSLOG-PATTERNS.md)** - Print vs OSLog logging patterns
- **[DISCOVERY-13](DISCOVERY-13-SWIFT-COMPILER-CRASHES.md)** - Swift compiler error resolution

## Platform Support

- **[PLATFORM-VISIONOS.md](PLATFORM-VISIONOS.md)** - visionOS entities and PresentationComponent patterns
- **[PLATFORM-IOS.md](PLATFORM-IOS.md)** - iOS-specific patterns
- **[PLATFORM-MACOS.md](PLATFORM-MACOS.md)** - macOS development patterns

## Validation Scripts

- **[Scripts/validate-syntax.sh](Scripts/validate-syntax.sh)** - First line of defense: `swiftc -typecheck`
- **[Scripts/check-tca-patterns.js](Scripts/check-tca-patterns.js)** - TCA pattern validation
- **[Scripts/reading-router.js](Scripts/reading-router.js)** - Smart documentation routing

## Success Metrics

Target outcomes when using Smith:
- ✅ 90% reduction in pattern violation bugs
- ✅ 50% faster agent task completion
- ✅ Zero over-engineering (simple solutions first)
- ✅ 100% Point-Free validated TCA patterns
- ✅ Perfect compilation before pattern application

## The Discipline

Smith prevents:
- ❌ Using deprecated TCA APIs (WithViewStore, old patterns)
- ❌ Over-engineering simple tasks
- ❌ Skipping syntax validation
- ❌ Ignoring reading budgets
- ❌ Race conditions with @Shared state
- ❌ Improper concurrency patterns

Smith ensures:
- ✅ Modern TCA 1.23.0+ patterns
- ✅ Proper dependency injection
- ✅ Apple-native toolchain usage
- ✅ Clear verification checklists
- ✅ Production-ready code

---

**Last Updated:** November 14, 2025
**Framework Version:** 1.1.1
**Validated Against:** Point-Free Swift Composable Architecture examples