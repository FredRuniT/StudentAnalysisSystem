# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Student Analysis System - A comprehensive educational assessment platform for predictive modeling and early warning systems. Analyzes Mississippi MAAP assessment data (2023-2025) to generate Individual Learning Plans (ILPs) and identify at-risk students.

## Essential Commands

### Building the Project

#### IMPORTANT: XcodeGen Configuration
The project uses XcodeGen with a modular Swift Package structure. The `project.yml` must reference Swift Package library products, NOT include source files directly. See [XcodeGen Configuration Guide](Documentation/Build/XcodeGen-Configuration.md) for details.

```bash
# Always regenerate Xcode project after file/package changes
xcodegen generate

# Build the Swift Package (command line)
swift build

# Build for release
swift build -c release

# Build macOS app
xcodebuild -scheme StudentAnalysisSystem-Mac build

# Build iOS app  
xcodebuild -scheme StudentAnalysisSystem-iOS build

# Clean everything and rebuild (if you encounter issues)
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData/StudentAnalysisSystem-*
xcodegen generate
swift build
```

#### Troubleshooting
For build issues, see [Build Issues Guide](Documentation/Troubleshooting/Build-Issues.md)

### Running the System
```bash
# Run the main analysis executable
swift run StudentAnalysisSystemMain

# Or after building for release
.build/release/StudentAnalysisSystemMain
```

### Testing
```bash
# Run all tests
swift test

# Run specific test target
swift test --filter AnalysisCoreTests
swift test --filter StatisticalEngineTests
swift test --filter PredictiveModelingTests
```

## Architecture

### Module Dependency Hierarchy
```
StudentAnalysisSystemMain (executable)
    ├── ReportGeneration
    │   ├── IndividualLearningPlan
    │   ├── PredictiveModeling
    │   └── AnalysisCore
    ├── IndividualLearningPlan
    │   ├── PredictiveModeling
    │   ├── StatisticalEngine
    │   └── AnalysisCore
    ├── PredictiveModeling
    │   ├── StatisticalEngine
    │   └── AnalysisCore
    ├── StatisticalEngine
    │   └── AnalysisCore
    └── AnalysisCore (foundation)
```

### Key Components

**AnalysisCore**: Foundation module containing data models, parsers, and utilities
- `NWEAParser` / `QUESTARParser`: Parse assessment data from different test providers
- `AssessmentComponent`: Core data model for test components (623,286 correlations across 1,117 unique components)
- `StudentData` / `StudentLongitudinalData`: Student assessment tracking models
- `DataFrameOptimizer` / `MemoryOptimizer`: Performance optimization for large datasets (25,946 students)

**StatisticalEngine**: Mathematical analysis and correlation calculations
- `CorrelationAnalyzer`: Generates correlation matrix using Pearson coefficient
- `MLXAccelerator`: Apple MLX framework integration for GPU acceleration
- `ValidationMetrics` / `ValidationResults`: Model validation and confidence scoring

**PredictiveModeling**: Early warning and risk assessment
- `EarlyWarningSystem`: Identifies at-risk students years in advance
- `ComponentCorrelationEngine`: Maps relationships between test components
- `BacktestingFramework`: Validates predictive models against historical data

**IndividualLearningPlan**: ILP generation and standards mapping
- `ILPGenerator`: Creates personalized learning plans based on correlations
- `StandardsRepository`: Maps assessments to Mississippi academic standards
- `ILPExporter`: Exports plans to multiple formats (MD, HTML, JSON, CSV)

**ReportGeneration**: Output generation and visualization
- `ReportBuilder`: Constructs comprehensive analysis reports
- `CSVExporter`: Bulk data export functionality
- `VisualizationData`: Data preparation for UI charts

### Data Flow
1. CSV assessment data (2023-2025) → Parsers (NWEA/QUESTAR)
2. AssessmentComponents → CorrelationAnalyzer → Correlation Matrix
3. Correlation Matrix + Student Data → EarlyWarningSystem → Risk Predictions
4. Risk Predictions + Standards → ILPGenerator → Individual Learning Plans
5. ILPs → Exporters → Output formats (MD/HTML/JSON/CSV)

## Critical Implementation Details

### Assessment Component Structure
Components follow pattern: `Grade_{grade}_{subject}_{component}_{provider}`
- Example: `Grade_3_ELA_RC2OP_QUESTAR`
- NWEA (2025) uses different component codes than QUESTAR (2023-2024)
- System handles 1,117 unique components across all grades/subjects

### Correlation Processing
- Calculates (1,117 × 1,116) ÷ 2 = 623,286 unique correlations
- Uses Pearson correlation coefficient with confidence intervals
- Correlations > 0.7 indicate strong predictive relationships
- Matrix is symmetric (A→B = B→A)

### Performance Considerations
- Uses full dataset of 25,946 students for maximum model accuracy
- Full dataset contains 25,946 students
- MLXAccelerator provides GPU optimization for correlation calculations
- DataFrameOptimizer batches operations to reduce memory usage

## Data Locations
- Input: `Data/MAAP_Test_Data/*.csv` (assessment data)
- Standards: `Data/Standards/*.json` (Mississippi standards by grade)
- Blueprints: `Data/MAAP_BluePrints/*.json` (test specifications)
- Output: `Output/` directory (all generated reports and ILPs)

## Platform Requirements
- macOS 15.0+ / iOS 18.0+
- Swift 6.0
- XcodeGen for project generation

## XcodeGen Reminder
**IMPORTANT**: Always run `xcodegen generate` after:
- Adding/removing Swift files
- Modifying Package.swift dependencies
- Changing target configurations
- Before building the Xcode project

**CRITICAL**: The `project.yml` configuration MUST:
- Only include app UI sources in app targets (Sources/StudentAnalysisSystem)
- Reference Swift Package library products as dependencies (AnalysisCore, StatisticalEngine, etc.)
- NOT include module source directories directly in app targets
- See [XcodeGen Configuration Guide](Documentation/Build/XcodeGen-Configuration.md) for correct setup