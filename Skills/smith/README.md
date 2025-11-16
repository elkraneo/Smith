# Smith Framework Skill - SPM Tool Dependencies

## External Dependencies

### Required Tools

**spmsift** - SPM Analysis Tool (Recommended)
- **Purpose**: xcsift-equivalent for Swift Package Manager
- **Installation**: `brew install elkraneo/tap/spmsift`
- **Usage**: Ultra-context-efficient SPM package analysis (96% savings)
- **Integration**: Used by `Scripts/spm-spmsift-simple.sh`
- **Repository**: https://github.com/elkraneo/spmsift

**sbsift** - Swift Build Analysis Tool (Recommended)
- **Purpose**: xcsift-equivalent for Swift Build compilation
- **Installation**: `brew install elkraneo/tap/sbsift`
- **Usage**: Context-efficient build analysis (43% savings)
- **Integration**: Used by `Scripts/validate-compilation-deep.sh` (automatic detection)
- **Repository**: https://github.com/elkraneo/sbsift

### Built-in Tools

The following tools are included in this skill and require no external installation:

**Smith Analysis Scripts:**
- `spm-quick.sh` - Minimal SPM triage (95% context savings)
- `spm-analyze.sh` - Structured JSON analysis (87% context savings)
- `spm-validate.sh` - Detailed SPM validation
- `spm-spmsift-simple.sh` - spmsift-based analyzer (requires spmsift tool)

**Compilation Scripts:**
- `validate-syntax.sh` - Swift syntax validation
- `validate-compilation-deep.sh` - Full workspace compilation analysis
- `smith-format-check.sh` - Swift Format validation

**Pattern Analysis:**
- `tca-pattern-validator.js` - TCA pattern validation (requires Node.js)

### Context Efficiency Comparison

| Tool | Context Usage | Output Size | Dependencies |
|------|---------------|-------------|--------------|
| `spm-spmsift-simple.sh` | Ultra-minimal | ~1.5KB | spmsift (Homebrew) |
| `spm-quick.sh` | Minimal | 3 lines | Built-in |
| `spm-analyze.sh` | Efficient | ~471B | Built-in |
| `spm-validate.sh` | Verbose | 50+ lines | Built-in |
| `swift package dump-package` | High | 40KB+ | Swift toolchain |

## Installation Requirements

### Minimum Setup
- Swift toolchain (for built-in scripts)
- Node.js (for TCA pattern validation)

### Full Setup (Recommended)
```bash
# Install sbsift for build analysis (Homebrew)
brew install elkraneo/tap/sbsift

# Install spmsift for SPM analysis (Homebrew)
brew install elkraneo/tap/spmsift

# Verify installations
sbsift --version
spmsift --version
```

### Usage Priority

Agents will follow this priority for analysis:

**SPM Analysis:**
1. **Primary**: `spm-spmsift-simple.sh` (if spmsift available)
2. **Fallback**: `spm-quick.sh` (built-in, always available)
3. **Escalation**: `spm-analyze.sh` → `spm-validate.sh` (as needed)

**Build Analysis:**
1. **Primary**: `validate-compilation-deep.sh` (uses sbsift automatically if available)
2. **Fallback**: `validate-compilation-deep.sh` (uses xcsift if sbsift unavailable)

This ensures maximum context efficiency while providing fallback options for environments without spmsift.