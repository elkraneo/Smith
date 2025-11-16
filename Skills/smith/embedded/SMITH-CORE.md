# SMITH-CORE - Universal Swift Patterns

**Core Smith patterns that apply to all Swift development, regardless of framework or platform.**

---

## 🔍 **When to Use smith-core**

**Auto-load when user mentions:**
- "dependency injection", "@Dependency", "DependencyClient"
- "concurrency", "async/await", "@MainActor"
- "testing", "@Test", "unit tests"
- "access control", "public", "internal"
- "Swift", "general Swift patterns"
- Build performance, compilation issues

---

## Core Constraints (Universal)

### Syntax First Rule
- **CRITICAL**: Fix compilation errors before applying patterns
- **CRITICAL**: Use `swiftc -typecheck` for syntax validation
- **CRITICAL**: 80% of tasks need < 15 minutes reading

### State Management & Concurrency
- **CRITICAL**: UI state mutations must be on `@MainActor`
- **CRITICAL**: Do not use `Task.detached` - use `Task { @MainActor in ... }`
- **STANDARD**: Cancel long-running tasks on teardown
- **STANDARD**: Use `async/await` over completion handlers
- **CRITICAL**: Swift 6+ Sendable requirements for concurrent code

### Dependency Injection
- **STANDARD**: Use `@DependencyClient` macro (modern approach)
- **CRITICAL**: Define dependencies only in Core modules, never UI layers
- **STANDARD**: Provide `testValue` and `previewValue` defaults
- **CRITICAL**: Override side effects through `DependencyValues`
- **GUIDANCE**: Use `@Dependency(\.date.now)`, `@Dependency(\.uuid)`, etc.

### Access Control & Public APIs
- **CRITICAL**: Trace transitive dependency chains when making types public
- **CRITICAL**: All referenced types must be public when exposing API
- **STANDARD**: Prefer internal visibility by default
- **GUIDANCE**: Consider API boundaries carefully

### Testing Framework
- **STANDARD**: Use Swift Testing framework (`@Test`, `#expect()`)
- **STANDARD**: Mark TCA tests `@MainActor`
- **STANDARD**: Use `TestClock()` for deterministic time
- **GUIDANCE**: Use `expectNoDifference` for complex data

### Error Handling
- **STANDARD**: Use Result types for error propagation
- **STANDARD**: Handle errors at appropriate boundaries
- **GUIDANCE**: Provide meaningful error messages

---

## Decision Trees (Core)

### Tree: @DependencyClient or Singleton?
Use when deciding dependency injection patterns.

**Questions:**
1. Is service used in TCA reducer? → Use @DependencyClient
2. Service needs different implementations for testing? → Use @DependencyClient
3. Service used across multiple features? → Use @DependencyClient
4. Apple framework integration? → Singleton or @DependencyClient wrapper
5. Service has mutable state? → Use @DependencyClient

---

## Quick Reference

### Common Dependencies
```swift
@Dependency(\.date.now) var now
@Dependency(\.uuid) var uuid
@Dependency(\.continuousClock) var clock
@Dependency(\.random) var random
@Dependency(\.calendar) var calendar
```

### Red Flags (Stop and Read)
- `@State` in business logic
- `Task.detached` usage
- Direct `Date()`, `UUID()` calls
- `Shared(value: x)` (should be `Shared(wrappedValue: x)`)
- Public properties without checking transitive types

### Verification Checklist
- [ ] Compilation succeeds before pattern application
- [ ] Dependencies injected via @DependencyClient
- [ ] No Task.detached usage
- [ ] Proper async/await patterns
- [ ] Access control chains validated
- [ ] Tests use Swift Testing framework

---

## Tool Integration

### Core Smith Tools
- `swiftc -typecheck` - Syntax validation
- `spm-spmsift-simple.sh` - Package structure analysis
- `sbsift` (when available) - Build analysis

### Context Efficiency
- Start with syntax validation
- Escalate to structured analysis only if needed
- Use context-efficient tools over verbose output

---

**smith-core provides the foundation for all Swift development - the patterns every project needs regardless of framework or platform choice.**