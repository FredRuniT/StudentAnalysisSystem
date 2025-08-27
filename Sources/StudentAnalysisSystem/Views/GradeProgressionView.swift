import SwiftUI
import Charts
import AnalysisCore
import PredictiveModeling
import StatisticalEngine

struct GradeProgressionView: View {
    @StateObject private var viewModel = GradeProgressionViewModel()
    @State private var selectedGradeRange = 3...8
    @State private var selectedComponent: String?
    @State private var showingCorrelationDetail = false
    @State private var selectedCorrelation: ProgressionCorrelation?
    @State private var selectedStudent: StudentAssessmentData?
    
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
            if let correlation = selectedCorrelation {
                CorrelationDetailSheet(correlation: correlation)
                    .frame(minWidth: 600, minHeight: 400)
            }
        }
        .onAppear {
            viewModel.loadCorrelations()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Grade range selector
            HStack {
                Text("Grade Range:")
                    .font(.headline)
                
                Picker("Start Grade", selection: $selectedGradeRange.lowerBound) {
                    ForEach(3...11, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                
                Text("to")
                
                Picker("End Grade", selection: $selectedGradeRange.upperBound) {
                    ForEach((selectedGradeRange.lowerBound + 1)...12, id: \.self) { grade in
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
                    ("Critical", Color.red, "90%+"),
                    ("Strong", Color.orange, "80-89%"),
                    ("Significant", Color.yellow, "70-79%"),
                    ("Moderate", Color.blue, "60-69%"),
                    ("Weak", Color.gray, "<60%")
                ], id: \.0) { label, color, range in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                        Text("\(label) (\(range))")
                            .font(.caption)
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
                .font(.headline)
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
                        .font(.headline)
                    
                    if let student = selectedStudent {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("\(student.firstName) \(student.lastName)")
                                    .font(.subheadline)
                                Text("Grade \(student.testGrade)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { selectedStudent = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
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
            if let component = selectedComponent {
                if let progressions = viewModel.gradeProgressions[component], !progressions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Progression Pathways for \(component)")
                                    .font(.title2)
                                    .bold()
                                
                                Text("\(progressions.count) correlations found across grades \(selectedGradeRange.lowerBound)-\(selectedGradeRange.upperBound)")
                                    .font(.subheadline)
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
                                    .font(.headline)
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

struct ComponentRow: View {
    let component: String
    let isSelected: Bool
    let correlationCount: Int
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(extractComponentName(component))
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text("\(correlationCount) correlations")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if correlationCount > 10 {
                    Image(systemName: "star.fill")
                        .foregroundStyle(isSelected ? .white : .yellow)
                        .imageScale(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private func extractComponentName(_ fullName: String) -> String {
        let parts = fullName.split(separator: "_")
        if parts.count >= 4 {
            return "\(parts[2]) - \(parts[3])"
        }
        return fullName
    }
}

struct ProgressionChart: View {
    let progressions: [ProgressionCorrelation]
    let gradeRange: ClosedRange<Int>
    let onSelectCorrelation: (ProgressionCorrelation) -> Void
    
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
                if let grade = value.as(Int.self) {
                    AxisValueLabel {
                        Text("Grade \(grade)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
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
        case 0.9...: return .red
        case 0.8..<0.9: return .orange
        case 0.7..<0.8: return .yellow
        case 0.6..<0.7: return .blue
        default: return .gray
        }
    }
}

struct ProgressionCorrelationCard: View {
    let progression: ProgressionCorrelation
    let onViewDetail: () -> Void
    
    var body: some View {
        HStack {
            // Correlation strength indicator
            ZStack {
                Circle()
                    .fill(correlationColor(progression.correlationStrength).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 0) {
                    Text("\(Int(abs(progression.correlationStrength) * 100))%")
                        .font(.headline)
                        .foregroundStyle(correlationColor(progression.correlationStrength))
                }
            }
            
            // Progression details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Grade \(progression.fromGrade) \(progression.fromComponent)")
                        .font(.headline)
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    
                    Text("Grade \(progression.toGrade) \(progression.toComponent)")
                        .font(.headline)
                }
                
                HStack(spacing: 12) {
                    Label("p < \(String(format: "%.3f", progression.pValue))", systemImage: "chart.xyaxis.line")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    Label("n = \(progression.sampleSize)", systemImage: "person.3")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    if progression.confidence > 0.95 {
                        Label("High confidence", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(progression.interpretation)
                    .font(.caption)
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
        case 0.9...: return .red
        case 0.8..<0.9: return .orange
        case 0.7..<0.8: return .yellow
        case 0.6..<0.7: return .blue
        default: return .gray
        }
    }
}

struct CorrelationDetailSheet: View {
    let correlation: ProgressionCorrelation
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Correlation Details")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("\(correlation.fromComponent) → \(correlation.toComponent)")
                        .font(.headline)
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
                        .font(.caption)
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
                        .font(.subheadline)
                    
                    if correlation.correlationStrength > 0.8 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Strong predictive relationship - early intervention recommended")
                                .font(.caption)
                                .foregroundStyle(.orange)
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
        case 0.9...: return .red
        case 0.8..<0.9: return .orange
        case 0.7..<0.8: return .yellow
        case 0.6..<0.7: return .blue
        default: return .gray
        }
    }
}

// MARK: - View Model

@MainActor
class GradeProgressionViewModel: ObservableObject {
    @Published var gradeProgressions: [String: [ProgressionCorrelation]] = [:]
    @Published var availableComponents: [String] = []
    @Published var correlationCounts: [String: Int] = [:]
    @Published var isLoading = false
    @Published var minimumCorrelationStrength: Double = 0.7
    
    private var allCorrelations: ValidatedCorrelationModel?
    
    func loadCorrelations() {
        isLoading = true
        
        Task {
            do {
                // Load correlation model
                let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("Output")
                    .appendingPathComponent("correlation_model.json")
                
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    let data = try Data(contentsOf: outputURL)
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
    
    func refreshData() {
        loadCorrelations()
    }
    
    private func extractAvailableComponents() {
        guard let model = allCorrelations else { return }
        
        var components = Set<String>()
        var counts: [String: Int] = [:]
        
        for (key, _) in model.correlations {
            let parts = key.split(separator: "_").map(String.init)
            if parts.count >= 2 {
                components.insert(parts[0])
                components.insert(parts[1])
                
                counts[parts[0], default: 0] += 1
                counts[parts[1], default: 0] += 1
            }
        }
        
        availableComponents = Array(components)
            .filter { $0.contains("Grade_") }
            .sorted { component1, component2 in
                let grade1 = extractGrade(from: component1)
                let grade2 = extractGrade(from: component2)
                if grade1 != grade2 {
                    return grade1 < grade2
                }
                return component1 < component2
            }
        
        correlationCounts = counts
    }
    
    func loadProgressionForComponent(_ component: String, gradeRange: ClosedRange<Int>) {
        guard let model = allCorrelations else { return }
        
        var progressions: [ProgressionCorrelation] = []
        
        // Find all correlations involving this component
        for (key, correlation) in model.correlations {
            if key.contains(component) && abs(correlation.coefficient) >= minimumCorrelationStrength {
                let parts = key.split(separator: "_").map(String.init)
                if parts.count >= 2 {
                    let fromComponent = parts[0]
                    let toComponent = parts[1]
                    let fromGrade = extractGrade(from: fromComponent)
                    let toGrade = extractGrade(from: toComponent)
                    
                    // Check if within grade range
                    if gradeRange.contains(fromGrade) && gradeRange.contains(toGrade) && fromGrade != toGrade {
                        let progression = ProgressionCorrelation(
                            id: key,
                            fromComponent: extractComponentName(fromComponent),
                            toComponent: extractComponentName(toComponent),
                            fromGrade: fromGrade,
                            toGrade: toGrade,
                            correlationStrength: correlation.coefficient,
                            confidence: correlation.confidence ?? 0,
                            pValue: correlation.pValue,
                            sampleSize: correlation.sampleSize,
                            interpretation: generateInterpretation(
                                from: fromComponent,
                                to: toComponent,
                                strength: correlation.coefficient
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
        let parts = component.split(separator: "_")
        if parts.count > 1, let grade = Int(parts[1]) {
            return grade
        }
        return 0
    }
    
    private func extractComponentName(_ fullName: String) -> String {
        let parts = fullName.split(separator: "_")
        if parts.count >= 4 {
            return String(parts[3])
        }
        return fullName
    }
    
    private func generateInterpretation(from: String, to: String, strength: Double) -> String {
        let percentage = Int(abs(strength) * 100)
        let fromGrade = extractGrade(from: from)
        let toGrade = extractGrade(from: to)
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

struct ProgressionCorrelation: Identifiable {
    let id: String
    let fromComponent: String
    let toComponent: String
    let fromGrade: Int
    let toGrade: Int
    let correlationStrength: Double
    let confidence: Double
    let pValue: Double
    let sampleSize: Int
    let interpretation: String
}