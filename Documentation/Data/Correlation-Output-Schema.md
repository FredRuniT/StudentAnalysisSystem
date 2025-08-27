# Correlation Output Data Schema

## Overview
This document defines the data schema and structure for correlation analysis outputs from the Student Analysis System. The system generates multiple correlation data formats for different analytical purposes.

## Core Data Models

### 1. CorrelationResult
**Primary correlation analysis result containing comprehensive statistical measures.**

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `source` | ComponentPair | Source assessment component | Grade_3_ELA_RC1OP_QUESTAR |
| `target` | ComponentPair | Target assessment component | Grade_4_ELA_RC2OP_NWEA |
| `pearsonR` | Double | Pearson correlation coefficient (-1.0 to 1.0) | 0.8347 |
| `spearmanR` | Double | Spearman rank correlation coefficient | 0.8291 |
| `rSquared` | Double | Coefficient of determination (0.0 to 1.0) | 0.6967 |
| `pValue` | Double | Statistical p-value (0.0 to 1.0) | 0.0001 |
| `sampleSize` | Int | Number of student records analyzed | 25946 |
| `confidenceInterval.lower` | Double | Lower bound of 95% confidence interval | 0.8201 |
| `confidenceInterval.upper` | Double | Upper bound of 95% confidence interval | 0.8487 |
| `isSignificant` | Bool | Statistical significance (p < 0.05) | true |

#### Derived Fields
- **correlationStrength**: Categorical strength based on |pearsonR|
  - `veryStrong`: 0.8-1.0
  - `strong`: 0.6-0.8  
  - `moderate`: 0.4-0.6
  - `weak`: 0.2-0.4
  - `negligible`: 0.0-0.2
- **direction**: `positive` or `negative` based on pearsonR sign

### 2. ComponentCorrelationMap
**Simplified correlation mapping for export and visualization.**

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `sourceComponent` | ComponentIdentifier | Source component details | {grade: 3, subject: "ELA", component: "RC1OP"} |
| `correlations[]` | ComponentCorrelation[] | Array of target correlations | [...] |

#### ComponentCorrelation Structure
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `target` | ComponentIdentifier | Target component identifier | {grade: 4, subject: "ELA", component: "RC2OP"} |
| `correlation` | Double | Pearson correlation coefficient | 0.8347 |
| `confidence` | Double | Statistical confidence (0.0 to 1.0) | 0.9999 |
| `sampleSize` | Int | Sample size for this correlation | 25946 |

### 3. ComponentIdentifier
**Standard component identification structure.**

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `grade` | Int | Grade level (3-8) | 3 |
| `subject` | String | Subject area | "ELA", "Mathematics" |
| `component` | String | Component code | "RC1OP", "D1OP", "A1OP" |
| `provider` | TestProvider | Assessment provider | QUESTAR, NWEA |

## CSV Export Formats

### 1. Correlation Export (correlations.csv)
```csv
Source_Grade,Source_Subject,Source_Component,Target_Grade,Target_Subject,Target_Component,Correlation,Sample_Size,Confidence
3,ELA,RC1OP,4,ELA,RC2OP,0.8347,25946,99.99%
3,Mathematics,D1OP,4,Mathematics,D2OP,0.7892,24853,99.87%
```

### 2. Predictive Indicators Export (predictive_indicators.csv)
```csv
Source_Component,Source_Grade,Target_Outcome,Target_Grade,Correlation,Confidence,Risk_Threshold,Success_Threshold,Accuracy,Precision,Recall,Sample_Size,Intervention_Type
RC1OP,3,Proficiency_Level,4,0.8347,99.99%,2.5,3.5,0.892,0.847,0.923,25946,targeted
D1OP,3,Mathematics_Proficiency,4,0.7892,99.87%,2.0,3.0,0.834,0.798,0.876,24853,intensive
```

## Component Naming Convention

### Pattern: `Grade_{grade}_{subject}_{component}_{provider}`

#### Subject Codes
- **ELA**: English Language Arts
- **Mathematics**: Mathematics/Math

#### Component Codes (QUESTAR 2023-2024)
**ELA Components:**
- RC1OP-RC5OP: Reading Comprehension (1-5)
- L1OP-L3OP: Language (1-3)
- W1OP: Writing

**Mathematics Components:**
- D1OP-D8OP: Mathematical Domains (1-8)
- A1OP-A4OP: Algebraic Thinking (1-4)
- G1OP-G2OP: Geometry (1-2)

#### Component Codes (NWEA 2025)
*Different component structure from QUESTAR - system handles both formats*

## Data Volume Specifications

### Scale Metrics
- **Total Students**: 25,946 across all years (2023-2025)
- **Unique Components**: 1,117 assessment components
- **Total Correlations**: 623,286 unique correlation pairs
- **Matrix Size**: 1,117 × 1,117 (symmetric)

### File Size Estimates
- **Full Correlation Matrix**: ~360MB (all correlation pairs)
- **Significant Correlations** (r > 0.7): ~15-20MB
- **Predictive Indicators**: ~5-8MB
- **Individual Learning Plans**: ~50-100MB (all students)

## Quality Thresholds

### Statistical Significance
- **p-value threshold**: < 0.05
- **Minimum sample size**: 30 students
- **Confidence level**: 95%

### Correlation Strength Thresholds
- **Strong predictive relationship**: |r| ≥ 0.7
- **Moderate predictive relationship**: |r| ≥ 0.5
- **Minimum reportable correlation**: |r| ≥ 0.3

## Data Validation Rules

### Required Fields
All CorrelationResult records must have:
- Valid source and target ComponentIdentifiers
- Non-null statistical measures (pearsonR, spearmanR, pValue)
- Sample size ≥ 30
- Confidence interval bounds

### Value Constraints
- Correlation coefficients: -1.0 ≤ r ≤ 1.0
- p-values: 0.0 ≤ p ≤ 1.0
- Sample sizes: positive integers
- Confidence intervals: lower < upper bound

## Usage Notes

1. **Symmetry**: The correlation matrix is symmetric (A→B = B→A)
2. **Memory Optimization**: Large datasets use batched processing
3. **GPU Acceleration**: MLX framework used for correlation calculations
4. **Export Formats**: CSV, JSON, Markdown supported for all data types
5. **Precision**: Correlation values stored with 4 decimal places for export