# Smith Framework Skill - Content Manifest

**Framework Version:** 1.1.1
**Last Updated:** November 14, 2025
**Total Files:** 18 documents

## Core Framework Documentation

### AGENTS-AGNOSTIC.md
**Universal Swift patterns - 735 lines**
- State Management & Concurrency (lines 24-313)
- Dependency Injection (lines 38-43, 317-415)
- Access Control & Public APIs (lines 443-598)
- Testing Framework (lines 75-80, 601-735)
- Syntax-first validation rules
- Reading budget guidelines
- Stop-and-re-read triggers

### AGENTS-TCA-PATTERNS.md
**Canonical TCA patterns - 495 lines**
- Pattern 1: Observing state with @Bindable
- Pattern 2: Optional state navigation (.sheet + .scope)
- Pattern 3: Multiple destinations (complex navigation)
- Pattern 4: Bindings for form inputs
- Pattern 5: Shared state (@Shared, @SharedReader)
- Modern TCA 1.23.0+ patterns
- Deprecated API detection (WithViewStore, @Perception.Bindable)
- Point-Free validated examples

### AGENTS-DECISION-TREES.md
**Architecture decision guidance - 184 lines**
- Tree 1: When to extract child features
- Tree 2: @DependencyClient vs Singleton dependencies
- Tree 3: Navigation patterns for different use cases
- Framework selection criteria
- Pattern choice guidance

### CLAUDE.md
**Direct instructions for Claude agents - 377 lines**
- Step-by-step workflow
- Task classification routing (30 seconds)
- Reading budget management
- Red flag detection
- Verification checklists
- Tool usage guidelines

## Case Studies (DISCOVERY Series)

### DISCOVERY-13-SWIFT-COMPILER-CRASHES.md
**Swift compiler error resolution**
- Common compilation failure patterns
- Diagnostic interpretation
- Resolution strategies
- Prevention techniques

### DISCOVERY-14-NESTED-REDUCER-GOTCHAS.md
**Nested @Reducer patterns (Point-Free validated)**
- Proper nested reducer syntax
- Child feature extraction
- Action forwarding patterns
- Common anti-patterns and fixes

### DISCOVERY-15-PRINT-OSLOG-PATTERNS.md
**Print vs OSLog logging patterns**
- Static logger construction
- Performance implications
- Agent-friendly logging practices
- Point-Free validated patterns

### DISCOVERY-5-ACCESS-CONTROL-CASCADE-FAILURE.md
**Access control cascade failures**
- Transitive dependency tracing
- Public API boundary management
- Compiler error vs access level confusion
- Prevention strategies

## Platform-Specific Documentation

### PLATFORM-VISIONOS.md
**visionOS development patterns**
- RealityView integration
- PresentationComponent patterns
- Entity and Model3D best practices
- 3D interaction patterns

### PLATFORM-IOS.md
**iOS-specific patterns**
- UIKit integration
- iOS-specific APIs
- Platform conventions

### PLATFORM-MACOS.md
**macOS development patterns**
- Mac-specific UI patterns
- AppKit integration
- Desktop conventions

### PLATFORM-IPADOS.md
**iPadOS specific patterns**
- Multi-window support
- Stage Manager integration
- Tablet-optimized patterns

## Reference Materials

### DISCOVERY-SUBMISSION-TEMPLATE.md
**Case study submission template**
- Standard format for new discoveries
- Evaluation criteria
- Documentation requirements

### DISCOVERY-EVALUATION-CHECKLIST.md
**Case study evaluation framework**
- Quality assessment criteria
- Pattern validation requirements
- Documentation standards

## Usage Patterns

### Quick Access Routes
| Task Type | Primary Document | Time Budget | Key Sections |
|-----------|------------------|-------------|--------------|
| Compilation errors | AGENTS-AGNOSTIC.md | 5 min | Syntax validation |
| TCA reducer work | AGENTS-TCA-PATTERNS.md | 15 min | Pattern 1-5 |
| Navigation | AGENTS-TCA-PATTERNS.md | 10 min | Pattern 2 |
| Testing | AGENTS-AGNOSTIC.md | 15 min | Lines 601-735 |
| Dependencies | AGENTS-DECISION-TREES.md | 10 min | Tree 2 |
| Architecture | AGENTS-DECISION-TREES.md | 25 min | All trees |
| visionOS | PLATFORM-VISIONOS.md | 15 min | Entity patterns |

### Anti-Pattern Detection
The skill automatically detects and prevents:
- WithViewStore usage (deprecated)
- @State in TCA reducers
- Wrong @Shared constructors
- Task.detached usage
- Direct Date() calls
- Access control cascades

### Reading Budget Enforcement
- Simple syntax fixes: 5 minutes maximum
- Feature implementations: 15 minutes maximum
- Complex architectural decisions: 25 minutes maximum
- 80% of tasks should complete in under 15 minutes

## Integration with Claude

### Auto-Detection Triggers
The skill activates on keywords like:
- "TCA reducer", "@Reducer", "@ObservableState"
- "Swift Composable Architecture", "WithViewStore"
- "SwiftUI navigation", ".sheet", ".scope"
- "Smith framework", "AGENTS documentation"
- "compilation error", "access control"

### Smart Routing Logic
1. **Task Classification** (30 seconds)
2. **Reading Assignment** (targeted sections only)
3. **Budget Enforcement** (time limits)
4. **Pattern Validation** (checklist verification)
5. **Completion Criteria** (compilation + patterns)

## Success Metrics

Target outcomes when using Smith skill:
- ✅ 90% reduction in pattern violation bugs
- ✅ 50% faster agent task completion
- ✅ Zero over-engineering (simple solutions first)
- ✅ 100% Point-Free validated TCA patterns
- ✅ Perfect compilation before pattern application

---

**Total Framework Size:** ~400KB embedded content
**Skill File Size:** ~15KB
**Token Overhead:** Minimal (smart routing)
**Validation:** Point-Free examples verified