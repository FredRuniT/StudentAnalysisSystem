import SwiftUI
import AnalysisCore
import ReportGeneration

// MARK: - Correlation Threshold Control

struct CorrelationThresholdControl: View {
    @ObservedObject var processor: CorrelationNetworkProcessor
    
    private let thresholdOptions: [Double] = [0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0]
    
    private func thresholdLabel(for value: Double) -> String {
        switch value {
        case 0.9...: return "Very Strong (r≥0.9)"
        case 0.7..<0.9: return "Strong (r≥0.7)"
        case 0.5..<0.7: return "Moderate (r≥0.5)"
        case 0.3..<0.5: return "Weak (r≥0.3)"
        default: return "All (r≥\(String(format: "%.1f", value)))"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Correlation Threshold")
                .font(.subheadline.weight(.medium))
            
            Picker("Threshold", selection: $processor.correlationThreshold) {
                ForEach(thresholdOptions, id: \.self) { value in
                    Text(thresholdLabel(for: value)).tag(value)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: processor.correlationThreshold) { oldValue, newValue in
                Task {
                    await MainActor.run {
                        processor.updateThreshold(newValue)
                    }
                }
            }
            
            // Custom slider for fine-tuning
            VStack(alignment: .leading, spacing: 4) {
                Text("Fine Tune: \(processor.correlationThreshold, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: $processor.correlationThreshold,
                    in: 0.1...1.0,
                    step: 0.05
                ) {
                    Text("Threshold")
                } minimumValueLabel: {
                    Text("0.1")
                        .font(.caption2)
                } maximumValueLabel: {
                    Text("1.0")
                        .font(.caption2)
                }
                .onChange(of: processor.correlationThreshold) { oldValue, newValue in
                    // Debounce updates to avoid excessive processing
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await MainActor.run {
                            if processor.correlationThreshold == newValue {
                                processor.updateThreshold(newValue)
                            }
                        }
                    }
                }
            }
            
            // Show current filter stats
            Text("Showing \(processor.filteredCorrelations.count) correlations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Grade Filter Control

struct GradeFilterControl: View {
    @ObservedObject var processor: CorrelationNetworkProcessor
    
    private let availableGrades = [3, 4, 5, 6, 7, 8]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Grade Levels")
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Button(processor.selectedGrades.isEmpty ? "Select All" : "Clear All") {
                    Task {
                        await MainActor.run {
                            if processor.selectedGrades.isEmpty {
                                processor.updateGradeFilter(Set(availableGrades))
                            } else {
                                processor.updateGradeFilter([])
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(availableGrades, id: \.self) { grade in
                    Button(action: {
                        Task {
                            await MainActor.run {
                                var newSelection = processor.selectedGrades
                                if newSelection.contains(grade) {
                                    newSelection.remove(grade)
                                } else {
                                    newSelection.insert(grade)
                                }
                                processor.updateGradeFilter(newSelection)
                            }
                        }
                    }) {
                        Text("Grade \(grade)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(processor.selectedGrades.contains(grade) ? .white : .primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(processor.selectedGrades.contains(grade) ? Color.accentColor : Color.gray.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if processor.selectedGrades.isEmpty {
                Text("All grades selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(processor.selectedGrades.count) grade\(processor.selectedGrades.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Subject Filter Control

struct SubjectFilterControl: View {
    @ObservedObject var processor: CorrelationNetworkProcessor
    
    private let availableSubjects = ["ELA", "MATH", "SCIENCE"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subject Areas")
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Button(processor.selectedSubjects.isEmpty ? "Select All" : "Clear All") {
                    Task {
                        await MainActor.run {
                            if processor.selectedSubjects.isEmpty {
                                processor.updateSubjectFilter(Set(availableSubjects))
                            } else {
                                processor.updateSubjectFilter([])
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 6) {
                ForEach(availableSubjects, id: \.self) { subject in
                    HStack {
                        Button(action: {
                            Task {
                                await MainActor.run {
                                    var newSelection = processor.selectedSubjects
                                    if newSelection.contains(subject) {
                                        newSelection.remove(subject)
                                    } else {
                                        newSelection.insert(subject)
                                    }
                                    processor.updateSubjectFilter(newSelection)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: processor.selectedSubjects.contains(subject) ? "checkmark.square" : "square")
                                    .foregroundColor(processor.selectedSubjects.contains(subject) ? .accentColor : .secondary)
                                
                                Circle()
                                    .fill(Color(hex: subjectColor(subject)) ?? .gray)
                                    .frame(width: 12, height: 12)
                                
                                Text(subject)
                                    .font(.system(.caption, weight: .medium))
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if processor.selectedSubjects.isEmpty {
                Text("All subjects selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(processor.selectedSubjects.count) subject\(processor.selectedSubjects.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func subjectColor(_ subject: String) -> String {
        switch subject {
        case "ELA": return "#0084FF"
        case "MATH": return "#AF52DE"
        case "SCIENCE": return "#34C759"
        default: return "#8E8E93"
        }
    }
}

// MARK: - Performance Settings Control

struct PerformanceSettingsControl: View {
    @ObservedObject var processor: CorrelationNetworkProcessor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Settings")
                .font(.subheadline.weight(.medium))
            
            VStack(alignment: .leading, spacing: 12) {
                // Max correlations slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Correlations: \(processor.maxCorrelations)")
                        .font(.caption.weight(.medium))
                    
                    Slider(
                        value: Binding(
                            get: { Double(processor.maxCorrelations) },
                            set: { processor.maxCorrelations = Int($0) }
                        ),
                        in: 1000...50000,
                        step: 1000
                    ) {
                        Text("Max Correlations")
                    } minimumValueLabel: {
                        Text("1K")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("50K")
                            .font(.caption2)
                    }
                    .onChange(of: processor.maxCorrelations) { oldValue, newValue in
                        // Debounce updates
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1.0 second
                            await MainActor.run {
                                if processor.maxCorrelations == newValue {
                                    processor.processCorrelations()
                                }
                            }
                        }
                    }
                }
                
                // Performance recommendations
                Group {
                    if processor.maxCorrelations > 25000 {
                        Label("High correlation count may impact performance", systemImage: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else if processor.maxCorrelations > 15000 {
                        Label("Medium performance impact expected", systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    } else {
                        Label("Optimal performance settings", systemImage: "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Network Legend

struct NetworkLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legend")
                .font(.headline)
            
            // Node colors
            VStack(alignment: .leading, spacing: 6) {
                Text("Subjects")
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 12) {
                    legendItem(color: "#0084FF", label: "ELA")
                    legendItem(color: "#AF52DE", label: "Math")
                    legendItem(color: "#34C759", label: "Science")
                }
            }
            
            Divider()
            
            // Edge strength
            VStack(alignment: .leading, spacing: 6) {
                Text("Correlation Strength")
                    .font(.subheadline.weight(.medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Rectangle()
                            .fill(Color(hex: "#32D74B") ?? .green)
                            .frame(width: 20, height: 3)
                        Text("Strong (r≥0.7)")
                            .font(.caption)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(Color(hex: "#FF9F0A") ?? .orange)
                            .frame(width: 20, height: 2)
                        Text("Moderate (r≥0.5)")
                            .font(.caption)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(Color(hex: "#8E8E93") ?? .gray)
                            .frame(width: 20, height: 1)
                        Text("Weak (r<0.5)")
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            // Significance indicators
            VStack(alignment: .leading, spacing: 6) {
                Text("Significance")
                    .font(.subheadline.weight(.medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("⭐")
                        Text("p < 0.01 (Highly Significant)")
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("☆")
                        Text("p < 0.05 (Significant)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1).opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
    
    private func legendItem(color: String, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: color) ?? .gray)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
        }
    }
}

// MARK: - Node Detail View

struct NodeDetailView: View {
    let component: ComponentIdentifier
    let processor: CorrelationNetworkProcessor
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Component info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(component.description)
                            .font(.title2.weight(.semibold))
                        
                        HStack {
                            Label("Grade \(component.grade)", systemImage: "graduationcap")
                            Label(component.subject, systemImage: "book")
                            Label(component.testProvider.rawValue, systemImage: "checkmark.seal")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Correlation statistics
                    if let node = processor.networkNodes.first(where: { $0.id == component }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Network Statistics")
                                .font(.headline)
                            
                            Grid(alignment: .leading) {
                                GridRow {
                                    Text("Connections:")
                                        .fontWeight(.medium)
                                    Text("\(node.connectionCount)")
                                }
                                GridRow {
                                    Text("Node Size:")
                                        .fontWeight(.medium)
                                    Text("\(node.nodeSize, specifier: "%.1f") points")
                                }
                            }
                            .font(.subheadline)
                        }
                        
                        Divider()
                    }
                    
                    // Top correlations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Strongest Correlations")
                            .font(.headline)
                        
                        let topCorrelations = getTopCorrelations(for: component)
                        
                        if topCorrelations.isEmpty {
                            Text("No correlations available")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(topCorrelations.prefix(10), id: \.id) { correlation in
                                CorrelationRowView(correlation: correlation)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Component Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getTopCorrelations(for component: ComponentIdentifier) -> [FilteredCorrelationResult] {
        return processor.filteredCorrelations
            .filter { $0.source == component || $0.target == component }
            .sorted { abs($0.correlation) > abs($1.correlation) }
    }
}

struct CorrelationRowView: View {
    let correlation: FilteredCorrelationResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(correlation.target.description)
                    .font(.subheadline.weight(.medium))
                Text(correlation.target.component)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                HStack {
                    Text(correlation.significance.rawValue)
                    Text("\(correlation.correlation, specifier: "%.3f")")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(correlation.correlation > 0 ? .blue : .red)
                }
                
                Text("n=\(correlation.sampleSize)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}