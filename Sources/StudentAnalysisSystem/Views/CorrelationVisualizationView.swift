import AnalysisCore
import Charts
import ReportGeneration
import StatisticalEngine
import SwiftUI

/// CorrelationVisualizationView represents...
struct CorrelationVisualizationView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    @State private var correlationData: ComponentCorrelationMap?
    @State private var selectedGradeFilter: Int?
    @State private var selectedSubject: String = "All"
    @State private var minimumCorrelation: Double = 0.7
    @State private var showOnlySignificant = true
    @State private var topCorrelations: [CorrelationPair] = []
    @State private var crossGradeCorrelations: [CrossGradeCorrelation] = []
    @State private var isLoading = true
    @State private var selectedVisualization = "Top Correlations"
    
    /// CorrelationPair represents...
    struct CorrelationPair: Identifiable {
        /// id property
        let id = UUID()
        /// source property
        let source: String
        /// target property
        let target: String
        /// correlation property
        let correlation: Double
        /// confidence property
        let confidence: Double
        /// sampleSize property
        let sampleSize: Int
        /// sourceGrade property
        let sourceGrade: Int
        /// targetGrade property
        let targetGrade: Int
    }
    
    /// CrossGradeCorrelation represents...
    struct CrossGradeCorrelation: Identifiable {
        /// id property
        let id = UUID()
        /// earlyGrade property
        let earlyGrade: Int
        /// laterGrade property
        let laterGrade: Int
        /// component property
        let component: String
        /// averageCorrelation property
        let averageCorrelation: Double
        /// count property
        let count: Int
    }
    
    /// visualizationTypes property
    let visualizationTypes = ["Top Correlations", "Cross-Grade Patterns", "Predictive Pathways", "Heatmap"]
    /// subjects property
    let subjects = ["All", "MATH", "ELA", "ENGLISH_II", "ALGEBRA I", "BIOLOGY", "U.S. HISTORY"]
    /// gradeOptions property
    let gradeOptions = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    
    /// body property
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
        .onChange(of: selectedSubject) { filterData() }
        .onChange(of: selectedGradeFilter) { filterData() }
        .onChange(of: minimumCorrelation) { filterData() }
        .themed()
    }
    
    /// headerView property
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Component Correlation Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Analyzing \(formatNumber(623286)) correlations across \(formatNumber(1117)) unique components")
                .font(AppleDesignSystem.Typography.subheadline)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
        }
        .padding(.horizontal)
    }
    
    /// controlsView property
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
                    .font(AppleDesignSystem.Typography.caption)
                Slider(value: $minimumCorrelation, in: 0.3...1.0, step: 0.05)
                    .frame(width: 150)
            }
            
            Toggle("Significant Only", isOn: $showOnlySignificant)
        }
        .padding(.horizontal)
    }
    
    /// mainVisualizationView property
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
        .cornerRadius(AppleDesignSystem.Corners.medium)
        .padding(.horizontal)
    }
    
    /// summaryStatisticsView property
    var summaryStatisticsView: some View {
        /// strongCount property
        let strongCount = topCorrelations.filter { $0.correlation > 0.7 }.count
        /// veryStrongCount property
        let veryStrongCount = topCorrelations.filter { $0.correlation > 0.85 }.count
        /// crossGradeCount property
        let crossGradeCount = crossGradeCorrelations.count
        /// avgConfidence property
        let avgConfidence = topCorrelations.isEmpty ? 0 : Int((topCorrelations.map { $0.confidence }.reduce(0, +) / Double(topCorrelations.count)) * 100)
        
        return HStack(spacing: 40) {
            CorrelationStatCard(title: "Strong Correlations", value: "\(strongCount)", subtitle: "r > 0.70")
            CorrelationStatCard(title: "Very Strong", value: "\(veryStrongCount)", subtitle: "r > 0.85")
            CorrelationStatCard(title: "Cross-Grade", value: "\(crossGradeCount)", subtitle: "Predictive")
            CorrelationStatCard(title: "Avg Confidence", value: "\(avgConfidence)%", subtitle: "Statistical")
        }
        .padding(.horizontal)
    }
    
    /// topCorrelationsView property
    var topCorrelationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strongest Component Correlations")
                .font(AppleDesignSystem.Typography.headline)
            
            if !topCorrelations.isEmpty {
                Chart(topCorrelations.prefix(20)) { pair in
                    BarMark(
                        x: .value("Correlation", pair.correlation),
                        y: .value("Pair", "\(pair.source) → \(pair.target)")
                    )
                    .foregroundStyle(correlationColor(for: pair.correlation))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(String(format: "%.3f", pair.correlation))
                            .font(AppleDesignSystem.Typography.caption2)
                            .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    }
                }
                .chartXScale(domain: minimumCorrelation...1.0)
                .frame(minHeight: 400)
            } else {
                Text("Loading correlation data...")
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
            }
        }
    }
    
    /// crossGradePatternsView property
    var crossGradePatternsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cross-Grade Predictive Patterns")
                .font(AppleDesignSystem.Typography.headline)
            
            Text("How early grade performance predicts later outcomes")
                .font(AppleDesignSystem.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            
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
                            /// grade property
                            if let grade = value.as(Int.self) {
                                Text("Grade \(grade)")
                            }
                        }
                    }
                }
                .frame(minHeight: 400)
            } else {
                Text("Analyzing cross-grade patterns...")
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
            }
        }
    }
    
    /// predictivePathwaysView property
    var predictivePathwaysView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictive Learning Pathways")
                .font(AppleDesignSystem.Typography.headline)
            
            Text("Component relationships that predict future success")
                .font(AppleDesignSystem.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            
            // Pathway visualization showing how Grade 3 components predict Grade 8 outcomes
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(topCorrelations.filter { $0.targetGrade > $0.sourceGrade }.prefix(10)) { pair in
                        HStack(spacing: 12) {
                            // Source
                            VStack(alignment: .leading) {
                                Text("Grade \(pair.sourceGrade)")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                Text(pair.source)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(AppleDesignSystem.Spacing.small)
                                    .background(AppleDesignSystem.SystemPalette.blue.opacity(0.1))
                                    .cornerRadius(AppleDesignSystem.Corners.small)
                            }
                            
                            // Arrow with correlation
                            VStack {
                                Image(systemName: "arrow.right")
                                    .foregroundColor(correlationColor(for: pair.correlation))
                                Text(String(format: "%.3f", pair.correlation))
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .fontWeight(.semibold)
                                Text("\(pair.sampleSize) students")
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                            }
                            .frame(width: 80)
                            
                            // Target
                            VStack(alignment: .leading) {
                                Text("Grade \(pair.targetGrade)")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                Text(pair.target)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(AppleDesignSystem.Spacing.small)
                                    .background(AppleDesignSystem.SystemPalette.green.opacity(0.1))
                                    .cornerRadius(AppleDesignSystem.Corners.small)
                            }
                            
                            Spacer()
                            
                            // Confidence indicator
                            VStack(alignment: .trailing) {
                                Text("Confidence")
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                Text("\(Int(pair.confidence * 100))%")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(pair.confidence > 0.8 ? AppleDesignSystem.SystemPalette.green : pair.confidence > 0.6 ? AppleDesignSystem.SystemPalette.orange : AppleDesignSystem.SystemPalette.red)
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
    
    /// correlationHeatmapView property
    var correlationHeatmapView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Correlation Heatmap")
                .font(AppleDesignSystem.Typography.headline)
            
            Text("Component-to-component correlation matrix")
                .font(AppleDesignSystem.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            
            // Simplified heatmap for top components
            Text("Full heatmap visualization coming soon...")
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 400, alignment: .center)
        }
    }
    
    /// correlationColor function description
    func correlationColor(for value: Double) -> Color {
        switch value {
        case 0.85...1.0:
            return AppleDesignSystem.SystemPalette.green
        case 0.7..<0.85:
            return AppleDesignSystem.SystemPalette.blue
        case 0.5..<0.7:
            return AppleDesignSystem.SystemPalette.orange
        default:
            return AppleDesignSystem.SystemPalette.red
        }
    }
    
    /// loadCorrelationData function description
    func loadCorrelationData() {
        Task {
            // Load correlation data from the JSON file
            /// outputURL property
            let outputURL = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlation_model.json")
            
            /// data property
            if let data = try? Data(contentsOf: outputURL) {
                // Parse the JSON - we'll extract top correlations
                /// json property
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   /// correlations property
                   let correlations = json["correlations"] as? [[String: Any]] {
                    
                    await MainActor.run {
                        parseCorrelations(correlations)
                        isLoading = false
                    }
                }
            }
        }
    }
    
    /// parseCorrelations function description
    func parseCorrelations(_ correlationsData: [[String: Any]]) {
        /// pairs property
        var pairs: [CorrelationPair] = []
        /// crossGrade property
        var crossGrade: [CrossGradeCorrelation] = []
        
        for correlationEntry in correlationsData.prefix(100) { // Process first 100 for performance
            /// source property
            guard let source = correlationEntry["sourceComponent"] as? [String: Any],
                  /// correlationsList property
                  let correlationsList = correlationEntry["correlations"] as? [[String: Any]] else { continue }
            
            /// sourceGrade property
            let sourceGrade = source["grade"] as? Int ?? 0
            /// sourceSubject property
            let sourceSubject = source["subject"] as? String ?? ""
            /// sourceComponent property
            let sourceComponent = source["component"] as? String ?? ""
            /// _ property
            let _ = source["testProvider"] as? String ?? ""
            /// sourceName property
            let sourceName = "G\(sourceGrade)_\(sourceSubject)_\(sourceComponent)"
            
            for correlation in correlationsList {
                /// target property
                guard let target = correlation["target"] as? [String: Any],
                      /// correlationValue property
                      let correlationValue = correlation["correlation"] as? Double,
                      /// confidence property
                      let confidence = correlation["confidence"] as? Double,
                      /// sampleSize property
                      let sampleSize = correlation["sampleSize"] as? Int,
                      correlationValue > minimumCorrelation else { continue }
                
                /// targetGrade property
                let targetGrade = target["grade"] as? Int ?? 0
                /// targetSubject property
                let targetSubject = target["subject"] as? String ?? ""
                /// targetComponent property
                let targetComponent = target["component"] as? String ?? ""
                /// targetName property
                let targetName = "G\(targetGrade)_\(targetSubject)_\(targetComponent)"
                
                /// pair property
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
                    /// existing property
                    if let existing = crossGrade.firstIndex(where: { 
                        $0.earlyGrade == sourceGrade && 
                        $0.laterGrade == targetGrade && 
                        $0.component == sourceSubject 
                    }) {
                        // Update existing
                        /// updated property
                        let updated = crossGrade[existing]
                        /// newAvg property
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
    
    /// filterData function description
    func filterData() {
        // Re-filter based on current settings
        loadCorrelationData()
    }
    
    /// formatNumber function description
    func formatNumber(_ number: Int) -> String {
        /// formatter property
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

/// CorrelationStatCard represents...
struct CorrelationStatCard: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    /// title property
    let title: String
    /// value property
    let value: String
    /// subtitle property
    let subtitle: String
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppleDesignSystem.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            Text(value)
                .font(AppleDesignSystem.Typography.title2)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(AppleDesignSystem.Typography.caption2)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
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