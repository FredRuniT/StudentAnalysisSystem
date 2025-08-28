import AnalysisCore
import IndividualLearningPlan
import SwiftUI

/// StudentProfileView represents...
struct StudentProfileView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    /// student property
    let student: StudentAssessmentData
    @StateObject private var ilpViewModel = ILPViewModel()
    @State private var selectedPlanType: PlanType = .auto
    @State private var showingILPGenerator = false
    @State private var showingExportOptions = false
    @State private var generatedILP: UIIndividualLearningPlan?
    
    /// body property
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
                /// ilp property
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
        .themed()
    }
    
    // MARK: - Section Views
    
    private var studentHeaderSection: some View {
        GroupBox {
            HStack(spacing: 20) {
                // Student avatar placeholder
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppleDesignSystem.SystemPalette.blue.opacity(0.3), AppleDesignSystem.SystemPalette.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text(student.firstName.prefix(1) + student.lastName.prefix(1))
                        .font(AppleDesignSystem.Typography.title)
                        .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(student.firstName) \(student.lastName)")
                        .font(AppleDesignSystem.Typography.title2)
                        .bold()
                    
                    HStack(spacing: 20) {
                        Label(student.msis, systemImage: "number")
                            .font(AppleDesignSystem.Typography.headline)
                            .foregroundStyle(.secondary)
                        
                        Label("Grade \(student.testGrade)", systemImage: "graduationcap")
                            .font(AppleDesignSystem.Typography.headline)
                            .foregroundStyle(.secondary)
                        
                        Label(student.schoolYear, systemImage: "calendar")
                            .font(AppleDesignSystem.Typography.headline)
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
                .font(AppleDesignSystem.Typography.headline)
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
                        color: countBelowBasicComponents() > 0 ? AppleDesignSystem.SystemPalette.red : AppleDesignSystem.SystemPalette.green
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
                .font(AppleDesignSystem.Typography.headline)
        }
    }
    
    private var componentScoresSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Component breakdown by category
                ForEach(groupComponentsByCategory(), id: \.key) { category, components in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category)
                            .font(AppleDesignSystem.Typography.headline)
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
                .font(AppleDesignSystem.Typography.headline)
        }
    }
    
    private var ilpGenerationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Individual Learning Plan Options")
                        .font(AppleDesignSystem.Typography.headline)
                    
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
                                .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                                .imageScale(.large)
                            
                            VStack(alignment: .leading) {
                                Text(type)
                                    .font(AppleDesignSystem.Typography.headline)
                                Text(description)
                                    .font(AppleDesignSystem.Typography.caption)
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
                .font(AppleDesignSystem.Typography.headline)
        }
    }
    
    private func generatedILPSection(_ ilp: UIIndividualLearningPlan) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Generated ILP", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                        .font(AppleDesignSystem.Typography.headline)
                    
                    Spacer()
                    
                    Text("Created: \(ilp.createdDate, format: .dateTime)")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                // ILP Summary
                VStack(alignment: .leading, spacing: 12) {
                    if !ilp.performanceSummary.isEmpty {
                        Text("Key Findings:")
                            .font(AppleDesignSystem.Typography.subheadline)
                            .bold()
                        
                        ForEach(ilp.performanceSummary.prefix(3), id: \.self) { summary in
                            HStack(alignment: .top) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                                    .imageScale(.small)
                                Text(summary)
                                    .font(AppleDesignSystem.Typography.caption)
                            }
                        }
                    }
                    
                    if !ilp.focusAreas.isEmpty {
                        Text("Priority Areas:")
                            .font(AppleDesignSystem.Typography.subheadline)
                            .bold()
                            .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            ForEach(ilp.focusAreas.prefix(3)) { area in
                                VStack {
                                    Image(systemName: iconForSubject(area.subject))
                                        .foregroundStyle(severityColor(area.severity))
                                        .imageScale(.large)
                                    Text(area.subject)
                                        .font(AppleDesignSystem.Typography.caption2)
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
                    
                    NavigationLink(destination: ILPDetailView(ilp: ilp.toBackendModel())) {
                        Label("View Full ILP", systemImage: "arrow.right.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        } label: {
            Label("Current ILP", systemImage: "doc.text.fill")
                .font(AppleDesignSystem.Typography.headline)
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineProficiencyLevel() -> String {
        /// avgScore property
        let avgScore = calculateOverallScore()
        return MississippiProficiencyLevels.getProficiencyLevel(score: Int(avgScore), grade: student.testGrade, subject: "Overall").level.rawValue
    }
    
    private func determineProficiencyLevelNumber() -> Int {
        /// avgScore property
        let avgScore = calculateOverallScore()
        return MississippiProficiencyLevels.getProficiencyLevel(score: Int(avgScore), grade: student.testGrade, subject: "Overall").level.numericValue
    }
    
    private func calculateOverallScore() -> Int {
        guard !student.uiComponents.isEmpty else { return 0 }
        /// total property
        let total = student.uiComponents.reduce(0) { $0 + Int($1.scaledScore) }
        return total / student.uiComponents.count
    }
    
    private func calculateSubjectAverage(subject: String) -> String {
        /// subjectComponents property
        let subjectComponents = student.uiComponents.filter { $0.componentKey.contains(subject) }
        guard !subjectComponents.isEmpty else { return "N/A" }
        /// avg property
        let avg = subjectComponents.reduce(0) { $0 + Int($1.scaledScore) } / subjectComponents.count
        return "\(avg)"
    }
    
    private func countBelowBasicComponents() -> Int {
        student.uiComponents.filter { $0.scaledScore < 650 }.count
    }
    
    private func groupComponentsByCategory() -> [(key: String, value: [UIAssessmentComponent])] {
        /// mathComponents property
        let mathComponents = student.uiComponents.filter { $0.componentKey.contains("MATH") }
        /// elaComponents property
        let elaComponents = student.uiComponents.filter { $0.componentKey.contains("ELA") }
        
        /// grouped property
        var grouped: [(key: String, value: [UIAssessmentComponent])] = []
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
        case "Advanced": return AppleDesignSystem.SystemPalette.green
        case "Proficient": return AppleDesignSystem.SystemPalette.blue
        case "Passing": return AppleDesignSystem.SystemPalette.yellow
        case "Basic": return AppleDesignSystem.SystemPalette.orange
        case "Minimal": return AppleDesignSystem.SystemPalette.red
        default: return .gray
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 750...: return AppleDesignSystem.SystemPalette.green
        case 700..<750: return AppleDesignSystem.SystemPalette.blue
        case 650..<700: return AppleDesignSystem.SystemPalette.yellow
        case 600..<650: return AppleDesignSystem.SystemPalette.orange
        default: return AppleDesignSystem.SystemPalette.red
        }
    }
    
    private func severityColor(_ severity: Double) -> Color {
        switch severity {
        case 0.8...: return AppleDesignSystem.SystemPalette.red
        case 0.6..<0.8: return AppleDesignSystem.SystemPalette.orange
        case 0.4..<0.6: return AppleDesignSystem.SystemPalette.yellow
        default: return AppleDesignSystem.SystemPalette.green
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
        /// ilp property
        guard let ilp = generatedILP else { return }
        Task {
            await ilpViewModel.exportILP(ilp, format: format)
        }
    }
}

// MARK: - Supporting Views

/// PerformanceMetric represents...
struct PerformanceMetric: View {
    /// title property
    let title: String
    /// value property
    let value: String
    /// color property
    let color: Color
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppleDesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(AppleDesignSystem.Typography.title3)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// ProficiencyLevelBar represents...
struct ProficiencyLevelBar: View {
    /// level property
    let level: Int
    /// scaledScore property
    let scaledScore: Int
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Proficiency Level")
                    .font(AppleDesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Scaled Score: \(scaledScore)")
                    .font(AppleDesignSystem.Typography.caption)
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
                    /// position property
                    let position = scorePosition(scaledScore, in: geometry.size.width)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(AppleDesignSystem.SystemPalette.blue, lineWidth: 2)
                        )
                        .offset(x: position - 8)
                }
            }
            .frame(height: 20)
            
            HStack {
                ForEach(["Minimal", "Basic", "Passing", "Proficient", "Advanced"], id: \.self) { levelName in
                    Text(levelName)
                        .font(AppleDesignSystem.Typography.caption2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 1: return AppleDesignSystem.SystemPalette.red
        case 2: return AppleDesignSystem.SystemPalette.orange
        case 3: return AppleDesignSystem.SystemPalette.yellow
        case 4: return AppleDesignSystem.SystemPalette.blue
        case 5: return AppleDesignSystem.SystemPalette.green
        default: return .gray
        }
    }
    
    private func scorePosition(_ score: Int, in width: CGFloat) -> CGFloat {
        /// normalized property
        let normalized = Double(score - 545) / Double(850 - 545)
        return CGFloat(normalized) * width
    }
}

/// ComponentScoreCard represents...
struct ComponentScoreCard: View {
    /// component property
    let component: UIAssessmentComponent
    
    /// body property
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(extractComponentName(component.componentKey))
                    .font(AppleDesignSystem.Typography.caption)
                    .bold()
                
                Text("Score: \(Int(component.scaledScore))")
                    .font(AppleDesignSystem.Typography.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(scoreIndicatorColor(Int(component.scaledScore)))
                .frame(width: 8, height: 8)
        }
        .padding(AppleDesignSystem.Spacing.small)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func extractComponentName(_ key: String) -> String {
        /// parts property
        let parts = key.split(separator: "_")
        if parts.count >= 4 {
            return String(parts[3])
        }
        return key
    }
    
    private func scoreIndicatorColor(_ score: Int) -> Color {
        switch score {
        case 750...: return AppleDesignSystem.SystemPalette.green
        case 700..<750: return AppleDesignSystem.SystemPalette.blue
        case 650..<700: return AppleDesignSystem.SystemPalette.yellow
        case 600..<650: return AppleDesignSystem.SystemPalette.orange
        default: return AppleDesignSystem.SystemPalette.red
        }
    }
}

/// ILPGeneratorSheet represents...
struct ILPGeneratorSheet: View {
    /// student property
    let student: StudentAssessmentData
    /// planType property
    let planType: PlanType
    /// onGenerate property
    let onGenerate: (UIIndividualLearningPlan) -> Void
    
    /// dismiss property
    @Environment(\.dismiss) var dismiss
    @State private var useBlueprints = true
    @State private var includeGradeProgression = true
    @State private var isGenerating = false
    
    /// body property
    var body: some View {
        VStack(spacing: 20) {
            Text("Generate Individual Learning Plan")
                .font(.largeTitle)
                .bold()
            
            Text("for \(student.firstName) \(student.lastName)")
                .font(AppleDesignSystem.Typography.headline)
                .foregroundStyle(.secondary)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Use Mississippi Test Blueprints", isOn: $useBlueprints)
                    Text("Maps weak components to specific MS-CCRS standards")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Toggle("Include Grade Progression Analysis", isOn: $includeGradeProgression)
                    Text("Predicts future struggles based on correlation data")
                        .font(AppleDesignSystem.Typography.caption)
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
            /// mockILP property
            let mockILP = UIIndividualLearningPlan(
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
                    UIFocusArea(
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
/// ILPViewModel represents...
class ILPViewModel: ObservableObject {
    /// students property
    @Published var students: [StudentAssessmentData] = []
    /// generatedILPs property
    @Published var generatedILPs: [UIIndividualLearningPlan] = []
    /// isGenerating property
    @Published var isGenerating = false
    /// selectedPlanType property
    @Published var selectedPlanType: PlanType = .auto
    
    /// generateILP function description
    func generateILP(for student: StudentAssessmentData) async {
        isGenerating = true
        defer { isGenerating = false }
        
        // TODO: In production, properly initialize and use ILPGenerator
        // For now, create a mock ILP for UI demonstration
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Create a mock ILP
        /// mockILP property
        let mockILP = UIIndividualLearningPlan(
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
                UIFocusArea(
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
    
    /// exportILP function description
    func exportILP(_ ilp: UIIndividualLearningPlan, format: ExportFormat) async {
        /// exporter property
        let exporter = ILPExporter()
        
        do {
            /// outputURL property
            let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Output")
                .appendingPathComponent("ILPs")
            
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            
            // Convert UI model to backend model for export
            /// backendILP property
            let backendILP = ilp.toBackendModel()
            
            switch format {
            case .markdown:
                /// content property
                let content = await exporter.exportToMarkdown(backendILP)
                /// fileURL property
                let fileURL = outputURL.appendingPathComponent("\(ilp.studentName)_ILP.md")
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                
            case .csv:
                /// content property
                let content = try await exporter.exportToCSV([backendILP])
                /// fileURL property
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

// ExportFormat moved to UILearningPlanModels.swift to avoid duplication