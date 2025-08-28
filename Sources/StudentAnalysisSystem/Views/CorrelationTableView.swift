import AnalysisCore
import Charts
import StatisticalEngine
import SwiftUI
import UniformTypeIdentifiers

/// CorrelationTableView represents...
struct CorrelationTableView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = CorrelationTableViewModel()
    @State private var sortOrder = [KeyPathComparator(\CorrelationTableViewModel.CorrelationRow.correlation, order: .reverse)]
    @State private var selection = Set<CorrelationTableViewModel.CorrelationRow.ID>()
    @State private var searchText = ""
    @State private var showExportOptions = false
    @State private var showImportOptions = false
    
    /// body property
    var body: some View {
        VStack(spacing: 0) {
            // Header with statistics
            headerView
            
            // Main table
            if viewModel.isLoading {
                loadingView
            } else {
                tableContent
            }
        }
        .searchable(text: $searchText, prompt: "Search components...")
        .toolbar {
            toolbarContent
        }
        .task {
            await viewModel.loadAllCorrelations()
        }
        .fileImporter(
            isPresented: $showImportOptions,
            allowedContentTypes: [.commaSeparatedText, .json],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await viewModel.handleFileImport(result)
            }
        }
        .fileExporter(
            isPresented: $showExportOptions,
            document: viewModel.exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "correlations_export.csv"
        ) { result in
            viewModel.handleExportResult(result)
        }
        .themed()
    }
    
    /// headerView property
    var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Component Correlation Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        Label("\(viewModel.filteredRows.count) of \(viewModel.allRows.count) correlations", systemImage: "chart.scatter")
                        Label("Loaded: \(viewModel.loadedCorrelations) items", systemImage: "checkmark.circle.fill")
                            .foregroundColor(AppleDesignSystem.SystemPalette.green)
                        if viewModel.isProcessingCSV {
                            Label("Processing CSV...", systemImage: "arrow.trianglehead.clockwise")
                                .foregroundColor(AppleDesignSystem.SystemPalette.orange)
                        }
                    }
                    .font(AppleDesignSystem.Typography.caption)
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }
                
                Spacer()
                
                // Quick stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Correlation: \(viewModel.averageCorrelation, specifier: "%.3f")")
                    Text("Strong (>0.7): \(viewModel.strongCorrelations)")
                    Text("Cross-Grade: \(viewModel.crossGradeCount)")
                }
                .font(AppleDesignSystem.Typography.caption)
                .padding(AppleDesignSystem.Spacing.small)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(AppleDesignSystem.Corners.small)
            }
            .padding()
            
            Divider()
        }
    }
    
    /// loadingView property
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.loadingProgress) {
                Text(viewModel.loadingMessage)
                    .font(AppleDesignSystem.Typography.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: 400)
            
            Text("Processing \(viewModel.loadedCorrelations) correlations...")
                .font(AppleDesignSystem.Typography.caption)
                .foregroundColor(themeManager.currentTheme.colors.secondaryText)
            
            Button("Cancel") {
                viewModel.cancelLoading()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    /// tableContent property
    var tableContent: some View {
        Table(viewModel.filteredRows, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Source", value: \.sourceFullName) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grade \(row.sourceGrade) - \(row.sourceSubject)")
                        .font(AppleDesignSystem.Typography.caption)
                    Text(row.sourceComponent)
                        .font(AppleDesignSystem.Typography.caption2)
                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }
            }
            .width(min: 150, ideal: 200)
            
            TableColumn("Target", value: \.targetFullName) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grade \(row.targetGrade) - \(row.targetSubject)")
                        .font(AppleDesignSystem.Typography.caption)
                    Text(row.targetComponent)
                        .font(AppleDesignSystem.Typography.caption2)
                        .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }
            }
            .width(min: 150, ideal: 200)
            
            TableColumn("Correlation", value: \.correlation) { row in
                HStack(spacing: 4) {
                    Circle()
                        .fill(correlationColor(row.correlation))
                        .frame(width: 8, height: 8)
                    Text(String(format: "%.4f", row.correlation))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(row.correlation > 0.85 ? .semibold : .regular)
                }
            }
            .width(min: 100, ideal: 120)
            
            TableColumn("Confidence", value: \.confidence) { row in
                HStack(spacing: 4) {
                    // Show significance indicator
                    if row.confidence > 0.99 {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppleDesignSystem.SystemPalette.purple)
                            .font(AppleDesignSystem.Typography.caption2)
                            .help("p < 0.01 - Highly Significant")
                    } else if row.confidence > 0.95 {
                        Image(systemName: "star")
                            .foregroundColor(AppleDesignSystem.SystemPalette.green)
                            .font(AppleDesignSystem.Typography.caption2)
                            .help("p < 0.05 - Significant")
                    }
                    
                    Text(String(format: "%.1f%%", row.confidence * 100))
                        .foregroundColor(row.confidence > 0.99 ? AppleDesignSystem.SystemPalette.purple : 
                                       row.confidence > 0.95 ? AppleDesignSystem.SystemPalette.green : 
                                       row.confidence > 0.90 ? AppleDesignSystem.SystemPalette.blue : AppleDesignSystem.SystemPalette.orange)
                }
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("Sample", value: \.sampleSize) { row in
                Text("\(row.sampleSize)")
                    .foregroundColor(row.sampleSize < 100 ? AppleDesignSystem.SystemPalette.orange : .primary)
            }
            .width(min: 60, ideal: 80)
            
            TableColumn("Provider", value: \.provider)
                .width(min: 60, ideal: 80)
        }
        .onChange(of: sortOrder) {
            viewModel.sort(using: sortOrder)
        }
        .onChange(of: searchText) {
            viewModel.filterRows(searchText: searchText)
        }
    }
    
    @ToolbarContentBuilder
    /// toolbarContent property
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Filter controls
            Picker("Min Correlation", selection: $viewModel.minimumCorrelation) {
                Text("All").tag(0.0)
                Text("> 0.5").tag(0.5)
                Text("> 0.7").tag(0.7)
                Text("> 0.85").tag(0.85)
                Text("> 0.95").tag(0.95)
            }
            .onChange(of: viewModel.minimumCorrelation) {
                viewModel.applyFilters()
            }
            
            Picker("Grade", selection: $viewModel.selectedGrade) {
                Text("All Grades").tag(nil as Int?)
                ForEach(3...12, id: \.self) { grade in
                    Text("Grade \(grade)").tag(grade as Int?)
                }
            }
            .onChange(of: viewModel.selectedGrade) {
                viewModel.applyFilters()
            }
            
            Picker("Subject", selection: $viewModel.selectedSubject) {
                Text("All Subjects").tag(nil as String?)
                ForEach(viewModel.availableSubjects, id: \.self) { subject in
                    Text(subject).tag(subject as String?)
                }
            }
            .onChange(of: viewModel.selectedSubject) {
                viewModel.applyFilters()
            }
            
            Toggle("Cross-Grade Only", isOn: $viewModel.showCrossGradeOnly)
                .onChange(of: viewModel.showCrossGradeOnly) {
                    viewModel.applyFilters()
                }
            
            Divider()
            
            Button(action: { showImportOptions = true }) {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            
            Button(action: { 
                viewModel.prepareExport(selection: selection)
                showExportOptions = true 
            }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Button(action: { Task { await viewModel.convertToCSV() } }) {
                Label("Convert to CSV", systemImage: "doc.badge.arrow.up")
            }
            .disabled(viewModel.isProcessingCSV)
        }
    }
    
    @ViewBuilder
    /// contextMenuContent function description
    func contextMenuContent(for items: Set<CorrelationTableViewModel.CorrelationRow.ID>) -> some View {
        Button("Copy") {
            viewModel.copyToClipboard(items: items)
        }
        
        Button("Export Selected") {
            viewModel.prepareExport(selection: items)
            showExportOptions = true
        }
        
        Divider()
        
        Button("Show Predictive Path") {
            viewModel.showPredictivePath(for: items)
        }
    }
    
    /// correlationColor function description
    func correlationColor(_ value: Double) -> Color {
        switch value {
        case 0.95...1.0: return AppleDesignSystem.SystemPalette.purple
        case 0.85..<0.95: return AppleDesignSystem.SystemPalette.green
        case 0.7..<0.85: return AppleDesignSystem.SystemPalette.blue
        case 0.5..<0.7: return AppleDesignSystem.SystemPalette.orange
        default: return AppleDesignSystem.SystemPalette.red
        }
    }
}

// View Model
@MainActor
/// CorrelationTableViewModel represents...
class CorrelationTableViewModel: ObservableObject {
    /// allRows property
    @Published var allRows: [CorrelationRow] = []
    /// filteredRows property
    @Published var filteredRows: [CorrelationRow] = []
    /// isLoading property
    @Published var isLoading = true
    /// loadingProgress property
    @Published var loadingProgress: Double = 0.0
    /// loadingMessage property
    @Published var loadingMessage = "Initializing..."
    /// loadedCorrelations property
    @Published var loadedCorrelations = 0
    /// isProcessingCSV property
    @Published var isProcessingCSV = false
    
    // Filters
    /// minimumCorrelation property
    @Published var minimumCorrelation: Double = 0.0
    /// selectedGrade property
    @Published var selectedGrade: Int?
    /// selectedSubject property
    @Published var selectedSubject: String?
    /// showCrossGradeOnly property
    @Published var showCrossGradeOnly = false
    /// availableSubjects property
    @Published var availableSubjects: [String] = []
    
    // Statistics
    /// averageCorrelation property
    @Published var averageCorrelation: Double = 0.0
    /// strongCorrelations property
    @Published var strongCorrelations = 0
    /// crossGradeCount property
    @Published var crossGradeCount = 0
    
    // Export
    /// exportDocument property
    @Published var exportDocument: CSVDocument?
    
    private var loadingTask: Task<Void, Never>?
    
    /// CorrelationRow represents...
    struct CorrelationRow: Identifiable, Equatable {
        /// id property
        let id = UUID()
        /// sourceGrade property
        let sourceGrade: Int
        /// sourceSubject property
        let sourceSubject: String
        /// sourceComponent property
        let sourceComponent: String
        /// targetGrade property
        let targetGrade: Int
        /// targetSubject property
        let targetSubject: String
        /// targetComponent property
        let targetComponent: String
        /// correlation property
        let correlation: Double
        /// confidence property
        let confidence: Double
        /// sampleSize property
        let sampleSize: Int
        /// provider property
        let provider: String
        
        /// sourceFullName property
        var sourceFullName: String {
            "Grade \(sourceGrade) \(sourceSubject) \(sourceComponent)"
        }
        
        /// targetFullName property
        var targetFullName: String {
            "Grade \(targetGrade) \(targetSubject) \(targetComponent)"
        }
        
        /// exportString property
        var exportString: String {
            "\(sourceGrade),\(sourceSubject),\(sourceComponent),\(targetGrade),\(targetSubject),\(targetComponent),\(correlation),\(confidence),\(sampleSize),\(provider)"
        }
        
        /// isCrossGrade property
        var isCrossGrade: Bool {
            targetGrade != sourceGrade
        }
    }
    
    /// loadAllCorrelations function description
    func loadAllCorrelations() async {
        loadingTask = Task {
            isLoading = true
            loadingMessage = "Loading correlation data..."
            
            // Try to load demo data first for immediate testing
            await loadFromJSON()
            
            updateStatistics()
            isLoading = false
        }
        
        await loadingTask?.value
    }
    
    private func loadFromJSON() async {
        // Try multiple possible locations for the correlation data
        /// possiblePaths property
        let possiblePaths = [
            // Demo file for immediate testing (smaller, realistic data)
            URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/demo_correlation_model.json"),
            // Full correlation model (backup)
            URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlation_model.json"),
            // Relative to current working directory
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Output/demo_correlation_model.json")
        ]
        
        /// jsonURL property
        var jsonURL: URL?
        /// foundPath property
        var foundPath: String = "No valid paths found"
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                jsonURL = path
                foundPath = path.path
                break
            }
        }
        
        /// validURL property
        guard let validURL = jsonURL else {
            loadingMessage = "Correlation file not found. Searched: \(possiblePaths.map { $0.path }.joined(separator: ", "))"
            isLoading = false
            return
        }
        
        do {
            loadingMessage = "Reading JSON data from: \(foundPath)..."
            /// data property
            let data = try Data(contentsOf: validURL)
            
            loadingMessage = "Parsing correlations..."
            loadingProgress = 0.1
            
            /// json property
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            /// correlationsArray property
            guard let correlationsArray = json?["correlations"] as? [[String: Any]] else {
                loadingMessage = "Invalid JSON structure"
                isLoading = false
                return
            }
            
            /// rows property
            var rows: [CorrelationRow] = []
            /// total property
            let total = correlationsArray.count
            /// subjects property
            var subjects = Set<String>()
            
            for (index, entry) in correlationsArray.enumerated() {
                autoreleasepool {
                    /// sourceDict property
                    guard let sourceDict = entry["sourceComponent"] as? [String: Any],
                          /// correlationsList property
                          let correlationsList = entry["correlations"] as? [[String: Any]] else { return }
                    
                    /// sourceGrade property
                    let sourceGrade = sourceDict["grade"] as? Int ?? 0
                    /// sourceSubject property
                    let sourceSubject = sourceDict["subject"] as? String ?? ""
                    /// sourceComponent property
                    let sourceComponent = sourceDict["component"] as? String ?? ""
                    /// sourceProvider property
                    let sourceProvider = sourceDict["testProvider"] as? String ?? ""
                    
                    subjects.insert(sourceSubject)
                    
                    for corrDict in correlationsList {
                        /// targetDict property
                        guard let targetDict = corrDict["target"] as? [String: Any],
                              /// correlationValue property
                              let correlationValue = corrDict["correlation"] as? Double,
                              /// confidence property
                              let confidence = corrDict["confidence"] as? Double,
                              /// sampleSize property
                              let sampleSize = corrDict["sampleSize"] as? Int,
                              correlationValue > 0.3 else { continue }
                        
                        /// targetGrade property
                        let targetGrade = targetDict["grade"] as? Int ?? 0
                        /// targetSubject property
                        let targetSubject = targetDict["subject"] as? String ?? ""
                        /// targetComponent property
                        let targetComponent = targetDict["component"] as? String ?? ""
                        
                        subjects.insert(targetSubject)
                        
                        /// row property
                        let row = CorrelationRow(
                            sourceGrade: sourceGrade,
                            sourceSubject: sourceSubject,
                            sourceComponent: sourceComponent,
                            targetGrade: targetGrade,
                            targetSubject: targetSubject,
                            targetComponent: targetComponent,
                            correlation: correlationValue,
                            confidence: confidence,
                            sampleSize: sampleSize,
                            provider: sourceProvider
                        )
                        
                        rows.append(row)
                    }
                    
                    if index % 100 == 0 {
                        /// progress property
                        let progress = Double(index) / Double(total)
                        Task { @MainActor in
                            self.loadingProgress = progress
                            self.loadingMessage = "Processing... \(Int(progress * 100))%"
                            self.loadedCorrelations = rows.count
                        }
                    }
                }
            }
            
            self.allRows = rows
            self.filteredRows = rows
            self.availableSubjects = Array(subjects).sorted()
            self.loadedCorrelations = rows.count
            self.loadingMessage = "Loaded \(rows.count) correlations"
            
        } catch {
            loadingMessage = "Error: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func loadFromCSV(url: URL) async {
        loadingMessage = "Loading CSV data..."
        
        do {
            /// content property
            let content = try String(contentsOf: url, encoding: .utf8)
            /// lines property
            let lines = content.components(separatedBy: .newlines)
            
            /// rows property
            var rows: [CorrelationRow] = []
            /// subjects property
            var subjects = Set<String>()
            
            for (index, line) in lines.enumerated() {
                if index == 0 { continue } // Skip header
                /// components property
                let components = line.components(separatedBy: ",")
                
                guard components.count >= 10 else { continue }
                
                /// sourceGrade property
                let sourceGrade = Int(components[0]) ?? 0
                /// sourceSubject property
                let sourceSubject = components[1]
                /// sourceComponent property
                let sourceComponent = components[2]
                /// targetGrade property
                let targetGrade = Int(components[3]) ?? 0
                /// targetSubject property
                let targetSubject = components[4]
                /// targetComponent property
                let targetComponent = components[5]
                /// correlation property
                let correlation = Double(components[6]) ?? 0.0
                /// confidence property
                let confidence = Double(components[7]) ?? 0.0
                /// sampleSize property
                let sampleSize = Int(components[8]) ?? 0
                /// provider property
                let provider = components[9]
                
                subjects.insert(sourceSubject)
                subjects.insert(targetSubject)
                
                /// row property
                let row = CorrelationRow(
                    sourceGrade: sourceGrade,
                    sourceSubject: sourceSubject,
                    sourceComponent: sourceComponent,
                    targetGrade: targetGrade,
                    targetSubject: targetSubject,
                    targetComponent: targetComponent,
                    correlation: correlation,
                    confidence: confidence,
                    sampleSize: sampleSize,
                    provider: provider
                )
                
                rows.append(row)
                
                if index % 1000 == 0 {
                    /// progress property
                    let progress = Double(index) / Double(lines.count)
                    loadingProgress = progress
                    loadingMessage = "Loading... \(Int(progress * 100))%"
                    loadedCorrelations = rows.count
                }
            }
            
            self.allRows = rows
            self.filteredRows = rows
            self.availableSubjects = Array(subjects).sorted()
            self.loadedCorrelations = rows.count
            
        } catch {
            loadingMessage = "Error loading CSV: \(error.localizedDescription)"
        }
    }
    
    /// convertToCSV function description
    func convertToCSV() async {
        isProcessingCSV = true
        
        /// csvURL property
        let csvURL = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlations.csv")
        
        /// csvContent property
        var csvContent = "SourceGrade,SourceSubject,SourceComponent,TargetGrade,TargetSubject,TargetComponent,Correlation,Confidence,SampleSize,Provider\n"
        
        for row in allRows {
            csvContent += row.exportString + "\n"
        }
        
        do {
            try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
            loadingMessage = "CSV file created successfully"
        } catch {
            loadingMessage = "Error creating CSV: \(error.localizedDescription)"
        }
        
        isProcessingCSV = false
    }
    
    /// sort function description
    func sort(using sortOrder: [KeyPathComparator<CorrelationRow>]) {
        filteredRows.sort(using: sortOrder)
    }
    
    /// filterRows function description
    func filterRows(searchText: String) {
        if searchText.isEmpty {
            applyFilters()
        } else {
            filteredRows = allRows.filter { row in
                row.sourceFullName.localizedCaseInsensitiveContains(searchText) ||
                row.targetFullName.localizedCaseInsensitiveContains(searchText) ||
                String(format: "%.4f", row.correlation).contains(searchText)
            }
            applyFilters()
        }
    }
    
    /// applyFilters function description
    func applyFilters() {
        /// filtered property
        var filtered = allRows
        
        if minimumCorrelation > 0 {
            filtered = filtered.filter { $0.correlation >= minimumCorrelation }
        }
        
        /// grade property
        if let grade = selectedGrade {
            filtered = filtered.filter { $0.sourceGrade == grade || $0.targetGrade == grade }
        }
        
        /// subject property
        if let subject = selectedSubject {
            filtered = filtered.filter { $0.sourceSubject == subject || $0.targetSubject == subject }
        }
        
        if showCrossGradeOnly {
            filtered = filtered.filter { $0.isCrossGrade }
        }
        
        filteredRows = filtered
        updateStatistics()
    }
    
    /// updateStatistics function description
    func updateStatistics() {
        if !filteredRows.isEmpty {
            averageCorrelation = filteredRows.map(\.correlation).reduce(0, +) / Double(filteredRows.count)
            strongCorrelations = filteredRows.filter { $0.correlation > 0.7 }.count
            crossGradeCount = filteredRows.filter { $0.isCrossGrade }.count
        }
    }
    
    /// cancelLoading function description
    func cancelLoading() {
        loadingTask?.cancel()
        isLoading = false
    }
    
    /// copyToClipboard function description
    func copyToClipboard(items: Set<UUID>) {
        /// rows property
        let rows = filteredRows.filter { items.contains($0.id) }
        /// text property
        let text = rows.map(\.exportString).joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    /// prepareExport function description
    func prepareExport(selection: Set<UUID>) {
        /// rows property
        let rows = selection.isEmpty ? filteredRows : filteredRows.filter { selection.contains($0.id) }
        /// csvContent property
        var csvContent = "SourceGrade,SourceSubject,SourceComponent,TargetGrade,TargetSubject,TargetComponent,Correlation,Confidence,SampleSize,Provider\n"
        csvContent += rows.map(\.exportString).joined(separator: "\n")
        exportDocument = CSVDocument(text: csvContent)
    }
    
    /// handleExportResult function description
    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        /// url property
        case .success(let url):
            loadingMessage = "Exported to \(url.lastPathComponent)"
        /// error property
        case .failure(let error):
            loadingMessage = "Export failed: \(error.localizedDescription)"
        }
    }
    
    /// handleFileImport function description
    func handleFileImport(_ result: Result<[URL], Error>) async {
        switch result {
        /// urls property
        case .success(let urls):
            /// url property
            guard let url = urls.first else { return }
            if url.pathExtension == "csv" {
                await loadFromCSV(url: url)
            } else {
                loadingMessage = "Unsupported file format"
            }
        /// error property
        case .failure(let error):
            loadingMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    /// showPredictivePath function description
    func showPredictivePath(for items: Set<UUID>) {
        // TODO: Implement predictive path visualization
    }
}

// CSV Document for export
/// CSVDocument represents...
struct CSVDocument: FileDocument {
    /// readableContentTypes property
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    /// text property
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        /// data property
        guard let data = configuration.file.regularFileContents,
              /// text property
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }
    
    /// fileWrapper function description
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        /// data property
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    CorrelationTableView()
        .frame(width: 1400, height: 900)
}