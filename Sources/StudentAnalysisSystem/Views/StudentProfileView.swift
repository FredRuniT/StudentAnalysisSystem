import SwiftUI
import AnalysisCore
import IndividualLearningPlan

struct StudentProfileView: View {
    let student: StudentAssessmentData
    @StateObject private var ilpViewModel = ILPViewModel()
    @State private var selectedPlanType: PlanType = .auto
    @State private var showingILPGenerator = false
    @State private var showingExportOptions = false
    @State private var generatedILP: IndividualLearningPlan?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Student Header
                studentHeaderSection
                
                // Performance Summary
                performanceSummarySection
                
                // Component Scores
                componentScoresSection
                
                // ILP Generation Section
                ilpGenerationSection
                
                // Generated ILP Preview (if available)
                if let ilp = generatedILP {
                    generatedILPSection(ilp)
                }
            }
            .padding()
        }
        .navigationTitle("Student Profile")
        .toolbar {
            ToolbarItem {
                Menu {
                    Button(action: { exportFormat(.pdf) }) {
                        Label("Export as PDF", systemImage: "doc.richtext")
                    }
                    Button(action: { exportFormat(.markdown) }) {
                        Label("Export as Markdown", systemImage: "doc.text")
                    }
                    Button(action: { exportFormat(.csv) }) {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(generatedILP == nil)
            }
        }
        .sheet(isPresented: $showingILPGenerator) {
            ILPGeneratorSheet(
                student: student,
                planType: selectedPlanType,
                onGenerate: { ilp in
                    generatedILP = ilp
                    showingILPGenerator = false
                }
            )
            .frame(minWidth: 700, minHeight: 500)
        }
    }
    
    // MARK: - Section Views
    
    private var studentHeaderSection: some View {
        GroupBox {
            HStack(spacing: 20) {
                // Student avatar placeholder
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text(student.firstName.prefix(1) + student.lastName.prefix(1))
                        .font(.title)
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(student.firstName) \(student.lastName)")
                        .font(.title2)
                        .bold()
                    
                    HStack(spacing: 20) {
                        Label(student.msis, systemImage: "number")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Label("Grade \(student.testGrade)", systemImage: "graduationcap")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Label(student.schoolYear, systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 8) {
                    Button(action: { showingILPGenerator = true }) {
                        Label("Generate ILP", systemImage: "doc.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if ilpViewModel.isGenerating {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .padding()
        } label: {
            Label("Student Information", systemImage: "person.crop.circle")
                .font(.headline)
        }
    }
    
    private var performanceSummarySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                // Overall Performance Metrics
                HStack(spacing: 20) {
                    PerformanceMetric(
                        title: "Overall Level",
                        value: determineProficiencyLevel(),
                        color: proficiencyColor(determineProficiencyLevel())
                    )
                    
                    PerformanceMetric(
                        title: "Math Performance",
                        value: calculateSubjectAverage(subject: "MATH"),
                        color: scoreColor(Double(calculateSubjectAverage(subject: "MATH")) ?? 0)
                    )
                    
                    PerformanceMetric(
                        title: "ELA Performance",
                        value: calculateSubjectAverage(subject: "ELA"),
                        color: scoreColor(Double(calculateSubjectAverage(subject: "ELA")) ?? 0)
                    )
                    
                    PerformanceMetric(
                        title: "Components Below Basic",
                        value: "\(countBelowBasicComponents())",
                        color: countBelowBasicComponents() > 0 ? .red : .green
                    )
                }
                
                // Proficiency Level Bar
                ProficiencyLevelBar(
                    level: determineProficiencyLevelNumber(),
                    scaledScore: calculateOverallScore()
                )
            }
            .padding()
        } label: {
            Label("Performance Summary", systemImage: "chart.bar.xaxis")
                .font(.headline)
        }
    }
    
    private var componentScoresSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Component breakdown by category
                ForEach(groupComponentsByCategory(), id: \.key) { category, components in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(components, id: \.componentKey) { component in
                                ComponentScoreCard(component: component)
                            }
                        }
                    }
                    
                    if category != groupComponentsByCategory().last?.key {
                        Divider()
                    }
                }
            }
            .padding()
        } label: {
            Label("Component Score Breakdown", systemImage: "list.bullet.rectangle")
                .font(.headline)
        }
    }
    
    private var ilpGenerationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Individual Learning Plan Options")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Plan Type", selection: $selectedPlanType) {
                        Text("Auto").tag(PlanType.auto)
                        Text("Remediation").tag(PlanType.remediation)
                        Text("Enrichment").tag(PlanType.enrichment)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                
                HStack(spacing: 16) {
                    // Plan type descriptions
                    ForEach([
                        ("Auto", "Automatically determines plan type based on performance", "wand.and.stars"),
                        ("Remediation", "Focus on improving weak areas", "arrow.up.circle"),
                        ("Enrichment", "Advanced challenges for high performers", "star.circle")
                    ], id: \.0) { type, description, icon in
                        HStack {
                            Image(systemName: icon)
                                .foregroundStyle(.blue)
                                .imageScale(.large)
                            
                            VStack(alignment: .leading) {
                                Text(type)
                                    .font(.headline)
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Button(action: { showingILPGenerator = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Individual Learning Plan")
                        Image(systemName: "sparkles")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        } label: {
            Label("ILP Generation", systemImage: "doc.badge.gearshape")
                .font(.headline)
        }
    }
    
    private func generatedILPSection(_ ilp: IndividualLearningPlan) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Generated ILP", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Created: \(ilp.createdDate, format: .dateTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // ILP Summary
                VStack(alignment: .leading, spacing: 12) {
                    if !ilp.performanceSummary.isEmpty {
                        Text("Key Findings:")
                            .font(.subheadline)
                            .bold()
                        
                        ForEach(ilp.performanceSummary.prefix(3), id: \.self) { summary in
                            HStack(alignment: .top) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.blue)
                                    .imageScale(.small)
                                Text(summary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if !ilp.focusAreas.isEmpty {
                        Text("Priority Areas:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            ForEach(ilp.focusAreas.prefix(3)) { area in
                                VStack {
                                    Image(systemName: iconForSubject(area.subject))
                                        .foregroundStyle(severityColor(area.severity))
                                        .imageScale(.large)
                                    Text(area.subject)
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(severityColor(area.severity).opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: { showingExportOptions = true }) {
                        Label("Export Options", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: ILPDetailView(ilp: ilp)) {
                        Label("View Full ILP", systemImage: "arrow.right.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        } label: {
            Label("Current ILP", systemImage: "doc.text.fill")
                .font(.headline)
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineProficiencyLevel() -> String {
        let avgScore = calculateOverallScore()
        return MississippiProficiencyLevels.shared.proficiencyLevel(for: avgScore, grade: student.testGrade, subject: "Overall").name
    }
    
    private func determineProficiencyLevelNumber() -> Int {
        let avgScore = calculateOverallScore()
        return MississippiProficiencyLevels.shared.proficiencyLevel(for: avgScore, grade: student.testGrade, subject: "Overall").level
    }
    
    private func calculateOverallScore() -> Int {
        guard !student.components.isEmpty else { return 0 }
        let total = student.components.reduce(0) { $0 + $1.scaledScore }
        return total / student.components.count
    }
    
    private func calculateSubjectAverage(subject: String) -> String {
        let subjectComponents = student.components.filter { $0.componentKey.contains(subject) }
        guard !subjectComponents.isEmpty else { return "N/A" }
        let avg = subjectComponents.reduce(0) { $0 + $1.scaledScore } / subjectComponents.count
        return "\(avg)"
    }
    
    private func countBelowBasicComponents() -> Int {
        student.components.filter { $0.scaledScore < 650 }.count
    }
    
    private func groupComponentsByCategory() -> [(key: String, value: [AssessmentComponent])] {
        let mathComponents = student.components.filter { $0.componentKey.contains("MATH") }
        let elaComponents = student.components.filter { $0.componentKey.contains("ELA") }
        
        var grouped: [(key: String, value: [AssessmentComponent])] = []
        if !mathComponents.isEmpty {
            grouped.append(("Mathematics", mathComponents))
        }
        if !elaComponents.isEmpty {
            grouped.append(("English Language Arts", elaComponents))
        }
        
        return grouped
    }
    
    private func proficiencyColor(_ level: String) -> Color {
        switch level {
        case "Advanced": return .green
        case "Proficient": return .blue
        case "Passing": return .yellow
        case "Basic": return .orange
        case "Minimal": return .red
        default: return .gray
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 750...: return .green
        case 700..<750: return .blue
        case 650..<700: return .yellow
        case 600..<650: return .orange
        default: return .red
        }
    }
    
    private func severityColor(_ severity: Double) -> Color {
        switch severity {
        case 0.8...: return .red
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .green
        }
    }
    
    private func iconForSubject(_ subject: String) -> String {
        if subject.lowercased().contains("math") {
            return "function"
        } else if subject.lowercased().contains("ela") || subject.lowercased().contains("english") {
            return "text.book.closed"
        } else {
            return "book"
        }
    }
    
    private func exportFormat(_ format: ExportFormat) {
        guard let ilp = generatedILP else { return }
        Task {
            await ilpViewModel.exportILP(ilp, format: format)
        }
    }
}

// MARK: - Supporting Views

struct PerformanceMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title3)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProficiencyLevelBar: View {
    let level: Int
    let scaledScore: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Proficiency Level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Scaled Score: \(scaledScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.separatorColor))
                        .frame(height: 20)
                    
                    // Level segments
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { segmentLevel in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(levelColor(segmentLevel).opacity(segmentLevel <= level ? 1 : 0.2))
                                .frame(width: geometry.size.width / 5 - 1)
                        }
                    }
                    .frame(height: 20)
                    
                    // Score position indicator
                    let position = scorePosition(scaledScore, in: geometry.size.width)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .offset(x: position - 8)
                }
            }
            .frame(height: 20)
            
            HStack {
                ForEach(["Minimal", "Basic", "Passing", "Proficient", "Advanced"], id: \.self) { levelName in
                    Text(levelName)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .blue
        case 5: return .green
        default: return .gray
        }
    }
    
    private func scorePosition(_ score: Int, in width: CGFloat) -> CGFloat {
        let normalized = Double(score - 545) / Double(850 - 545)
        return CGFloat(normalized) * width
    }
}

struct ComponentScoreCard: View {
    let component: AssessmentComponent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(extractComponentName(component.componentKey))
                    .font(.caption)
                    .bold()
                
                Text("Score: \(component.scaledScore)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(scoreIndicatorColor(component.scaledScore))
                .frame(width: 8, height: 8)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func extractComponentName(_ key: String) -> String {
        let parts = key.split(separator: "_")
        if parts.count >= 4 {
            return String(parts[3])
        }
        return key
    }
    
    private func scoreIndicatorColor(_ score: Int) -> Color {
        switch score {
        case 750...: return .green
        case 700..<750: return .blue
        case 650..<700: return .yellow
        case 600..<650: return .orange
        default: return .red
        }
    }
}

struct ILPGeneratorSheet: View {
    let student: StudentAssessmentData
    let planType: PlanType
    let onGenerate: (IndividualLearningPlan) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var useBlueprints = true
    @State private var includeGradeProgression = true
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Generate Individual Learning Plan")
                .font(.largeTitle)
                .bold()
            
            Text("for \(student.firstName) \(student.lastName)")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Use Mississippi Test Blueprints", isOn: $useBlueprints)
                    Text("Maps weak components to specific MS-CCRS standards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Toggle("Include Grade Progression Analysis", isOn: $includeGradeProgression)
                    Text("Predicts future struggles based on correlation data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            
            if isGenerating {
                ProgressView("Generating ILP...")
                    .progressViewStyle(.circular)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Generate") {
                    generateILP()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
        }
        .padding()
    }
    
    private func generateILP() {
        isGenerating = true
        
        Task {
            // TODO: In production, properly initialize and use ILPGenerator
            // For now, create a mock ILP for UI demonstration
            
            // Simulate processing delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Create a mock ILP
            let mockILP = IndividualLearningPlan(
                id: UUID(),
                studentMSIS: student.msis,
                studentName: "\(student.firstName) \(student.lastName)",
                currentGrade: student.testGrade,
                targetGrade: student.testGrade + 1,
                createdDate: Date(),
                targetCompletionDate: Date().addingTimeInterval(86400 * 180), // 6 months
                performanceSummary: [
                    "Blueprint-based analysis complete",
                    "Grade progression pathways identified",
                    "Personalized interventions generated"
                ],
                focusAreas: [
                    FocusArea(
                        id: UUID().uuidString,
                        subject: "Primary Focus Area",
                        description: "Targeted learning objectives",
                        components: ["Component1", "Component2"],
                        severity: 0.7,
                        standards: []
                    )
                ],
                learningObjectives: [],
                milestones: [],
                interventionStrategies: [],
                timeline: nil,
                planType: planType
            )
            
            await MainActor.run {
                onGenerate(mockILP)
                isGenerating = false
            }
        }
    }
}

// MARK: - ILP View Model
@MainActor
class ILPViewModel: ObservableObject {
    @Published var students: [StudentAssessmentData] = []
    @Published var generatedILPs: [IndividualLearningPlan] = []
    @Published var isGenerating = false
    @Published var selectedPlanType: PlanType = .auto
    
    func generateILP(for student: StudentAssessmentData) async {
        isGenerating = true
        defer { isGenerating = false }
        
        // TODO: In production, properly initialize and use ILPGenerator
        // For now, create a mock ILP for UI demonstration
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Create a mock ILP
        let mockILP = IndividualLearningPlan(
            id: UUID(),
            studentMSIS: student.msis,
            studentName: "\(student.firstName) \(student.lastName)",
            currentGrade: student.testGrade,
            targetGrade: student.testGrade + 1,
            createdDate: Date(),
            targetCompletionDate: Date().addingTimeInterval(86400 * 180), // 6 months
            performanceSummary: [
                "Student performance analysis complete",
                "Identified areas for improvement",
                "Customized learning plan generated"
            ],
            focusAreas: [
                FocusArea(
                    id: UUID().uuidString,
                    subject: "Mathematics",
                    description: "Focus on core concepts",
                    components: ["D1", "D2"],
                    severity: 0.6,
                    standards: []
                )
            ],
            learningObjectives: [],
            milestones: [],
            interventionStrategies: [],
            timeline: nil,
            planType: selectedPlanType
        )
        
        generatedILPs.append(mockILP)
    }
    
    func exportILP(_ ilp: IndividualLearningPlan, format: ExportFormat) async {
        let exporter = ILPExporter()
        
        do {
            let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Output")
                .appendingPathComponent("ILPs")
            
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            
            switch format {
            case .markdown:
                let content = try exporter.exportToMarkdown(ilp)
                let fileURL = outputURL.appendingPathComponent("\(ilp.studentName)_ILP.md")
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                
            case .csv:
                let content = try exporter.exportToCSV([ilp])
                let fileURL = outputURL.appendingPathComponent("\(ilp.studentName)_ILP.csv")
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                
            case .pdf:
                // PDF export would require additional implementation
                print("PDF export not yet implemented")
            }
        } catch {
            print("Error exporting ILP: \(error)")
        }
    }
}

enum ExportFormat {
    case pdf
    case markdown
    case csv
}