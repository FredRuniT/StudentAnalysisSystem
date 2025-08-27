# Student Analysis System - Data Dictionary

## Overview
This data dictionary defines all field types, formats, constraints, and definitions used throughout the Student Analysis System for processing Mississippi MAAP assessment data.

## Core Data Types

### Assessment Components

#### ComponentIdentifier
**Description**: Unique identifier for assessment components across all test providers and years.

| Field | Type | Format | Description | Example |
|-------|------|--------|-------------|---------|
| `grade` | Integer | 3-8 | Grade level | `3` |
| `subject` | String | Enum | Subject area | `"ELA"`, `"Mathematics"` |
| `component` | String | Pattern | Component code | `"RC1OP"`, `"D1OP"` |
| `provider` | TestProvider | Enum | Assessment provider | `QUESTAR`, `NWEA` |

**Component Code Patterns:**
- **QUESTAR (2023-2024)**: `{TYPE}{NUMBER}OP` format
  - ELA: RC1OP-RC5OP, L1OP-L3OP, W1OP
  - Math: D1OP-D8OP, A1OP-A4OP, G1OP-G2OP
- **NWEA (2025)**: Different coding structure (provider-specific)

#### ComponentPair
**Description**: Represents a specific component for a student assessment.

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `identifier` | ComponentIdentifier | Component identification | See above |
| `studentID` | String | Student MSIS identifier | `"MS12345678"` |
| `score` | Double | Component score | `3.45` |
| `scaledScore` | Double | Scaled score value | `425` |
| `year` | Integer | Assessment year | `2024` |

### Student Data

#### StudentDemographics
**Description**: Student demographic and background information.

| Field | Type | Format | Description | Values |
|-------|------|--------|-------------|--------|
| `ethnicity` | String | Categorical | Student ethnicity | `"Hispanic"`, `"White"`, `"Black"`, etc. |
| `gender` | String | Categorical | Student gender | `"M"`, `"F"` |
| `economicStatus` | String | Categorical | Economic disadvantage status | `"Economically Disadvantaged"`, `"Not Economically Disadvantaged"` |
| `specialEducation` | Boolean | Boolean | Special education status | `true`, `false` |
| `englishLearner` | Boolean | Boolean | English learner status | `true`, `false` |
| `migrant` | Boolean | Boolean | Migrant student status | `true`, `false` |

#### TestProvider
**Description**: Enumeration of assessment providers.

| Value | Description | Years Active |
|-------|-------------|--------------|
| `QUESTAR` | Questar Assessment Inc. | 2023-2024 |
| `NWEA` | Northwest Evaluation Association | 2025 |

### Statistical Measures

#### CorrelationResult
**Description**: Complete correlation analysis result with statistical measures.

| Field | Type | Range | Precision | Description |
|-------|------|-------|-----------|-------------|
| `pearsonR` | Double | -1.0 to 1.0 | 4 decimal places | Pearson product-moment correlation |
| `spearmanR` | Double | -1.0 to 1.0 | 4 decimal places | Spearman rank correlation |
| `rSquared` | Double | 0.0 to 1.0 | 4 decimal places | Coefficient of determination |
| `pValue` | Double | 0.0 to 1.0 | 4 decimal places | Statistical p-value |
| `sampleSize` | Integer | ≥ 30 | Whole number | Number of student records |
| `confidenceInterval.lower` | Double | -1.0 to 1.0 | 4 decimal places | Lower bound (95% CI) |
| `confidenceInterval.upper` | Double | -1.0 to 1.0 | 4 decimal places | Upper bound (95% CI) |
| `isSignificant` | Boolean | true/false | N/A | Statistical significance (p < 0.05) |

#### CorrelationStrength
**Description**: Categorical classification of correlation strength.

| Value | Range | Description |
|-------|-------|-------------|
| `negligible` | 0.0 ≤ \|r\| < 0.2 | Very weak relationship |
| `weak` | 0.2 ≤ \|r\| < 0.4 | Weak relationship |
| `moderate` | 0.4 ≤ \|r\| < 0.6 | Moderate relationship |
| `strong` | 0.6 ≤ \|r\| < 0.8 | Strong relationship |
| `veryStrong` | 0.8 ≤ \|r\| ≤ 1.0 | Very strong relationship |

#### CorrelationDirection
**Description**: Direction of correlation relationship.

| Value | Condition | Description |
|-------|-----------|-------------|
| `positive` | r > 0 | Positive correlation |
| `negative` | r < 0 | Negative correlation |

### Predictive Modeling

#### PredictiveIndicator
**Description**: Early warning system indicator for student risk assessment.

| Field | Type | Range/Format | Description |
|-------|------|--------------|-------------|
| `sourceComponent` | String | Component code | Predictor component | 
| `sourceGrade` | Integer | 3-8 | Grade of predictor |
| `targetOutcome` | String | Outcome type | Target to predict |
| `targetGrade` | Integer | 3-8 | Grade of target |
| `correlation` | Double | -1.0 to 1.0 | Predictive correlation |
| `confidence` | Double | 0.0 to 1.0 | Model confidence |
| `riskThreshold` | Double | 0.0 to 5.0 | Risk classification threshold |
| `successThreshold` | Double | 0.0 to 5.0 | Success classification threshold |
| `validationMetrics.accuracy` | Double | 0.0 to 1.0 | Model accuracy |
| `validationMetrics.precision` | Double | 0.0 to 1.0 | Model precision |
| `validationMetrics.recall` | Double | 0.0 to 1.0 | Model recall |
| `recommendedIntervention` | InterventionType | Enum | Suggested intervention |

#### InterventionType
**Description**: Types of educational interventions.

| Value | Description | Intensity |
|-------|-------------|-----------|
| `monitoring` | Regular progress monitoring | Low |
| `targeted` | Targeted skill intervention | Medium |
| `intensive` | Intensive remediation | High |
| `comprehensive` | Comprehensive support plan | Very High |

### Individual Learning Plans

#### StudentInfo
**Description**: Student identification and basic information.

| Field | Type | Format | Description |
|-------|------|--------|-------------|
| `msis` | String | MS######## | Mississippi Student ID |
| `name` | String | Text | Student full name |
| `grade` | Integer | 3-8 | Current grade level |
| `school` | String | Text | School name |
| `district` | String | Text | District name |

#### LearningObjective
**Description**: Specific learning goal within an ILP.

| Field | Type | Description |
|-------|------|-------------|
| `knowledgeObjectives` | [String] | Factual knowledge goals |
| `understandingObjectives` | [String] | Conceptual understanding goals |
| `skillsObjectives` | [String] | Procedural skill goals |
| `standardId` | String | Mississippi standard reference |
| `priority` | ObjectivePriority | Importance level |

#### ObjectivePriority
**Description**: Priority level for learning objectives.

| Value | Description |
|-------|-------------|
| `critical` | Must master immediately |
| `high` | High priority for grade level |
| `medium` | Important but not critical |
| `low` | Enrichment or review |

#### InterventionStrategy
**Description**: Specific intervention approach.

| Field | Type | Description |
|-------|------|-------------|
| `tier` | InterventionTier | RTI tier level |
| `approach` | String | Intervention method |
| `duration` | TimeInterval | Expected duration |
| `frequency` | String | Session frequency |
| `groupSize` | GroupSize | Instructional group size |

#### InterventionTier
**Description**: Response to Intervention (RTI) tier levels.

| Value | Description | Support Level |
|-------|-------------|---------------|
| `tier1` | Universal instruction | Classroom-wide |
| `tier2` | Targeted group intervention | Small group |
| `tier3` | Intensive individual support | One-on-one |

#### GroupSize
**Description**: Instructional group size categories.

| Value | Range | Description |
|-------|-------|-------------|
| `individual` | 1 | One-on-one instruction |
| `small` | 2-5 | Small group |
| `medium` | 6-12 | Medium group |
| `large` | 13+ | Large group/classroom |

## Data Validation Rules

### Required Field Validation
- All correlation results must have non-null statistical measures
- Sample sizes must be ≥ 30 for statistical validity
- Student identifiers must follow MS######## format
- Grade levels must be within 3-8 range

### Value Constraints
- Correlation coefficients: -1.0 ≤ r ≤ 1.0
- p-values: 0.0 ≤ p ≤ 1.0
- Confidence intervals: lower < upper bound
- Assessment scores: positive values only

### Data Quality Thresholds
- **Minimum correlation significance**: p < 0.05
- **Strong predictive correlation**: |r| ≥ 0.7
- **Minimum sample size**: 30 students
- **Confidence level**: 95% for all intervals

## Export Formats

### CSV Format Specifications
- **Decimal precision**: 4 places for correlations, 2 places for percentages
- **Date format**: YYYY-MM-DD
- **Text encoding**: UTF-8
- **Field delimiter**: Comma (,)
- **Text qualifier**: Double quotes (") for fields containing commas

### JSON Format Specifications
- **Schema validation**: JSON Schema v4 compatible
- **Null handling**: Explicit null values for missing data
- **Array formatting**: Bracket notation for collections
- **Nesting**: Maximum 3 levels deep for readability

## File Naming Conventions

### Output Files
- **Correlations**: `correlations_YYYY-MM-DD.csv`
- **Predictive Models**: `predictive_indicators_YYYY-MM-DD.csv`
- **ILPs**: `ilp_student_{MSIS}.md`
- **Reports**: `analysis_report_YYYY-MM-DD.html`

### Backup Files
- **Pattern**: `{original_name}_backup_YYYYMMDDhhmmss.{ext}`
- **Retention**: 30 days for automated backups
- **Location**: `Backups/` subdirectory