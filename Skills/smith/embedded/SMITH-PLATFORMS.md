# SMITH-PLATFORMS - Platform-Specific Patterns

**Platform-specific patterns for iOS, macOS, and visionOS development within the Smith framework.**

---

## 🔍 **When to Use smith-platforms**

**Auto-load when user mentions:**
- "iOS", "UIKit", "iPhone", "iPad"
- "macOS", "AppKit", "Mac"
- "visionOS", "RealityKit", "ARKit", "Vision Pro"
- Platform-specific APIs or frameworks
- Cross-platform development considerations

---

## visionOS Patterns

### Core visionOS Rules
- **CRITICAL**: Never use ARView - use RealityView
- **CRITICAL**: Scene only in App target, never in feature modules
- **STANDARD**: Use RealityView for all 3D content
- **STANDARD**: VisionOS 26+ target, no backwards compatibility needed

### RealityKit Integration
```swift
// ✅ CORRECT: Modern visionOS approach
import RealityKit

struct ARContentView: View {
  var body: some View {
    RealityView { content in
      let entity = Entity()
      entity.components.set(ModelComponent(mesh: ..., materials: ...))
      content.add(entity)
    }
    .gesture(TapGesture()
      .targetedToEntity(where: .has(ModelComponent.self))
      .onEnded { value in
        // Handle interaction
      })
  }
}
```

### visionOS Entity Patterns
```swift
@Reducer
struct ARFeature {
  @ObservableState
  struct State {
    var entities: [Entity] = []
    var isAnchoring = false
  }

  enum Action {
    case addEntity(Entity)
    case toggleAnchoring
    case placeInWorld
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addEntity(let entity):
        state.entities.append(entity)
        return .none
      case .toggleAnchoring:
        state.isAnchoring.toggle()
        return .none
      case .placeInWorld:
        return .run { [entities = state.entities] send in
          // World anchoring logic
        }
      }
    }
  }
}
```

---

## iOS Patterns

### UIKit Integration
- **STANDARD**: Use UIViewControllerRepresentable for UIKit views
- **STANDARD**: Prefer SwiftUI-first architecture
- **GUIDANCE**: Bridge UIKit only when necessary

### iOS-Specific APIs
```swift
// iOS view controller integration
struct UIKitBridgeView: UIViewControllerRepresentable {
  @Bindable var store: StoreOf<iOSFeature>

  func makeUIViewController(context: Context) -> SomeViewController {
    let vc = SomeViewController()
    vc.store = store
    return vc
  }

  func updateUIViewController(_ uiViewController: SomeViewController, context: Context) {
    uiViewController.update(store: store)
  }
}
```

### iOS Testing Patterns
```swift
@Test
func iOSFeatureIntegration() async {
  let store = TestStore(initialState: iOSFeature.State()) {
    iOSFeature()
  } dependencies: {
    $0.uiApplication = .uiApplication
  }

  await store.send(.viewDidLoad)
  // iOS-specific test logic
}
```

---

## macOS Patterns

### AppKit Integration
- **STANDARD**: Use NSViewControllerRepresentable
- **STANDARD**: Respect macOS window management
- **GUIDANCE**: Handle menu bar and dock integration

### macOS-Specific Considerations
```swift
// macOS window management
struct MacContentView: View {
  @Bindable var store: StoreOf<MacFeature>

  var body: some View {
    MacContentView(store: store)
      .frame(minWidth: 800, minHeight: 600)
      .toolbar {
        ToolbarItem {
          Button("New Document") {
            store.send(.newDocument)
          }
        }
      }
  }
}
```

---

## Cross-Platform Patterns

### Platform Abstraction
```swift
@Reducer
struct CrossPlatformFeature {
  @ObservableState
  struct State {
    var platformSpecificData: PlatformData?
  }

  enum Action {
    case loadPlatformData
    case handlePlatformAction(PlatformAction)
  }

  @Dependency(\.platformClient) var platformClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .loadPlatformData:
        return .run { send in
          let data = await platformClient.loadPlatformSpecificData()
          await send(.platformDataLoaded(data))
        }
      case .handlePlatformAction(let action):
        return platformClient.handle(action)
      }
    }
  }
}
```

### Conditional Compilation
```swift
#if os(visionOS)
extension CrossPlatformFeature {
  func handleVisionOSSpecific(action: VisionOSAction) -> Effect<Action> {
    // visionOS-specific logic
  }
}
#elseif os(iOS)
extension CrossPlatformFeature {
  func handleIOSSpecific(action: iOSAction) -> Effect<Action> {
    // iOS-specific logic
  }
}
#elseif os(macOS)
extension CrossPlatformFeature {
  func handleMacOSSpecific(action: MacOSAction) -> Effect<Action> {
    // macOS-specific logic
  }
}
#endif
```

---

## Platform Decision Trees

### When to Use Platform-Specific Features
1. **Is feature platform-unique?** → Use platform-specific patterns
2. **Can it be abstracted?** → Create cross-platform abstraction
3. **Does it require platform APIs?** → Use conditional compilation
4. **Is it UI-related?** → Prefer SwiftUI with platform-specific modifiers

### Platform Testing Strategy
1. **Core logic**: Test once, verify cross-platform
2. **Platform integration**: Test on each target platform
3. **UI behavior**: Test with platform-specific simulators/devices
4. **Performance**: Profile on target hardware

---

## Platform-Specific Tool Integration

### Build Analysis
- Use spmsift for package structure analysis
- Use sbsift for build validation
- Platform-specific build targets in Package.swift

### Deployment Considerations
- visionOS: Minimum deployment target 1.0
- iOS: Consider iPhone/iPad differences
- macOS: Handle Intel vs Apple Silicon differences

---

## Verification Checklist

### visionOS
- [ ] No ARView usage (RealityView only)
- [ ] Scene definition only in App target
- [ ] Proper RealityKit entity management
- [ ] World anchoring correctly implemented

### iOS
- [ ] Proper UIKit bridge patterns
- [ ] SwiftUI-first architecture maintained
- [ ] iOS-specific testing covered

### macOS
- [ ] AppKit integration correct
- [ ] Window management handled
- [ ] Menu bar integration considered

### Cross-Platform
- [ ] Platform abstractions properly designed
- [ ] Conditional compilation used correctly
- [ ] Testing covers all target platforms

---

**smith-platforms provides the platform-specific guidance needed to build robust, maintainable applications across Apple's ecosystem while following Smith's core principles.**