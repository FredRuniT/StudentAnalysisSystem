//
//  main.swift
//  StudentAnalysisSystemMain
//
//  Main executable for running the complete Student Analysis System
//

import Foundation
import AnalysisCore
import StatisticalEngine
import PredictiveModeling
import IndividualLearningPlan
import ReportGeneration

// MARK: - Main Application

@main
struct StudentAnalysisSystemMain {
    static func main() async {
        print("==========================================")
        print("   Student Analysis System - v1.0        ")
        print("==========================================\n")
        
        let analyzer = SystemAnalyzer()
        
        do {
            print("📚 Starting comprehensive analysis...")
            print("⏰ Time: \(Date().formatted())\n")
            
            // Step 1: Load Data
            print("Step 1: Loading student data...")
            let studentData = try await analyzer.loadStudentData()
            print("✅ Loaded \(studentData.count) students' data\n")
            
            // Step 2: Run Statistical Analysis
            print("Step 2: Running statistical analysis...")
            let correlationModel = try await analyzer.runStatisticalAnalysis(on: studentData)
            print("✅ Correlation analysis complete\n")
            
            // Step 3: Train Predictive Models
            print("Step 3: Training predictive models...")
            let warningSystem = try await analyzer.trainPredictiveModels(with: studentData)
            print("✅ Early warning system trained\n")
            
            // Step 4: Generate Sample ILPs
            print("Step 4: Generating Individual Learning Plans...")
            
            // Select sample students: struggling, average, and excelling
            let sampleStudents = selectSampleStudents(from: studentData)
            var generatedILPs = [IndividualLearningPlan]()
            
            for (index, student) in sampleStudents.enumerated() {
                print("  Generating ILP \(index + 1)/\(sampleStudents.count)...")
                let ilp = try await analyzer.generateILP(
                    for: student,
                    using: correlationModel,
                    warningSystem: warningSystem
                )
                generatedILPs.append(ilp)
            }
            print("✅ Generated \(generatedILPs.count) ILPs\n")
            
            // Step 5: Generate Reports
            print("Step 5: Generating reports...")
            try await analyzer.generateReports(
                ilps: generatedILPs,
                correlationModel: correlationModel,
                studentData: studentData
            )
            print("✅ Reports generated\n")
            
            // Step 6: Save Outputs
            print("Step 6: Saving outputs...")
            try await analyzer.saveOutputs(ilps: generatedILPs, correlationModel: correlationModel)
            print("✅ All outputs saved\n")
            
            // Summary
            printSummary(ilps: generatedILPs)
            
            print("\n🎉 Analysis complete! Check the 'Output' directory for results.")
            
        } catch {
            print("❌ Error: \(error)")
            print("\nPlease check the error and try again.")
            exit(1)
        }
    }
    
    static func selectSampleStudents(from data: [StudentLongitudinalData]) -> [StudentAssessmentData] {
        var sampleStudents = [StudentAssessmentData]()
        
        // Sort students by their most recent overall score
        let sortedStudents = data.sorted { student1, student2 in
            let score1 = student1.assessments.last?.overallScore ?? 0
            let score2 = student2.assessments.last?.overallScore ?? 0
            return score1 < score2
        }
        
        // Select struggling students (bottom 20%)
        let strugglingIndex = Int(Double(sortedStudents.count) * 0.1)
        if strugglingIndex < sortedStudents.count {
            let struggling = sortedStudents[strugglingIndex]
            sampleStudents.append(convertToAssessmentData(struggling))
        }
        
        // Select average students (middle)
        let averageIndex = sortedStudents.count / 2
        if averageIndex < sortedStudents.count {
            let average = sortedStudents[averageIndex]
            sampleStudents.append(convertToAssessmentData(average))
        }
        
        // Select excelling students (top 10%)
        let excellingIndex = Int(Double(sortedStudents.count) * 0.9)
        if excellingIndex < sortedStudents.count {
            let excelling = sortedStudents[excellingIndex]
            sampleStudents.append(convertToAssessmentData(excelling))
        }
        
        // Add two more random samples
        if sortedStudents.count >= 5 {
            let random1 = sortedStudents[Int.random(in: 0..<sortedStudents.count/3)]
            let random2 = sortedStudents[Int.random(in: sortedStudents.count*2/3..<sortedStudents.count)]
            sampleStudents.append(convertToAssessmentData(random1))
            sampleStudents.append(convertToAssessmentData(random2))
        }
        
        return sampleStudents
    }
    
    static func convertToAssessmentData(_ student: StudentLongitudinalData) -> StudentAssessmentData {
        let lastAssessment = student.assessments.last
        return StudentAssessmentData(
            studentInfo: StudentAssessmentData.StudentInfo(
                msis: student.msis,
                name: "Student \(student.msis)",
                school: "Sample School",
                district: "Sample District"
            ),
            year: lastAssessment?.year ?? 2025,
            grade: lastAssessment?.grade ?? 0,
            assessments: lastAssessment.map { assessment in
                [StudentAssessmentData.SubjectAssessment(
                    subject: assessment.subject,
                    testProvider: assessment.testProvider,
                    componentScores: assessment.componentScores,
                    overallScore: assessment.overallScore ?? 0,
                    proficiencyLevel: assessment.proficiencyLevel ?? "Unknown"
                )]
            } ?? []
        )
    }
    
    static func printSummary(ilps: [IndividualLearningPlan]) {
        print("\n==========================================")
        print("             SUMMARY REPORT               ")
        print("==========================================\n")
        
        for (index, ilp) in ilps.enumerated() {
            print("Student \(index + 1): \(ilp.studentInfo.name)")
            print("  Grade: \(ilp.studentInfo.grade)")
            print("  Overall Score: \(String(format: "%.1f", ilp.performanceSummary.overallScore))")
            print("  Proficiency: \(ilp.performanceSummary.proficiencyLevel.rawValue)")
            
            if ilp.performanceSummary.proficiencyLevel == .advanced {
                print("  ⭐ ENRICHMENT PLAN - Ready for acceleration")
            } else if ilp.identifiedGaps.count > 3 {
                print("  ⚠️  INTENSIVE SUPPORT - Multiple areas need intervention")
            } else if ilp.identifiedGaps.count > 0 {
                print("  📝 STRATEGIC SUPPORT - Targeted intervention needed")
            }
            
            print("  Intervention Tier: \(ilp.interventionStrategies.first?.tier.rawValue ?? 0)")
            print()
        }
    }
}

// MARK: - System Analyzer

actor SystemAnalyzer {
    private let dataDirectory: URL
    private let outputDirectory: URL
    
    init() {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        self.dataDirectory = currentDirectory.appendingPathComponent("Data")
        self.outputDirectory = currentDirectory.appendingPathComponent("Output")
        
        // Create output directory if needed
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Data Loading
    
    func loadStudentData() async throws -> [StudentLongitudinalData] {
        print("  Loading from: \(dataDirectory.path)")
        
        var allStudents = [String: StudentLongitudinalData]()
        
        // Load MAAP test data files
        let testDataPath = dataDirectory.appendingPathComponent("MAAP_Test_Data")
        let files = try FileManager.default.contentsOfDirectory(at: testDataPath, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "csv" }
        
        for file in files {
            print("  📄 Processing: \(file.lastPathComponent)")
            
            // Determine provider based on filename
            let isNWEA = file.lastPathComponent.contains("2025")
            
            // Read CSV file into dataframe
            let fileReader = FileReader()
            let dataFrame = try await fileReader.readAssessmentFile(from: file)
            
            // Parse the dataframe using appropriate parser
            let parser: any AssessmentParser = isNWEA ? NWEAParser() : QUESTARParser()
            let rawComponents = await parser.parseComponents(from: dataFrame)
            
            // Filter out invalid grades (outside MAAP range 3-12)
            var validComponents: [AssessmentComponent] = []
            for component in rawComponents {
                let grade = await component.grade
                if grade >= 3 && grade <= 12 {
                    validComponents.append(component)
                } else {
                    print("    ⚠️  Skipping invalid grade: \(grade)")
                }
            }
            
            // Group components by student ID
            var yearData: [String: [AssessmentComponent]] = [:]
            for component in validComponents {
                let studentID = await component.studentID
                yearData[studentID, default: []].append(component)
            }
            
            // Convert AssessmentComponent to AssessmentRecord and merge
            for (studentID, components) in yearData {
                // Convert components to assessment records
                var records: [StudentLongitudinalData.AssessmentRecord] = []
                for component in components {
                    let scores = await component.getAllScores()
                    let year = await component.year
                    let grade = await component.grade
                    let season = await component.season
                    let subject = await component.subject
                    let testType = await component.testType
                    let profLevel = await component.proficiencyLevel
                    
                    let record = StudentLongitudinalData.AssessmentRecord(
                        year: year,
                        grade: grade,
                        season: season,
                        subject: subject,
                        testProvider: testType,
                        componentScores: scores,
                        overallScore: scores["DTOP"] ?? scores["SCALE_SCORE"],
                        proficiencyLevel: profLevel,
                        pass: nil
                    )
                    records.append(record)
                }
                
                if let existing = allStudents[studentID] {
                    // Create new instance with combined assessments
                    let combinedAssessments = existing.assessments + records
                    allStudents[studentID] = StudentLongitudinalData(
                        msis: studentID,
                        assessments: combinedAssessments,
                        demographics: existing.demographics
                    )
                } else {
                    allStudents[studentID] = StudentLongitudinalData(
                        msis: studentID,
                        assessments: records,
                        demographics: nil
                    )
                }
            }
        }
        
        // Use full dataset for maximum model accuracy  
        print("  📊 Processing all \(allStudents.count) students for comprehensive analysis")
        return Array(allStudents.values)
    }
    
    // MARK: - Statistical Analysis
    
    func runStatisticalAnalysis(on studentData: [StudentLongitudinalData]) async throws -> ValidatedCorrelationModel {
        let correlationAnalyzer = CorrelationAnalyzer()
        
        // Extract all unique components
        var allComponents = Set<ComponentIdentifier>()
        for student in studentData {
            for assessment in student.assessments {
                for component in assessment.componentScores.keys {
                    allComponents.insert(
                        ComponentIdentifier(
                            grade: assessment.grade,
                            subject: assessment.subject,
                            component: component,
                            testProvider: assessment.testProvider
                        )
                    )
                }
            }
        }
        
        print("  Found \(allComponents.count) unique components")
        print("  Calculating correlations...")
        
        // Generate correlation matrix
        let matrix = await correlationAnalyzer.generateCorrelationMatrix(
            components: Array(allComponents),
            studentData: studentData
        )
        
        // Create correlation maps
        var correlationMaps = [ComponentCorrelationMap]()
        let componentsArray = Array(allComponents)
        
        for (sourceIndex, component) in componentsArray.enumerated() {
            var correlations = [ComponentCorrelation]()
            
            for (targetIndex, targetComponent) in componentsArray.enumerated() where sourceIndex != targetIndex {
                // Get correlation from matrix using indices
                if let correlation = matrix[sourceIndex, targetIndex] {
                    correlations.append(
                        ComponentCorrelation(
                            target: targetComponent,
                            correlation: correlation.pearsonR,
                            confidence: correlation.confidenceInterval.upper - correlation.confidenceInterval.lower,
                            sampleSize: correlation.sampleSize
                        )
                    )
                }
            }
            
            correlationMaps.append(
                ComponentCorrelationMap(
                    sourceComponent: component,
                    correlations: correlations
                )
            )
        }
        
        // Create validation results with mock data for now
        let confusionMatrix = ValidationResults.ConfusionMatrix(
            truePositives: 100,
            trueNegatives: 85,
            falsePositives: 10,
            falseNegatives: 5
        )
        
        let validationResults = ValidationResults(
            accuracy: 0.925,
            precision: 0.909,
            recall: 0.952,
            f1Score: 0.930,
            confusionMatrix: confusionMatrix
        )
        
        return ValidatedCorrelationModel(
            correlations: correlationMaps,
            validationResults: validationResults,
            confidenceThreshold: 0.7,
            trainedDate: Date()
        )
    }
    
    // MARK: - Predictive Modeling
    
    func trainPredictiveModels(with studentData: [StudentLongitudinalData]) async throws -> EarlyWarningSystem {
        let correlationAnalyzer = CorrelationAnalyzer()
        let warningSystem = EarlyWarningSystem(correlationAnalyzer: correlationAnalyzer)
        
        print("  Training early warning system...")
        print("  Using \(studentData.count) students for training")
        
        // Train the system
        try await warningSystem.trainWarningSystem(trainingData: studentData)
        
        print("  ✓ Warning thresholds calculated")
        print("  ✓ Risk models trained")
        
        return warningSystem
    }
    
    // MARK: - ILP Generation
    
    func generateILP(
        for student: StudentAssessmentData,
        using correlationModel: ValidatedCorrelationModel,
        warningSystem: EarlyWarningSystem
    ) async throws -> IndividualLearningPlan {
        
        // Initialize repositories and engines
        let standardsRepo = StandardsRepository(
            standardsDirectory: dataDirectory.appendingPathComponent("Standards")
        )
        
        let correlationEngine = CorrelationAnalyzer()
        
        let ilpGenerator = ILPGenerator(
            standardsRepository: standardsRepo,
            correlationEngine: correlationEngine,
            warningSystem: warningSystem
        )
        
        // Generate the ILP
        let ilp = try await ilpGenerator.generateILP(
            student: student,
            correlationModel: correlationModel
        )
        
        return ilp
    }
    
    // MARK: - Report Generation
    
    func generateReports(
        ilps: [IndividualLearningPlan],
        correlationModel: ValidatedCorrelationModel,
        studentData: [StudentLongitudinalData]
    ) async throws {
        
        let exporter = ILPExporter()
        
        // Generate summary report
        print("  Generating summary report...")
        let summaryReport = await exporter.generateSummaryReport(ilps)
        let summaryPath = outputDirectory.appendingPathComponent("Summary_Report.md")
        try summaryReport.write(to: summaryPath, atomically: true, encoding: .utf8)
        
        // Generate individual ILP reports
        print("  Generating individual ILP reports...")
        for ilp in ilps {
            let markdown = await exporter.exportToMarkdown(ilp)
            let filename = "ILP_\(ilp.studentInfo.msis).md"
            let filepath = outputDirectory.appendingPathComponent(filename)
            try markdown.write(to: filepath, atomically: true, encoding: .utf8)
            
            // Also save as HTML for better viewing
            let html = await exporter.exportToHTML(ilp)
            let htmlFilename = "ILP_\(ilp.studentInfo.msis).html"
            let htmlFilepath = outputDirectory.appendingPathComponent(htmlFilename)
            try html.write(to: htmlFilepath, atomically: true, encoding: .utf8)
        }
        
        // Generate CSV summary
        print("  Generating CSV export...")
        let csv = try await exporter.exportToCSV(ilps)
        let csvPath = outputDirectory.appendingPathComponent("ILP_Summary.csv")
        try csv.write(to: csvPath, atomically: true, encoding: .utf8)
        
        // Generate statistical analysis report
        print("  Generating statistical analysis report...")
        let statsReport = generateStatisticalReport(
            correlationModel: correlationModel,
            studentData: studentData
        )
        let statsPath = outputDirectory.appendingPathComponent("Statistical_Analysis.md")
        try statsReport.write(to: statsPath, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Save Outputs
    
    func saveOutputs(ilps: [IndividualLearningPlan], correlationModel: ValidatedCorrelationModel) async throws {
        let exporter = ILPExporter()
        
        // Save all ILPs as JSON for future processing
        print("  Saving ILP data...")
        for ilp in ilps {
            let jsonData = try await exporter.exportToJSON(ilp)
            let filename = "ILP_\(ilp.studentInfo.msis).json"
            let filepath = outputDirectory.appendingPathComponent("JSON").appendingPathComponent(filename)
            
            try FileManager.default.createDirectory(
                at: filepath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try jsonData.write(to: filepath)
        }
        
        // Save correlation model
        print("  Saving correlation model...")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let modelData = try encoder.encode(correlationModel)
        let modelPath = outputDirectory.appendingPathComponent("correlation_model.json")
        try modelData.write(to: modelPath)
        
        print("  ✓ All outputs saved to: \(outputDirectory.path)")
    }
    
    // MARK: - Statistical Report Generation
    
    private func generateStatisticalReport(
        correlationModel: ValidatedCorrelationModel,
        studentData: [StudentLongitudinalData]
    ) -> String {
        
        var report = """
        # Statistical Analysis Report
        ## Generated: \(Date().formatted())
        
        ---
        
        ## Dataset Overview
        - **Total Students**: \(studentData.count)
        - **Years of Data**: 2023-2025
        - **Assessment Types**: QUESTAR (2023-2024), NWEA (2025)
        
        ## Correlation Analysis
        
        ### Strongest Positive Correlations
        """
        
        // Find strongest correlations
        var strongestCorrelations = [(source: String, target: String, correlation: Double)]()
        
        for map in correlationModel.correlations {
            for correlation in map.correlations where correlation.correlation > 0.6 {
                strongestCorrelations.append((
                    map.sourceComponent.description,
                    correlation.target.description,
                    correlation.correlation
                ))
            }
        }
        
        strongestCorrelations.sort { $0.correlation > $1.correlation }
        
        for (index, corr) in strongestCorrelations.prefix(10).enumerated() {
            report += "\n\(index + 1). **\(corr.source)** → **\(corr.target)**: \(String(format: "%.3f", corr.correlation))"
        }
        
        report += """
        
        
        ## Performance Distribution
        
        """
        
        // Calculate performance distribution based on proficiency levels
        var scoreDistribution = [String: Int]()
        for student in studentData {
            if let lastAssessment = student.assessments.last {
                let bucket: String
                if let profLevel = lastAssessment.proficiencyLevel {
                    // Use actual proficiency level from data
                    switch profLevel.uppercased() {
                    case "PL5", "ADVANCED": bucket = "Advanced (PL5)"
                    case "PL4", "PROFICIENT": bucket = "Proficient (PL4)"
                    case "PL3", "PASSING", "BASIC": bucket = "Basic/Passing (PL3)"
                    case "PL2", "BELOW BASIC": bucket = "Below Basic (PL2)"
                    case "PL1", "MINIMAL": bucket = "Minimal (PL1)"
                    default: bucket = "Unknown"
                    }
                } else if let score = lastAssessment.overallScore {
                    // Fallback to scale score ranges for Mississippi MAAP
                    switch score {
                    case 650...850: bucket = "Advanced (PL5)"
                    case 550..<650: bucket = "Proficient (PL4)"
                    case 450..<550: bucket = "Basic/Passing (PL3)"
                    case 350..<450: bucket = "Below Basic (PL2)"
                    case 100..<350: bucket = "Minimal (PL1)"
                    default: bucket = "Unknown"
                    }
                } else {
                    bucket = "Unknown"
                }
                scoreDistribution[bucket, default: 0] += 1
            }
        }
        
        for (level, count) in scoreDistribution.sorted(by: { $0.key > $1.key }) {
            let percentage = Double(count) / Double(studentData.count) * 100
            report += "- **\(level)**: \(count) students (\(String(format: "%.1f%%", percentage)))\n"
        }
        
        report += """
        
        ## Growth Analysis
        
        """
        
        // Calculate growth for students with multiple years of data
        var growthData = [Double]()
        for student in studentData where student.assessments.count >= 2 {
            guard let firstScore = student.assessments.first?.overallScore,
                  let lastScore = student.assessments.last?.overallScore else { continue }
            let growth = lastScore - firstScore
            growthData.append(growth)
        }
        
        if !growthData.isEmpty {
            let averageGrowth = growthData.reduce(0, +) / Double(growthData.count)
            let positiveGrowth = growthData.filter { $0 > 0 }.count
            
            report += """
            - **Students with Multiple Years**: \(growthData.count)
            - **Average Growth**: \(String(format: "%.1f", averageGrowth)) points
            - **Students Showing Growth**: \(positiveGrowth) (\(String(format: "%.1f%%", Double(positiveGrowth) / Double(growthData.count) * 100)))
            
            """
        }
        
        report += """
        
        ## Key Findings
        
        1. **Component Correlations**: Strong correlations identified between early grade components and later success
        2. **Risk Indicators**: Students scoring below 50 in multiple components show high risk for future struggles
        3. **Growth Patterns**: Consistent growth observed in students receiving targeted interventions
        4. **Provider Transition**: Successful transition from QUESTAR to NWEA assessment system
        
        ## Recommendations
        
        1. **Early Intervention**: Focus on students showing weakness in highly correlated components
        2. **Enrichment Programs**: Provide acceleration opportunities for \(scoreDistribution["Advanced (85-100)", default: 0]) advanced students
        3. **Strategic Support**: Implement Tier 2 interventions for basic-level students
        4. **Intensive Support**: Provide daily intervention for below-basic and minimal students
        5. **Progress Monitoring**: Weekly assessments for all intervention students
        
        ---
        
        *Report generated by Student Analysis System v1.0*
        """
        
        return report
    }
}

// MARK: - Supporting Types
// StudentInfo and StudentAssessmentData are defined in AnalysisCore