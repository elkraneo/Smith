# PLATFORM - macOS

Platform-specific constraints, patterns, and guidance for macOS development.

**Universal rules:** See [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
**Architecture decisions:** See [DECISION-TREES.md](./DECISION-TREES.md)

---

## Platform Context

- **Target:** macOS 26+
- **UI Framework:** SwiftUI (latest APIs)
- **Architecture:** TCA 1.23.0+
- **Modern APIs:** No backwards compatibility required

---

## macOS-Specific Constraints

### Keyboard Navigation & Focus

- All interactive elements must support keyboard navigation
- Focus states confirmed on macOS
- Cmd+key shortcuts for common actions

### Window Management

- Respect macOS window lifecycle
- Support multiple windows (if applicable to feature)
- Window restoration on app relaunch
- Command+W closes windows (standard macOS behavior)

### Menu Bar Integration

- Use standard Menu structures where appropriate
- Respect menu bar conventions (File, Edit, View, Window, Help)
- Keyboard shortcuts follow macOS standards (Cmd not Ctrl)

---

## macOS-Specific Patterns

### Web View Integration

macOS features full WKWebView support (unlike visionOS which uses RealityView).

```swift
#if os(macOS)
import WebKit

struct ArticleReaderView: View {
  @NSViewRepresentable
  func makeNSView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    let webView = WKWebView(frame: .zero, configuration: config)
    return webView
  }

  func updateNSView(_ nsView: WKWebView, context: Context) {
    nsView.load(URLRequest(url: articleURL))
  }
}
#endif
```

### macOS-Specific UI Components

When UI differs significantly from iOS/iPadOS:

```
FeatureMac/
├── FeatureViewMac.swift     // macOS-specific view
├── FeatureSidebar.swift     // Sidebar navigation
└── FeatureToolbar.swift     // Toolbar with commands
```

Platform-specific targets allow clean separation while sharing Core logic.

---

## Code Organization for macOS

### Directory Structure

```
Scroll/
├── Scroll.xcodeproj
├── Scroll/
│   ├── App/
│   │   ├── ScrollApp.swift
│   │   └── Scenes.swift (#if os(macOS) window management)
│   ├── Features/
│   │   ├── ArticleReader/
│   │   │   ├── ArticleReaderView.swift (shared)
│   │   │   └── ArticleReaderMac.swift (#if os(macOS))
│   │   └── ...
│   ├── Utilities/
│   └── Services/
└── Tests/
```

---

## Build Configuration

**Recommended: Use xcsift for token-efficient output**
```bash
xcodebuild build -scheme MyApp 2>&1 | xcsift
```

**When you need more metadata: Use XcodeBuildMCP**
- Build product paths
- Architecture-specific builds (arm64 vs x86_64)
- Code signing details

**Notes:**
- No special derived data paths needed (unlike visionOS)
- Standard Debug/Release configurations

---

## Testing on macOS

- Swift Testing framework required
- Can test full application on simulator
- Hardware testing on actual Mac when needed

```bash
xcodebuild test -scheme Scroll -destination platform=macOS
```

---

## Accessibility on macOS

### VoiceOver Support

- Full VoiceOver compatibility required
- Test with VoiceOver enabled (System Preferences → Accessibility)

### Keyboard Access

- All features accessible via keyboard
- No mouse-only interactions

### Dynamic Type

- Support Dynamic Type sizing
- Test with all text size preferences

---

## Performance Considerations

### File System Access

- Use standard file APIs (FileManager)
- Respect sandbox restrictions if sandboxed
- Cache file access where possible

### Memory

- Monitor memory usage in Activity Monitor
- Large file operations should be streamed, not buffered entirely

---

## macOS-Specific Dependencies

### Common Libraries

- **Alamofire** - Network requests (if needed)
- **SQLiteData** - Persistence (Point-Free library, cross-platform)
- **WebKit** - Web rendering (standard Apple framework)
- **Combine/async-await** - Asynchronous operations

### Never Add

- ❌ Electron or web-based frameworks (defeats "native excellence" principle)
- ❌ Cross-platform libraries that weaken macOS integration

---

## macOS Window Scenes

macOS supports multiple window groups. Use Scene API properly:

```swift
@main
struct ScrollApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 800, minHeight: 600)
    }
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button("About Scroll") {
          // Show about window
        }
      }
    }
  }
}
```

---

## References

- **Universal rules:** [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
- **Decision trees:** [DECISION-TREES.md](./DECISION-TREES.md)
- **Task scope:** [TASK-SCOPE.md](./TASK-SCOPE.md)
- **Apple HIG (macOS):** https://developer.apple.com/design/human-interface-guidelines/macos
