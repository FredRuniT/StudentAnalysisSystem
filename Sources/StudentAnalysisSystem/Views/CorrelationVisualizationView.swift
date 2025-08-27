import SwiftUI
import Charts
import AnalysisCore
import StatisticalEngine
import ReportGeneration

struct CorrelationVisualizationView: View {
    @State private var correlationData: ComponentCorrelationMap?
    @State private var selectedGradeFilter: Int?
    @State private var selectedSubject: String = "All"
    @State private var minimumCorrelation: Double = 0.7
    @State private var showOnlySignificant = true
    @State private var topCorrelations: [CorrelationPair] = []
    @State private var crossGradeCorrelations: [CrossGradeCorrelation] = []
    @State private var isLoading = true
    @State private var selectedVisualization = "Top Correlations"
    
    struct CorrelationPair: Identifiable {
        let id = UUID()
        let source: String
        let target: String
        let correlation: Double
        let confidence: Double
        let sampleSize: Int
        let sourceGrade: Int
        let targetGrade: Int
    }
    
    struct CrossGradeCorrelation: Identifiable {
        let id = UUID()
        let earlyGrade: Int
        let laterGrade: Int
        let component: String
        let averageCorrelation: Double
        let count: Int
    }
    
    let visualizationTypes = ["Top Correlations", "Cross-Grade Patterns", "Predictive Pathways", "Heatmap"]
    let subjects = ["All", "MATH", "ELA", "ENGLISH_II", "ALGEBRA I", "BIOLOGY", "U.S. HISTORY"]
    let gradeOptions = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerView
            controlsView
            mainVisualizationView
            summaryStatisticsView
            Spacer()
        }
        .onAppear {
            loadCorrelationData()
        }
        .onChange(of: selectedSubject) { _ in filterData() }
        .onChange(of: selectedGradeFilter) { _ in filterData() }
        .onChange(of: minimumCorrelation) { _ in filterData() }
    }
    
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Component Correlation Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Analyzing \(formatNumber(623286)) correlations across \(formatNumber(1117)) unique components")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    var controlsView: some View {
        HStack(spacing: 20) {
            Picker("Visualization", selection: $selectedVisualization) {
                ForEach(visualizationTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 400)
            
            Spacer()
            
            Picker("Subject", selection: $selectedSubject) {
                ForEach(subjects, id: \.self) { subject in
                    Text(subject).tag(subject)
                }
            }
            .frame(width: 150)
            
            Picker("Grade", selection: $selectedGradeFilter) {
                Text("All Grades").tag(nil as Int?)
                ForEach(gradeOptions, id: \.self) { grade in
                    Text("Grade \(grade)").tag(grade as Int?)
                }
            }
            .frame(width: 120)
            
            VStack(alignment: .leading) {
                Text("Min Correlation: \(minimumCorrelation, specifier: "%.2f")")
                    .font(.caption)
                Slider(value: $minimumCorrelation, in: 0.3...1.0, step: 0.05)
                    .frame(width: 150)
            }
            
            Toggle("Significant Only", isOn: $showOnlySignificant)
        }
        .padding(.horizontal)
    }
    
    var mainVisualizationView: some View {
        Group {
            switch selectedVisualization {
            case "Top Correlations":
                topCorrelationsView
            case "Cross-Grade Patterns":
                crossGradePatternsView
            case "Predictive Pathways":
                predictivePathwaysView
            case "Heatmap":
                correlationHeatmapView
            default:
                EmptyView()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    var summaryStatisticsView: some View {
        let strongCount = topCorrelations.filter { $0.correlation > 0.7 }.count
        let veryStrongCount = topCorrelations.filter { $0.correlation > 0.85 }.count
        let crossGradeCount = crossGradeCorrelations.count
        let avgConfidence = topCorrelations.isEmpty ? 0 : Int((topCorrelations.map { $0.confidence }.reduce(0, +) / Double(topCorrelations.count)) * 100)
        
        return HStack(spacing: 40) {
            StatCard(title: "Strong Correlations", value: "\(strongCount)", subtitle: "r > 0.70")
            StatCard(title: "Very Strong", value: "\(veryStrongCount)", subtitle: "r > 0.85")
            StatCard(title: "Cross-Grade", value: "\(crossGradeCount)", subtitle: "Predictive")
            StatCard(title: "Avg Confidence", value: "\(avgConfidence)%", subtitle: "Statistical")
        }
        .padding(.horizontal)
    }
    
    var topCorrelationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strongest Component Correlations")
                .font(.headline)
            
            if !topCorrelations.isEmpty {
                Chart(topCorrelations.prefix(20)) { pair in
                    BarMark(
                        x: .value("Correlation", pair.correlation),
                        y: .value("Pair", "\(pair.source) → \(pair.target)")
                    )
                    .foregroundStyle(correlationColor(for: pair.correlation))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(String(format: "%.3f", pair.correlation))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .chartXScale(domain: minimumCorrelation...1.0)
                .frame(minHeight: 400)
            } else {
                Text("Loading correlation data...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
            }
        }
    }
    
    var crossGradePatternsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cross-Grade Predictive Patterns")
                .font(.headline)
            
            Text("How early grade performance predicts later outcomes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !crossGradeCorrelations.isEmpty {
                Chart(crossGradeCorrelations.prefix(15)) { correlation in
                    RectangleMark(
                        xStart: .value("Early Grade", correlation.earlyGrade),
                        xEnd: .value("Later Grade", correlation.laterGrade),
                        y: .value("Component", correlation.component)
                    )
                    .foregroundStyle(by: .value("Correlation", correlation.averageCorrelation))
                    .opacity(correlation.averageCorrelation)
                }
                .chartXScale(domain: 3...12)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let grade = value.as(Int.self) {
                                Text("Grade \(grade)")
                            }
                        }
                    }
                }
                .frame(minHeight: 400)
            } else {
                Text("Analyzing cross-grade patterns...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
            }
        }
    }
    
    var predictivePathwaysView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictive Learning Pathways")
                .font(.headline)
            
            Text("Component relationships that predict future success")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Pathway visualization showing how Grade 3 components predict Grade 8 outcomes
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(topCorrelations.filter { $0.targetGrade > $0.sourceGrade }.prefix(10)) { pair in
                        HStack(spacing: 12) {
                            // Source
                            VStack(alignment: .leading) {
                                Text("Grade \(pair.sourceGrade)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(pair.source)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            // Arrow with correlation
                            VStack {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(correlationColor(for: pair.correlation))
                                Text(String(format: "%.3f", pair.correlation))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Text("\(pair.sampleSize) students")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 80)
                            
                            // Target
                            VStack(alignment: .leading) {
                                Text("Grade \(pair.targetGrade)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(pair.target)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            Spacer()
                            
                            // Confidence indicator
                            VStack(alignment: .trailing) {
                                Text("Confidence")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(Int(pair.confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(pair.confidence > 0.8 ? .green : pair.confidence > 0.6 ? .orange : .red)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    var correlationHeatmapView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Correlation Heatmap")
                .font(.headline)
            
            Text("Component-to-component correlation matrix")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Simplified heatmap for top components
            Text("Full heatmap visualization coming soon...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
        }
    }
    
    func correlationColor(for value: Double) -> Color {
        switch value {
        case 0.85...1.0:
            return .green
        case 0.7..<0.85:
            return .blue
        case 0.5..<0.7:
            return .orange
        default:
            return .red
        }
    }
    
    func loadCorrelationData() {
        Task {
            // Load correlation data from the JSON file
            let outputURL = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlation_model.json")
            
            if let data = try? Data(contentsOf: outputURL) {
                // Parse the JSON - we'll extract top correlations
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let correlations = json["correlations"] as? [[String: Any]] {
                    
                    await MainActor.run {
                        parseCorrelations(correlations)
                        isLoading = false
                    }
                }
            }
        }
    }
    
    func parseCorrelations(_ correlationsData: [[String: Any]]) {
        var pairs: [CorrelationPair] = []
        var crossGrade: [CrossGradeCorrelation] = []
        
        for correlationEntry in correlationsData.prefix(100) { // Process first 100 for performance
            guard let source = correlationEntry["sourceComponent"] as? [String: Any],
                  let correlationsList = correlationEntry["correlations"] as? [[String: Any]] else { continue }
            
            let sourceGrade = source["grade"] as? Int ?? 0
            let sourceSubject = source["subject"] as? String ?? ""
            let sourceComponent = source["component"] as? String ?? ""
            let _ = source["testProvider"] as? String ?? ""
            let sourceName = "G\(sourceGrade)_\(sourceSubject)_\(sourceComponent)"
            
            for correlation in correlationsList {
                guard let target = correlation["target"] as? [String: Any],
                      let correlationValue = correlation["correlation"] as? Double,
                      let confidence = correlation["confidence"] as? Double,
                      let sampleSize = correlation["sampleSize"] as? Int,
                      correlationValue > minimumCorrelation else { continue }
                
                let targetGrade = target["grade"] as? Int ?? 0
                let targetSubject = target["subject"] as? String ?? ""
                let targetComponent = target["component"] as? String ?? ""
                let targetName = "G\(targetGrade)_\(targetSubject)_\(targetComponent)"
                
                let pair = CorrelationPair(
                    source: sourceName,
                    target: targetName,
                    correlation: correlationValue,
                    confidence: confidence,
                    sampleSize: sampleSize,
                    sourceGrade: sourceGrade,
                    targetGrade: targetGrade
                )
                pairs.append(pair)
                
                // Track cross-grade correlations
                if targetGrade > sourceGrade && correlationValue > 0.7 {
                    if let existing = crossGrade.firstIndex(where: { 
                        $0.earlyGrade == sourceGrade && 
                        $0.laterGrade == targetGrade && 
                        $0.component == sourceSubject 
                    }) {
                        // Update existing
                        let updated = crossGrade[existing]
                        let newAvg = (updated.averageCorrelation * Double(updated.count) + correlationValue) / Double(updated.count + 1)
                        crossGrade[existing] = CrossGradeCorrelation(
                            earlyGrade: sourceGrade,
                            laterGrade: targetGrade,
                            component: sourceSubject,
                            averageCorrelation: newAvg,
                            count: updated.count + 1
                        )
                    } else {
                        crossGrade.append(CrossGradeCorrelation(
                            earlyGrade: sourceGrade,
                            laterGrade: targetGrade,
                            component: sourceSubject,
                            averageCorrelation: correlationValue,
                            count: 1
                        ))
                    }
                }
            }
        }
        
        // Sort by correlation strength
        topCorrelations = pairs.sorted { $0.correlation > $1.correlation }
        crossGradeCorrelations = crossGrade.sorted { $0.averageCorrelation > $1.averageCorrelation }
    }
    
    func filterData() {
        // Re-filter based on current settings
        loadCorrelationData()
    }
    
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 120)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    CorrelationVisualizationView()
}