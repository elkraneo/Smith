# SMITH-BUILD-HANGS - Build Hang Analysis Protocol

**When Smith detects or user reports build hangs, follow this structured analysis protocol.**

---

## 🔍 **Build Hang Detection Triggers**

**Auto-detect when:**
- User mentions "build hanging", "stuck", "won't finish", "compilation hang"
- Smith tools report timeout (124 exit code)
- Build stays on same file for > 2 minutes
- Xcode shows "Processing files" indefinitely

---

## 🎯 **Smith Build Hang Protocol**

### **Phase 1: Immediate Triage (60 seconds)**

**Step 1: Identify the hanging target**
```bash
# What's actually hanging?
find . -name "*.swift" -type f -exec grep -l "PATTERN_FROM_ERROR" {} \;

# For String+Extras.swift hang:
echo "Hang reported on: String+Extras.swift"
echo "Checking if file is used elsewhere..."
find . -name "*.swift" -type f -exec grep -l "removingPrefix\|String+Extras" {} \;
```

**Step 2: Isolated compilation test**
```bash
# Test the problematic file in isolation
swiftc -typecheck -Xfrontend -warn-long-function-bodies=100 path/to/problematic.swift

# If this passes, issue is likely dependency-related
# If this hangs, issue is in the file itself
```

### **Phase 2: Dependency Analysis (90 seconds)**

**Step 3: Check for circular dependencies**
```bash
# Find files that import or use the hanging file
grep -r "import.*MODULE" . --include="*.swift" | grep -v ".build/"

# Check for mutual imports between modules
swift package dump-package | jq '.targets[].dependencies'
```

**Step 4: Build cache corruption check**
```bash
# Most common cause of hangs
echo "Checking build cache corruption..."
echo "DerivedData size:"
du -sh ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null | head -5

# If > 500MB, likely corruption
```

### **Phase 3: Swift Toolchain Analysis (120 seconds)**

**Step 5: Type inference debugging**
```bash
# Check for complex type inference
swiftc -typecheck -Xfrontend -debug-constraints path/to/problematic.swift

# Look for exponential type inference patterns
swiftc -typecheck -Xfrontend -warn-long-expression-type-checking=50 path/to/problematic.swift
```

**Step 6: Module dependency graph**
```bash
# Build dependency graph to find cycles
swift package show-dependencies --format json | jq '.dependencies[]'

# Check for overly complex dependency chains
find . -name "*.swift" -exec wc -l {} \; | sort -n | tail -10
```

---

## 🛠️ **Smith Recommended Actions**

### **Immediate Fixes (80% success rate)**

**Fix 1: Clean build state**
```bash
# Kill all Xcode processes
killall Xcode
killall SourceKitService
killall swift-frontend

# Clean build cache
rm -rf ~/Library/Developer/Xcode/DerivedData/*
xcodebuild clean -workspace . -scheme SCHEME
```

**Fix 2: Simplify the hanging file**
```bash
# If String+Extras.swift is hanging:
# 1. Check for overly complex generic constraints
# 2. Look for recursive function definitions
# 3. Simplify complex computed properties
```

**Fix 3: Isolate problematic code**
```bash
# Comment out half the file, test
# Comment out other half, test
# Binary search to find exact problematic line
```

### **Advanced Fixes (20% success rate)**

**Fix 4: Module restructuring**
```bash
# Split large modules (>1000 lines)
# Remove circular dependencies
# Move utility extensions to separate modules
```

**Fix 5: Swift compiler flags**
```bash
# Add to build settings:
# -Xfrontend -warn-long-function-bodies=100
# -Xfrontend -warn-long-expression-type-checking=50
# -Xfrontend -debug-time-function-bodies
```

---

## 📋 **Smith Action Checklist**

When user reports build hang:

**[ ] Phase 1: Triage**
- [ ] Identify exact file/target hanging
- [ ] Test isolated compilation
- [ ] Determine if file-specific or dependency issue

**[ ] Phase 2: Dependencies**
- [ ] Check for circular imports
- [ ] Verify build cache size (< 500MB healthy)
- [ ] Test with clean build environment

**[ ] Phase 3: Toolchain Analysis**
- [ ] Use Swift type inference debugging
- [ ] Build dependency graph
- [ ] Identify complexity hotspots

**[ ] Apply Fixes**
- [ ] Start with clean build (Fix 1)
- [ ] Simplify problematic code (Fix 2-3)
- [ ] Restructure if needed (Fix 4-5)

**[ ] Verify Resolution**
- [ ] Build completes in reasonable time (< 2 min)
- [ ] No new compilation errors introduced
- [ ] All tests still pass

---

## 🛠️ **Overlooked Swift Toolchain Analysis Tools**

### **Swift Compiler Hidden Gems**

**Type System Analysis:**
```bash
# Debug constraint solving (exponential type inference)
swiftc -typecheck -Xfrontend -debug-constraints file.swift

# Warn about slow type checking
swiftc -typecheck -Xfrontend -warn-long-expression-type-checking=50 file.swift

# AST dump for structural analysis
swiftc -dump-ast file.swift | jq .  # JSON AST analysis

# Scope map debugging (circular reference detection)
swiftc -dump-scope-maps expanded file.swift
```

**Performance Analysis:**
```bash
# Function timing analysis
swiftc -typecheck -Xfrontend -debug-time-function-bodies file.swift

# Module dependency explanation
swiftc -Xfrontend -explain-module-dependency-detailed ProblematicModule file.swift

# Build cache analysis
swiftc -driver-time-compilation file.swift
```

**Module System Debugging:**
```bash
# Dependency chain visualization
swiftc -emit-dependencies file.swift

# Module interface verification
swiftc -verify-emitted-module-interface file.swift

# Module serialization debugging
swiftc -Rmodule-serialization file.swift
```

### **Xcode Build System Tools**

**Build Timing Analysis:**
```bash
# Detailed build timing
xcodebuild -showBuildTimingSummary

# Parallel execution analysis
xcodebuild -parallelizeTargets

# Build system debugging
xcodebuild -debug-scheme
```

**Index Store Analysis:**
```bash
# Index store diagnostics
xcodebuild -index-store-path

# Build cache health check
find ~/Library/Developer/Xcode/DerivedData -name "*.index" -exec du -sh {} \;
```

### **System-Level Tools**

**Process and Memory Analysis:**
```bash
# Swift compiler process monitoring
ps aux | grep swift-frontend

# Memory usage during hang
top -pid $(pgrep swift-frontend)

# File descriptor leaks
lsof -p $(pgrep swift-frontend)
```

**Build Cache Forensics:**
```bash
# Module cache corruption detection
find ~/Library/Developer/Xcode/DerivedData -name "*.swiftmodule" -exec file {} \;

# Incremental build state analysis
find . -name "*.swiftdeps" -exec wc -l {} \; | sort -n
```

## 🔧 **Smith Tools Integration**

**New Smith Scripts:**
```bash
# smith-build-hang-analyzer.sh
# - Uses overlooked tools automatically
# - Systematic debugging workflow
# - Root cause identification

# smith-type-inference-debugger.sh
# - Specialized for type checking hangs
# - Uses -debug-constraints analysis
# - Identifies exponential inference patterns

# smith-module-dependency-analyzer.sh
# - Circular dependency detection
# - Module interface verification
# - Build cache corruption detection
```

**Enhanced validate-compilation-deep.sh:**
- Detect timeout (exit code 124)
- Auto-trigger hang analysis protocol
- Provide structured recommendations
- Track success rates for different fixes

---

## 🎯 **Expected Success Rates**

**Smith Build Hang Protocol:**
- **Clean build fixes**: 60% success rate
- **Code simplification**: 25% success rate
- **Module restructuring**: 10% success rate
- **Compiler flag tuning**: 5% success rate

**Total expected success**: 95% of build hang cases resolved

---

**The key is systematic analysis - not random fixes. Smith provides the path, you follow it.**