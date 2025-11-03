# PLATFORM - iOS

Platform-specific constraints, patterns, and guidance for iOS development.

**Universal rules:** See [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
**Architecture decisions:** See [DECISION-TREES.md](./DECISION-TREES.md)

---

## Platform Context

- **Target:** iOS 26+
- **UI Framework:** SwiftUI (latest APIs)
- **Architecture:** TCA 1.23.0+
- **Modern APIs:** No backwards compatibility required
- **Device Focus:** iPhones (all sizes, all orientations)

---

## iOS-Specific Constraints

### Portrait & Landscape

- Support both orientations (unless explicitly locked)
- Layouts must adapt to orientation changes
- Safe area respected for notch, Dynamic Island, home indicator

### Touch Interactions

- All interactive elements must be touch-friendly (minimum 44pt)
- Swipe gestures for navigation patterns
- Long-press for context menus

### System Integrations

- Share Sheet integration
- Notifications
- Background refresh
- Siri Shortcuts

---

## iOS-Specific Patterns

### Share Extension

Most read-it-later apps need Share Sheet integration:

```swift
#if os(iOS)
@main
struct ShareExtension: App {
  @Environment(\.scenePhase) var scenePhase

  var body: some Scene {
    WindowGroup {
      ShareView()
    }
    .onChange(of: scenePhase) { phase in
      if phase == .background {
        // Save shared link to app database
      }
    }
  }
}
#endif
```

### Lock Screen Widgets

iOS 16+ supports Lock Screen widgets:

```swift
struct ArticleWidgetProvider: TimelineProvider {
  func getSnapshot(in context: Context, completion: @escaping (ArticleEntry) -> Void) {
    // Return current article being read
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ArticleEntry>) -> Void) {
    // Update timeline with next article
  }
}
```

---

## Code Organization for iOS

### Directory Structure

```
Scroll/
├── Scroll.xcodeproj
├── Scroll/
│   ├── App/
│   │   ├── ScrollApp.swift
│   │   └── SceneDelegate.swift
│   ├── Features/
│   │   ├── ArticleReader/
│   │   │   ├── ArticleReaderView.swift (iOS view)
│   │   │   └── ArticleReaderPreview.swift
│   │   └── ...
│   ├── Utilities/
│   └── Services/
├── Widgets/                        # Lock Screen widgets
│   ├── ArticleWidget.swift
│   └── WidgetBundle.swift
├── ShareExtension/                # Share Sheet integration
│   ├── ShareView.swift
│   └── ShareTarget.swift
└── Tests/
```

---

## Build Configuration

**Recommended: Use xcsift for token-efficient output**
```bash
xcodebuild build -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | xcsift
```

**When you need more metadata: Use XcodeBuildMCP**
- Device-specific deployment
- Build product paths
- Simulator management

**Notes:**
- No special derived data paths needed (uses standard Xcode location)
- Standard Debug/Release configurations
- Support both iPhone and iPad (iPad has specific layout needs—see PLATFORM-IPADOS.md)
```

---

## Testing on iOS

- Swift Testing framework required
- Test on multiple device sizes (iPhone 15, iPhone 16, SE, Max variants)
- Test on both orientations

```bash
xcodebuild test -scheme Scroll -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Accessibility on iOS

### VoiceOver Support

- Full VoiceOver compatibility required
- Test with VoiceOver enabled (Settings → Accessibility → VoiceOver)
- All UI elements labeled meaningfully

### Dynamic Type

- Support Dynamic Type up to extra-large sizes
- Test with all text size preferences
- No hardcoded font sizes

### Haptic Feedback

- Use haptic feedback for confirmation (success, warning, error)
- ```swift
  let feedback = UIImpactFeedbackGenerator(style: .medium)
  feedback.impactOccurred()
  ```

---

## Performance Considerations

### Battery & Thermal

- Background tasks respect iOS constraints
- BGTaskScheduler for background refresh (not continuous)
- Monitor battery impact of features

### Memory

- iOS devices have less memory than macOS
- Monitor memory warnings (onMemoryWarning)
- Clean up large caches when app backgrounded

### Network

- Handle network transitions (WiFi ↔ cellular)
- Resume downloads on network failure
- Show network status to user when appropriate

---

## iOS-Specific Dependencies

### Common Libraries

- **SQLiteData** - Persistence (Point-Free library, cross-platform)
- **WebKit** - Web rendering (via WKWebView)
- **BackgroundTasks** - Background refresh
- **UserNotifications** - Local & push notifications
- **WidgetKit** - Lock Screen widgets

### Never Add

- ❌ Electron or web-based frameworks
- ❌ Cross-platform libraries that weaken native integration

---

## Scene Management

iOS manages app lifecycle through Scenes:

```swift
@main
struct ScrollApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

Handle state restoration:

```swift
.onOpenURL { url in
  // Handle deep links
}
```

---

## Status Bar Customization

Respect system status bar:

```swift
struct ContentView: View {
  @Environment(\.horizontalSizeClass) var sizeClass

  var body: some View {
    VStack {
      // Your content
    }
    .ignoresSafeArea(.keyboard)  // Keyboard doesn't affect safe area
  }
}
```

---

## References

- **Universal rules:** [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
- **Decision trees:** [DECISION-TREES.md](./DECISION-TREES.md)
- **Task scope:** [TASK-SCOPE.md](./TASK-SCOPE.md)
- **iPad considerations:** [PLATFORM-IPADOS.md](./PLATFORM-IPADOS.md)
- **Apple HIG (iOS):** https://developer.apple.com/design/human-interface-guidelines/ios
