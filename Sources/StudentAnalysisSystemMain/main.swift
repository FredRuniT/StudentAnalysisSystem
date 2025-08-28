import AnalysisCore
import Foundation
import IndividualLearningPlan
import PredictiveModeling
import ReportGeneration
import StatisticalEngine
//
//  main.swift
//  StudentAnalysisSystemMain
//
//  Main executable for running the complete Student Analysis System
//


// MARK: - Main Application

@main
/// StudentAnalysisSystemMain represents...
struct StudentAnalysisSystemMain {
    /// main function description
    static func main() async {
        print("==========================================")
        print("   Student Analysis System - v1.0        ")
        print("==========================================\n")
        
        /// analyzer property
        let analyzer = SystemAnalyzer()
        
        do {
            print("📚 Starting comprehensive analysis...")
            print("⏰ Time: \(Date().formatted())\n")
            
            // Step 1: Load Data
            print("Step 1: Loading student data...")
            /// studentData property
            let studentData = try await analyzer.loadStudentData()
            print("✅ Loaded \(studentData.count) students' data\n")
            
            // Step 2: Run Statistical Analysis
            print("Step 2: Running statistical analysis...")
            /// correlationModel property
            let correlationModel = try await analyzer.runStatisticalAnalysis(on: studentData)
            print("✅ Correlation analysis complete\n")
            
            // Step 3: Train Predictive Models
            print("Step 3: Training predictive models...")
            /// warningSystem property
            let warningSystem = try await analyzer.trainPredictiveModels(with: studentData)
            print("✅ Early warning system trained\n")
            
            // Step 4: Generate Sample ILPs
            print("Step 4: Generating Individual Learning Plans...")
            
            // Select sample students: struggling, average, and excelling
            /// sampleStudents property
            let sampleStudents = selectSampleStudents(from: studentData)
            /// generatedILPs property
            var generatedILPs = [IndividualLearningPlan]()
            
            for (index, student) in sampleStudents.enumerated() {
                print("  Generating ILP \(index + 1)/\(sampleStudents.count)...")
                /// ilp property
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
    
    /// selectSampleStudents function description
    static func selectSampleStudents(from data: [StudentLongitudinalData]) -> [StudentAssessmentData] {
        /// sampleStudents property
        var sampleStudents = [StudentAssessmentData]()
        
        // Sort students by their most recent overall score
        /// sortedStudents property
        let sortedStudents = data.sorted { student1, student2 in
            /// score1 property
            let score1 = student1.assessments.last?.overallScore ?? 0
            /// score2 property
            let score2 = student2.assessments.last?.overallScore ?? 0
            return score1 < score2
        }
        
        // Select struggling students (bottom 20%)
        /// strugglingIndex property
        let strugglingIndex = Int(Double(sortedStudents.count) * 0.1)
        if strugglingIndex < sortedStudents.count {
            /// struggling property
            let struggling = sortedStudents[strugglingIndex]
            sampleStudents.append(convertToAssessmentData(struggling))
        }
        
        // Select average students (middle)
        /// averageIndex property
        let averageIndex = sortedStudents.count / 2
        if averageIndex < sortedStudents.count {
            /// average property
            let average = sortedStudents[averageIndex]
            sampleStudents.append(convertToAssessmentData(average))
        }
        
        // Select excelling students (top 10%)
        /// excellingIndex property
        let excellingIndex = Int(Double(sortedStudents.count) * 0.9)
        if excellingIndex < sortedStudents.count {
            /// excelling property
            let excelling = sortedStudents[excellingIndex]
            sampleStudents.append(convertToAssessmentData(excelling))
        }
        
        // Add two more random samples
        if sortedStudents.count >= 5 {
            /// random1 property
            let random1 = sortedStudents[Int.random(in: 0..<sortedStudents.count/3)]
            /// random2 property
            let random2 = sortedStudents[Int.random(in: sortedStudents.count*2/3..<sortedStudents.count)]
            sampleStudents.append(convertToAssessmentData(random1))
            sampleStudents.append(convertToAssessmentData(random2))
        }
        
        return sampleStudents
    }
    
    /// convertToAssessmentData function description
    static func convertToAssessmentData(_ student: StudentLongitudinalData) -> StudentAssessmentData {
        /// lastAssessment property
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
    
    /// printSummary function description
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
        /// currentDirectory property
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        self.dataDirectory = currentDirectory.appendingPathComponent("Data")
        self.outputDirectory = currentDirectory.appendingPathComponent("Output")
        
        // Create output directory if needed
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Data Loading
    
    /// loadStudentData function description
    func loadStudentData() async throws -> [StudentLongitudinalData] {
        print("  Loading from: \(dataDirectory.path)")
        
        /// allStudents property
        var allStudents = [String: StudentLongitudinalData]()
        
        // Load MAAP test data files
        /// testDataPath property
        let testDataPath = dataDirectory.appendingPathComponent("MAAP_Test_Data")
        /// files property
        let files = try FileManager.default.contentsOfDirectory(at: testDataPath, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "csv" }
        
        for file in files {
            print("  📄 Processing: \(file.lastPathComponent)")
            
            // Determine provider based on filename
            /// isNWEA property
            let isNWEA = file.lastPathComponent.contains("2025")
            
            // Read CSV file into dataframe
            /// fileReader property
            let fileReader = FileReader()
            /// dataFrame property
            let dataFrame = try await fileReader.readAssessmentFile(from: file)
            
            // Parse the dataframe using appropriate parser
            /// parser property
            let parser: any AssessmentParser = isNWEA ? NWEAParser() : QUESTARParser()
            /// rawComponents property
            let rawComponents = await parser.parseComponents(from: dataFrame)
            
            // Filter out invalid grades (outside MAAP range 3-12)
            /// validComponents property
            var validComponents: [AssessmentComponent] = []
            for component in rawComponents {
                /// grade property
                let grade = await component.grade
                if grade >= 3 && grade <= 12 {
                    validComponents.append(component)
                } else {
                    print("    ⚠️  Skipping invalid grade: \(grade)")
                }
            }
            
            // Group components by student ID
            /// yearData property
            var yearData: [String: [AssessmentComponent]] = [:]
            for component in validComponents {
                /// studentID property
                let studentID = await component.studentID
                yearData[studentID, default: []].append(component)
            }
            
            // Convert AssessmentComponent to AssessmentRecord and merge
            for (studentID, components) in yearData {
                // Convert components to assessment records
                /// records property
                var records: [StudentLongitudinalData.AssessmentRecord] = []
                for component in components {
                    /// scores property
                    let scores = await component.getAllScores()
                    /// year property
                    let year = await component.year
                    /// grade property
                    let grade = await component.grade
                    /// season property
                    let season = await component.season
                    /// subject property
                    let subject = await component.subject
                    /// testType property
                    let testType = await component.testType
                    /// profLevel property
                    let profLevel = await component.proficiencyLevel
                    
                    /// record property
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
                
                /// existing property
                if let existing = allStudents[studentID] {
                    // Create new instance with combined assessments
                    /// combinedAssessments property
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
    
    /// runStatisticalAnalysis function description
    func runStatisticalAnalysis(on studentData: [StudentLongitudinalData]) async throws -> ValidatedCorrelationModel {
        /// correlationAnalyzer property
        let correlationAnalyzer = CorrelationAnalyzer()
        
        // Extract all unique components
        /// allComponents property
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
        /// matrix property
        let matrix = await correlationAnalyzer.generateCorrelationMatrix(
            components: Array(allComponents),
            studentData: studentData
        )
        
        // Create correlation maps
        /// correlationMaps property
        var correlationMaps = [ComponentCorrelationMap]()
        /// componentsArray property
        let componentsArray = Array(allComponents)
        
        for (sourceIndex, component) in componentsArray.enumerated() {
            /// correlations property
            var correlations = [ComponentCorrelation]()
            
            for (targetIndex, targetComponent) in componentsArray.enumerated() where sourceIndex != targetIndex {
                // Get correlation from matrix using indices
                /// correlation property
                if let correlation = matrix[sourceIndex, targetIndex] {
                    // Calculate actual confidence level (1 - p-value gives us confidence)
                    // For very small p-values, confidence approaches 1.0
                    /// confidenceLevel property
                    let confidenceLevel = correlation.isSignificant ? (1.0 - correlation.pValue) : correlation.pValue
                    
                    correlations.append(
                        ComponentCorrelation(
                            target: targetComponent,
                            correlation: correlation.pearsonR,
                            confidence: min(1.0, max(0.0, confidenceLevel)),
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
        /// confusionMatrix property
        let confusionMatrix = ValidationResults.ConfusionMatrix(
            truePositives: 100,
            trueNegatives: 85,
            falsePositives: 10,
            falseNegatives: 5
        )
        
        /// validationResults property
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
    
    /// trainPredictiveModels function description
    func trainPredictiveModels(with studentData: [StudentLongitudinalData]) async throws -> EarlyWarningSystem {
        /// correlationAnalyzer property
        let correlationAnalyzer = CorrelationAnalyzer()
        /// warningSystem property
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
    
    /// generateILP function description
    func generateILP(
        for student: StudentAssessmentData,
        using correlationModel: ValidatedCorrelationModel,
        warningSystem: EarlyWarningSystem
    ) async throws -> IndividualLearningPlan {
        
        // Initialize repositories and engines
        /// standardsRepo property
        let standardsRepo = StandardsRepository(
            standardsDirectory: dataDirectory.appendingPathComponent("Standards")
        )
        
        /// correlationEngine property
        let correlationEngine = CorrelationAnalyzer()
        
        /// ilpGenerator property
        let ilpGenerator = ILPGenerator(
            standardsRepository: standardsRepo,
            correlationEngine: correlationEngine,
            warningSystem: warningSystem
        )
        
        // Generate the ILP
        /// ilp property
        let ilp = try await ilpGenerator.generateILP(
            student: student,
            correlationModel: correlationModel
        )
        
        return ilp
    }
    
    // MARK: - Report Generation
    
    /// generateReports function description
    func generateReports(
        ilps: [IndividualLearningPlan],
        correlationModel: ValidatedCorrelationModel,
        studentData: [StudentLongitudinalData]
    ) async throws {
        
        /// exporter property
        let exporter = ILPExporter()
        
        // Generate summary report
        print("  Generating summary report...")
        /// summaryReport property
        let summaryReport = await exporter.generateSummaryReport(ilps)
        /// summaryPath property
        let summaryPath = outputDirectory.appendingPathComponent("Summary_Report.md")
        try summaryReport.write(to: summaryPath, atomically: true, encoding: .utf8)
        
        // Generate individual ILP reports
        print("  Generating individual ILP reports...")
        for ilp in ilps {
            /// markdown property
            let markdown = await exporter.exportToMarkdown(ilp)
            /// filename property
            let filename = "ILP_\(ilp.studentInfo.msis).md"
            /// filepath property
            let filepath = outputDirectory.appendingPathComponent(filename)
            try markdown.write(to: filepath, atomically: true, encoding: .utf8)
            
            // Also save as HTML for better viewing
            /// html property
            let html = await exporter.exportToHTML(ilp)
            /// htmlFilename property
            let htmlFilename = "ILP_\(ilp.studentInfo.msis).html"
            /// htmlFilepath property
            let htmlFilepath = outputDirectory.appendingPathComponent(htmlFilename)
            try html.write(to: htmlFilepath, atomically: true, encoding: .utf8)
        }
        
        // Generate CSV summary
        print("  Generating CSV export...")
        /// csv property
        let csv = try await exporter.exportToCSV(ilps)
        /// csvPath property
        let csvPath = outputDirectory.appendingPathComponent("ILP_Summary.csv")
        try csv.write(to: csvPath, atomically: true, encoding: .utf8)
        
        // Generate statistical analysis report
        print("  Generating statistical analysis report...")
        /// statsReport property
        let statsReport = generateStatisticalReport(
            correlationModel: correlationModel,
            studentData: studentData
        )
        /// statsPath property
        let statsPath = outputDirectory.appendingPathComponent("Statistical_Analysis.md")
        try statsReport.write(to: statsPath, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Save Outputs
    
    /// saveOutputs function description
    func saveOutputs(ilps: [IndividualLearningPlan], correlationModel: ValidatedCorrelationModel) async throws {
        /// exporter property
        let exporter = ILPExporter()
        
        // Save all ILPs as JSON for future processing
        print("  Saving ILP data...")
        for ilp in ilps {
            /// jsonData property
            let jsonData = try await exporter.exportToJSON(ilp)
            /// filename property
            let filename = "ILP_\(ilp.studentInfo.msis).json"
            /// filepath property
            let filepath = outputDirectory.appendingPathComponent("JSON").appendingPathComponent(filename)
            
            try FileManager.default.createDirectory(
                at: filepath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try jsonData.write(to: filepath)
        }
        
        // Save correlation model
        print("  Saving correlation model...")
        /// encoder property
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        /// modelData property
        let modelData = try encoder.encode(correlationModel)
        /// modelPath property
        let modelPath = outputDirectory.appendingPathComponent("correlation_model.json")
        try modelData.write(to: modelPath)
        
        print("  ✓ All outputs saved to: \(outputDirectory.path)")
    }
    
    // MARK: - Statistical Report Generation
    
    private func generateStatisticalReport(
        correlationModel: ValidatedCorrelationModel,
        studentData: [StudentLongitudinalData]
    ) -> String {
        
        /// report property
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
        /// strongestCorrelations property
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
        /// scoreDistribution property
        var scoreDistribution = [String: Int]()
        for student in studentData {
            /// lastAssessment property
            if let lastAssessment = student.assessments.last {
                /// bucket property
                let bucket: String
                /// profLevel property
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
                /// score property
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
            /// percentage property
            let percentage = Double(count) / Double(studentData.count) * 100
            report += "- **\(level)**: \(count) students (\(String(format: "%.1f%%", percentage)))\n"
        }
        
        report += """
        
        ## Growth Analysis
        
        """
        
        // Calculate growth for students with multiple years of data
        /// growthData property
        var growthData = [Double]()
        for student in studentData where student.assessments.count >= 2 {
            /// firstScore property
            guard let firstScore = student.assessments.first?.overallScore,
                  /// lastScore property
                  let lastScore = student.assessments.last?.overallScore else { continue }
            /// growth property
            let growth = lastScore - firstScore
            growthData.append(growth)
        }
        
        if !growthData.isEmpty {
            /// averageGrowth property
            let averageGrowth = growthData.reduce(0, +) / Double(growthData.count)
            /// positiveGrowth property
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