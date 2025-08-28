import AnalysisCore
import SwiftUI

struct ConfigurationView: View {
    @StateObject private var viewModel = ConfigurationViewModel()
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                CorrelationSettingsView(config: .init(
                    get: { viewModel.configuration.correlation },
                    set: { viewModel.configuration = viewModel.configuration.updating(correlation: $0) }
                ))
                    .tabItem {
                        Label("Correlation", systemImage: "chart.xyaxis.line")
                    }
                    .tag(0)
                
                EarlyWarningSettingsView(config: .init(
                    get: { viewModel.configuration.earlyWarning },
                    set: { viewModel.configuration = viewModel.configuration.updating(earlyWarning: $0) }
                ))
                    .tabItem {
                        Label("Early Warning", systemImage: "exclamationmark.triangle")
                    }
                    .tag(1)
                
                GrowthSettingsView(config: .init(
                    get: { viewModel.configuration.growth },
                    set: { viewModel.configuration = viewModel.configuration.updating(growth: $0) }
                ))
                    .tabItem {
                        Label("Growth", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(2)
                
                ILPSettingsView(config: .init(
                    get: { viewModel.configuration.ilp },
                    set: { viewModel.configuration = viewModel.configuration.updating(ilp: $0) }
                ))
                    .tabItem {
                        Label("ILP", systemImage: "doc.text")
                    }
                    .tag(3)
                
                PerformanceSettingsView(config: .init(
                    get: { viewModel.configuration.performance },
                    set: { viewModel.configuration = viewModel.configuration.updating(performance: $0) }
                ))
                    .tabItem {
                        Label("Performance", systemImage: "speedometer")
                    }
                    .tag(4)
            }
            .navigationTitle("Analysis Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveConfiguration()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Correlation Settings View
struct CorrelationSettingsView: View {
    @Binding var config: SystemConfiguration.CorrelationParameters
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Minimum Correlation", systemImage: "chart.bar.fill")
                    Spacer()
                    Text("\(config.minimumCorrelation, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.minimumCorrelation },
                    set: { config = config.updating(minimumCorrelation: $0) }
                ), in: 0...1, step: 0.05)
                
            } header: {
                Text("Correlation Thresholds")
            } footer: {
                Text("Correlations below this value will be excluded from analysis")
            }
            
            Section {
                HStack {
                    Label("Strong Correlation", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
                    Spacer()
                    Text("\(config.strongCorrelationThreshold, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.strongCorrelationThreshold },
                    set: { config = config.updating(strongCorrelationThreshold: $0) }
                ), in: 0.5...1, step: 0.05)
                
                HStack {
                    Label("Very Strong Correlation", systemImage: "chart.line.uptrend.xyaxis.circle.fill")
                    Spacer()
                    Text("\(config.veryStrongCorrelationThreshold, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.veryStrongCorrelationThreshold },
                    set: { config = config.updating(veryStrongCorrelationThreshold: $0) }
                ), in: 0.7...1, step: 0.05)
                
            } header: {
                Text("Strength Classifications")
            }
            
            Section {
                LabeledContent {
                    Stepper(value: .init(
                        get: { config.minimumSampleSize },
                        set: { config = config.updating(minimumSampleSize: $0) }
                    ), in: 10...100, step: 5) {
                        Text("\(config.minimumSampleSize) students")
                    }
                } label: {
                    Label("Minimum Sample Size", systemImage: "person.3.fill")
                }
            } header: {
                Text("Sample Requirements")
            } footer: {
                Text("Minimum number of students required for valid correlation")
            }
            
            Section {
                Toggle(isOn: .init(
                    get: { config.useBonferroniCorrection },
                    set: { config = config.updating(useBonferroniCorrection: $0) }
                )) {
                    Label("Bonferroni Correction", systemImage: "function")
                }
                
                HStack {
                    Label("P-Value Threshold", systemImage: "percent")
                    Spacer()
                    Text("\(config.pValueThreshold, specifier: "%.3f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.pValueThreshold },
                    set: { config = config.updating(pValueThreshold: $0) }
                ), in: 0.001...0.1, step: 0.001)
                
            } header: {
                Text("Statistical Significance")
            }
        }
    }
}

// MARK: - Early Warning Settings View
struct EarlyWarningSettingsView: View {
    @Binding var config: SystemConfiguration.EarlyWarningParameters
    @State private var showingPercentileEditor = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Critical Risk Multiplier", systemImage: "exclamationmark.circle.fill")
                    Spacer()
                    Text("\(config.criticalRiskMultiplier, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.criticalRiskMultiplier },
                    set: { config = config.updating(criticalRiskMultiplier: $0) }
                ), in: 0.5...1, step: 0.05)
                
            } header: {
                Text("Risk Levels")
            } footer: {
                Text("Scores below threshold × multiplier trigger critical warnings")
            }
            
            Section {
                LabeledContent {
                    Button {
                        showingPercentileEditor = true
                    } label: {
                        HStack {
                            Text("\(config.thresholdPercentiles.count) percentiles")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .imageScale(.small)
                        }
                    }
                } label: {
                    Label("Threshold Percentiles", systemImage: "chart.bar")
                }
                
                HStack {
                    Label("Minimum F1 Score", systemImage: "checkmark.seal.fill")
                    Spacer()
                    Text("\(config.minimumF1Score, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.minimumF1Score },
                    set: { config = config.updating(minimumF1Score: $0) }
                ), in: 0.3...0.9, step: 0.05)
                
            } header: {
                Text("Threshold Discovery")
            }
            
            Section {
                LabeledContent {
                    Stepper(value: .init(
                        get: { config.minimumStudentsForThreshold },
                        set: { config = config.updating(minimumStudentsForThreshold: $0) }
                    ), in: 20...200, step: 10) {
                        Text("\(config.minimumStudentsForThreshold) students")
                    }
                } label: {
                    Label("Min Students for Threshold", systemImage: "person.3.sequence.fill")
                }
            } header: {
                Text("Data Requirements")
            }
        }
        .sheet(isPresented: $showingPercentileEditor) {
            PercentileEditorView(percentiles: .init(
                get: { config.thresholdPercentiles },
                set: { config = config.updating(thresholdPercentiles: $0) }
            ))
        }
    }
}

// MARK: - Growth Settings View
struct GrowthSettingsView: View {
    @Binding var config: SystemConfiguration.GrowthParameters
    
    var body: some View {
        Form {
            Section {
                Picker(selection: .init(
                    get: { config.growthMethod },
                    set: { config = config.updating(growthMethod: $0) }
                )) {
                    Text("Simple Gain").tag(SystemConfiguration.GrowthParameters.GrowthMethod.simpleGain)
                    Text("Percent Growth").tag(SystemConfiguration.GrowthParameters.GrowthMethod.percentGrowth)
                    Text("Value Added").tag(SystemConfiguration.GrowthParameters.GrowthMethod.valueAdded)
                    Text("Student Growth Percentile").tag(SystemConfiguration.GrowthParameters.GrowthMethod.studentGrowthPercentile)
                    Text("Conditional Growth").tag(SystemConfiguration.GrowthParameters.GrowthMethod.conditionalGrowth)
                } label: {
                    Label("Growth Method", systemImage: "chart.line.uptrend.xyaxis")
                }
                .pickerStyle(.menu)
            } header: {
                Text("Calculation Method")
            } footer: {
                growthMethodDescription
            }
            
            Section {
                HStack {
                    Label("Adequate Growth", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(config.adequateGrowthThreshold, specifier: "%.1f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.adequateGrowthThreshold },
                    set: { config = config.updating(adequateGrowthThreshold: $0) }
                ), in: 0...2, step: 0.1)
                
                HStack {
                    Label("Expected Annual Growth", systemImage: "calendar")
                    Spacer()
                    Text("\(config.expectedAnnualGrowth, specifier: "%.1f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.expectedAnnualGrowth },
                    set: { config = config.updating(expectedAnnualGrowth: $0) }
                ), in: 0.5...2, step: 0.1)
                
            } header: {
                Text("Growth Thresholds")
            }
            
            Section {
                Toggle(isOn: .init(
                    get: { config.useCohortReferencing },
                    set: { config = config.updating(useCohortReferencing: $0) }
                )) {
                    Label("Cohort Referencing", systemImage: "person.2.fill")
                }
                
                Toggle(isOn: .init(
                    get: { config.adjustForRegressionToMean },
                    set: { config = config.updating(adjustForRegressionToMean: $0) }
                )) {
                    Label("Adjust for Regression to Mean", systemImage: "arrow.triangle.merge")
                }
                
                Toggle(isOn: .init(
                    get: { config.includeConfidenceIntervals },
                    set: { config = config.updating(includeConfidenceIntervals: $0) }
                )) {
                    Label("Include Confidence Intervals", systemImage: "plusminus.circle")
                }
            } header: {
                Text("Growth Options")
            }
        }
    }
    
    private var growthMethodDescription: some View {
        switch config.growthMethod {
        case .simpleGain:
            return Text("Current Score - Previous Score")
        case .percentGrowth:
            return Text("(Current - Previous) / Previous × 100")
        case .valueAdded:
            return Text("Actual Growth - Expected Growth")
        case .studentGrowthPercentile:
            return Text("Percentile rank of growth compared to peers")
        case .conditionalGrowth:
            return Text("Growth adjusted for initial performance level")
        }
    }
}

// MARK: - ILP Settings View
struct ILPSettingsView: View {
    @Binding var config: SystemConfiguration.ILPParameters
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Enrichment Threshold", systemImage: "star.circle.fill")
                    Spacer()
                    Text("\(Int(config.enrichmentThreshold))%")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.enrichmentThreshold },
                    set: { config = config.updating(enrichmentThreshold: $0) }
                ), in: 70...95, step: 5)
                
            } header: {
                Text("Student Classification")
            } footer: {
                Text("Students scoring above this threshold receive enrichment plans")
            }
            
            Section {
                LabeledContent {
                    Stepper(value: .init(
                        get: { config.maxStandardsPerILP },
                        set: { config = config.updating(maxStandardsPerILP: $0) }
                    ), in: 5...20, step: 1) {
                        Text("\(config.maxStandardsPerILP) standards")
                    }
                } label: {
                    Label("Max Standards per ILP", systemImage: "doc.text.fill")
                }
                
                HStack {
                    Label("Correlation Weight", systemImage: "scalemass.fill")
                    Spacer()
                    Text("\(config.correlationWeight, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: .init(
                    get: { config.correlationWeight },
                    set: { config = config.updating(correlationWeight: $0) }
                ), in: 0...1, step: 0.05)
                
            } header: {
                Text("ILP Generation")
            }
            
            Section {
                Toggle(isOn: .init(
                    get: { config.includePrerequisites },
                    set: { config = config.updating(includePrerequisites: $0) }
                )) {
                    Label("Include Prerequisites", systemImage: "list.number")
                }
                
                Toggle(isOn: .init(
                    get: { config.includeCrossCurricular },
                    set: { config = config.updating(includeCrossCurricular: $0) }
                )) {
                    Label("Include Cross-Curricular", systemImage: "rectangle.grid.2x2")
                }
            } header: {
                Text("Additional Standards")
            }
        }
    }
}

// MARK: - Performance Settings View
struct PerformanceSettingsView: View {
    @Binding var config: SystemConfiguration.PerformanceParameters
    
    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Stepper(value: .init(
                        get: { config.batchSize },
                        set: { config = config.updating(batchSize: $0) }
                    ), in: 100...5000, step: 100) {
                        Text("\(config.batchSize) records")
                    }
                } label: {
                    Label("Batch Size", systemImage: "square.grid.3x3.fill")
                }
                
                LabeledContent {
                    Stepper(value: .init(
                        get: { config.memoryLimitMB },
                        set: { config = config.updating(memoryLimitMB: $0) }
                    ), in: 1024...16384, step: 1024) {
                        Text("\(config.memoryLimitMB / 1024) GB")
                    }
                } label: {
                    Label("Memory Limit", systemImage: "memorychip.fill")
                }
            } header: {
                Text("Resource Management")
            }
            
            Section {
                Toggle(isOn: .init(
                    get: { config.enableParallelProcessing },
                    set: { config = config.updating(enableParallelProcessing: $0) }
                )) {
                    Label("Parallel Processing", systemImage: "cpu")
                }
                
                if config.enableParallelProcessing {
                    LabeledContent {
                        Stepper(value: .init(
                            get: { config.maxConcurrentTasks },
                            set: { config = config.updating(maxConcurrentTasks: $0) }
                        ), in: 2...16, step: 1) {
                            Text("\(config.maxConcurrentTasks) tasks")
                        }
                    } label: {
                        Label("Max Concurrent Tasks", systemImage: "square.stack.3d.up.fill")
                    }
                }
                
                Toggle(isOn: .init(
                    get: { config.enableMLXAcceleration },
                    set: { config = config.updating(enableMLXAcceleration: $0) }
                )) {
                    Label("MLX Acceleration", systemImage: "bolt.fill")
                }
            } header: {
                Text("Processing Options")
            }
        }
    }
}

// MARK: - Percentile Editor View
struct PercentileEditorView: View {
    @Binding var percentiles: [Int]
    @State private var newPercentile = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(percentiles.sorted(), id: \.self) { percentile in
                        HStack {
                            Text("\(percentile)th percentile")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                        }
                    }
                    .onDelete { indices in
                        let sorted = percentiles.sorted()
                        for index in indices.sorted(by: >) {
                            if let removeIndex = percentiles.firstIndex(of: sorted[index]) {
                                percentiles.remove(at: removeIndex)
                            }
                        }
                    }
                } header: {
                    Text("Active Percentiles")
                }
                
                Section {
                    HStack {
                        TextField("Percentile (1-99)", text: $newPercentile)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        
                        Button("Add") {
                            if let value = Int(newPercentile),
                               value >= 1 && value <= 99,
                               !percentiles.contains(value) {
                                percentiles.append(value)
                                newPercentile = ""
                            }
                        }
                        .disabled(newPercentile.isEmpty)
                    }
                } header: {
                    Text("Add Percentile")
                }
            }
            .navigationTitle("Threshold Percentiles")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions for updating immutable structs
extension SystemConfiguration.CorrelationParameters {
    func updating(
        minimumCorrelation: Double? = nil,
        strongCorrelationThreshold: Double? = nil,
        veryStrongCorrelationThreshold: Double? = nil,
        minimumSampleSize: Int? = nil,
        confidenceLevel: Double? = nil,
        pValueThreshold: Double? = nil,
        useBonferroniCorrection: Bool? = nil
    ) -> Self {
        SystemConfiguration.CorrelationParameters(
            minimumCorrelation: minimumCorrelation ?? self.minimumCorrelation,
            strongCorrelationThreshold: strongCorrelationThreshold ?? self.strongCorrelationThreshold,
            veryStrongCorrelationThreshold: veryStrongCorrelationThreshold ?? self.veryStrongCorrelationThreshold,
            minimumSampleSize: minimumSampleSize ?? self.minimumSampleSize,
            confidenceLevel: confidenceLevel ?? self.confidenceLevel,
            pValueThreshold: pValueThreshold ?? self.pValueThreshold,
            useBonferroniCorrection: useBonferroniCorrection ?? self.useBonferroniCorrection
        )
    }
}

extension SystemConfiguration.EarlyWarningParameters {
    func updating(
        criticalRiskMultiplier: Double? = nil,
        thresholdPercentiles: [Int]? = nil,
        minimumF1Score: Double? = nil,
        minimumStudentsForThreshold: Int? = nil,
        falsePositiveWeight: Double? = nil
    ) -> Self {
        SystemConfiguration.EarlyWarningParameters(
            criticalRiskMultiplier: criticalRiskMultiplier ?? self.criticalRiskMultiplier,
            thresholdPercentiles: thresholdPercentiles ?? self.thresholdPercentiles,
            minimumF1Score: minimumF1Score ?? self.minimumF1Score,
            minimumStudentsForThreshold: minimumStudentsForThreshold ?? self.minimumStudentsForThreshold,
            falsePositiveWeight: falsePositiveWeight ?? self.falsePositiveWeight
        )
    }
}

extension SystemConfiguration.GrowthParameters {
    func updating(
        growthMethod: GrowthMethod? = nil,
        adequateGrowthThreshold: Double? = nil,
        expectedAnnualGrowth: Double? = nil,
        useCohortReferencing: Bool? = nil,
        includeConfidenceIntervals: Bool? = nil,
        adjustForRegressionToMean: Bool? = nil,
        growthPercentiles: GrowthPercentiles? = nil
    ) -> Self {
        SystemConfiguration.GrowthParameters(
            growthMethod: growthMethod ?? self.growthMethod,
            adequateGrowthThreshold: adequateGrowthThreshold ?? self.adequateGrowthThreshold,
            expectedAnnualGrowth: expectedAnnualGrowth ?? self.expectedAnnualGrowth,
            useCohortReferencing: useCohortReferencing ?? self.useCohortReferencing,
            includeConfidenceIntervals: includeConfidenceIntervals ?? self.includeConfidenceIntervals,
            adjustForRegressionToMean: adjustForRegressionToMean ?? self.adjustForRegressionToMean,
            growthPercentiles: growthPercentiles ?? self.growthPercentiles
        )
    }
}

extension SystemConfiguration.ILPParameters {
    func updating(
        enrichmentThreshold: Double? = nil,
        proficiencyThresholds: ProficiencyThresholds? = nil,
        maxStandardsPerILP: Int? = nil,
        correlationWeight: Double? = nil,
        includePrerequisites: Bool? = nil,
        includeCrossCurricular: Bool? = nil
    ) -> Self {
        SystemConfiguration.ILPParameters(
            enrichmentThreshold: enrichmentThreshold ?? self.enrichmentThreshold,
            proficiencyThresholds: proficiencyThresholds ?? self.proficiencyThresholds,
            maxStandardsPerILP: maxStandardsPerILP ?? self.maxStandardsPerILP,
            correlationWeight: correlationWeight ?? self.correlationWeight,
            includePrerequisites: includePrerequisites ?? self.includePrerequisites,
            includeCrossCurricular: includeCrossCurricular ?? self.includeCrossCurricular
        )
    }
}

extension SystemConfiguration.PerformanceParameters {
    func updating(
        batchSize: Int? = nil,
        enableParallelProcessing: Bool? = nil,
        maxConcurrentTasks: Int? = nil,
        memoryLimitMB: Int? = nil,
        enableMLXAcceleration: Bool? = nil
    ) -> Self {
        SystemConfiguration.PerformanceParameters(
            batchSize: batchSize ?? self.batchSize,
            enableParallelProcessing: enableParallelProcessing ?? self.enableParallelProcessing,
            maxConcurrentTasks: maxConcurrentTasks ?? self.maxConcurrentTasks,
            memoryLimitMB: memoryLimitMB ?? self.memoryLimitMB,
            enableMLXAcceleration: enableMLXAcceleration ?? self.enableMLXAcceleration
        )
    }
}

#Preview {
    ConfigurationView()
}