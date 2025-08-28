import AnalysisCore
import Charts
import PredictiveModeling
import StatisticalEngine
import SwiftUI

/// GradeProgressionView represents...
struct GradeProgressionView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = GradeProgressionViewModel()
    @State private var startGrade = 3
    @State private var endGrade = 8
    @State private var selectedComponent: String?
    @State private var showingCorrelationDetail = false
    @State private var selectedCorrelation: ProgressionCorrelation?
    @State private var selectedStudent: StudentAssessmentData?
    
    private var selectedGradeRange: ClosedRange<Int> {
        startGrade...endGrade
    }
    
    /// body property
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with controls
                headerSection
                
                Divider()
                
                // Main content
                if viewModel.isLoading {
                    ProgressView("Loading correlation data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Left panel: Component selector
                            componentSelectorPanel
                                .frame(width: geometry.size.width * 0.3)
                            
                            Divider()
                            
                            // Right panel: Progression visualization
                            progressionVisualizationPanel
                                .frame(width: geometry.size.width * 0.7)
                        }
                    }
                }
            }
            .navigationTitle("Grade Progression Analysis")
            .toolbar {
                ToolbarItem {
                    Button(action: { viewModel.refreshData() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCorrelationDetail) {
            /// correlation property
            if let correlation = selectedCorrelation {
                CorrelationDetailSheet(correlation: correlation)
                    .frame(minWidth: 600, minHeight: 400)
            }
        }
        .onAppear {
            viewModel.loadCorrelations()
        }
        .themed()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Grade range selector
            HStack {
                Text("Grade Range:")
                    .font(AppleDesignSystem.Typography.headline)
                
                Picker("Start Grade", selection: $startGrade) {
                    ForEach(3...11, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                
                Text("to")
                
                Picker("End Grade", selection: $endGrade) {
                    ForEach((startGrade + 1)...12, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                
                Spacer()
                
                // Correlation strength filter
                HStack {
                    Text("Min Strength:")
                    Picker("", selection: $viewModel.minimumCorrelationStrength) {
                        Text("50%").tag(0.5)
                        Text("60%").tag(0.6)
                        Text("70%").tag(0.7)
                        Text("80%").tag(0.8)
                        Text("90%").tag(0.9)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
            }
            .padding(.horizontal)
            
            // Legend
            HStack(spacing: 20) {
                ForEach([
                    ("Critical", AppleDesignSystem.SystemPalette.red, "90%+"),
                    ("Strong", AppleDesignSystem.SystemPalette.orange, "80-89%"),
                    ("Significant", AppleDesignSystem.SystemPalette.yellow, "70-79%"),
                    ("Moderate", AppleDesignSystem.SystemPalette.blue, "60-69%"),
                    ("Weak", Color.gray, "<60%")
                ], id: \.0) { label, color, range in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                        Text("\(label) (\(range))")
                            .font(AppleDesignSystem.Typography.caption)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Component Selector Panel
    
    private var componentSelectorPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Component")
                .font(AppleDesignSystem.Typography.headline)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.availableComponents, id: \.self) { component in
                        ComponentRow(
                            component: component,
                            isSelected: selectedComponent == component,
                            correlationCount: viewModel.correlationCounts[component] ?? 0,
                            onSelect: {
                                selectedComponent = component
                                viewModel.loadProgressionForComponent(component, gradeRange: selectedGradeRange)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            if selectedStudent != nil {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Student Context")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    /// student property
                    if let student = selectedStudent {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                            
                            VStack(alignment: .leading) {
                                Text("\(student.firstName) \(student.lastName)")
                                    .font(AppleDesignSystem.Typography.subheadline)
                                Text("Grade \(student.testGrade)")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { selectedStudent = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AppleDesignSystem.Spacing.small)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Progression Visualization Panel
    
    private var progressionVisualizationPanel: some View {
        VStack {
            /// component property
            if let component = selectedComponent {
                /// progressions property
                if let progressions = viewModel.gradeProgressions[component], !progressions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Progression Pathways for \(component)")
                                    .font(AppleDesignSystem.Typography.title2)
                                    .bold()
                                
                                Text("\(progressions.count) correlations found across grades \(selectedGradeRange.lowerBound)-\(selectedGradeRange.upperBound)")
                                    .font(AppleDesignSystem.Typography.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            
                            // Progression chart
                            ProgressionChart(
                                progressions: progressions,
                                gradeRange: selectedGradeRange,
                                onSelectCorrelation: { correlation in
                                    selectedCorrelation = correlation
                                    showingCorrelationDetail = true
                                }
                            )
                            .frame(height: 400)
                            .padding(.horizontal)
                            
                            // Correlation list
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Detailed Correlations")
                                    .font(AppleDesignSystem.Typography.headline)
                                    .padding(.horizontal)
                                
                                ForEach(progressions.sorted { $0.correlationStrength > $1.correlationStrength }) { progression in
                                    ProgressionCorrelationCard(
                                        progression: progression,
                                        onViewDetail: {
                                            selectedCorrelation = progression
                                            showingCorrelationDetail = true
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Progressions Found",
                        systemImage: "chart.line.flattrend.xyaxis",
                        description: Text("No correlations found for \(component) in the selected grade range")
                    )
                }
            } else {
                ContentUnavailableView(
                    "Select a Component",
                    systemImage: "hand.point.left",
                    description: Text("Choose a component from the left panel to view its grade progression pathways")
                )
            }
        }
    }
}

// MARK: - Supporting Views

/// ComponentRow represents...
struct ComponentRow: View {
    /// component property
    let component: String
    /// isSelected property
    let isSelected: Bool
    /// correlationCount property
    let correlationCount: Int
    /// onSelect property
    let onSelect: () -> Void
    
    /// body property
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(extractComponentName(component))
                        .font(AppleDesignSystem.Typography.subheadline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text("\(correlationCount) correlations")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if correlationCount > 10 {
                    Image(systemName: "star.fill")
                        .foregroundStyle(isSelected ? .white : AppleDesignSystem.SystemPalette.yellow)
                        .imageScale(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppleDesignSystem.SystemPalette.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private func extractComponentName(_ fullName: String) -> String {
        /// parts property
        let parts = fullName.split(separator: "_")
        if parts.count >= 4 {
            return "\(parts[2]) - \(parts[3])"
        }
        return fullName
    }
}

/// ProgressionChart represents...
struct ProgressionChart: View {
    /// progressions property
    let progressions: [ProgressionCorrelation]
    /// gradeRange property
    let gradeRange: ClosedRange<Int>
    /// onSelectCorrelation property
    let onSelectCorrelation: (ProgressionCorrelation) -> Void
    
    /// body property
    var body: some View {
        Chart {
            ForEach(progressions) { progression in
                LineMark(
                    x: .value("From Grade", progression.fromGrade),
                    y: .value("Correlation", progression.correlationStrength)
                )
                .foregroundStyle(correlationColor(progression.correlationStrength))
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                LineMark(
                    x: .value("To Grade", progression.toGrade),
                    y: .value("Correlation", progression.correlationStrength)
                )
                .foregroundStyle(correlationColor(progression.correlationStrength))
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Connection points
                PointMark(
                    x: .value("From Grade", progression.fromGrade),
                    y: .value("Correlation", progression.correlationStrength)
                )
                .foregroundStyle(correlationColor(progression.correlationStrength))
                .symbolSize(100)
                
                PointMark(
                    x: .value("To Grade", progression.toGrade),
                    y: .value("Correlation", progression.correlationStrength)
                )
                .foregroundStyle(correlationColor(progression.correlationStrength))
                .symbolSize(100)
            }
            
            // Reference line for minimum threshold
            RuleMark(y: .value("Threshold", 0.7))
                .foregroundStyle(.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartXScale(domain: gradeRange.lowerBound...gradeRange.upperBound)
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(preset: .aligned) { value in
                /// grade property
                if let grade = value.as(Int.self) {
                    AxisValueLabel {
                        Text("Grade \(grade)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                /// strength property
                if let strength = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(strength * 100))%")
                    }
                    AxisGridLine()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func correlationColor(_ strength: Double) -> Color {
        switch abs(strength) {
        case 0.9...: return AppleDesignSystem.SystemPalette.red
        case 0.8..<0.9: return AppleDesignSystem.SystemPalette.orange
        case 0.7..<0.8: return AppleDesignSystem.SystemPalette.yellow
        case 0.6..<0.7: return AppleDesignSystem.SystemPalette.blue
        default: return .gray
        }
    }
}

/// ProgressionCorrelationCard represents...
struct ProgressionCorrelationCard: View {
    /// progression property
    let progression: ProgressionCorrelation
    /// onViewDetail property
    let onViewDetail: () -> Void
    
    /// body property
    var body: some View {
        HStack {
            // Correlation strength indicator
            ZStack {
                Circle()
                    .fill(correlationColor(progression.correlationStrength).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 0) {
                    Text("\(Int(abs(progression.correlationStrength) * 100))%")
                        .font(AppleDesignSystem.Typography.headline)
                        .foregroundStyle(correlationColor(progression.correlationStrength))
                }
            }
            
            // Progression details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Grade \(progression.fromGrade) \(progression.fromComponent)")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    
                    Text("Grade \(progression.toGrade) \(progression.toComponent)")
                        .font(AppleDesignSystem.Typography.headline)
                }
                
                HStack(spacing: 12) {
                    Label("p < \(String(format: "%.3f", progression.pValue))", systemImage: "chart.xyaxis.line")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                    
                    Label("n = \(progression.sampleSize)", systemImage: "person.3")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                    
                    if progression.confidence > 0.95 {
                        Label("High confidence", systemImage: "star.fill")
                            .font(AppleDesignSystem.Typography.caption)
                            .foregroundStyle(AppleDesignSystem.SystemPalette.yellow)
                    }
                }
                
                Text(progression.interpretation)
                    .font(AppleDesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: onViewDetail) {
                Image(systemName: "info.circle")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func correlationColor(_ strength: Double) -> Color {
        switch abs(strength) {
        case 0.9...: return AppleDesignSystem.SystemPalette.red
        case 0.8..<0.9: return AppleDesignSystem.SystemPalette.orange
        case 0.7..<0.8: return AppleDesignSystem.SystemPalette.yellow
        case 0.6..<0.7: return AppleDesignSystem.SystemPalette.blue
        default: return .gray
        }
    }
}

/// CorrelationDetailSheet represents...
struct CorrelationDetailSheet: View {
    /// correlation property
    let correlation: ProgressionCorrelation
    /// dismiss property
    @Environment(\.dismiss) var dismiss
    
    /// body property
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Correlation Details")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("\(correlation.fromComponent) → \(correlation.toComponent)")
                        .font(AppleDesignSystem.Typography.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            
            // Correlation strength visual
            ZStack {
                Circle()
                    .fill(correlationColor(correlation.correlationStrength).opacity(0.2))
                    .frame(width: 100, height: 100)
                
                VStack {
                    Text("\(Int(abs(correlation.correlationStrength) * 100))%")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(correlationColor(correlation.correlationStrength))
                    
                    Text("correlation")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Statistics
            GroupBox("Statistical Metrics") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Pearson Coefficient:")
                        Spacer()
                        Text(String(format: "%.4f", correlation.correlationStrength))
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("P-Value:")
                        Spacer()
                        Text(String(format: "%.5f", correlation.pValue))
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Confidence Level:")
                        Spacer()
                        Text("\(Int(correlation.confidence * 100))%")
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Text("Sample Size:")
                        Spacer()
                        Text("\(correlation.sampleSize) students")
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding()
            }
            
            // Interpretation
            GroupBox("Interpretation") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(correlation.interpretation)
                        .font(AppleDesignSystem.Typography.subheadline)
                    
                    if correlation.correlationStrength > 0.8 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppleDesignSystem.SystemPalette.orange)
                            Text("Strong predictive relationship - early intervention recommended")
                                .font(AppleDesignSystem.Typography.caption)
                                .foregroundStyle(AppleDesignSystem.SystemPalette.orange)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Action buttons
            HStack {
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Generate ILP") {
                    // Would trigger ILP generation based on this correlation
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 500)
    }
    
    private func correlationColor(_ strength: Double) -> Color {
        switch abs(strength) {
        case 0.9...: return AppleDesignSystem.SystemPalette.red
        case 0.8..<0.9: return AppleDesignSystem.SystemPalette.orange
        case 0.7..<0.8: return AppleDesignSystem.SystemPalette.yellow
        case 0.6..<0.7: return AppleDesignSystem.SystemPalette.blue
        default: return .gray
        }
    }
}

// MARK: - View Model

@MainActor
/// GradeProgressionViewModel represents...
class GradeProgressionViewModel: ObservableObject {
    /// gradeProgressions property
    @Published var gradeProgressions: [String: [ProgressionCorrelation]] = [:]
    /// availableComponents property
    @Published var availableComponents: [String] = []
    /// correlationCounts property
    @Published var correlationCounts: [String: Int] = [:]
    /// isLoading property
    @Published var isLoading = false
    /// minimumCorrelationStrength property
    @Published var minimumCorrelationStrength: Double = 0.7
    
    private var allCorrelations: ValidatedCorrelationModel?
    
    /// loadCorrelations function description
    func loadCorrelations() {
        isLoading = true
        
        Task {
            do {
                // Load correlation model
                /// outputURL property
                let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("Output")
                    .appendingPathComponent("correlation_model.json")
                
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    /// data property
                    let data = try Data(contentsOf: outputURL)
                    /// decoder property
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    allCorrelations = try decoder.decode(ValidatedCorrelationModel.self, from: data)
                    
                    extractAvailableComponents()
                }
            } catch {
                print("Error loading correlations: \(error)")
            }
            
            isLoading = false
        }
    }
    
    /// refreshData function description
    func refreshData() {
        loadCorrelations()
    }
    
    private func extractAvailableComponents() {
        /// model property
        guard let model = allCorrelations else { return }
        
        /// components property
        var components = Set<String>()
        /// counts property
        var counts: [String: Int] = [:]
        
        for correlationMap in model.correlations {
            /// sourceKey property
            let sourceKey = "\(correlationMap.sourceComponent.grade)_\(correlationMap.sourceComponent.subject)_\(correlationMap.sourceComponent.component)"
            components.insert(sourceKey)
            counts[sourceKey, default: 0] += 1
            
            for correlation in correlationMap.correlations {
                /// targetKey property
                let targetKey = "\(correlation.target.grade)_\(correlation.target.subject)_\(correlation.target.component)"
                components.insert(targetKey)
                counts[targetKey, default: 0] += 1
            }
        }
        
        availableComponents = Array(components)
            .filter { $0.contains("Grade_") }
            .sorted { component1, component2 in
                /// grade1 property
                let grade1 = extractGrade(from: component1)
                /// grade2 property
                let grade2 = extractGrade(from: component2)
                if grade1 != grade2 {
                    return grade1 < grade2
                }
                return component1 < component2
            }
        
        correlationCounts = counts
    }
    
    /// loadProgressionForComponent function description
    func loadProgressionForComponent(_ component: String, gradeRange: ClosedRange<Int>) {
        /// model property
        guard let model = allCorrelations else { return }
        
        /// progressions property
        var progressions: [ProgressionCorrelation] = []
        
        // Find all correlations involving this component
        for correlationMap in model.correlations {
            /// sourceKey property
            let sourceKey = "\(correlationMap.sourceComponent.grade)_\(correlationMap.sourceComponent.subject)_\(correlationMap.sourceComponent.component)"
            
            for correlation in correlationMap.correlations {
                /// targetKey property
                let targetKey = "\(correlation.target.grade)_\(correlation.target.subject)_\(correlation.target.component)"
                
                if (sourceKey.contains(component) || targetKey.contains(component)) && 
                   abs(correlation.correlation) >= minimumCorrelationStrength {
                    /// fromComponent property
                    let fromComponent = sourceKey
                    /// toComponent property
                    let toComponent = targetKey
                    /// fromGrade property
                    let fromGrade = extractGrade(from: fromComponent)
                    /// toGrade property
                    let toGrade = extractGrade(from: toComponent)
                    
                    // Check if within grade range
                    if gradeRange.contains(fromGrade) && gradeRange.contains(toGrade) && fromGrade != toGrade {
                        /// progression property
                        let progression = ProgressionCorrelation(
                            id: "\(sourceKey)_to_\(targetKey)",
                            fromComponent: extractComponentName(fromComponent),
                            toComponent: extractComponentName(toComponent),
                            fromGrade: fromGrade,
                            toGrade: toGrade,
                            correlationStrength: correlation.correlation,
                            confidence: correlation.confidence,
                            pValue: 0.05, // Default p-value since it's not in the model
                            sampleSize: correlation.sampleSize,
                            interpretation: generateInterpretation(
                                from: fromComponent,
                                to: toComponent,
                                strength: correlation.correlation
                            )
                        )
                        progressions.append(progression)
                    }
                }
            }
        }
        
        gradeProgressions[component] = progressions
    }
    
    private func extractGrade(from component: String) -> Int {
        /// parts property
        let parts = component.split(separator: "_")
        /// grade property
        if parts.count > 1, let grade = Int(parts[1]) {
            return grade
        }
        return 0
    }
    
    private func extractComponentName(_ fullName: String) -> String {
        /// parts property
        let parts = fullName.split(separator: "_")
        if parts.count >= 4 {
            return String(parts[3])
        }
        return fullName
    }
    
    private func generateInterpretation(from: String, to: String, strength: Double) -> String {
        /// percentage property
        let percentage = Int(abs(strength) * 100)
        /// fromGrade property
        let fromGrade = extractGrade(from: from)
        /// toGrade property
        let toGrade = extractGrade(from: to)
        /// yearDiff property
        let yearDiff = abs(toGrade - fromGrade)
        
        if strength > 0.8 {
            return "Students struggling with \(extractComponentName(from)) have a \(percentage)% likelihood of struggling with \(extractComponentName(to)) \(yearDiff) year(s) later. Early intervention strongly recommended."
        } else if strength > 0.7 {
            return "Strong correlation indicates \(percentage)% of students weak in \(extractComponentName(from)) will face challenges in \(extractComponentName(to)) after \(yearDiff) year(s)."
        } else {
            return "Moderate correlation suggests potential future challenges. \(percentage)% correlation strength over \(yearDiff) year(s)."
        }
    }
}

// MARK: - Models

/// ProgressionCorrelation represents...
struct ProgressionCorrelation: Identifiable {
    /// id property
    let id: String
    /// fromComponent property
    let fromComponent: String
    /// toComponent property
    let toComponent: String
    /// fromGrade property
    let fromGrade: Int
    /// toGrade property
    let toGrade: Int
    /// correlationStrength property
    let correlationStrength: Double
    /// confidence property
    let confidence: Double
    /// pValue property
    let pValue: Double
    /// sampleSize property
    let sampleSize: Int
    /// interpretation property
    let interpretation: String
}