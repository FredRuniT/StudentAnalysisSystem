import SwiftUI
import AnalysisCore
import PredictiveModeling
import Charts

@MainActor
struct ContentView: View {
    @State private var analysisEngine = AnalysisEngine()
    @State private var isProcessing = false
    @State private var selectedFiles: [URL] = []
    @State private var validationResults: ValidationResults?
    @State private var correlationMatrix: CorrelationMatrix?
    
    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            HSplitView {
                VStack {
                    FileSelectionView(selectedFiles: $selectedFiles)
                    
                    if !selectedFiles.isEmpty {
                        Button("Run Analysis") {
                            Task {
                                await runAnalysis()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                    }
                    
                    if isProcessing {
                        ProgressView("Processing...")
                            .padding()
                    }
                    
                    if let results = validationResults {
                        ValidationResultsView(results: results)
                    }
                }
                
                if let matrix = correlationMatrix {
                    CorrelationMatrixView(matrix: matrix)
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
    
    private func runAnalysis() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Load data
            let studentData = try await analysisEngine.loadData(from: selectedFiles)
            
            // Run correlation analysis
            correlationMatrix = try await analysisEngine.buildCorrelationMatrix(
                studentData: studentData
            )
            
            // Validate model
            validationResults = try await analysisEngine.validateModel(
                studentData: studentData
            )
        } catch {
            // Handle error
            print("Analysis error: \(error)")
        }
    }
}


public extension AnalysisEngine {
    
    func generateComprehensiveEducationPlans(
        studentData: [StudentAssessmentData],
        correlationModel: ValidatedCorrelationModel
    ) async throws -> EducationPlans {
        
        // Identify struggling students
        let warningSystem = EarlyWarningSystem(correlationAnalyzer: correlationAnalyzer)
        let strugglingStudents = await identifyStrugglingStudents(studentData)
        
        // Identify acceleration candidates
        let accelerationAnalyzer = AccelerationAnalyzer(
            correlationEngine: correlationAnalyzer,
            standardsRepository: standardsRepository
        )
        let accelerationCandidates = await accelerationAnalyzer.identifyAccelerationCandidates(
            studentData: studentData,
            correlationModel: correlationModel
        )
        
        // Generate plans for both groups
        var interventionPlans: [IndividualLearningPlan] = []
        var enrichmentPlans: [EnrichmentPlan] = []
        
        // Intervention plans for struggling students
        await withTaskGroup(of: IndividualLearningPlan?.self) { group in
            for student in strugglingStudents {
                group.addTask {
                    return await self.ilpGenerator.generateILP(
                        student: student,
                        correlationModel: correlationModel
                    )
                }
            }
            
            for await plan in group {
                if let plan = plan {
                    interventionPlans.append(plan)
                }
            }
        }
        
        // Enrichment plans for high achievers
        let enrichmentGenerator = EnrichmentPlanGenerator(
            standardsRepository: standardsRepository,
            correlationModel: correlationModel
        )
        
        await withTaskGroup(of: [EnrichmentPlan].self) { group in
            for candidate in accelerationCandidates {
                group.addTask {
                    var plans: [EnrichmentPlan] = []
                    for pathway in candidate.pathways {
                        let plan = await enrichmentGenerator.generateEnrichmentPlan(
                            for: candidate,
                            pathway: pathway
                        )
                        plans.append(plan)
                    }
                    return plans
                }
            }
            
            for await plans in group {
                enrichmentPlans.append(contentsOf: plans)
            }
        }
        
        return EducationPlans(
            interventionPlans: interventionPlans,
            enrichmentPlans: enrichmentPlans,
            totalStudentsAnalyzed: studentData.count,
            strugglingCount: strugglingStudents.count,
            accelerationCount: accelerationCandidates.count,
            onGradeLevelCount: studentData.count - strugglingStudents.count - accelerationCandidates.count
        )
    }
}
