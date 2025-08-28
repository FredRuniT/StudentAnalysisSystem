import Foundation
import AnalysisCore

/// Analyzes student performance and generates grade progression recommendations
public class GradeProgressionAnalyzer {
    
    // MARK: - Properties
    private let blueprintManager: BlueprintManager
    private let correlationEngine: ComponentCorrelationEngine
    private var correlationMaps: [ComponentCorrelationEngine.ComponentCorrelationMap] = []
    
    // MARK: - Initialization
    public init(blueprintManager: BlueprintManager = BlueprintManager.shared,
                correlationEngine: ComponentCorrelationEngine) {
        self.blueprintManager = blueprintManager
        self.correlationEngine = correlationEngine
    }
    
    /// Set pre-computed correlation maps for use in analysis
    public func setCorrelationMaps(_ maps: [ComponentCorrelationEngine.ComponentCorrelationMap]) {
        self.correlationMaps = maps
    }
    
    // MARK: - Main Analysis
    
    /// Generate comprehensive grade progression plan for a student
    public func generateProgressionPlan(
        student: StudentLongitudinalData,
        currentGrade: Int,
        targetGrade: Int
    ) -> StudentProgressionPlan {
        
        // Analyze current performance
        let currentPerformance = analyzeCurrentPerformance(student: student, grade: currentGrade)
        
        // Identify weak areas using correlations
        let weakAreas = identifyWeakAreas(performance: currentPerformance)
        
        // Get correlated future impacts
        let futureImpacts = analyzeFutureImpacts(weakAreas: weakAreas, 
                                                 currentGrade: currentGrade,
                                                 targetGrade: targetGrade)
        
        // Generate learning focuses based on blueprints
        let learningFocuses = generateLearningFocuses(
            weakAreas: weakAreas,
            futureImpacts: futureImpacts,
            currentGrade: currentGrade,
            targetGrade: targetGrade
        )
        
        // Create prioritized action plan
        let actionPlan = createActionPlan(learningFocuses: learningFocuses)
        
        return StudentProgressionPlan(
            studentId: student.msis,
            currentGrade: currentGrade,
            targetGrade: targetGrade,
            currentPerformance: currentPerformance,
            weakAreas: weakAreas,
            futureImpacts: futureImpacts,
            learningFocuses: learningFocuses,
            actionPlan: actionPlan,
            generatedDate: Date()
        )
    }
    
    // MARK: - Performance Analysis
    
    /// Analyze student's current performance
    private func analyzeCurrentPerformance(student: StudentLongitudinalData, grade: Int) -> PerformanceAnalysis {
        var componentScores: [ComponentScore] = []
        
        // Get most recent assessment for the grade
        guard let assessment = student.assessments
            .filter({ $0.grade == grade })
            .sorted(by: { $0.year > $1.year })
            .first else {
            return PerformanceAnalysis(componentScores: [], overallLevel: .minimal)
        }
        
        // Analyze each component
        for (componentCode, rawScore) in assessment.componentScores {
            let percentile = calculatePercentile(score: rawScore)
            let score = ComponentScore(
                component: componentCode,
                subject: assessment.subject,
                rawScore: rawScore,
                percentile: percentile,
                performanceLevel: MississippiProficiencyLevels.getProficiencyLevelFromPercentage(percentile).level,
                reportingCategory: getReportingCategory(component: componentCode, 
                                                       grade: grade, 
                                                       subject: assessment.subject)
            )
            componentScores.append(score)
        }
        
        // Calculate overall performance level
        let avgPercentile = componentScores.map { $0.percentile }.reduce(0, +) / Double(componentScores.count)
        let overallLevel = MississippiProficiencyLevels.getProficiencyLevelFromPercentage(avgPercentile).level
        
        return PerformanceAnalysis(
            componentScores: componentScores,
            overallLevel: overallLevel
        )
    }
    
    /// Identify weak areas that need attention
    private func identifyWeakAreas(performance: PerformanceAnalysis) -> [WeakArea] {
        var weakAreas: [WeakArea] = []
        
        for score in performance.componentScores {
            if score.performanceLevel == .minimal || score.performanceLevel == .basic {
                let standards = getRelatedStandards(
                    component: score.component,
                    category: score.reportingCategory
                )
                
                let weakArea = WeakArea(
                    component: score.component,
                    subject: score.subject,
                    performanceLevel: score.performanceLevel,
                    reportingCategory: score.reportingCategory,
                    relatedStandards: standards,
                    severity: calculateSeverity(performanceLevel: score.performanceLevel)
                )
                weakAreas.append(weakArea)
            }
        }
        
        // Sort by severity
        return weakAreas.sorted { $0.severity > $1.severity }
    }
    
    // MARK: - Correlation Analysis
    
    /// Analyze future impacts using correlation data
    private func analyzeFutureImpacts(weakAreas: [WeakArea], 
                                     currentGrade: Int,
                                     targetGrade: Int) -> [FutureImpact] {
        var impacts: [FutureImpact] = []
        
        for weakArea in weakAreas {
            // Get correlations for this component
            let componentKey = "Grade_\(currentGrade)_\(weakArea.subject)_\(weakArea.component)"
            
            // Get correlations from pre-computed maps
            let correlations = correlationEngine.getCorrelationsForComponent(
                componentKey: componentKey,
                correlationMaps: correlationMaps,
                threshold: 0.3
            )
            
            if !correlations.isEmpty {
                for correlation in correlations {
                    // Check if correlation is for target grade or intermediate grades
                    if let targetComponent = parseComponentKey(correlation.targetComponent) {
                        if targetComponent.grade >= currentGrade && targetComponent.grade <= targetGrade {
                            let impact = FutureImpact(
                                sourceComponent: weakArea.component,
                                targetComponent: targetComponent.component,
                                targetGrade: targetComponent.grade,
                                correlationStrength: correlation.correlation,
                                confidence: correlation.confidence,
                                impactDescription: generateImpactDescription(
                                    source: weakArea,
                                    target: targetComponent,
                                    correlation: correlation.correlation
                                )
                            )
                            impacts.append(impact)
                        }
                    }
                }
            }
        }
        
        // Sort by correlation strength and grade
        return impacts.sorted { 
            if $0.targetGrade == $1.targetGrade {
                return $0.correlationStrength > $1.correlationStrength
            }
            return $0.targetGrade < $1.targetGrade
        }
    }
    
    // MARK: - Learning Focus Generation
    
    /// Generate specific learning focuses based on weak areas and future impacts
    private func generateLearningFocuses(weakAreas: [WeakArea],
                                        futureImpacts: [FutureImpact],
                                        currentGrade: Int,
                                        targetGrade: Int) -> [LearningFocus] {
        var focuses: [LearningFocus] = []
        
        for weakArea in weakAreas {
            // Get standards for this weak area
            let standards = blueprintManager.getStandards(
                grade: currentGrade,
                subject: weakArea.subject.lowercased()
            )
            
            // Find relevant standards based on reporting category
            let relevantStandards = standards.filter { 
                $0.reportingCategory == weakArea.reportingCategory 
            }
            
            for standard in relevantStandards {
                // Determine focus area based on performance level
                let focusArea = determineFocusArea(
                    performanceLevel: weakArea.performanceLevel,
                    standard: standard
                )
                
                // Get specific skills from standard
                let skills = extractSkills(from: standard, focusArea: focusArea)
                
                // Generate activities based on standard and performance
                let activities = generateActivities(
                    standard: standard,
                    performanceLevel: weakArea.performanceLevel,
                    focusArea: focusArea
                )
                
                // Estimate time based on severity and correlation impact
                let timeWeeks = estimateTimeNeeded(
                    severity: weakArea.severity,
                    impactCount: futureImpacts.filter { $0.sourceComponent == weakArea.component }.count
                )
                
                let focus = LearningFocus(
                    standardId: standard.standard.id,
                    focusArea: focusArea,
                    specificSkills: skills,
                    suggestedActivities: activities,
                    estimatedTimeWeeks: timeWeeks
                )
                
                focuses.append(focus)
            }
        }
        
        return focuses
    }
    
    // MARK: - Action Plan Creation
    
    /// Create prioritized action plan
    private func createActionPlan(learningFocuses: [LearningFocus]) -> ActionPlan {
        var phases: [ActionPhase] = []
        
        // Group focuses by priority and time
        let immediate = learningFocuses.filter { $0.estimatedTimeWeeks <= 4 }
        let shortTerm = learningFocuses.filter { $0.estimatedTimeWeeks > 4 && $0.estimatedTimeWeeks <= 12 }
        let longTerm = learningFocuses.filter { $0.estimatedTimeWeeks > 12 }
        
        // Create immediate phase (0-4 weeks)
        if !immediate.isEmpty {
            phases.append(ActionPhase(
                name: "Immediate Intervention",
                timeframe: "0-4 weeks",
                focuses: immediate,
                goals: generatePhaseGoals(focuses: immediate)
            ))
        }
        
        // Create short-term phase (1-3 months)
        if !shortTerm.isEmpty {
            phases.append(ActionPhase(
                name: "Short-term Development",
                timeframe: "1-3 months",
                focuses: shortTerm,
                goals: generatePhaseGoals(focuses: shortTerm)
            ))
        }
        
        // Create long-term phase (3+ months)
        if !longTerm.isEmpty {
            phases.append(ActionPhase(
                name: "Long-term Mastery",
                timeframe: "3+ months",
                focuses: longTerm,
                goals: generatePhaseGoals(focuses: longTerm)
            ))
        }
        
        return ActionPlan(
            phases: phases,
            totalEstimatedWeeks: learningFocuses.map { $0.estimatedTimeWeeks }.reduce(0, +),
            priorityStandards: Array(Set(learningFocuses.map { $0.standardId })).sorted()
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculatePercentile(score: Double) -> Double {
        // Simplified percentile calculation
        // In production, this would use actual score distributions
        return min(100, max(0, (score - 200) / 3))
    }
    
    private func getReportingCategory(component: String, grade: Int, subject: String) -> String {
        blueprintManager.getReportingCategory(for: component, grade: grade, subject: subject)?.name ?? "Unknown"
    }
    
    private func getRelatedStandards(component: String, category: String) -> [String] {
        // Extract standards from category
        // This would map component codes to specific standards
        []
    }
    
    private func calculateSeverity(performanceLevel: PerformanceLevel) -> Double {
        switch performanceLevel {
        case .minimal: return 1.0
        case .basic: return 0.75
        case .passing: return 0.5
        case .proficient: return 0.25
        case .advanced: return 0.0
        }
    }
    
    private func parseComponentKey(_ key: String) -> (grade: Int, subject: String, component: String)? {
        let parts = key.split(separator: "_")
        guard parts.count >= 4,
              parts[0] == "Grade",
              let grade = Int(parts[1]),
              parts[0] == "Grade" else {
            return nil
        }
        let subject = String(parts[2])
        let component = parts[3...].joined(separator: "_")
        return (grade, subject, String(component))
    }
    
    private func generateImpactDescription(source: WeakArea, 
                                          target: (grade: Int, subject: String, component: String),
                                          correlation: Double) -> String {
        let strength = correlation > 0.7 ? "strongly" : correlation > 0.5 ? "moderately" : "weakly"
        return "Performance in \(source.component) \(strength) impacts \(target.component) in Grade \(target.grade)"
    }
    
    private func determineFocusArea(performanceLevel: PerformanceLevel, standard: LearningStandard) -> FocusArea {
        switch performanceLevel {
        case .minimal:
            return .knowledge  // Start with foundational knowledge
        case .basic:
            return .understanding  // Build conceptual understanding
        case .passing:
            return .skills  // Develop application skills
        case .proficient:
            return .practice  // Additional practice for mastery
        case .advanced:
            return .enrichment  // Enrichment activities
        }
    }
    
    private func extractSkills(from standard: LearningStandard, focusArea: FocusArea) -> [String] {
        switch focusArea {
        case .knowledge:
            return standard.studentPerformance.categories.knowledge.items
        case .understanding:
            return standard.studentPerformance.categories.understanding.items
        case .skills, .practice:
            return standard.studentPerformance.categories.skills.items
        case .enrichment:
            // Combine all for enrichment
            return standard.studentPerformance.categories.skills.items
        }
    }
    
    private func generateActivities(standard: LearningStandard, 
                                   performanceLevel: PerformanceLevel,
                                   focusArea: FocusArea) -> [String] {
        var activities: [String] = []
        
        switch focusArea {
        case .knowledge:
            activities = [
                "Review foundational concepts using manipulatives",
                "Complete guided practice problems with step-by-step support",
                "Watch instructional videos on \(standard.standard.id)",
                "Use flashcards for key vocabulary: \(standard.relatedKeywords.terms.prefix(3).joined(separator: ", "))"
            ]
        case .understanding:
            activities = [
                "Explain concepts in your own words",
                "Create visual representations and diagrams",
                "Complete concept mapping exercises",
                "Participate in small group discussions"
            ]
        case .skills:
            activities = [
                "Complete practice problems independently",
                "Apply concepts to real-world scenarios",
                "Solve multi-step problems",
                "Complete timed practice assessments"
            ]
        case .practice:
            activities = [
                "Complete challenge problems",
                "Teach concepts to a peer",
                "Create practice problems for others",
                "Complete cumulative reviews"
            ]
        case .enrichment:
            activities = [
                "Explore advanced applications",
                "Complete project-based learning tasks",
                "Research related topics independently",
                "Participate in academic competitions"
            ]
        }
        
        return activities
    }
    
    private func estimateTimeNeeded(severity: Double, impactCount: Int) -> Int {
        // Base time on severity
        var weeks = Int(severity * 8)  // 0-8 weeks based on severity
        
        // Add time for high-impact areas
        if impactCount > 5 {
            weeks += 4
        } else if impactCount > 2 {
            weeks += 2
        }
        
        return max(2, weeks)  // Minimum 2 weeks
    }
    
    private func generatePhaseGoals(focuses: [LearningFocus]) -> [String] {
        var goals: [String] = []
        
        // Group by focus area
        let byArea = Dictionary(grouping: focuses, by: { $0.focusArea })
        
        for (area, areaFocuses) in byArea {
            let standardIds = areaFocuses.map { $0.standardId }.joined(separator: ", ")
            goals.append("Develop \(area.rawValue) in standards: \(standardIds)")
        }
        
        return goals
    }
}

// MARK: - Supporting Types

public struct StudentProgressionPlan {
    public let studentId: String
    public let currentGrade: Int
    public let targetGrade: Int
    public let currentPerformance: PerformanceAnalysis
    public let weakAreas: [WeakArea]
    public let futureImpacts: [FutureImpact]
    public let learningFocuses: [LearningFocus]
    public let actionPlan: ActionPlan
    public let generatedDate: Date
}

public struct PerformanceAnalysis {
    public let componentScores: [ComponentScore]
    public let overallLevel: PerformanceLevel
}

public struct ComponentScore {
    public let component: String
    public let subject: String
    public let rawScore: Double
    public let percentile: Double
    public let performanceLevel: PerformanceLevel
    public let reportingCategory: String
}

public struct WeakArea {
    public let component: String
    public let subject: String
    public let performanceLevel: PerformanceLevel
    public let reportingCategory: String
    public let relatedStandards: [String]
    public let severity: Double
}

public struct FutureImpact {
    public let sourceComponent: String
    public let targetComponent: String
    public let targetGrade: Int
    public let correlationStrength: Double
    public let confidence: Double
    public let impactDescription: String
}

public struct ActionPlan {
    public let phases: [ActionPhase]
    public let totalEstimatedWeeks: Int
    public let priorityStandards: [String]
}

public struct ActionPhase {
    public let name: String
    public let timeframe: String
    public let focuses: [LearningFocus]
    public let goals: [String]
}