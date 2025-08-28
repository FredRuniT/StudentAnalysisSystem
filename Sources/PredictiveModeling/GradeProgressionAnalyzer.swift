import AnalysisCore
import Foundation

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
        /// currentPerformance property
        let currentPerformance = analyzeCurrentPerformance(student: student, grade: currentGrade)
        
        // Identify weak areas using correlations
        /// weakAreas property
        let weakAreas = identifyWeakAreas(performance: currentPerformance)
        
        // Get correlated future impacts
        /// futureImpacts property
        let futureImpacts = analyzeFutureImpacts(weakAreas: weakAreas, 
                                                 currentGrade: currentGrade,
                                                 targetGrade: targetGrade)
        
        // Generate learning focuses based on blueprints
        /// learningFocuses property
        let learningFocuses = generateLearningFocuses(
            weakAreas: weakAreas,
            futureImpacts: futureImpacts,
            currentGrade: currentGrade,
            targetGrade: targetGrade
        )
        
        // Create prioritized action plan
        /// actionPlan property
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
        /// componentScores property
        var componentScores: [ComponentScore] = []
        
        // Get most recent assessment for the grade
        /// assessment property
        guard let assessment = student.assessments
            .filter({ $0.grade == grade })
            .sorted(by: { $0.year > $1.year })
            .first else {
            return PerformanceAnalysis(componentScores: [], overallLevel: .minimal)
        }
        
        // Analyze each component
        for (componentCode, rawScore) in assessment.componentScores {
            /// percentile property
            let percentile = calculatePercentile(score: rawScore)
            /// score property
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
        /// avgPercentile property
        let avgPercentile = componentScores.map { $0.percentile }.reduce(0, +) / Double(componentScores.count)
        /// overallLevel property
        let overallLevel = MississippiProficiencyLevels.getProficiencyLevelFromPercentage(avgPercentile).level
        
        return PerformanceAnalysis(
            componentScores: componentScores,
            overallLevel: overallLevel
        )
    }
    
    /// Identify weak areas that need attention
    private func identifyWeakAreas(performance: PerformanceAnalysis) -> [WeakArea] {
        /// weakAreas property
        var weakAreas: [WeakArea] = []
        
        for score in performance.componentScores {
            if score.performanceLevel == .minimal || score.performanceLevel == .basic {
                /// standards property
                let standards = getRelatedStandards(
                    component: score.component,
                    category: score.reportingCategory
                )
                
                /// weakArea property
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
        /// impacts property
        var impacts: [FutureImpact] = []
        
        for weakArea in weakAreas {
            // Get correlations for this component
            /// componentKey property
            let componentKey = "Grade_\(currentGrade)_\(weakArea.subject)_\(weakArea.component)"
            
            // Get correlations from pre-computed maps
            /// correlations property
            let correlations = correlationEngine.getCorrelationsForComponent(
                componentKey: componentKey,
                correlationMaps: correlationMaps,
                threshold: 0.3
            )
            
            if !correlations.isEmpty {
                for correlation in correlations {
                    // Check if correlation is for target grade or intermediate grades
                    /// targetComponent property
                    if let targetComponent = parseComponentKey(correlation.targetComponent) {
                        if targetComponent.grade >= currentGrade && targetComponent.grade <= targetGrade {
                            /// impact property
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
        /// focuses property
        var focuses: [LearningFocus] = []
        
        for weakArea in weakAreas {
            // Get standards for this weak area
            /// standards property
            let standards = blueprintManager.getStandards(
                grade: currentGrade,
                subject: weakArea.subject.lowercased()
            )
            
            // Find relevant standards based on reporting category
            /// relevantStandards property
            let relevantStandards = standards.filter { 
                $0.reportingCategory == weakArea.reportingCategory 
            }
            
            for standard in relevantStandards {
                // Determine focus area based on performance level
                /// focusArea property
                let focusArea = determineFocusArea(
                    performanceLevel: weakArea.performanceLevel,
                    standard: standard
                )
                
                // Get specific skills from standard
                /// skills property
                let skills = extractSkills(from: standard, focusArea: focusArea)
                
                // Generate activities based on standard and performance
                /// activities property
                let activities = generateActivities(
                    standard: standard,
                    performanceLevel: weakArea.performanceLevel,
                    focusArea: focusArea
                )
                
                // Estimate time based on severity and correlation impact
                /// timeWeeks property
                let timeWeeks = estimateTimeNeeded(
                    severity: weakArea.severity,
                    impactCount: futureImpacts.filter { $0.sourceComponent == weakArea.component }.count
                )
                
                /// focus property
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
        /// phases property
        var phases: [ActionPhase] = []
        
        // Group focuses by priority and time
        /// immediate property
        let immediate = learningFocuses.filter { $0.estimatedTimeWeeks <= 4 }
        /// shortTerm property
        let shortTerm = learningFocuses.filter { $0.estimatedTimeWeeks > 4 && $0.estimatedTimeWeeks <= 12 }
        /// longTerm property
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
        /// parts property
        let parts = key.split(separator: "_")
        guard parts.count >= 4,
              parts[0] == "Grade",
              /// grade property
              let grade = Int(parts[1]),
              parts[0] == "Grade" else {
            return nil
        }
        /// subject property
        let subject = String(parts[2])
        /// component property
        let component = parts[3...].joined(separator: "_")
        return (grade, subject, String(component))
    }
    
    private func generateImpactDescription(source: WeakArea, 
                                          target: (grade: Int, subject: String, component: String),
                                          correlation: Double) -> String {
        /// strength property
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
        /// activities property
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
        /// weeks property
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
        /// goals property
        var goals: [String] = []
        
        // Group by focus area
        /// byArea property
        let byArea = Dictionary(grouping: focuses, by: { $0.focusArea })
        
        for (area, areaFocuses) in byArea {
            /// standardIds property
            let standardIds = areaFocuses.map { $0.standardId }.joined(separator: ", ")
            goals.append("Develop \(area.rawValue) in standards: \(standardIds)")
        }
        
        return goals
    }
}

// MARK: - Supporting Types

/// StudentProgressionPlan represents...
public struct StudentProgressionPlan {
    /// studentId property
    public let studentId: String
    /// currentGrade property
    public let currentGrade: Int
    /// targetGrade property
    public let targetGrade: Int
    /// currentPerformance property
    public let currentPerformance: PerformanceAnalysis
    /// weakAreas property
    public let weakAreas: [WeakArea]
    /// futureImpacts property
    public let futureImpacts: [FutureImpact]
    /// learningFocuses property
    public let learningFocuses: [LearningFocus]
    /// actionPlan property
    public let actionPlan: ActionPlan
    /// generatedDate property
    public let generatedDate: Date
}

/// PerformanceAnalysis represents...
public struct PerformanceAnalysis {
    /// componentScores property
    public let componentScores: [ComponentScore]
    /// overallLevel property
    public let overallLevel: PerformanceLevel
}

/// ComponentScore represents...
public struct ComponentScore {
    /// component property
    public let component: String
    /// subject property
    public let subject: String
    /// rawScore property
    public let rawScore: Double
    /// percentile property
    public let percentile: Double
    /// performanceLevel property
    public let performanceLevel: PerformanceLevel
    /// reportingCategory property
    public let reportingCategory: String
}

/// WeakArea represents...
public struct WeakArea {
    /// component property
    public let component: String
    /// subject property
    public let subject: String
    /// performanceLevel property
    public let performanceLevel: PerformanceLevel
    /// reportingCategory property
    public let reportingCategory: String
    /// relatedStandards property
    public let relatedStandards: [String]
    /// severity property
    public let severity: Double
}

/// FutureImpact represents...
public struct FutureImpact {
    /// sourceComponent property
    public let sourceComponent: String
    /// targetComponent property
    public let targetComponent: String
    /// targetGrade property
    public let targetGrade: Int
    /// correlationStrength property
    public let correlationStrength: Double
    /// confidence property
    public let confidence: Double
    /// impactDescription property
    public let impactDescription: String
}

/// ActionPlan represents...
public struct ActionPlan {
    /// phases property
    public let phases: [ActionPhase]
    /// totalEstimatedWeeks property
    public let totalEstimatedWeeks: Int
    /// priorityStandards property
    public let priorityStandards: [String]
}

/// ActionPhase represents...
public struct ActionPhase {
    /// name property
    public let name: String
    /// timeframe property
    public let timeframe: String
    /// focuses property
    public let focuses: [LearningFocus]
    /// goals property
    public let goals: [String]
}