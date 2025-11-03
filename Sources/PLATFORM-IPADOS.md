# PLATFORM - iPadOS

Platform-specific constraints, patterns, and guidance for iPadOS development.

**Universal rules:** See [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
**Architecture decisions:** See [DECISION-TREES.md](./DECISION-TREES.md)
**iOS baseline:** See [PLATFORM-IOS.md](./PLATFORM-IOS.md) (iPadOS builds on iOS)

---

## Platform Context

- **Target:** iPadOS 26+
- **UI Framework:** SwiftUI (with iPad-specific adaptations)
- **Architecture:** TCA 1.23.0+
- **Modern APIs:** No backwards compatibility required
- **Device Focus:** iPads (all sizes, all orientations, split view)

---

## iPadOS Differences from iOS

iPadOS is **not just iOS on a bigger screen**. It has distinct paradigms:

### Layout Adaptations

- **Regular horizontal size class** - More space for layouts
- **Split View** - Two apps side-by-side requires different state management
- **Slide Over** - Floating window may have limited space
- **Multitasking** - App may be in picture-in-picture mode

### Input Methods

- **Touch** - Like iOS
- **Keyboard + trackpad** - Full keyboard shortcuts, mouse support
- **Apple Pencil** - For drawing, note-taking (if applicable)
- **External keyboards** - Full keyboard navigation

### UI Paradigms

- **Sidebar/Detail split** - Common pattern (like macOS)
- **Navigation Stack** - Different back button behavior
- **Popovers** - Preferred over full-screen modals
- **Menu bar absent** - Use keyboard shortcuts instead

---

## iPadOS-Specific Constraints

### Multi-Window Support

iPadOS apps can run in multiple windows (M1+ iPads):

```swift
WindowGroup {
  ContentView()
}
.commands {
  CommandGroup(replacing: .newItem) {
    Button("New Window") {
      // Create new window with different document
    }
  }
}
```

### Split View State Management

When app appears in split view, state must adapt:

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var body: some View {
  if horizontalSizeClass == .regular {
    // Two-column layout (sidebar + detail)
    HStack {
      Sidebar()
      DetailView()
    }
  } else {
    // Single column (stacked)
    NavigationStack {
      ContentList()
    }
  }
}
```

### External Keyboard Support

Full keyboard navigation required:

```swift
.keyboardShortcut("n", modifiers: .command)  // Cmd+N
.keyboardShortcut("w", modifiers: .command)  // Cmd+W (close)
.keyboardShortcut("s", modifiers: .command)  // Cmd+S (save)
```

---

## iPadOS-Specific Patterns

### Sidebar + Detail Layout

The standard iPad reading experience uses a sidebar:

```swift
struct ContentView: View {
  @State private var selectedArticle: Article?

  var body: some View {
    NavigationSplitView {
      ArticleList(selection: $selectedArticle)
    } detail: {
      if let article = selectedArticle {
        ArticleDetailView(article: article)
      } else {
        Text("Select an article")
      }
    }
  }
}
```

### Popovers Instead of Sheets

On iPad, prefer popovers over full-screen sheets:

```swift
// ❌ On iPad, sheets cover too much
.sheet(isPresented: $showSettings) {
  SettingsView()
}

// ✅ Better: Use popover on iPad, sheet on iPhone
.popover(isPresented: $showSettings) {
  SettingsView()
    .frame(minWidth: 300, minHeight: 400)
}
```

### Keyboard Shortcuts

Provide keyboard shortcuts for power users:

```swift
struct ArticleView: View {
  @Bindable var store: StoreOf<ArticleFeature>

  var body: some View {
    VStack {
      ArticleContent(store: store)
    }
    .keyboardShortcut("a", modifiers: .command)  // Cmd+A archive
    .keyboardShortcut("t", modifiers: .command)  // Cmd+T tag
    .keyboardShortcut("s", modifiers: .command)  // Cmd+S save
  }
}
```

---

## Code Organization for iPadOS

### Shared with iOS

Most code is shared with iOS. Only UI layout differs.

```
Scroll/
├── Scroll.xcodeproj
├── Scroll/
│   ├── App/
│   │   ├── ScrollApp.swift
│   │   └── SceneDelegate.swift
│   ├── Features/
│   │   ├── ArticleReader/
│   │   │   ├── ArticleReaderView.swift (shared)
│   │   │   └── ArticleReaderPad.swift (#if os(iPadOS))
│   │   └── ...
│   ├── Layouts/
│   │   ├── CompactLayout.swift (iPhone)
│   │   └── RegularLayout.swift (iPad)
│   └── ...
└── Tests/
```

### Conditional Compilation

```swift
#if os(iPadOS)
  // iPad-specific code
#elseif os(iOS)
  // iPhone-specific code
#endif
```

---

## Build Configuration

**Recommended: Use xcsift for token-efficient output**
```bash
xcodebuild build -scheme MyApp -destination 'platform=iPadOS Simulator,name=iPad Pro (12.9-inch)' 2>&1 | xcsift
```

**When you need more metadata: Use XcodeBuildMCP**
- Device-specific deployment
- Build product paths
- Simulator management

**Testing Requirements:**
- Test on multiple iPad models: iPad Pro 11", iPad Air, iPad mini, iPad (standard)
- Test in both orientations and split view

---

## Testing on iPadOS

- Swift Testing framework required
- Test on different iPad sizes (iPad Pro 11", 12.9", iPad Air, iPad mini)
- Test in split view, slide over, and full screen
- Test keyboard navigation

```bash
xcodebuild test -scheme Scroll -destination 'platform=iPadOS Simulator,name=iPad Pro (12.9-inch)'
```

---

## Accessibility on iPadOS

### Keyboard Navigation

- All features must work with keyboard + trackpad
- Tab order must be logical
- Keyboard shortcuts for common actions

### VoiceOver Support

- Full VoiceOver compatibility on iPad
- Touch exploration mode supported
- All UI elements labeled meaningfully

### Dynamic Type

- Support Dynamic Type sizing
- Larger font sizes than on iPhone may be needed for readability

---

## Performance Considerations

### Larger Canvas

- iPad has more screen space but also higher pixel density
- Images should be optimized for Retina displays
- Don't load massive datasets just because there's more space

### Memory

- iPad has more memory than iPhone
- Still avoid unnecessary allocations
- Cache large data structures appropriately

### Rendering

- Complex layouts on iPad should still render smoothly
- Use `.renderingMode(.template)` for icon tinting
- Avoid expensive view hierarchies (prefer containers)

---

## iPadOS-Specific Dependencies

### Common Libraries

- **SQLiteData** - Persistence (Point-Free library)
- **WebKit** - Web rendering (via WKWebView)
- **PencilKit** - Apple Pencil support (if applicable)

### Additional iPad Features

- **UISplitViewController** - For complex split view scenarios (if SwiftUI insufficient)
- **Drag & Drop** - Drag articles between windows or to other apps

---

## Contextual Menus & Popovers

Provide context-sensitive options:

```swift
.contextMenu {
  Button("Archive") {
    store.send(.archive)
  }
  Button("Tag") {
    store.send(.showTags)
  }
  Button("Share") {
    store.send(.share)
  }
}
```

---

## Stage Manager (iPadOS 16.1+)

iPads can organize windows via Stage Manager:

```swift
WindowGroup {
  ContentView()
}
.defaultWindowPlacement { value in
  SizeAndPosition(
    size: CGSize(width: 800, height: 1000),
    normalizedPosition: UnitPoint(x: 0.5, y: 0.5)
  )
}
```

---

## References

- **Universal rules:** [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
- **Decision trees:** [DECISION-TREES.md](./DECISION-TREES.md)
- **Task scope:** [TASK-SCOPE.md](./TASK-SCOPE.md)
- **iOS baseline:** [PLATFORM-IOS.md](./PLATFORM-IOS.md)
- **Apple HIG (iPadOS):** https://developer.apple.com/design/human-interface-guidelines/ipados
