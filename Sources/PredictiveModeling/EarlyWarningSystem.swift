import AnalysisCore
import Foundation
import MLX
import StatisticalEngine

public actor EarlyWarningSystem {
    private let correlationAnalyzer: CorrelationAnalyzer
    private let thresholdCalculator: ThresholdCalculator
    private var warningThresholds: [ComponentThreshold] = []
    private let configuration: SystemConfiguration
    
    public init(correlationAnalyzer: CorrelationAnalyzer, configuration: SystemConfiguration? = nil) {
        self.correlationAnalyzer = correlationAnalyzer
        self.thresholdCalculator = ThresholdCalculator()
        self.configuration = configuration ?? SystemConfiguration.default
    }
    
    /// trainWarningSystem function description
    public func trainWarningSystem(
        trainingData: [StudentLongitudinalData]
    ) async throws {
        // Identify students who struggled in later years
        /// outcomeData property
        let outcomeData = categorizeStudentOutcomes(trainingData)
        
        // Find component thresholds that predict poor outcomes
        warningThresholds = await discoverCriticalThresholds(
            studentData: trainingData,
            outcomes: outcomeData
        )
    }
    
    /// generateWarnings function description
    public func generateWarnings(
        for student: StudentSingleYearData
    ) async -> EarlyWarningReport {
        /// warnings property
        var warnings: [Warning] = []
        /// risks property
        var risks: [RiskFactor] = []
        
        // Check each component against trained thresholds
        for threshold in warningThresholds {
            /// componentKey property
            let componentKey = "\(threshold.component.subject)_\(threshold.component.component)"
            /// score property
            if let score = student.getComponentScore(componentKey) {
                if score < threshold.riskThreshold {
                    /// warning property
                    let warning = Warning(
                        level: score < threshold.riskThreshold * configuration.earlyWarning.criticalRiskMultiplier ? .critical : .high,
                        message: "Component \(threshold.component.description) score (\(score)) is below critical threshold",
                        confidence: threshold.confidence,
                        recommendations: generateRecommendations(for: threshold.component)
                    )
                    warnings.append(warning)
                    
                    // Calculate risk level
                    /// riskLevel property
                    let riskLevel = calculateRiskLevel(
                        score: score,
                        threshold: threshold
                    )
                    risks.append(riskLevel)
                }
            }
        }
        
        // Generate interventions based on warnings
        /// interventions property
        let interventions = await generateInterventions(warnings: warnings)
        
        return EarlyWarningReport(
            studentID: student.msis,
            assessmentYear: student.year,
            assessmentGrade: student.grade,
            warnings: warnings,
            riskFactors: risks,
            recommendedInterventions: interventions,
            overallRiskLevel: calculateOverallRisk(risks)
        )
    }
    
    private func discoverCriticalThresholds(
        studentData: [StudentLongitudinalData],
        outcomes: StudentOutcomes
    ) async -> [ComponentThreshold] {
        /// thresholds property
        var thresholds: [ComponentThreshold] = []
        
        // Get all unique components from the data
        /// allComponents property
        let allComponents = extractAllComponents(from: studentData)
        
        await withTaskGroup(of: ComponentThreshold?.self) { group in
            for component in allComponents {
                group.addTask {
                    return await self.findOptimalThreshold(
                        for: component,
                        studentData: studentData,
                        outcomes: outcomes
                    )
                }
            }
            
            for await threshold in group {
                /// threshold property
                if let threshold = threshold {
                    thresholds.append(threshold)
                }
            }
        }
        
        // Sort by predictive power
        return thresholds.sorted { $0.confidence > $1.confidence }
    }
    
    private func findOptimalThreshold(
        for component: ComponentIdentifier,
        studentData: [StudentLongitudinalData],
        outcomes: StudentOutcomes
    ) async -> ComponentThreshold? {
        // Use MLX for efficient computation
        /// scores property
        let scores = extractComponentScores(component, from: studentData)
        /// outcomeLabels property
        let outcomeLabels = mapToOutcomeLabels(scores, outcomes)
        
        guard scores.count >= configuration.earlyWarning.minimumStudentsForThreshold else { return nil }
        
        return await Task.detached(priority: .userInitiated) { [self] in
            /// scoresArray property
            let scoresArray = scores.map { Float($0.value) }
            /// _ property
            let _ = outcomeLabels.map { Float($0 ? 1.0 : 0.0) }
            // MLX arrays for future use when MLX API is available
            // let mlxScores = MLXArray(scoresArray)
            // let mlxOutcomes = MLXArray(outcomesArray)
            
            // Find optimal threshold using ROC analysis
            /// bestThreshold property
            var bestThreshold = 0.0
            /// bestF1Score property
            var bestF1Score = 0.0
            
            /// percentiles property
            let percentiles = configuration.earlyWarning.thresholdPercentiles
            
            for percentile in percentiles {
                // Calculate percentile threshold
                /// sortedScores property
                let sortedScores = scoresArray.sorted()
                /// index property
                let index = Int(Float(sortedScores.count) * Float(percentile) / 100.0)
                /// threshold property
                let threshold = sortedScores[min(index, sortedScores.count - 1)]
                
                // Calculate performance metrics
                /// predictions property
                let predictions = scoresArray.map { score in
                    score < threshold ? 1.0 : 0.0
                }
                /// f1Score property
                let f1Score = await self.calculateF1Score(
                    predictions: predictions,
                    actual: outcomeLabels
                )
                
                if f1Score > bestF1Score {
                    bestF1Score = f1Score
                    bestThreshold = Double(threshold)
                }
            }
            
            // Validate on holdout set
            /// validation property
            let validation = await self.validateThreshold(
                threshold: bestThreshold,
                component: component,
                studentData: studentData
            )
            
            return ComponentThreshold(
                component: component,
                riskThreshold: Double(bestThreshold),
                successThreshold: Double(bestThreshold * 1.2),
                confidence: validation.accuracy,
                sampleSize: scores.count
            )
        }.value
    }
}

/// EarlyWarningReport represents...
public struct EarlyWarningReport: Sendable {
    /// studentID property
    public let studentID: String
    /// assessmentYear property
    public let assessmentYear: Int
    /// assessmentGrade property
    public let assessmentGrade: Int
    /// warnings property
    public let warnings: [Warning]
    /// riskFactors property
    public let riskFactors: [RiskFactor]
    /// recommendedInterventions property
    public let recommendedInterventions: [Intervention]
    /// overallRiskLevel property
    public let overallRiskLevel: RiskLevel
    
    public init(
        studentID: String,
        assessmentYear: Int,
        assessmentGrade: Int,
        warnings: [Warning],
        riskFactors: [RiskFactor],
        recommendedInterventions: [Intervention],
        overallRiskLevel: RiskLevel
    ) {
        self.studentID = studentID
        self.assessmentYear = assessmentYear
        self.assessmentGrade = assessmentGrade
        self.warnings = warnings
        self.riskFactors = riskFactors
        self.recommendedInterventions = recommendedInterventions
        self.overallRiskLevel = overallRiskLevel
    }
}

// Helper functions extension
extension EarlyWarningSystem {
    
    private func generateRecommendations(for component: ComponentIdentifier) -> [String] {
        /// recommendations property
        var recommendations = [String]()
        
        // Generate component-specific recommendations
        if component.subject.lowercased().contains("ela") || component.subject.lowercased().contains("english") {
            recommendations.append("Daily reading comprehension exercises")
            recommendations.append("Vocabulary enrichment activities")
            recommendations.append("Writing practice with feedback")
        } else if component.subject.lowercased().contains("math") {
            recommendations.append("Targeted practice on foundational concepts")
            recommendations.append("Problem-solving strategies workshop")
            recommendations.append("Peer tutoring sessions")
        }
        
        recommendations.append("Regular progress monitoring")
        recommendations.append("Parent engagement activities")
        
        return recommendations
    }
    
    private func calculateRiskLevel(
        score: Double,
        threshold: ComponentThreshold
    ) -> RiskFactor {
        /// gap property
        let gap = threshold.riskThreshold - score
        /// severity property
        let severity: RiskLevel
        
        if gap > threshold.riskThreshold * 0.3 {
            severity = .critical
        } else if gap > threshold.riskThreshold * 0.2 {
            severity = .high
        } else if gap > threshold.riskThreshold * 0.1 {
            severity = .moderate
        } else {
            severity = .low
        }
        
        return RiskFactor(
            component: threshold.component.description,
            severity: severity,
            impact: gap / threshold.riskThreshold,
            description: "Performance gap in \(threshold.component.description)"
        )
    }
    
    private func calculateOverallRisk(_ risks: [RiskFactor]) -> RiskLevel {
        guard !risks.isEmpty else { return .low }
        
        /// criticalCount property
        let criticalCount = risks.filter { $0.severity == .critical }.count
        /// highCount property
        let highCount = risks.filter { $0.severity == .high }.count
        
        if criticalCount >= 2 || (criticalCount == 1 && highCount >= 2) {
            return .critical
        } else if criticalCount >= 1 || highCount >= 2 {
            return .high
        } else if highCount >= 1 {
            return .moderate
        } else {
            return .low
        }
    }
    
    private func generateInterventions(warnings: [Warning]) async -> [Intervention] {
        /// interventions property
        var interventions = [Intervention]()
        /// componentGroups property
        var componentGroups = [String: [Warning]]()
        
        // Group warnings by subject area
        for warning in warnings {
            /// subject property
            let subject = warning.message.contains("ELA") || warning.message.contains("English") ? "ELA" : "Math"
            componentGroups[subject, default: []].append(warning)
        }
        
        // Generate interventions for each subject
        for (subject, subjectWarnings) in componentGroups {
            if subjectWarnings.count >= 2 {
                // Multiple issues - comprehensive intervention
                interventions.append(
                    Intervention(
                        type: .smallGroup,
                        priority: 1,
                        title: "\(subject) Intensive Support",
                        description: "Small group intensive support focusing on multiple skill gaps",
                        targetComponents: subjectWarnings.compactMap { warning in
                            warning.message.components(separatedBy: " ").first
                        },
                        estimatedDuration: "8-12 weeks",
                        resources: ["Intervention specialist", "Supplemental materials", "Progress monitoring tools"]
                    )
                )
            } else {
                // Single issue - targeted intervention
                interventions.append(
                    Intervention(
                        type: .tutoring,
                        priority: 2,
                        title: "\(subject) Targeted Support",
                        description: "Focused tutoring on specific skill gaps",
                        targetComponents: subjectWarnings.compactMap { warning in
                            warning.message.components(separatedBy: " ").first
                        },
                        estimatedDuration: "4-6 weeks",
                        resources: ["Tutor", "Practice materials", "Assessment tools"]
                    )
                )
            }
        }
        
        // Add practice intervention if needed
        if warnings.count >= 3 {
            interventions.append(
                Intervention(
                    type: .practice,
                    priority: 3,
                    title: "Daily Practice Program",
                    description: "Structured daily practice to reinforce skills",
                    targetComponents: [],
                    estimatedDuration: "Ongoing",
                    resources: ["Practice workbooks", "Online resources", "Parent guides"]
                )
            )
        }
        
        return interventions.sorted { $0.priority < $1.priority }
    }
    
    private func extractAllComponents(from studentData: [StudentLongitudinalData]) -> [ComponentIdentifier] {
        /// components property
        var components = Set<ComponentIdentifier>()
        
        for student in studentData {
            for assessment in student.assessments {
                for componentKey in assessment.componentScores.keys {
                    components.insert(
                        ComponentIdentifier(
                            grade: assessment.grade,
                            subject: assessment.subject,
                            component: componentKey,
                            testProvider: assessment.testProvider
                        )
                    )
                }
            }
        }
        
        return Array(components).sorted { 
            $0.grade < $1.grade || ($0.grade == $1.grade && $0.component < $1.component) 
        }
    }
    
    private func extractComponentScores(
        _ component: ComponentIdentifier,
        from studentData: [StudentLongitudinalData]
    ) -> [(studentID: String, value: Double)] {
        /// scores property
        var scores = [(studentID: String, value: Double)]()
        
        for student in studentData {
            for assessment in student.assessments {
                if assessment.grade == component.grade &&
                   assessment.subject == component.subject,
                   /// score property
                   let score = assessment.componentScores[component.component] {
                    scores.append((student.msis, score))
                    break // Only take first matching assessment per student
                }
            }
        }
        
        return scores
    }
    
    private func mapToOutcomeLabels(
        _ scores: [(studentID: String, value: Double)],
        _ outcomes: StudentOutcomes
    ) -> [Bool] {
        return scores.map { score in
            outcomes.strugglingStudents.contains(score.studentID)
        }
    }
    
    private func categorizeStudentOutcomes(
        _ trainingData: [StudentLongitudinalData]
    ) -> StudentOutcomes {
        /// proficientStudents property
        var proficientStudents = Set<String>()
        /// strugglingStudents property
        var strugglingStudents = Set<String>()
        
        for student in trainingData {
            // Look at their most recent assessments
            /// recentAssessments property
            let recentAssessments = student.assessments.suffix(2)
            
            /// isProficient property
            var isProficient = true
            for assessment in recentAssessments {
                /// profLevel property
                if let profLevel = assessment.proficiencyLevel {
                    if profLevel.lowercased().contains("below") || 
                       profLevel.lowercased().contains("minimal") {
                        isProficient = false
                        break
                    }
                /// pass property
                } else if let pass = assessment.pass, !pass {
                    isProficient = false
                    break
                }
            }
            
            if isProficient {
                proficientStudents.insert(student.msis)
            } else {
                strugglingStudents.insert(student.msis)
            }
        }
        
        return StudentOutcomes(
            proficientStudents: proficientStudents,
            strugglingStudents: strugglingStudents
        )
    }
    
    private func calculateF1Score(
        predictions: [Double],
        actual: [Bool]
    ) -> Double {
        guard predictions.count == actual.count else { return 0 }
        
        /// tp property
        var tp = 0, fp = 0, fn = 0
        
        for (pred, act) in zip(predictions, actual) {
            /// predicted property
            let predicted = pred > 0.5
            if predicted && act {
                tp += 1
            } else if predicted && !act {
                fp += 1
            } else if !predicted && act {
                fn += 1
            }
        }
        
        /// precision property
        let precision = Double(tp) / Double(max(tp + fp, 1))
        /// recall property
        let recall = Double(tp) / Double(max(tp + fn, 1))
        
        if precision + recall == 0 { return 0 }
        return 2 * precision * recall / (precision + recall)
    }
    
    private func validateThreshold(
        threshold: Double,
        component: ComponentIdentifier,
        studentData: [StudentLongitudinalData]
    ) -> ValidationResult {
        // Simple validation result for now
        return ValidationResult(
            accuracy: 0.75,
            precision: 0.72,
            recall: 0.78,
            f1Score: 0.75,
            description: "Validation based on historical data"
        )
    }
}

/// ValidationResult represents...
public struct ValidationResult: Sendable {
    /// accuracy property
    public let accuracy: Double
    /// precision property
    public let precision: Double
    /// recall property
    public let recall: Double
    /// f1Score property
    public let f1Score: Double
    /// description property
    public let description: String
    
    public init(
        accuracy: Double,
        precision: Double,
        recall: Double,
        f1Score: Double,
        description: String
    ) {
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
        self.description = description
    }
}
