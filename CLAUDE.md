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

### Component to Reporting Category Mapping
Test components map to Mississippi reporting categories:
- D1, D2 → Operations & Algebraic Thinking (OA)
- D3, D4 → Number & Operations Base Ten (NBT)
- D5, D6 → Fractions (NF)
- D7, D8 → Measurement & Data (MD)
- D9, D0 → Geometry (G)
- RC → Reading Comprehension
- LA → Language Arts

### Correlation Processing
- Calculates (1,117 × 1,116) ÷ 2 = 623,286 unique correlations
- Uses Pearson correlation coefficient with confidence intervals
- **IMPORTANT**: Confidence = 1 - p-value (NOT interval width)
- Correlations > 0.7 indicate strong predictive relationships
- Matrix is symmetric (A→B = B→A)
- Significance indicators: ⭐ for p<0.01, ☆ for p<0.05

### Blueprint Integration
**NEW**: System now integrates Mississippi MAAP Test Blueprints:
- Maps weak components to specific MS-CCRS standards
- Extracts Knowledge, Understanding, and Skills expectations
- Uses test weight percentages to prioritize interventions
- Creates grade progression paths using correlation predictions
- Example: Grade 3 D1OP weakness (35%) → Maps to 3.OA.1-9 standards → Predicts 95% correlation with Grade 5 struggles

### Mississippi Proficiency Levels
**CRITICAL**: Must use official Mississippi levels:
- Level 1: Minimal
- Level 2: Basic
- Level 3: Passing
- Level 4: Proficient
- Level 5: Advanced

### Performance Considerations
- Uses full dataset of 25,946 students for maximum model accuracy
- MLXAccelerator provides GPU optimization for correlation calculations
- DataFrameOptimizer batches operations to reduce memory usage
- CorrelationTableView uses native macOS Table for efficient display of 600K+ correlations

## Data Locations
- Input: `Data/MAAP_Test_Data/*.csv` (assessment data)
- Standards: `Data/Standards/*.json` (Mississippi standards by grade)
- Blueprints: `Data/MAAP_BluePrints/*.json` (test specifications)
- Output: `Output/` directory (all generated reports and ILPs)
  - **IMPORTANT**: Output folder is in .gitignore (files can exceed 100MB)
  - Contains correlation_model.json with 600K+ correlations

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

## Key Files and New Features

### Blueprint Integration Files
- `Sources/AnalysisCore/Models/Blueprint.swift` - Blueprint data models
- `Sources/AnalysisCore/Services/BlueprintManager.swift` - Loads and manages blueprints
- `Sources/PredictiveModeling/GradeProgressionAnalyzer.swift` - Grade progression analysis
- `Sources/IndividualLearningPlan/ILPGenerator+Blueprint.swift` - Blueprint-enhanced ILP generation

### UI Components
- `Sources/StudentAnalysisSystem/Views/CorrelationTableView.swift` - Native macOS table for correlations
- Shows all 623,286 correlations with sorting, filtering, and CSV export
- Star indicators: ⭐ (p<0.01 highly significant), ☆ (p<0.05 significant)

### Documentation
- `Documentation/Features/Blueprint-Integration.md` - Blueprint system overview
- `Documentation/Features/Blueprint-Usage-Guide.md` - Following Test Blueprints 101
- `AGENT_HANDOFF.md` - Current issues and state for agent handoff

## Known Issues and TODOs
- ILPGenerator+Blueprint.swift has compilation errors (type mismatches, access levels)
- Need to standardize on Mississippi's official proficiency levels
- Some types like ValidatedCorrelationModel need to be created or mapped
- InterventionType enum missing required values

## Development Notes
- Development machine: 128GB MacBook Pro
- Processing machine: 192GB Mac Studio (for full dataset analysis)
- Full analysis processes 25,946 students generating 623,286 correlations