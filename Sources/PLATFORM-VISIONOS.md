# PLATFORM - visionOS

Platform-specific constraints, patterns, and guidance for visionOS development.

**Universal rules:** See [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
**Architecture decisions:** See [DECISION-TREES.md](./DECISION-TREES.md)

---

## Platform Context

- **Target:** visionOS 26+
- **Device:** Apple Vision Pro
- **UI Framework:** SwiftUI + RealityKit
- **Architecture:** TCA 1.23.0+
- **Modern APIs:** No backwards compatibility required

---

## Hard visionOS Constraints

### [CRITICAL] Never Use ARView

**This is non-negotiable.**

```swift
// ❌ NEVER DO THIS
import ARKit
let arView = ARView(frame: .zero)
arView.installGestures()

// ✅ ALWAYS DO THIS
import RealityKit

RealityView { content in
  let entity = Entity()
  // Configure entity
  content.add(entity)
}
```

**Why:** ARView is deprecated in visionOS. RealityView is the modern, platform-native approach. ARView will not compile reliably on visionOS with strict concurrency.

### [CRITICAL] Scene Only in App Target

Do not define `Scene` outside the main App target:

```swift
// ❌ WRONG - Never in feature modules
public struct MyFeature {
  public var body: some Scene { ... }  // DON'T DO THIS
}

// ✅ CORRECT - Scene only in App
@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }

    ImmersiveSpace(id: "immersive") {
      ImmersiveView()
    }
  }
}
```

**Why:** Scenes manage app lifecycle. Feature modules should only define Views and Reducers. Keeps module boundaries clean.

### [CRITICAL] @MainActor for RealityView Mutations

Any mutations to RealityKit content must be on MainActor:

```swift
@MainActor
func updateRealityContent() {
  // Safe to mutate RealityKit entities
}

RealityView { content in
  let entity = Entity()
  content.add(entity)  // Already on MainActor in RealityView closure
} update: { content in
  // Also on MainActor
  if let entity = content.findEntity(named: "myEntity") {
    var transform = entity.transform
    transform.translation.y += 0.1
    entity.move(to: transform, relativeTo: content)
  }
}
```

### @Observable for State (No Combine)

Use `@Observable`, never Combine:

```swift
// ✅ CORRECT
@Observable
final class GameState {
  var score: Int = 0
  var particles: [Particle] = []
}

// ❌ WRONG
class GameState: ObservableObject {
  @Published var score: Int = 0
}
```

---

## RealityView Integration Patterns

### Basic RealityView Setup

```swift
import RealityKit

struct ContentView: View {
  var body: some View {
    RealityView { content in
      // Add entities here
      let entity = Entity()
      entity.position = [0, 0, -1]
      content.add(entity)
    }
  }
}
```

### RealityView with Model3D

Load 3D models:

```swift
RealityView { content in
  if let model = try? await ModelEntity(named: "MyModel", in: Bundle.main) {
    var transform = model.transform
    transform.translation.y = 0.5
    model.move(to: transform, relativeTo: content)
    content.add(model)
  }
}
```

### RealityView with SwiftUI Attachments

Add SwiftUI views as 3D space attachments:

```swift
RealityView { content in
  let entity = Entity()

  // Create SwiftUI view attachment
  let attachment = ViewAttachmentComponent(
    rootView: VStack {
      Text("Info Panel")
      Button("Close") { /* ... */ }
    }
    .frame(width: 300, height: 200)
    .padding()
    .background(.regularMaterial)
  )

  entity.components.set(attachment)
  entity.position = [0, 1.5, -1]
  content.add(entity)
}
```

### RealityView Update Handler

Handle dynamic content changes:

```swift
RealityView { content in
  // Initial setup
  let entity = Entity()
  content.add(entity)
} update: { content in
  // Called when view updates
  if let entity = content.findEntity(named: "myEntity") {
    var transform = entity.transform
    transform.translation.y += 0.1
    entity.move(to: transform, relativeTo: content)
  }
}
```

### PresentationComponent Entity Creation

**[CRITICAL]** When using `PresentationComponent` for popovers or presentations, the entity must be created and added to the scene early, not lazily on demand.

**Problem:** If you defer entity creation until presentation is needed, the entity may not exist in the scene when the view tries to render, resulting in invisible popovers despite correct state management.

**Pattern:**
```swift
// ✅ CORRECT: Create presentation entity during button configuration
private func configureButton(for button: Entity, in container: Entity) {
  // ... button setup ...

  // Create the PresentationComponent entity immediately
  let popoverEntity = Entity()
  popoverEntity.name = "button-popover"
  var presentation = PresentationComponent(
    configuration: .popover(arrowEdge: .bottom),
    content: PopoverContentView()
  )
  presentation.isPresented = false  // Start hidden
  popoverEntity.components.set(presentation)
  container.addChild(popoverEntity)
}

// ✅ Later, toggle visibility via state observation
.onChange(of: store.popoverVisibility) { _, isVisible in
  // Update isPresented flag
  if var presentation = popoverEntity.components[PresentationComponent.self] {
    presentation.isPresented = isVisible
    popoverEntity.components.set(presentation)
  }
}
```

**Why:** RealityKit requires the entity to be in the scene graph before its components can be rendered. If you create the entity lazily when presentation is needed, there's a synchronization gap where the view tries to render content for a non-existent entity.

**Key Points:**
- Create `PresentationComponent` entities during scene setup, not on-demand
- Initialize with `isPresented = false`
- Toggle `isPresented` via state observation (onChange handlers)
- Keep the entity in the scene; don't add/remove it repeatedly

---

### [CRITICAL] Entity Cleanup on State Transitions

**Problem:** `ViewAttachmentComponent` references SwiftUI views that observe TCA stores. When level/feature transitions occur:
1. TCA state is cleared ✓
2. But RealityKit entities persist in scene ✗
3. Stale entities reference old store/state → non-interactive views

**Pattern: Explicit Entity Cleanup BEFORE Level Transition**

```swift
// GameView+Level.swift
extension GameView {
  /// Called when current level changes
  func onLevelChange(_ oldLevel: CurrentLevel, _ newLevel: CurrentLevel) {
    // ✅ Clear RealityKit entities BEFORE new level setup
    clearLevelSpecificEntities(for: oldLevel)

    // Then set up new level
    setupLevel(newLevel)
  }

  private func clearLevelSpecificEntities(for level: CurrentLevel) {
    switch level {
    case .intro, .glitch, .legacy:
      // ✅ Clear screen button popovers
      game.renderer.clearScreenButtonPopovers()

    case .mpa:
      // ✅ Clear MPA-specific entities
      game.renderer.clearMPAEntities()
    }
  }
}

// GameRenderer+Button3D.swift
extension GameRenderer {
  /// Clear all screen button popover entities when transitioning levels.
  ///
  /// Called from `GameView.onLevelChange()` to prevent stale entities.
  /// This is critical for preventing non-interactive UI when `ViewAttachmentComponent`
  /// references old store state.
  public func clearScreenButtonPopovers() {
    for (_, entity) in screenButtonPopoverEntities {
      entity.removeFromParent()  // ✅ Remove from RealityKit scene
    }
    screenButtonPopoverEntities.removeAll()  // ✅ Clear dictionary
  }
}

// Usage in RealityView
.onAppear {
  gameView.$store.changes
    .map(\.currentLevel)
    .removeDuplicates()
    .sink { newLevel in
      gameView.onLevelChange(gameView.store.currentLevel, newLevel)
    }
    .store(in: &cancellables)
}
```

**Verification Checklist:**

- [ ] Entity cleanup method exists (`clearXEntities()`)
- [ ] Method called in level/feature transition handler
- [ ] Method called BEFORE new level setup (not after)
- [ ] Entities removed from parent (`removeFromParent()`)
- [ ] Entity dictionary/storage cleared (`.removeAll()`)
- [ ] New entities created fresh (not reused from previous state)
- [ ] No orphaned entities in scene after transition

**Why This Matters:**

When `ViewAttachmentComponent` wraps a SwiftUI view that observes a TCA store:
- The attachment holds a strong reference to the view
- The view observes the store state
- If the store is cleared but entity isn't, the view still exists with stale data
- Interactions on the stale view won't work (they reference cleared state)

**Related:** See DISCOVERY-4 for entity creation patterns, DISCOVERY-12 for real-world impact.

---

## ImmersiveSpace Lifecycle

### Opening & Closing Immersive Space

Use environment actions to control immersive space:

```swift
@Reducer
public struct GameFeature {
  @Dependency(\.openImmersiveSpace) var openImmersiveSpace
  @Dependency(\.dismissImmersiveSpace) var dismissImmersiveSpace

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .startGame:
        return .run { send in
          await openImmersiveSpace(id: "gameSpace")
        }

      case .endGame:
        return .run { send in
          await dismissImmersiveSpace()
        }

      default:
        return .none
      }
    }
  }
}
```

### ImmersiveView State Transitions

Use `onAppear`/`onDisappear` for state setup/teardown:

```swift
struct ImmersiveGameView: View {
  @Bindable var store: StoreOf<GameFeature>

  var body: some View {
    RealityView { content in
      let game = GameEngine()
      content.add(game.rootEntity)
    }
    .onAppear {
      store.send(.immersiveViewAppeared)
    }
    .onDisappear {
      store.send(.immersiveViewDisappeared)
    }
  }
}
```

### Immersion Style

Default is `.mixed`. Change only when task requires otherwise:

```swift
ImmersiveSpace(id: "immersive") {
  ImmersiveView()
    .immersionStyle(selection: .constant(.full), in: .full, .mixed)
}
```

---

## Gestures in visionOS

### Handling User Interactions

Use standard SwiftUI gestures with RealityView:

```swift
RealityView { content in
  // Add entities
  let entity = Entity()
  content.add(entity)
}
.gesture(
  DragGesture()
    .onChanged { value in
      // Handle drag - update entity position
    }
    .onEnded { value in
      // Finalize movement
    }
)
.gesture(
  MagnificationGesture()
    .onChanged { scale in
      // Handle pinch to zoom
    }
)
.gesture(
  RotationGesture()
    .onChanged { angle in
      // Handle rotation
    }
)
```

### Eye Gaze & Hand Tracking

For advanced spatial interactions:

```swift
RealityView { content in
  // Initialize 3D content
}
.onContinuousHover { phase in
  switch phase {
  case .active(let location):
    // Handle hover over element
    break
  case .ended:
    // Handle hover end
    break
  }
}
```

---

## Build Configuration (Critical)

### Build Output Strategy for visionOS

**Recommended: Use xcsift for token-efficient output**

```bash
xcodebuild build \
  -scheme MyApp \
  -configuration Debug \
  -derivedDataPath /Volumes/Plutonian/Xcode/DerivedData \
  2>&1 | xcsift
```

**Why:** Minimal JSON output (~150-300 tokens) with errors, line numbers, file paths.

**Output:**
```json
{
  "success": false,
  "errors": [
    {
      "file": "GameView.swift",
      "line": 42,
      "column": 14,
      "message": "Cannot convert value of type 'X' to expected argument type 'Y'"
    }
  ],
  "errorCount": 1,
  "warningCount": 0
}
```

### When to Use XcodeBuildMCP

Use `mcp__XcodeBuildMCP__*` tools when you need full build metadata:

```swift
mcp__XcodeBuildMCP__build_sim({
  projectPath: "/path/to/app.xcodeproj",
  scheme: "MyApp",
  simulatorName: "Vision Pro"
})

mcp__XcodeBuildMCP__test_sim({
  projectPath: "/path/to/app.xcodeproj",
  scheme: "MyApp",
  simulatorName: "Vision Pro"
})
```

**When needed:**
- Build product paths/binary locations
- Code coverage information
- Full build metadata
- Device-specific deployment

**Trade-off:** Higher token cost (~800-1200 tokens) but complete information

### CRITICAL: External Drive Path

**Always include `-derivedDataPath /Volumes/Plutonian/Xcode/DerivedData`** when using xcodebuild or xcsift. visionOS builds are large and must go to external drive:

```bash
xcodebuild build \
  -scheme MyApp \
  -configuration Debug \
  -derivedDataPath /Volumes/Plutonian/Xcode/DerivedData \
  2>&1 | xcsift
```

---

## Code Organization for visionOS

### Single Target for Focused Apps

Unlike multi-platform projects, visionOS-exclusive apps often use a simpler structure:

```
MyVisionApp/
├── Sources/
│   ├── App/
│   │   ├── MyVisionApp.swift
│   │   └── AppFeature.swift
│   ├── Game/
│   │   ├── GameFeature.swift
│   │   ├── GameView.swift
│   │   ├── GameEngine.swift
│   │   └── ...
│   ├── UI/
│   │   ├── MenuView.swift
│   │   ├── SettingsView.swift
│   │   └── ...
│   ├── Models/
│   │   ├── GameState.swift
│   │   ├── Particle.swift
│   │   └── ...
│   └── Services/
│       ├── GameCenterClient.swift
│       ├── AudioService.swift
│       └── ...
├── Tests/
│   └── MyVisionAppTests/
└── Resources/
```

**When to split into modules:**
- 3D engine logic becomes reusable
- Game logic is 1000+ lines
- Want platform-agnostic core logic

---

## Performance Optimization for visionOS

### RealityKit Performance Tips

1. **Limit active entities** - Too many hurt performance
   ```swift
   let maxEntities = 200
   if state.particles.count > maxEntities {
     state.particles.removeFirst(state.particles.count - maxEntities)
   }
   ```

2. **Batch updates** - Update in batches, not one-by-one
   ```swift
   // ❌ Slow: Update individually
   for particle in particles {
     updateParticlePosition(particle)
   }

   // ✅ Fast: Batch
   var batch = [ModelEntity]()
   for particle in particles {
     batch.append(createParticleEntity(particle))
   }
   content.add(contentsOf: batch)
   ```

3. **Use LOD (Level of Detail)** - Simplify models based on distance
   ```swift
   let distance = entity.position.distance(from: camera.position)
   if distance > 10 {
     entity.model?.mesh = lodMeshes.far
   } else {
     entity.model?.mesh = lodMeshes.near
   }
   ```

4. **Profile with Instruments**
   - Use Reality Composer to profile
   - Monitor frame rate and memory
   - Optimize before shipping

---

## Testing visionOS Features

### Core Logic Testing (Platform-Agnostic)

Test game logic without RealityView:

```swift
import Testing
import Dependencies
@testable import MyVisionApp

@Suite(.dependencies {
  $0.continuousClock = TestClock()
  $0.gameEngine = .mock
})
struct GameFeatureTests {
  @Test @MainActor
  func gameStartsCorrectly() async {
    let store = TestStore(initialState: GameFeature.State()) {
      GameFeature()
    }

    await store.send(.startGame) {
      $0.gameState = .playing
    }

    await store.finish()
  }
}
```

### RealityView Testing

Test RealityView integration separately (more challenging):

```swift
import Testing
@testable import MyVisionApp

@Suite
struct GameViewTests {
  @Test
  func realityViewRenders() {
    // Test that RealityView initializes without errors
    let view = GameView()
    // Assertions on view structure
  }
}
```

---

## Accessibility in visionOS

### VoiceOver Support

Ensure all interactive elements work with VoiceOver:

```swift
Button("Start Game") {
  store.send(.startGame)
}
.accessibilityLabel("Start Game")
.accessibilityHint("Begins a new game of pollen collection")
```

### Spatial Audio

Consider audio cues for spatial interactions:

```swift
.onTapGesture {
  AudioService.play(.success)
  store.send(.particleCollected)
}
```

---

## Safety Rules for visionOS Development

### Edit Safety

- **Only edit files directly related to current task**
- Before editing files outside immediate scope, **ask for explicit approval**
- Never make "helpful" edits to unrelated code
- **Always show diff before committing changes**

### Command Execution Safety

- Run each command once and analyze output
- If a command fails, describe error and ask what to do next—**do NOT retry automatically**
- Maximum 3 retry attempts per command; describe issue instead
- **Never execute the same command in a loop**

### Git & Version Control

- **Never auto-commit changes without showing diff first**
- Ask for confirmation before any destructive operations (rebase, force-push, reset)
- Use `git diff` to preview changes before committing

### MCP Tool Usage

- Use SosumiDocs MCP for Apple documentation
- Limit web search to documentation lookups only
- Verify all tool results before acting
- One MCP call per task step; don't chain tools blindly

### When in Doubt

- Ask for clarification rather than making assumptions
- Describe what you're about to do before doing it
- **Stop and wait for feedback instead of proceeding with uncertainty**

---

## References

- **Universal rules:** [AGENTS-AGNOSTIC.md](./AGENTS-AGNOSTIC.md)
- **Decision trees:** [DECISION-TREES.md](./DECISION-TREES.md)
- **Task scope:** [TASK-SCOPE.md](./TASK-SCOPE.md)
- **Apple Vision Pro Documentation:** https://developer.apple.com/documentation/visionos
- **RealityKit:** https://developer.apple.com/documentation/realitykit
- **WWDC25 Session 323:** Refine your app for Apple Vision Pro
