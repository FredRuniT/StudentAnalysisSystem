import AnalysisCore
import IndividualLearningPlan
import SwiftUI

/// PredictiveCorrelationView represents...
struct PredictiveCorrelationView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = PredictiveCorrelationViewModel()
    @State private var selectedCategory: String?
    @State private var showingILPGenerator = false
    @State private var selectedCorrelationForILP: CorrelationPrediction?
    @State private var showingStudentSearch = false
    
    /// body property
    var body: some View {
        NavigationSplitView {
            // Left sidebar: Categories
            List(selection: $selectedCategory) {
                Section("Predictive Analysis") {
                    ForEach(viewModel.reportingCategories) { category in
                        HStack {
                            Image(systemName: iconForCategory(category.id))
                                .foregroundStyle(colorForCategory(category.id))
                                .frame(width: 20)
                            
                            VStack(alignment: .leading) {
                                Text(category.name)
                                    .font(AppleDesignSystem.Typography.headline)
                                
                                /// correlations property
                                if let correlations = viewModel.topCorrelationsByCategory[category.name],
                                   !correlations.isEmpty {
                                    Text("\(correlations.count) strong predictors")
                                        .font(AppleDesignSystem.Typography.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            /// correlations property
                            if let correlations = viewModel.topCorrelationsByCategory[category.name],
                               /// strongest property
                               let strongest = correlations.first {
                                Text("\(Int(abs(strongest.correlationStrength) * 100))%")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundStyle(viewModel.correlationColor(strongest.correlationStrength))
                                    .bold()
                            }
                        }
                        .tag(category.name)
                    }
                }
                
                Section("Student-Specific") {
                    Button(action: { showingStudentSearch = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                            Text("Analyze Student")
                            Spacer()
                            if viewModel.selectedStudent != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Predictive Correlations")
            .toolbar {
                ToolbarItem {
                    Button(action: { Task { await viewModel.loadTopCorrelations() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingCorrelations)
                }
            }
        } detail: {
            // Right side: Correlation details or ILP
            /// ilp property
            if let ilp = viewModel.generatedILP {
                ILPPreviewView(ilp: ilp, onDismiss: {
                    viewModel.generatedILP = nil
                })
            /// category property
            } else if let category = selectedCategory {
                CategoryCorrelationDetailView(
                    category: category,
                    viewModel: viewModel,
                    onGenerateILP: { correlation in
                        selectedCorrelationForILP = correlation
                        Task {
                            await viewModel.generateILPForCorrelation(correlation)
                        }
                    }
                )
            } else if viewModel.selectedStudent != nil {
                StudentPredictionView(viewModel: viewModel)
            } else {
                EmptyStateView()
            }
        }
        .sheet(isPresented: $showingStudentSearch) {
            StudentSearchView(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
        .themed()
    }
    
    private func iconForCategory(_ categoryId: String) -> String {
        switch categoryId {
        case "OA": return "function"
        case "NBT": return "number.square"
        case "NF": return "divide.square"
        case "MD": return "ruler"
        case "G": return "square.on.circle"
        case "RC": return "book"
        case "LA": return "text.quote"
        default: return "questionmark.circle"
        }
    }
    
    private func colorForCategory(_ categoryId: String) -> Color {
        switch categoryId {
        case "OA": return AppleDesignSystem.SystemPalette.blue
        case "NBT": return AppleDesignSystem.SystemPalette.green
        case "NF": return AppleDesignSystem.SystemPalette.orange
        case "MD": return AppleDesignSystem.SystemPalette.purple
        case "G": return AppleDesignSystem.SystemPalette.pink
        case "RC": return .cyan
        case "LA": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Category Correlation Detail View
/// CategoryCorrelationDetailView represents...
struct CategoryCorrelationDetailView: View {
    /// category property
    let category: String
    /// viewModel property
    let viewModel: PredictiveCorrelationViewModel
    /// onGenerateILP property
    let onGenerateILP: (CorrelationPrediction) -> Void
    
    /// correlations property
    var correlations: [CorrelationPrediction] {
        viewModel.topCorrelationsByCategory[category] ?? []
    }
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(category)
                        .font(.largeTitle)
                        .bold()
                    Text("Top Predictive Correlations")
                        .font(AppleDesignSystem.Typography.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                // Filter controls
                HStack {
                    Text("Min Strength:")
                    Picker("", selection: .constant(viewModel.minimumCorrelationStrength)) {
                        Text("50%").tag(0.5)
                        Text("70%").tag(0.7)
                        Text("80%").tag(0.8)
                        Text("90%").tag(0.9)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
            .padding()
            
            if correlations.isEmpty {
                ContentUnavailableView(
                    "No Strong Correlations",
                    systemImage: "chart.scatter",
                    description: Text("No correlations above \(Int(viewModel.minimumCorrelationStrength * 100))% strength found for this category")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(correlations) { correlation in
                            CorrelationCard(
                                correlation: correlation,
                                viewModel: viewModel,
                                onGenerateILP: { onGenerateILP(correlation) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Correlation Card
/// CorrelationCard represents...
struct CorrelationCard: View {
    /// correlation property
    let correlation: CorrelationPrediction
    /// viewModel property
    let viewModel: PredictiveCorrelationViewModel
    /// onGenerateILP property
    let onGenerateILP: () -> Void
    
    @State private var isExpanded = false
    @State private var isHovering = false
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Correlation strength indicator
                ZStack {
                    Circle()
                        .fill(viewModel.correlationColor(correlation.correlationStrength).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    VStack(spacing: 2) {
                        Image(systemName: viewModel.correlationIcon(correlation.correlationStrength))
                            .foregroundStyle(viewModel.correlationColor(correlation.correlationStrength))
                            .imageScale(.large)
                        
                        Text("\(Int(abs(correlation.correlationStrength) * 100))%")
                            .font(AppleDesignSystem.Typography.caption2)
                            .bold()
                    }
                }
                
                // Correlation description
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(correlation.description)
                            .font(AppleDesignSystem.Typography.headline)
                        
                        if correlation.confidence > 0.95 {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AppleDesignSystem.SystemPalette.yellow)
                                .imageScale(.small)
                                .help("High confidence (p < 0.01)")
                        } else if correlation.confidence > 0.9 {
                            Image(systemName: "star")
                                .foregroundStyle(AppleDesignSystem.SystemPalette.yellow)
                                .imageScale(.small)
                                .help("Significant (p < 0.05)")
                        }
                    }
                    
                    Text("Students weak in \(correlation.sourceComponent) are \(correlation.strengthDescription) likely to struggle with \(correlation.targetComponent)")
                        .font(AppleDesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        Label(correlation.confidenceDescription, systemImage: "checkmark.shield")
                            .font(AppleDesignSystem.Typography.caption)
                            .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                        
                        Label("n = \(correlation.sampleSize)", systemImage: "person.3")
                            .font(AppleDesignSystem.Typography.caption)
                            .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                        
                        if correlation.targetGrade > correlation.sourceGrade {
                            Label("\(correlation.targetGrade - correlation.sourceGrade) year prediction",
                                  systemImage: "calendar")
                                .font(AppleDesignSystem.Typography.caption)
                                .foregroundStyle(AppleDesignSystem.SystemPalette.purple)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 8) {
                    Button(action: onGenerateILP) {
                        Label("Generate ILP", systemImage: "doc.badge.plus")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .help("Generate an Individual Learning Plan based on this correlation")
                    
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detailed Analysis")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Statistical Metrics")
                                .font(AppleDesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                            
                            LabeledContent("Pearson Coefficient", value: String(format: "%.3f", correlation.correlationStrength))
                            LabeledContent("P-Value", value: String(format: "%.4f", correlation.pValue))
                            LabeledContent("Sample Size", value: "\(correlation.sampleSize) students")
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Intervention Impact")
                                .font(AppleDesignSystem.Typography.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("Early intervention in Grade \(correlation.sourceGrade) can prevent:")
                                .font(AppleDesignSystem.Typography.caption)
                            Text("• \(Int(abs(correlation.correlationStrength) * 100))% risk of Grade \(correlation.targetGrade) struggles")
                                .font(AppleDesignSystem.Typography.caption)
                                .foregroundStyle(AppleDesignSystem.SystemPalette.orange)
                            Text("• Potential \(correlation.targetGrade - correlation.sourceGrade)-year learning gap")
                                .font(AppleDesignSystem.Typography.caption)
                                .foregroundStyle(AppleDesignSystem.SystemPalette.red)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.correlationColor(correlation.correlationStrength).opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Student Prediction View
/// StudentPredictionView represents...
struct StudentPredictionView: View {
    /// viewModel property
    let viewModel: PredictiveCorrelationViewModel
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            /// student property
            if let student = viewModel.selectedStudent {
                // Student header
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(student.firstName) \(student.lastName)")
                            .font(.largeTitle)
                            .bold()
                        Text("MSIS: \(student.msis) • Grade \(student.testGrade)")
                            .font(AppleDesignSystem.Typography.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            /// prediction property
                            if let prediction = viewModel.studentPredictions.first {
                                // Generate ILP for the highest risk prediction
                                // This would need to be implemented
                            }
                        }
                    }) {
                        Label("Generate Comprehensive ILP", systemImage: "doc.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                
                // Predictions list
                if viewModel.studentPredictions.isEmpty {
                    ContentUnavailableView(
                        "No Predictions Available",
                        systemImage: "chart.line.downtrend",
                        description: Text("No future struggles predicted for this student")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.studentPredictions) { prediction in
                                StudentPredictionCard(prediction: prediction)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Student Prediction Card
/// StudentPredictionCard represents...
struct StudentPredictionCard: View {
    /// prediction property
    let prediction: FuturePrediction
    
    /// body property
    var body: some View {
        HStack {
            // Risk indicator
            VStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(prediction.riskColor)
                    .imageScale(.large)
                
                Text(prediction.riskLevel)
                    .font(AppleDesignSystem.Typography.caption)
                    .foregroundStyle(prediction.riskColor)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Weakness: \(prediction.currentWeakness)")
                    .font(AppleDesignSystem.Typography.headline)
                
                Text("Predicted Struggle: \(prediction.predictedStruggle) in Grade \(prediction.predictedGrade)")
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Label("\(Int(prediction.likelihood * 100))% likely", systemImage: "chart.line.uptrend.xyaxis")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(prediction.riskColor)
                    
                    Label("In \(prediction.timeframe)", systemImage: "calendar")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(AppleDesignSystem.SystemPalette.purple)
                    
                    Label("\(Int(prediction.confidence * 100))% confidence", systemImage: "checkmark.shield")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "arrow.right.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ILP Preview View
/// ILPPreviewView represents...
struct ILPPreviewView: View {
    /// ilp property
    let ilp: IndividualLearningPlan
    /// onDismiss property
    let onDismiss: () -> Void
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Generated Individual Learning Plan")
                        .font(.largeTitle)
                        .bold()
                    Text("\(ilp.studentInfo.name) • Grade \(ilp.studentInfo.grade)")
                        .font(AppleDesignSystem.Typography.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {}) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Performance summary
                    GroupBox("Performance Summary") {
                        VStack(alignment: .leading) {
                            Text("Overall Score: \(ilp.performanceSummary.overallScore, specifier: "%.1f")")
                                .padding(.vertical, 2)
                            Text("Proficiency: \(ilp.performanceSummary.proficiencyLevel.rawValue)")
                                .padding(.vertical, 2)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Focus areas
                    GroupBox("Priority Focus Areas") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(ilp.focusAreas) { area in
                                HStack {
                                    Circle()
                                        .fill(severityColor(area.severity))
                                        .frame(width: 8, height: 8)
                                    
                                    VStack(alignment: .leading) {
                                        Text(area.subject)
                                            .font(AppleDesignSystem.Typography.headline)
                                        Text(area.description)
                                            .font(AppleDesignSystem.Typography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Learning objectives
                    if !ilp.learningObjectives.isEmpty {
                        GroupBox("Learning Objectives") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(ilp.learningObjectives.prefix(5)) { objective in
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text(objective.description)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Milestones
                    if !ilp.milestones.isEmpty {
                        GroupBox("9-Week Milestones") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(ilp.milestones.prefix(3)) { milestone in
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                                        VStack(alignment: .leading) {
                                            Text(milestone.title)
                                                .font(AppleDesignSystem.Typography.headline)
                                            Text("Target: \(milestone.targetDate, format: .dateTime.month().day())")
                                                .font(AppleDesignSystem.Typography.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func severityColor(_ severity: Double) -> Color {
        switch severity {
        case 0.8...:
            return AppleDesignSystem.SystemPalette.red
        case 0.6..<0.8:
            return AppleDesignSystem.SystemPalette.orange
        case 0.4..<0.6:
            return AppleDesignSystem.SystemPalette.yellow
        default:
            return AppleDesignSystem.SystemPalette.green
        }
    }
}

// MARK: - Student Search View
/// StudentSearchView represents...
struct StudentSearchView: View {
    /// viewModel property
    let viewModel: PredictiveCorrelationViewModel
    /// dismiss property
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    /// body property
    var body: some View {
        VStack {
            Text("Select Student for Analysis")
                .font(.largeTitle)
                .bold()
                .padding()
            
            TextField("Search by name or MSIS...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            // Placeholder for student list
            List {
                ForEach(0..<5) { index in
                    Button(action: {
                        // In real implementation, this would select an actual student
                        /// sampleStudent property
                        let sampleStudent = StudentAssessmentData(
                            studentInfo: StudentAssessmentData.StudentInfo(
                                msis: "MS00\(index)",
                                name: "Sample Student \(index + 1)",
                                school: "Sample School",
                                district: "Sample District"
                            ),
                            year: 2025,
                            grade: 5 + index,
                            assessments: []
                        )
                        Task {
                            await viewModel.loadStudentPredictions(sampleStudent)
                        }
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Sample Student \(index + 1)")
                                    .font(AppleDesignSystem.Typography.headline)
                                Text("MSIS: MS00\(index) • Grade \(5 + index)")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack {
                Button("Cancel", action: { dismiss() })
                    .keyboardShortcut(.escape)
            }
            .padding()
        }
    }
}

// MARK: - Empty State View
/// EmptyStateView represents...
struct EmptyStateView: View {
    /// body property
    var body: some View {
        ContentUnavailableView(
            "Select a Category",
            systemImage: "chart.scatter",
            description: Text("Choose a reporting category from the sidebar to view predictive correlations, or search for a specific student to see their predicted future struggles.")
        )
    }
}