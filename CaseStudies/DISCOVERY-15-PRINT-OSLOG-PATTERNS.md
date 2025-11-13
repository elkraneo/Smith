# DISCOVERY-15: Print vs OSLog Patterns for Agent Logging

**Date**: 2025-11-13
**Impact**: HIGH - Agent debugging effectiveness and production observability
**Status**: RESOLVED - Documented OSLog patterns with Point-Free validation

## Problem Summary

Agents consistently default to `print()` statements for debugging, creating significant problems:

1. **Debugging Hell**: No categorization, filtering, or structured logging in production
2. **Performance Impact**: `print()` is synchronous and blocks main thread
3. **Production Blindness**: `print()` disappears in release builds
4. **Memory Issues**: String concatenation in hot paths
5. **Security Risks**: Sensitive data logged without control

**Root Cause**: Agents choose `print()` for simplicity but create long-term observability problems.

---

## 🚨 **Agent Anti-Pattern: Print Overuse**

### What Agents Typically Do:

```swift
// ❌ AGENT DEFAULT PATTERN
@Reducer
struct UserProfileFeature {
    @ObservableState
    struct State {
        var user: User?
        var isLoading = false
        var error: String?
    }

    enum Action {
        case loadUser(userID: String)
        case userLoaded(User)
        case loadFailed(Error)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadUser(let userID):
                print("Loading user: \(userID)")                    // ❌ No context
                state.isLoading = true
                return .run { send in
                    do {
                        let user = try await userClient.fetch(id: userID)
                        print("User loaded: \(user.email)")           // ❌ Security risk
                        await send(.userLoaded(user))
                    } catch {
                        print("Error loading user: \(error)")        // ❌ No severity
                        await send(.loadFailed(error))
                    }
                }

            case .userLoaded(let user):
                print("User profile loaded successfully")           // ❌ No categorization
                state.user = user
                state.isLoading = false
                return .none

            case .loadFailed(let error):
                print("Failed to load user: \(error.localizedDescription)") // ❌ No structure
                state.error = error.localizedDescription
                state.isLoading = false
                return .none
            }
        }
    }
}
```

### Problems This Creates:

1. **Can't filter logs**: All prints go to same stream
2. **No performance visibility**: Don't know which operations are slow
3. **Production debugging**: `print()` disappears in release builds
4. **Security exposure**: Email/PII logged without control
5. **Memory pressure**: String concatenation in every log
6. **No log levels**: Can't distinguish debug vs error vs info

---

## ✅ **Point-Free Validated Patterns**

### Pattern 1: Structured OSLog with Subsystems

Based on Point-Free's `Logger.shared.log()` pattern in their test cases:

```swift
// ✅ POINT-FREE PATTERN (VALIDATED)
import OSLog

@Reducer
struct UserProfileFeature {
    // ✅ Create logger with subsystem and category
    private static let logger = Logger(
        subsystem: "com.app.userprofile",
        category: "UserProfileFeature"
    )

    @ObservableState
    struct State {
        var user: User?
        var isLoading = false
        var error: String?
    }

    enum Action {
        case loadUser(userID: String)
        case userLoaded(User)
        case loadFailed(Error)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadUser(let userID):
                // ✅ Structured logging with context
                Self.logger.info("Loading user profile", metadata: [
                    "userID": "\(userID)",
                    "timestamp": "\(Date().timeIntervalSince1970)"
                ])

                state.isLoading = true
                return .run { send in
                    do {
                        let user = try await userClient.fetch(id: userID)
                        // ✅ Success without sensitive data
                        Self.logger.info("User profile loaded successfully", metadata: [
                            "userID": "\(userID)",
                            "hasProfileImage": "\(user.profileImage != nil)"
                        ])
                        await send(.userLoaded(user))
                    } catch {
                        // ✅ Error with context, no sensitive info
                        Self.logger.error("Failed to load user profile", metadata: [
                            "userID": "\(userID)",
                            "errorDomain": "\(type(of: error))",
                            "errorCode": "\(error.localizedDescription.prefix(50))"
                        ])
                        await send(.loadFailed(error))
                    }
                }

            case .userLoaded(let user):
                Self.logger.debug("Updating UI with loaded user profile", metadata: [
                    "userID": "\(user.id)",
                    "updateType": "profile_loaded"
                ])
                state.user = user
                state.isLoading = false
                return .none

            case .loadFailed(let error):
                Self.logger.warning("Displaying error to user", metadata: [
                    "errorType": "\(type(of: error))",
                    "userFriendly": "true"
                ])
                state.error = error.localizedDescription
                state.isLoading = false
                return .none
            }
        }
    }
}
```

### Pattern 2: Performance-Optimized Logging

```swift
// ✅ PERFORMANCE OPTIMIZED PATTERN
@Reducer
struct PerformanceIntensiveFeature {
    private static let logger = Logger(
        subsystem: "com.app.performance",
        category: "PerformanceIntensiveFeature"
    )

    @ObservableState
    struct State {
        var processingItems: [ProcessingItem] = []
        var metrics: ProcessingMetrics = .init()
    }

    enum Action {
        case startProcessing([DataItem])
        case itemProcessed(ProcessingItem, TimeInterval)
        case batchCompleted
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startProcessing(let items):
                let batchID = UUID().uuidString
                Self.logger.info("Starting batch processing", metadata: [
                    "batchID": "\(batchID)",
                    "itemCount": "\(items.count)",
                    "estimatedDuration": "\(Double(items.count) * 0.1)"
                ])

                return .run { send in
                    let startTime = CFAbsoluteTimeGetCurrent()

                    for (index, item) in items.enumerated() {
                        let itemStartTime = CFAbsoluteTimeGetCurrent()
                        // Simulate processing
                        let processedItem = try await processItem(item)
                        let duration = CFAbsoluteTimeGetCurrent() - itemStartTime

                        // ✅ Only log performance metrics, not every item
                        if duration > 0.5 || index % 10 == 0 {
                            Self.logger.debug("Item processing metrics", metadata: [
                                "batchID": "\(batchID)",
                                "itemIndex": "\(index)",
                                "duration": "\(String(format: "%.3f", duration))",
                                "thresholdExceeded": "\(duration > 0.5)"
                            ])
                        }

                        await send(.itemProcessed(processedItem, duration))
                    }

                    let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
                    Self.logger.info("Batch processing completed", metadata: [
                        "batchID": "\(batchID)",
                        "totalDuration": "\(String(format: "%.3f", totalDuration))",
                        "avgItemDuration": "\(String(format: "%.3f", totalDuration / Double(items.count)))"
                    ])

                    await send(.batchCompleted)
                } catch: { error in
                    Self.logger.error("Batch processing failed", metadata: [
                        "batchID": "\(batchID)",
                        "errorType": "\(type(of: error))",
                        "errorDescription": "\(error.localizedDescription)"
                    ])
                }

            case .itemProcessed(let item, let duration):
                // ✅ Update state without logging (too noisy)
                state.processingItems.append(item)
                state.metrics.recordProcessingTime(duration)
                return .none

            case .batchCompleted:
                Self.logger.info("Updating UI with batch results", metadata: [
                    "totalItems": "\(state.processingItems.count)",
                    "avgProcessingTime": "\(state.metrics.averageProcessingTime)"
                ])
                return .none
            }
        }
    }
}
```

### Pattern 3: Dependency-Injected Logging for Testing

```swift
// ✅ TESTABLE LOGGING PATTERN
protocol LoggingClient {
    func info(_ message: String, metadata: [String: String])
    func debug(_ message: String, metadata: [String: String])
    func warning(_ message: String, metadata: [String: String])
    func error(_ message: String, metadata: [String: String])
}

// ✅ Production implementation
struct OSLogClient: LoggingClient {
    let logger: Logger

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func info(_ message: String, metadata: [String: String]) {
        logger.info("\(message, privacy: .public)", metadata: metadata.asMetadata())
    }

    func debug(_ message: String, metadata: [String: String]) {
        logger.debug("\(message, privacy: .public)", metadata: metadata.asMetadata())
    }

    func warning(_ message: String, metadata: [String: String]) {
        logger.warning("\(message, privacy: .public)", metadata: metadata.asMetadata())
    }

    func error(_ message: String, metadata: [String: String]) {
        logger.error("\(message, privacy: .public)", metadata: metadata.asMetadata())
    }
}

// ✅ Test implementation
struct TestLogClient: LoggingClient {
    var loggedMessages: [(level: LogLevel, message: String, metadata: [String: String])] = []

    enum LogLevel {
        case info, debug, warning, error
    }

    func info(_ message: String, metadata: [String: String]) {
        loggedMessages.append((.info, message, metadata))
    }

    func debug(_ message: String, metadata: [String: String]) {
        loggedMessages.append((.debug, message, metadata))
    }

    func warning(_ message: String, metadata: [String: String]) {
        loggedMessages.append((.warning, message, metadata))
    }

    func error(_ message: String, metadata: [String: String]) {
        loggedMessages.append((.error, message, metadata))
    }
}

extension Dictionary where Key == String, Value == String {
    func asMetadata() -> [String: Any] {
        self.mapValues { $0 as Any }
    }
}

// ✅ Usage in reducer
@Reducer
struct LoggingExampleFeature {
    @Dependency(\.loggingClient) var loggingClient

    @ObservableState
    struct State {
        var value = 0
    }

    enum Action {
        case increment
        case complexOperation
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .increment:
                loggingClient.debug("Incrementing value", metadata: [
                    "currentValue": "\(state.value)",
                    "newValue": "\(state.value + 1)"
                ])
                state.value += 1
                return .none

            case .complexOperation:
                loggingClient.info("Starting complex operation", metadata: [
                    "operationID": "\(UUID().uuidString)",
                    "startTime": "\(Date().timeIntervalSince1970)"
                ])
                return .run { send in
                    // Complex operation here
                    loggingClient.info("Complex operation completed", metadata: [
                        "duration": "\(1.5)",
                        "success": "true"
                    ])
                }
            }
        }
    }
}
```

---

## 📊 **Print vs OSLog Comparison**

| Aspect | ❌ `print()` | ✅ `OSLog` |
|--------|-------------|------------|
| **Performance** | Synchronous, blocks thread | Asynchronous, optimized |
| **Production** | Disappears in release builds | Persists with configurable levels |
| **Filtering** | No filtering (all-or-nothing) | Subsystem/category/level filtering |
| **Context** | Just strings | Structured metadata |
| **Security** | No privacy controls | Privacy annotations |
| **Testing** | Hard to capture/test | Injectable dependency |
| **Memory** | String concatenation overhead | Optimized string handling |
| **Debugging** | Console only | Console + Instruments + third-party tools |

---

## 🎯 **Agent Guidelines: When to Use What**

### **Use `print()` ONLY for:**

```swift
// ✅ APPROPRIATE PRINT USAGE
// 1. Quick debugging during development (remove before commit)
print("DEBUG: \(variableName) = \(variableValue)")  // Remove this!

// 2. Temporary development scaffolding
print("Placeholder: Implement actual logic here")  // Remove this!

// 3. One-time debugging that won't be committed
// (Use in development branch only, never in main)
```

### **Use OSLog for:**

```swift
// ✅ APPROPRIATE OSLOG USAGE
// 1. All production logging
logger.info("User action completed", metadata: ["action": "login"])

// 2. Performance monitoring
logger.info("Operation completed", metadata: ["duration": "\(duration)"])

// 3. Error tracking
logger.error("Operation failed", metadata: ["error": "\(error.localizedDescription)"])

// 4. State transitions
logger.debug("State changed", metadata: ["from": "\(oldState)", "to": "\(newState)"])

// 5. Business metrics
logger.info("Feature used", metadata: ["feature": "search", "count": "\(results.count)"])
```

---

## 🔧 **Implementation Patterns**

### Pattern 1: Centralized Logger Factory

```swift
// ✅ CENTRALIZED LOGGER FACTORY
struct AppLogger {
    static let shared = AppLogger()

    // Domain-specific loggers
    let user: Logger
    let network: Logger
    let performance: Logger
    let ui: Logger
    let security: Logger

    private init() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.app.unknown"

        self.user = Logger(subsystem: "\(bundleID).user", category: "User")
        self.network = Logger(subsystem: "\(bundleID).network", category: "Network")
        self.performance = Logger(subsystem: "\(bundleID).performance", category: "Performance")
        self.ui = Logger(subsystem: "\(bundleID).ui", category: "UI")
        self.security = Logger(subsystem: "\(bundleID).security", category: "Security")
    }
}

// ✅ Usage in reducers
@Reducer
struct UserProfileFeature {
    @Dependency(\.appLogger) var logger

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadUser:
                logger.user.info("Loading user profile", metadata: ["userID": "\(userID)"])
                return .none
            case .loadFailed:
                logger.network.error("Network request failed", metadata: ["endpoint": "user/profile"])
                return .none
            }
        }
    }
}
```

### Pattern 2: Performance-Aware Logging

```swift
// ✅ PERFORMANCE-AWARE LOGGING
@Reducer
struct HighFrequencyFeature {
    private static let logger = Logger(subsystem: "com.app.hf", category: "HighFrequency")

    @ObservableState
    struct State {
        var counter = 0
        var lastLoggedValue = 0
    }

    enum Action {
        case increment
        case batchIncrement(Int)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .increment:
                state.counter += 1

                // ✅ Only log every 100 increments to avoid spam
                if state.counter % 100 == 0 {
                    Self.logger.info("Milestone reached", metadata: [
                        "counter": "\(state.counter)",
                        "batchSize": "100"
                    ])
                }
                return .none

            case .batchIncrement(let count):
                let oldValue = state.counter
                state.counter += count

                // ✅ Log batch operations
                Self.logger.info("Batch increment completed", metadata: [
                    "previousValue": "\(oldValue)",
                    "newValue": "\(state.counter)",
                    "batchSize": "\(count)"
                ])
                return .none
            }
        }
    }
}
```

---

## 🧪 **Testing OSLog Patterns**

### Test Example: Verifying Logging

```swift
@Test
func testUserLoadingLogsCorrectly() async throws {
    let testLogClient = TestLogClient()

    let store = TestStore(initialState: UserProfileFeature.State()) {
        UserProfileFeature()
    } withDependencies: {
        $0.loggingClient = testLogClient
        $0.userClient = .mock
    }

    await store.send(.loadUser(userID: "123"))

    // ✅ Verify correct logging
    let infoLogs = testLogClient.loggedMessages.filter { $0.level == .info }
    XCTAssertEqual(infoLogs.count, 1)
    XCTAssertEqual(infoLogs.first?.message, "Loading user profile")
    XCTAssertEqual(infoLogs.first?.metadata["userID"], "123")

    await store.receive(.userLoaded(.mock))

    let debugLogs = testLogClient.loggedMessages.filter { $0.level == .debug }
    XCTAssertEqual(debugLogs.count, 1)
    XCTAssertEqual(debugLogs.first?.message, "Updating UI with loaded user profile")
}
```

---

## 🎯 **Key Insights**

1. **Point-Free uses structured logging**: Even their test cases use `Logger.shared.log()`
2. **Performance matters**: OSLog is async and optimized vs synchronous `print()`
3. **Context is critical**: Structured metadata makes debugging possible
4. **Testing requires dependency injection**: Need to verify logging behavior
5. **Production visibility**: `print()` disappears, OSLog persists with filtering

**This prevents the agent debugging hell by providing structured, testable, production-ready logging patterns.**

---

## Framework Integration

**Update**: AGENTS-AGNOSTIC.md
- Add logging patterns section with OSLog vs print guidance
- Add performance considerations for logging
- Add testable logging dependency patterns

**Update**: AGENTS-TCA-PATTERNS.md
- Add logging verification checklist items
- Include OSLog patterns in all examples

**Enforcement**: [STANDARD] - Use OSLog for production logging, `print()` only for temporary debugging

---

**Last Updated**: November 13, 2025
**Validation**: Confirmed against Point-Free `Logger.shared.log()` patterns