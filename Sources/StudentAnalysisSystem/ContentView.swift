import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingConfiguration = false
    @State private var isProcessing = false
    @State private var analysisProgress = 0.0
    @State private var statusMessage = "Ready to analyze"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                Section("Analysis") {
                    Label("Dashboard", systemImage: "chart.xyaxis.line")
                        .tag(0)
                    
                    Label("Early Warning", systemImage: "exclamationmark.triangle.fill")
                        .tag(1)
                    
                    Label("Correlation Matrix", systemImage: "chart.scatter")
                        .tag(2)
                    
                    Label("Network Visualization", systemImage: "circle.hexagongrid.fill")
                        .tag(3)
                    
                    Label("Student Reports", systemImage: "person.text.rectangle")
                        .tag(4)
                }
                
                Section("Data") {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                        .tag(5)
                    
                    Label("Data Overview", systemImage: "tablecells")
                        .tag(6)
                }
                
                Section("Settings") {
                    Label("Configuration", systemImage: "gearshape")
                        .tag(7)
                        .onTapGesture {
                            showingConfiguration = true
                        }
                }
            }
            .navigationTitle("Student Analysis System")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            // Detail View
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                case 1:
                    EarlyWarningDashboardView()
                case 2:
                    CorrelationTableView()
                case 3:
                    CorrelationNetworkView()
                case 4:
                    StudentReportsView()
                case 5:
                    DataImportView()
                case 6:
                    DataOverviewView()
                case 7:
                    ConfigurationOverviewView()
                default:
                    DashboardView()
                }
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            ConfigurationView()
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Analysis Dashboard")
                            .font(.largeTitle)
                            .bold()
                        Text("Mississippi MAAP Assessment Data (2023-2025)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    Button(action: {}) {
                        Label("Run Analysis", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                
                // Key Metrics
                HStack(spacing: 16) {
                    MetricCard(
                        title: "Total Students",
                        value: "25,946",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Components Analyzed",
                        value: "1,117",
                        icon: "chart.bar.fill",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Correlations",
                        value: "623,286",
                        icon: "arrow.triangle.merge",
                        color: .orange
                    )
                    
                    MetricCard(
                        title: "Risk Identified",
                        value: "3,842",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Charts Section
                HStack(spacing: 16) {
                    ChartCard(title: "Grade Distribution")
                    ChartCard(title: "Proficiency Trends")
                }
                .padding(.horizontal)
                
                HStack(spacing: 16) {
                    ChartCard(title: "Correlation Strength")
                    ChartCard(title: "Early Warning Accuracy")
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Early Warning Dashboard
struct EarlyWarningDashboardView: View {
    @State private var selectedGrade = 3
    @State private var riskLevel = "All"
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header with filters
            HStack {
                Text("Early Warning System")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Picker("Grade", selection: $selectedGrade) {
                    ForEach(3...12, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Risk Level", selection: $riskLevel) {
                    Text("All").tag("All")
                    Text("Critical").tag("Critical")
                    Text("High").tag("High")
                    Text("Moderate").tag("Moderate")
                    Text("Low").tag("Low")
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            .padding()
            
            // Risk Summary Cards
            HStack(spacing: 16) {
                RiskCard(level: "Critical", count: 342, color: .red)
                RiskCard(level: "High", count: 1284, color: .orange)
                RiskCard(level: "Moderate", count: 2216, color: .yellow)
                RiskCard(level: "Low", count: 8432, color: .green)
            }
            .padding(.horizontal)
            
            // Student List
            Text("At-Risk Students")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            List {
                ForEach(0..<10, id: \.self) { _ in
                    StudentRiskRow()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .imageScale(.large)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ChartCard: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Chart Placeholder")
                        .foregroundStyle(.secondary)
                )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RiskCard: View {
    let level: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(level)
                    .font(.headline)
            }
            
            Text("\(count)")
                .font(.title2)
                .bold()
            
            Text("students")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StudentRiskRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Student Name")
                    .font(.headline)
                Text("MSIS: 123456789")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Label("Math", systemImage: "function")
                    .foregroundStyle(.orange)
                Label("ELA", systemImage: "text.book.closed")
                    .foregroundStyle(.red)
            }
            
            Text("Critical")
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views
struct CorrelationAnalysisView: View {
    var body: some View {
        VStack {
            Text("Correlation Analysis")
                .font(.largeTitle)
                .bold()
            
            Text("Component correlation matrix and analysis tools")
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct StudentReportsView: View {
    var body: some View {
        VStack {
            Text("Student Reports")
                .font(.largeTitle)
                .bold()
            
            Text("Individual Learning Plans and progress reports")
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct DataImportView: View {
    var body: some View {
        VStack {
            Text("Data Import")
                .font(.largeTitle)
                .bold()
            
            Text("Import CSV assessment data")
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct DataOverviewView: View {
    var body: some View {
        VStack {
            Text("Data Overview")
                .font(.largeTitle)
                .bold()
            
            Text("View and manage imported assessment data")
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct ConfigurationOverviewView: View {
    @State private var showingFullConfig = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Configuration")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Button("Edit Configuration") {
                    showingFullConfig = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("Current analysis parameters")
                .foregroundStyle(.secondary)
            
            // Quick settings preview
            VStack(alignment: .leading, spacing: 16) {
                ConfigRow(label: "Minimum Correlation", value: "0.3")
                ConfigRow(label: "Strong Correlation Threshold", value: "0.7")
                ConfigRow(label: "Critical Risk Multiplier", value: "0.8")
                ConfigRow(label: "Enrichment Threshold", value: "85%")
                ConfigRow(label: "Growth Method", value: "Value Added")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingFullConfig) {
            ConfigurationView()
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}

struct ConfigRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    ContentView()
}