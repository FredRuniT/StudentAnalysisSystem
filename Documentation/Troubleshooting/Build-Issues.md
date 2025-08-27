# Build Issues Troubleshooting Guide

## Common Build Issues and Solutions

### Issue 1: "No such module" errors in Xcode

**Symptoms:**
```
/path/to/file.swift:3:8: error: no such module 'AnalysisCore'
import AnalysisCore
       ^
```

**Cause:** The project.yml file is incorrectly configured, causing XcodeGen to include all source files directly in the app target instead of using Swift Package library products.

**Solution:**
1. Check that `project.yml` only includes the app's UI sources in the target
2. Ensure all Swift Package library products are listed as dependencies
3. Regenerate the project: `xcodegen generate`
4. Clean build folder in Xcode: Product → Clean Build Folder (⇧⌘K)
5. Build again

See: [XcodeGen Configuration Guide](../Build/XcodeGen-Configuration.md)

---

### Issue 2: Build succeeds in terminal but fails in Xcode

**Symptoms:**
- `swift build` works fine
- Xcode build fails with module import errors

**Solution:**
1. Clear derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/StudentAnalysisSystem-*
   ```
2. Regenerate Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open the regenerated project and build

---

### Issue 3: Missing dependencies after Package.swift changes

**Symptoms:**
- Build errors about missing types or modules
- Imports that were working suddenly fail

**Solution:**
1. Update Package.swift dependencies if needed
2. Regenerate Xcode project: `xcodegen generate`
3. Reset Swift Package caches:
   ```bash
   swift package reset
   swift package resolve
   ```
4. Clean and rebuild

---

### Issue 4: App builds but won't launch

**Symptoms:**
- Build succeeds
- App crashes on launch or doesn't appear

**Possible Solutions:**
1. Check that all required frameworks are embedded:
   - In Xcode, select the app target
   - Go to "Frameworks, Libraries, and Embedded Content"
   - Ensure all frameworks are set to "Embed & Sign"

2. Check minimum deployment target matches your system:
   - macOS 15.0+ required
   - iOS 18.0+ required

3. Check for runtime crashes in Console.app

---

## Build Commands Quick Reference

### Command Line Builds
```bash
# Clean build
swift package clean && swift build

# Release build
swift build -c release

# Run executable
swift run StudentAnalysisSystem

# Run tests
swift test
```

### Xcode Builds
```bash
# Build Mac app
xcodebuild -scheme StudentAnalysisSystem-Mac -configuration Debug build

# Build iOS app
xcodebuild -scheme StudentAnalysisSystem-iOS -configuration Debug build

# List available schemes
xcodebuild -list -project StudentAnalysisSystem.xcodeproj

# Clean build folder
xcodebuild -scheme StudentAnalysisSystem-Mac clean
```

### XcodeGen Commands
```bash
# Generate Xcode project
xcodegen generate

# Generate with verbose output
xcodegen generate --verbose

# Validate project.yml
xcodegen dump --file project.yml
```

## When All Else Fails

1. **Complete Reset:**
   ```bash
   # Clean everything
   rm -rf .build
   rm -rf ~/Library/Developer/Xcode/DerivedData/StudentAnalysisSystem-*
   swift package clean
   
   # Regenerate and rebuild
   xcodegen generate
   swift build
   ```

2. **Check for Updates:**
   - Ensure Xcode is up to date
   - Update XcodeGen: `brew upgrade xcodegen`
   - Update Swift: Check with `swift --version`

3. **Verify Dependencies:**
   ```bash
   swift package show-dependencies
   swift package diagnose-api-breaking-changes
   ```

## Getting Help

If you encounter an issue not covered here:
1. Check the build logs for detailed error messages
2. Run with verbose output: `swift build -v`
3. Check that all imports match the module structure in Package.swift
4. Ensure all files are included in the appropriate target in Package.swift