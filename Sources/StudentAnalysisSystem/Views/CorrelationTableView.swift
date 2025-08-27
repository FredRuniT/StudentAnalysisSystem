import SwiftUI
import Charts
import AnalysisCore
import StatisticalEngine
import UniformTypeIdentifiers

struct CorrelationTableView: View {
    @StateObject private var viewModel = CorrelationTableViewModel()
    @State private var sortOrder = [KeyPathComparator(\CorrelationTableViewModel.CorrelationRow.correlation, order: .reverse)]
    @State private var selection = Set<CorrelationTableViewModel.CorrelationRow.ID>()
    @State private var searchText = ""
    @State private var showExportOptions = false
    @State private var showImportOptions = false
    
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
    }
    
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
                            .foregroundColor(.green)
                        if viewModel.isProcessingCSV {
                            Label("Processing CSV...", systemImage: "arrow.trianglehead.clockwise")
                                .foregroundColor(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Correlation: \(viewModel.averageCorrelation, specifier: "%.3f")")
                    Text("Strong (>0.7): \(viewModel.strongCorrelations)")
                    Text("Cross-Grade: \(viewModel.crossGradeCount)")
                }
                .font(.caption)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .padding()
            
            Divider()
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.loadingProgress) {
                Text(viewModel.loadingMessage)
                    .font(.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: 400)
            
            Text("Processing \(viewModel.loadedCorrelations) correlations...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                viewModel.cancelLoading()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    var tableContent: some View {
        Table(viewModel.filteredRows, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Source", value: \.sourceFullName) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grade \(row.sourceGrade) - \(row.sourceSubject)")
                        .font(.caption)
                    Text(row.sourceComponent)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .width(min: 150, ideal: 200)
            
            TableColumn("Target", value: \.targetFullName) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grade \(row.targetGrade) - \(row.targetSubject)")
                        .font(.caption)
                    Text(row.targetComponent)
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                Text(String(format: "%.1f%%", row.confidence * 100))
                    .foregroundColor(row.confidence > 0.8 ? .green : row.confidence > 0.6 ? .orange : .red)
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("Sample", value: \.sampleSize) { row in
                Text("\(row.sampleSize)")
                    .foregroundColor(row.sampleSize < 100 ? .orange : .primary)
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
    
    func correlationColor(_ value: Double) -> Color {
        switch value {
        case 0.95...1.0: return .purple
        case 0.85..<0.95: return .green
        case 0.7..<0.85: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
}

// View Model
@MainActor
class CorrelationTableViewModel: ObservableObject {
    @Published var allRows: [CorrelationRow] = []
    @Published var filteredRows: [CorrelationRow] = []
    @Published var isLoading = true
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage = "Initializing..."
    @Published var loadedCorrelations = 0
    @Published var isProcessingCSV = false
    
    // Filters
    @Published var minimumCorrelation: Double = 0.0
    @Published var selectedGrade: Int?
    @Published var selectedSubject: String?
    @Published var showCrossGradeOnly = false
    @Published var availableSubjects: [String] = []
    
    // Statistics
    @Published var averageCorrelation: Double = 0.0
    @Published var strongCorrelations = 0
    @Published var crossGradeCount = 0
    
    // Export
    @Published var exportDocument: CSVDocument?
    
    private var loadingTask: Task<Void, Never>?
    
    struct CorrelationRow: Identifiable, Equatable {
        let id = UUID()
        let sourceGrade: Int
        let sourceSubject: String
        let sourceComponent: String
        let targetGrade: Int
        let targetSubject: String
        let targetComponent: String
        let correlation: Double
        let confidence: Double
        let sampleSize: Int
        let provider: String
        
        var sourceFullName: String {
            "Grade \(sourceGrade) \(sourceSubject) \(sourceComponent)"
        }
        
        var targetFullName: String {
            "Grade \(targetGrade) \(targetSubject) \(targetComponent)"
        }
        
        var exportString: String {
            "\(sourceGrade),\(sourceSubject),\(sourceComponent),\(targetGrade),\(targetSubject),\(targetComponent),\(correlation),\(confidence),\(sampleSize),\(provider)"
        }
        
        var isCrossGrade: Bool {
            targetGrade != sourceGrade
        }
    }
    
    func loadAllCorrelations() async {
        loadingTask = Task {
            isLoading = true
            loadingMessage = "Loading correlation data..."
            
            // Check if CSV exists first (faster loading)
            let csvURL = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlations.csv")
            
            if FileManager.default.fileExists(atPath: csvURL.path) {
                await loadFromCSV(url: csvURL)
            } else {
                await loadFromJSON()
            }
            
            updateStatistics()
            isLoading = false
        }
        
        await loadingTask?.value
    }
    
    private func loadFromJSON() async {
        let jsonURL = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlation_model.json")
        
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            loadingMessage = "Correlation file not found"
            isLoading = false
            return
        }
        
        do {
            loadingMessage = "Reading JSON data (352 MB)..."
            let data = try Data(contentsOf: jsonURL)
            
            loadingMessage = "Parsing correlations..."
            loadingProgress = 0.1
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let correlationsArray = json?["correlations"] as? [[String: Any]] else {
                loadingMessage = "Invalid JSON structure"
                isLoading = false
                return
            }
            
            var rows: [CorrelationRow] = []
            let total = correlationsArray.count
            var subjects = Set<String>()
            
            for (index, entry) in correlationsArray.enumerated() {
                autoreleasepool {
                    guard let sourceDict = entry["sourceComponent"] as? [String: Any],
                          let correlationsList = entry["correlations"] as? [[String: Any]] else { return }
                    
                    let sourceGrade = sourceDict["grade"] as? Int ?? 0
                    let sourceSubject = sourceDict["subject"] as? String ?? ""
                    let sourceComponent = sourceDict["component"] as? String ?? ""
                    let sourceProvider = sourceDict["testProvider"] as? String ?? ""
                    
                    subjects.insert(sourceSubject)
                    
                    for corrDict in correlationsList {
                        guard let targetDict = corrDict["target"] as? [String: Any],
                              let correlationValue = corrDict["correlation"] as? Double,
                              let confidence = corrDict["confidence"] as? Double,
                              let sampleSize = corrDict["sampleSize"] as? Int,
                              correlationValue > 0.3 else { continue }
                        
                        let targetGrade = targetDict["grade"] as? Int ?? 0
                        let targetSubject = targetDict["subject"] as? String ?? ""
                        let targetComponent = targetDict["component"] as? String ?? ""
                        
                        subjects.insert(targetSubject)
                        
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
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var rows: [CorrelationRow] = []
            var subjects = Set<String>()
            
            for (index, line) in lines.enumerated() {
                if index == 0 { continue } // Skip header
                let components = line.components(separatedBy: ",")
                
                guard components.count >= 10 else { continue }
                
                let sourceGrade = Int(components[0]) ?? 0
                let sourceSubject = components[1]
                let sourceComponent = components[2]
                let targetGrade = Int(components[3]) ?? 0
                let targetSubject = components[4]
                let targetComponent = components[5]
                let correlation = Double(components[6]) ?? 0.0
                let confidence = Double(components[7]) ?? 0.0
                let sampleSize = Int(components[8]) ?? 0
                let provider = components[9]
                
                subjects.insert(sourceSubject)
                subjects.insert(targetSubject)
                
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
    
    func convertToCSV() async {
        isProcessingCSV = true
        
        let csvURL = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Output/correlations.csv")
        
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
    
    func sort(using sortOrder: [KeyPathComparator<CorrelationRow>]) {
        filteredRows.sort(using: sortOrder)
    }
    
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
    
    func applyFilters() {
        var filtered = allRows
        
        if minimumCorrelation > 0 {
            filtered = filtered.filter { $0.correlation >= minimumCorrelation }
        }
        
        if let grade = selectedGrade {
            filtered = filtered.filter { $0.sourceGrade == grade || $0.targetGrade == grade }
        }
        
        if let subject = selectedSubject {
            filtered = filtered.filter { $0.sourceSubject == subject || $0.targetSubject == subject }
        }
        
        if showCrossGradeOnly {
            filtered = filtered.filter { $0.isCrossGrade }
        }
        
        filteredRows = filtered
        updateStatistics()
    }
    
    func updateStatistics() {
        if !filteredRows.isEmpty {
            averageCorrelation = filteredRows.map(\.correlation).reduce(0, +) / Double(filteredRows.count)
            strongCorrelations = filteredRows.filter { $0.correlation > 0.7 }.count
            crossGradeCount = filteredRows.filter { $0.isCrossGrade }.count
        }
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
        isLoading = false
    }
    
    func copyToClipboard(items: Set<UUID>) {
        let rows = filteredRows.filter { items.contains($0.id) }
        let text = rows.map(\.exportString).joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    func prepareExport(selection: Set<UUID>) {
        let rows = selection.isEmpty ? filteredRows : filteredRows.filter { selection.contains($0.id) }
        var csvContent = "SourceGrade,SourceSubject,SourceComponent,TargetGrade,TargetSubject,TargetComponent,Correlation,Confidence,SampleSize,Provider\n"
        csvContent += rows.map(\.exportString).joined(separator: "\n")
        exportDocument = CSVDocument(text: csvContent)
    }
    
    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            loadingMessage = "Exported to \(url.lastPathComponent)"
        case .failure(let error):
            loadingMessage = "Export failed: \(error.localizedDescription)"
        }
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            if url.pathExtension == "csv" {
                await loadFromCSV(url: url)
            } else {
                loadingMessage = "Unsupported file format"
            }
        case .failure(let error):
            loadingMessage = "Import failed: \(error.localizedDescription)"
        }
    }
    
    func showPredictivePath(for items: Set<UUID>) {
        // TODO: Implement predictive path visualization
    }
}

// CSV Document for export
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    CorrelationTableView()
        .frame(width: 1400, height: 900)
}