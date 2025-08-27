# XcodeGen Configuration Guide

## Overview
This document explains the correct configuration for XcodeGen when working with a Swift Package that has multiple library products.

## Problem Description
When using XcodeGen with a modular Swift Package structure, the project.yml configuration must properly reference Swift Package library products instead of directly including source files from multiple modules in a single target.

### Incorrect Approach ❌
```yaml
targets:
  StudentAnalysisSystemMac:
    type: application
    platform: macOS
    sources:
      # DON'T include all module sources directly in the app target
      - path: Sources/StudentAnalysisSystem
      - path: Sources/AnalysisCore
      - path: Sources/StatisticalEngine
      - path: Sources/PredictiveModeling
      - path: Sources/IndividualLearningPlan
      - path: Sources/ReportGeneration
    dependencies:
      - package: LocalPackage
        products:
          - MLX
          - Algorithms
```
```
**Why this fails:** This approach treats all files as part of a single target, breaking module boundaries and causing "No such module" import errors.

### Correct Approach ✅
```yaml
targets:
  StudentAnalysisSystemMac:
    type: application
    platform: macOS
    sources:
      # ONLY include the app's UI source files
      - path: Sources/StudentAnalysisSystem
        createIntermediateGroups: true
    dependencies:
      - package: LocalPackage
        products:
          # Reference the Swift Package library products
          - AnalysisCore
          - StatisticalEngine
          - PredictiveModeling
          - IndividualLearningPlan
          - ReportGeneration
```

## Complete Working Configuration

```yaml
name: StudentAnalysisSystem
options:
  bundleIdPrefix: com.studentanalysis
  deploymentTarget:
    iOS: 18.0
    macOS: 15.0
  createIntermediateGroups: true
  generateEmptyDirectories: true
  
packages:
  LocalPackage:
    path: .

settings:
  base:
    SWIFT_VERSION: 6.0
    MARKETING_VERSION: 1.0.0
    CURRENT_PROJECT_VERSION: 1
    SWIFT_STRICT_CONCURRENCY: complete

targets:
  # macOS App
  StudentAnalysisSystemMac:
    type: application
    platform: macOS
    sources:
      - path: Sources/StudentAnalysisSystem
        createIntermediateGroups: true
    dependencies:
      - package: LocalPackage
        products:
          - AnalysisCore
          - StatisticalEngine
          - PredictiveModeling
          - IndividualLearningPlan
          - ReportGeneration
    settings:
      base:
        PRODUCT_NAME: StudentAnalysisSystemMac
        PRODUCT_BUNDLE_IDENTIFIER: com.studentanalysis.mac
        COMBINE_HIDPI_IMAGES: YES
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_NSHumanReadableCopyright: "Copyright © 2025"
        INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.education
        INFOPLIST_KEY_NSMainStoryboardFile: ""
        INFOPLIST_KEY_NSPrincipalClass: NSApplication

  # iOS App
  StudentAnalysisSystemiOS:
    type: application
    platform: iOS
    sources:
      - path: Sources/StudentAnalysisSystem
        createIntermediateGroups: true
    dependencies:
      - package: LocalPackage
        products:
          - AnalysisCore
          - StatisticalEngine
          - PredictiveModeling
          - IndividualLearningPlan
          - ReportGeneration
    settings:
      base:
        PRODUCT_NAME: StudentAnalysisSystemiOS
        PRODUCT_BUNDLE_IDENTIFIER: com.studentanalysis.ios
        TARGETED_DEVICE_FAMILY: 1,2
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait"

  # Command-line executable
  StudentAnalysisSystemApp:
    type: tool
    platform: macOS
    sources:
      - path: Sources/StudentAnalysisSystemMain
        createIntermediateGroups: true
    dependencies:
      - package: LocalPackage
        products:
          - AnalysisCore
          - StatisticalEngine
          - PredictiveModeling
          - IndividualLearningPlan
          - ReportGeneration

schemes:
  StudentAnalysisSystem-Mac:
    build:
      targets:
        StudentAnalysisSystemMac: all
    run:
      config: Debug
      executable: StudentAnalysisSystemMac
    test:
      config: Debug
    archive:
      config: Release

  StudentAnalysisSystem-iOS:
    build:
      targets:
        StudentAnalysisSystemiOS: all
    run:
      config: Debug
      executable: StudentAnalysisSystemiOS
    test:
      config: Debug
    archive:
      config: Release
      
  StudentAnalysisSystemApp:
    build:
      targets:
        StudentAnalysisSystemApp: all
    run:
      config: Debug
      executable: StudentAnalysisSystemApp
    test:
      config: Debug
    archive:
      config: Release
```

## Key Points

1. **LocalPackage**: References the Swift Package at the root of the project (path: .)
2. **App targets only include UI sources**: The app targets should only include their UI-specific source files
3. **Library products as dependencies**: All Swift Package library products must be listed as dependencies
4. **Module boundaries are preserved**: Each module maintains its own namespace and imports work correctly

## How to Apply Changes

1. Update `project.yml` with the correct configuration
2. Regenerate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Build the project:
   ```bash
   xcodebuild -scheme StudentAnalysisSystem-Mac build
   ```

## Verification

After applying the configuration, verify that:
- The project builds successfully in Xcode
- Module imports work correctly (e.g., `import AnalysisCore`)
- The app launches properly
- All Swift Package products are visible in the project navigator