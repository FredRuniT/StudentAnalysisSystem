import AnalysisCore
import Charts
import SwiftUI

/// OptimizedCorrelationView represents...
struct OptimizedCorrelationView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var dataLoader = CorrelationDataLoader()
    @State private var selectedVisualization = "Top Correlations"
    @State private var selectedSubject = "All"
    @State private var selectedGradeFilter: Int?
    @State private var minimumCorrelation: Double = 0.7
    @State private var showOnlySignificant = true
    
    /// visualizationTypes property
    let visualizationTypes = ["Top Correlations", "Cross-Grade Patterns", "Predictive Pathways", "Matrix View"]
    /// subjects property
    let subjects = ["All", "MATH", "ELA", "ENGLISH_II", "ALGEBRA I", "BIOLOGY", "U.S. HISTORY"]
    /// gradeOptions property
    let gradeOptions = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    
    /// body property
    var body: some View {
        GeometryReader { geometry in
            if dataLoader.isLoading {
                loadingView
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerView
                        controlsView
                        
                        // Main visualization with proper sizing
                        mainVisualizationView
                            .frame(height: calculateChartHeight(for: selectedVisualization, geometry: geometry))
                        
                        summaryStatisticsView
                    }
                    .padding(.vertical)
                }
            }
        }
        .task {
            await dataLoader.loadCorrelationsOptimized()
        }
        .themed()
    }
    
    /// loadingView property
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: dataLoader.loadingProgress) {
                Text(dataLoader.loadingMessage)
                    .font(AppleDesignSystem.Typography.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: 400)
            
            Text("Processing \(formatNumber(623286)) correlations...")
                .font(AppleDesignSystem.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// headerView property
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Component Correlation Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                Text("Analyzing \(formatNumber(623286)) correlations across \(formatNumber(1117)) components")
                    .font(AppleDesignSystem.Typography.subheadline)
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                
                Spacer()
                
                if !dataLoader.isLoading {
                    Text("Loaded: \(dataLoader.topCorrelations.count) correlations")
                        .font(AppleDesignSystem.Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppleDesignSystem.SystemPalette.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal)
    }
    
    /// controlsView property
    var controlsView: some View {
        HStack(spacing: 16) {
            // Visualization picker
            Picker("Visualization", selection: $selectedVisualization) {
                ForEach(visualizationTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Filters in a more compact layout
            HStack(spacing: 12) {
                Picker("Subject", selection: $selectedSubject) {
                    ForEach(subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .frame(width: 120)
                
                Picker("Grade", selection: $selectedGradeFilter) {
                    Text("All").tag(nil as Int?)
                    ForEach(gradeOptions, id: \.self) { grade in
                        Text("G\(grade)").tag(grade as Int?)
                    }
                }
                .frame(width: 80)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Min: \(minimumCorrelation, specifier: "%.2f")")
                        .font(AppleDesignSystem.Typography.caption2)
                    Slider(value: $minimumCorrelation, in: 0.3...1.0, step: 0.05)
                        .frame(width: 100)
                }
                
                Toggle("Significant", isOn: $showOnlySignificant)
                    .toggleStyle(.checkbox)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    /// mainVisualizationView property
    var mainVisualizationView: some View {
        /// filteredData property
        let filteredData = dataLoader.filterCorrelations(
            subject: selectedSubject == "All" ? nil : selectedSubject,
            grade: selectedGradeFilter,
            minCorrelation: minimumCorrelation
        )
        
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
            
            switch selectedVisualization {
            case "Top Correlations":
                topCorrelationsChart(data: filteredData)
            case "Cross-Grade Patterns":
                crossGradePatterns
            case "Predictive Pathways":
                predictivePathways(data: filteredData)
            case "Matrix View":
                matrixView(data: filteredData)
            default:
                EmptyView()
            }
        }
        .padding(.horizontal)
    }
    
    /// topCorrelationsChart function description
    func topCorrelationsChart(data: [CorrelationDataLoader.CorrelationPair]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top \(min(data.count, 30)) Strongest Correlations")
                .font(AppleDesignSystem.Typography.headline)
                .padding(.horizontal)
            
            if !data.isEmpty {
                Chart(data.prefix(30)) { pair in
                    BarMark(
                        x: .value("Correlation", pair.correlation),
                        y: .value("Components", "\(pair.sourceName) → \(pair.targetName)")
                    )
                    .foregroundStyle(by: .value("Strength", correlationCategory(pair.correlation)))
                }
                .chartXScale(domain: minimumCorrelation...1.0)
                .chartLegend(position: .top)
                .padding()
            } else {
                Text("No correlations match the current filters")
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    /// crossGradePatterns property
    var crossGradePatterns: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cross-Grade Predictive Patterns")
                .font(AppleDesignSystem.Typography.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(dataLoader.crossGradeCorrelations.prefix(20), id: \.id) { pattern in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Grade \(pattern.earlyGrade)")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .padding(AppleDesignSystem.Spacing.xs)
                                    .background(AppleDesignSystem.SystemPalette.blue.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Image(systemName: "arrow.right")
                                    .font(AppleDesignSystem.Typography.caption)
                                
                                Text("Grade \(pattern.laterGrade)")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .padding(AppleDesignSystem.Spacing.xs)
                                    .background(AppleDesignSystem.SystemPalette.green.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            Text(pattern.subject)
                                .font(AppleDesignSystem.Typography.caption2)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(correlationColor(pattern.averageCorrelation))
                                    .frame(width: 8, height: 8)
                                Text(String(format: "%.3f", pattern.averageCorrelation))
                                    .font(AppleDesignSystem.Typography.caption2)
                            }
                            
                            Text("\(pattern.count) correlations")
                                .font(AppleDesignSystem.Typography.caption2)
                                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                        }
                        .padding()
                        .frame(width: 150)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
        }
    }
    
    /// predictivePathways function description
    func predictivePathways(data: [CorrelationDataLoader.CorrelationPair]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predictive Learning Pathways")
                .font(AppleDesignSystem.Typography.headline)
                .padding(.horizontal)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data.filter { $0.target.grade > $0.source.grade }.prefix(15), id: \.id) { pair in
                        HStack(spacing: 16) {
                            // Source component
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Grade \(pair.source.grade)")
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                Text(pair.source.component)
                                    .font(.system(.caption, design: .monospaced))
                                Text(pair.source.subject)
                                    .font(AppleDesignSystem.Typography.caption2)
                            }
                            .padding(AppleDesignSystem.Spacing.small)
                            .frame(width: 120)
                            .background(AppleDesignSystem.SystemPalette.blue.opacity(0.1))
                            .cornerRadius(AppleDesignSystem.Corners.small)
                            
                            // Correlation strength
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(correlationColor(pair.correlation))
                                Text(String(format: "%.3f", pair.correlation))
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .fontWeight(.bold)
                                Text("\(pair.sampleSize)")
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                            }
                            
                            // Target component
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Grade \(pair.target.grade)")
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                Text(pair.target.component)
                                    .font(.system(.caption, design: .monospaced))
                                Text(pair.target.subject)
                                    .font(AppleDesignSystem.Typography.caption2)
                            }
                            .padding(AppleDesignSystem.Spacing.small)
                            .frame(width: 120)
                            .background(AppleDesignSystem.SystemPalette.green.opacity(0.1))
                            .cornerRadius(AppleDesignSystem.Corners.small)
                            
                            Spacer()
                            
                            // Confidence
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Confidence")
                                    .font(AppleDesignSystem.Typography.caption2)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                                Text("\(Int(pair.confidence * 100))%")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(pair.confidence > 0.8 ? AppleDesignSystem.SystemPalette.green : AppleDesignSystem.SystemPalette.orange)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.02))
                        .cornerRadius(AppleDesignSystem.Corners.small)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    /// matrixView function description
    func matrixView(data: [CorrelationDataLoader.CorrelationPair]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Correlation Matrix View")
                .font(AppleDesignSystem.Typography.headline)
                .padding(.horizontal)
            
            Text("Interactive matrix visualization coming soon...")
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    /// summaryStatisticsView property
    var summaryStatisticsView: some View {
        /// filtered property
        let filtered = dataLoader.filterCorrelations(
            subject: selectedSubject == "All" ? nil : selectedSubject,
            grade: selectedGradeFilter,
            minCorrelation: minimumCorrelation
        )
        
        /// strongCount property
        let strongCount = filtered.filter { $0.correlation > 0.7 }.count
        /// veryStrongCount property
        let veryStrongCount = filtered.filter { $0.correlation > 0.85 }.count
        /// perfectCount property
        let perfectCount = filtered.filter { $0.correlation > 0.95 }.count
        
        return HStack(spacing: 20) {
            StatCard(
                title: "Filtered",
                value: "\(filtered.count)",
                subtitle: "Correlations"
            )
            
            StatCard(
                title: "Strong",
                value: "\(strongCount)",
                subtitle: "r > 0.70"
            )
            
            StatCard(
                title: "Very Strong",
                value: "\(veryStrongCount)",
                subtitle: "r > 0.85"
            )
            
            StatCard(
                title: "Near Perfect",
                value: "\(perfectCount)",
                subtitle: "r > 0.95"
            )
            
            Spacer()
            
            if dataLoader.correlationChunks.count > 1 {
                Text("Chunk \(dataLoader.currentChunkIndex + 1) of \(dataLoader.correlationChunks.count)")
                    .font(AppleDesignSystem.Typography.caption)
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            }
        }
        .padding(.horizontal)
    }
    
    // Helper functions
    /// calculateChartHeight function description
    func calculateChartHeight(for visualization: String, geometry: GeometryProxy) -> CGFloat {
        switch visualization {
        case "Top Correlations":
            return min(geometry.size.height * 0.6, 600)
        case "Cross-Grade Patterns":
            return 200
        case "Predictive Pathways":
            return min(geometry.size.height * 0.5, 500)
        case "Matrix View":
            return min(geometry.size.height * 0.7, 700)
        default:
            return 400
        }
    }
    
    /// correlationCategory function description
    func correlationCategory(_ value: Double) -> String {
        switch value {
        case 0.9...1.0: return "Near Perfect"
        case 0.7..<0.9: return "Strong"
        case 0.5..<0.7: return "Moderate"
        default: return "Weak"
        }
    }
    
    /// correlationColor function description
    func correlationColor(_ value: Double) -> Color {
        switch value {
        case 0.9...1.0: return AppleDesignSystem.SystemPalette.purple
        case 0.7..<0.9: return AppleDesignSystem.SystemPalette.green
        case 0.5..<0.7: return AppleDesignSystem.SystemPalette.blue
        default: return AppleDesignSystem.SystemPalette.orange
        }
    }
    
    /// formatNumber function description
    func formatNumber(_ number: Int) -> String {
        /// formatter property
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

/// StatCard represents...
struct StatCard: View {
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
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppleDesignSystem.Typography.caption2)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            Text(value)
                .font(AppleDesignSystem.Typography.title3)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(AppleDesignSystem.Typography.caption2)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(AppleDesignSystem.Corners.small)
    }
}

#Preview {
    OptimizedCorrelationView()
        .frame(width: 1200, height: 800)
}