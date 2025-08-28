# View Data Requirements Audit

## Overview
This document maps what the problematic views expect versus what the actual backend models provide.

## 1. ILPDetailView Requirements

### View Expects (Based on Compilation Errors):

#### Direct ILP Properties Expected:
- `ilp.studentMSIS` - NOT EXISTS (actual: `ilp.studentInfo.msis`)
- `ilp.currentGrade` - NOT EXISTS (actual: `ilp.studentInfo.grade`) 
- `ilp.planType` - NOT EXISTS (not in backend model)
- `ilp.focusAreas` - NOT EXISTS (actual: `ilp.identifiedGaps`)
- `ilp.milestones` - NOT EXISTS (actual: `ilp.timeline.milestones`)

#### Nested Object Expectations:
- `timeline.phases` - NOT EXISTS (Timeline only has startDate, endDate, milestones)
- `phase.name` - NOT EXISTS (phases don't exist in backend)
- `objective.standard` - NOT EXISTS (actual: `objective.standardId`)
- `milestone.assessmentMethods` - NOT EXISTS (Milestone only has date, description, assessmentType)
- `milestone.criteria` - NOT EXISTS

### Actual Backend Model (IndividualLearningPlan):
```swift
public struct IndividualLearningPlan {
    public let studentInfo: StudentInfo {
        msis: String
        name: String
        grade: Int
        school: String
        testDate: Date
        testType: String
    }
    public let assessmentDate: Date
    public let performanceSummary: PerformanceAnalysis
    public let identifiedGaps: [WeakArea]  // NOT focusAreas
    public let targetStandards: [String]
    public let learningObjectives: [ScaffoldedLearningObjective]
    public let interventionStrategies: [InterventionStrategy]
    public let additionalRecommendations: [String]
    public let predictedOutcomes: [PredictedOutcome]
    public let timeline: Timeline {
        startDate: Date
        endDate: Date
        milestones: [Milestone]
    }
}
```

## 2. PredictiveCorrelationView Requirements

### View Expects:
- `ilp.focusAreas` - NOT EXISTS (actual: `ilp.identifiedGaps`)
- `area.severity` - NOT EXISTS for WeakArea (actual: `area.gap`)
- `ilp.performanceSummary` as array - WRONG TYPE (it's PerformanceAnalysis object, not array)

## 3. StudentProfileView Requirements

### View Expects:
- UI model properties that need conversion through ModelAdapters
- Export functions expecting async patterns
- ILP navigation expecting proper model conversion

## 4. ILPGeneratorView Requirements

### View Expects:
- Generates UIIndividualLearningPlan
- Needs conversion to backend IndividualLearningPlan for ILPDetailView

## Data Model Mismatches Summary

### Critical Missing Properties:
1. **planType** - UI concept not in backend
2. **focusAreas** → should use `identifiedGaps`
3. **studentMSIS/currentGrade** → should use `studentInfo.msis/grade`
4. **phases** - UI concept for timeline visualization, not in backend
5. **severity** → should use `gap` for WeakArea

### Type Mismatches:
1. **performanceSummary** - Backend is object, views expect array
2. **Milestone** types don't match between Timeline.Milestone and expected Milestone
3. **LearningObjective** vs **ScaffoldedLearningObjective**

## Recommended Solutions

### Option 1: Create View-Specific Wrapper Models
Create wrapper models that provide the expected properties by adapting backend data:

```swift
extension IndividualLearningPlan {
    var studentMSIS: String { studentInfo.msis }
    var currentGrade: Int { studentInfo.grade }
    var focusAreas: [WeakArea] { identifiedGaps }
    var planType: PlanType { 
        // Derive from performance level
        if performanceSummary.proficiencyLevel == .advanced {
            return .enrichment
        } else if performanceSummary.proficiencyLevel == .minimal {
            return .remediation
        }
        return .auto
    }
}
```

### Option 2: Update Views to Use Correct Properties
Modify views to access the actual backend model properties:
- Replace `ilp.studentMSIS` with `ilp.studentInfo.msis`
- Replace `ilp.focusAreas` with `ilp.identifiedGaps`
- Remove references to non-existent properties like `phases`

### Option 3: Create Comprehensive UI Models
Build complete UI-specific models that views expect and provide full conversion in ModelAdapters.swift

## Priority Fixes

1. **ContentView** - Use ZStack instead of Group to avoid type inference
2. **ILPDetailView** - Add computed properties or fix property access
3. **PredictiveCorrelationView** - Fix focusAreas and performanceSummary usage
4. **Model Adapters** - Ensure complete UI ↔ Backend conversions