import AnalysisCore
import Charts
import IndividualLearningPlan
import SwiftUI

/// ILPDetailView represents...
struct ILPDetailView: View {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    /// ilp property
    let ilp: IndividualLearningPlan
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var selectedObjectiveCategory: String = "All"
    @State private var expandedMilestones: Set<String> = []
    /// dismiss property
    @Environment(\.dismiss) var dismiss
    
    /// body property
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Divider()
                
                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Label("Overview", systemImage: "square.grid.2x2").tag(0)
                    Label("Learning Objectives", systemImage: "list.bullet.rectangle").tag(1)
                    Label("Interventions", systemImage: "lightbulb").tag(2)
                    Label("Milestones", systemImage: "flag").tag(3)
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis").tag(4)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case 0:
                        overviewTab
                    case 1:
                        learningObjectivesTab
                    case 2:
                        interventionsTab
                    case 3:
                        milestonesTab
                    case 4:
                        progressTab
                    default:
                        overviewTab
                    }
                }
            }
            .navigationTitle("Individual Learning Plan")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: { showingExportSheet = true }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: print) {
                            Label("Print", systemImage: "printer")
                        }
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportOptionsSheet(ilp: ilp)
                .frame(width: 400, height: 300)
        }
        .themed()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 20) {
            // Student info
            VStack(alignment: .leading, spacing: 8) {
                Text(ilp.studentInfo.name)
                    .font(AppleDesignSystem.Typography.title2)
                    .bold()
                
                HStack(spacing: 16) {
                    Label("MSIS: \(ilp.studentMSIS)", systemImage: "number")
                    Label("Grade \(ilp.currentGrade)", systemImage: "graduationcap")
                    Label(ilp.planType.rawValue.capitalized, systemImage: planTypeIcon)
                        .foregroundStyle(planTypeColor)
                }
                .font(AppleDesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Plan metadata
            VStack(alignment: .trailing, spacing: 8) {
                Text("Created: \(ilp.createdDate, format: .dateTime.month().day().year())")
                    .font(AppleDesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                
                /// targetDate property
                if let targetDate = ilp.targetCompletionDate {
                    Text("Target: \(targetDate, format: .dateTime.month().day().year())")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Performance Summary Card
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Performance Summary", systemImage: "chart.bar.xaxis")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    // Performance summary display
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall Score: \(ilp.performanceSummary.overallScore, specifier: "%.1f")")
                            .font(AppleDesignSystem.Typography.subheadline)
                        Text("Proficiency: \(ilp.performanceSummary.proficiencyLevel.rawValue)")
                            .font(AppleDesignSystem.Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            
            // Focus Areas Grid
            if !ilp.focusAreas.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Priority Focus Areas", systemImage: "target")
                            .font(AppleDesignSystem.Typography.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(ilp.focusAreas) { area in
                                FocusAreaDetailCard(area: area)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Quick Stats
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Plan Statistics", systemImage: "chart.pie")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    HStack(spacing: 20) {
                        ILPStatCard(
                            title: "Objectives",
                            value: "\(ilp.learningObjectives.count)",
                            icon: "list.bullet",
                            color: AppleDesignSystem.SystemPalette.blue
                        )
                        
                        ILPStatCard(
                            title: "Interventions",
                            value: "\(ilp.interventionStrategies.count)",
                            icon: "lightbulb",
                            color: AppleDesignSystem.SystemPalette.orange
                        )
                        
                        ILPStatCard(
                            title: "Milestones",
                            value: "\(ilp.milestones.count)",
                            icon: "flag",
                            color: AppleDesignSystem.SystemPalette.green
                        )
                        
                        ILPStatCard(
                            title: "Timeline",
                            value: "\(ilp.timeline.phases.count) phases",
                            icon: "calendar",
                            color: AppleDesignSystem.SystemPalette.purple
                        )
                    }
                }
                .padding()
            }
        }
        .padding()
    }
    
    // MARK: - Learning Objectives Tab
    
    private var learningObjectivesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(objectiveCategories, id: \.self) { category in
                        Button(action: { selectedObjectiveCategory = category }) {
                            Text(category)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedObjectiveCategory == category ? AppleDesignSystem.SystemPalette.blue : Color(NSColor.controlBackgroundColor))
                                .foregroundStyle(selectedObjectiveCategory == category ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            
            // Objectives List
            ForEach(filteredObjectives) { objective in
                LearningObjectiveCard(objective: objective)
            }
            
            if filteredObjectives.isEmpty {
                ContentUnavailableView(
                    "No Objectives",
                    systemImage: "list.bullet.rectangle",
                    description: Text("No learning objectives found for this category")
                )
            }
        }
        .padding()
    }
    
    // MARK: - Interventions Tab
    
    private var interventionsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(ilp.interventionStrategies.enumerated()), id: \.offset) { index, strategy in
                InterventionStrategyCard(strategy: strategy)
            }
            
            if ilp.interventionStrategies.isEmpty {
                ContentUnavailableView(
                    "No Interventions",
                    systemImage: "lightbulb",
                    description: Text("No intervention strategies have been defined")
                )
            }
        }
        .padding()
    }
    
    // MARK: - Milestones Tab
    
    private var milestonesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Timeline visualization
            if !ilp.timeline.milestones.isEmpty {
                TimelineView(milestones: ilp.timeline.milestones)
                    .frame(height: 100)
                    .padding(.horizontal)
            }
            
            // Milestone cards
            ForEach(ilp.milestones) { milestone in
                MilestoneCard(
                    milestone: milestone,
                    isExpanded: expandedMilestones.contains(milestone.id),
                    onToggle: {
                        withAnimation {
                            if expandedMilestones.contains(milestone.id) {
                                expandedMilestones.remove(milestone.id)
                            } else {
                                expandedMilestones.insert(milestone.id)
                            }
                        }
                    }
                )
            }
            
            if ilp.milestones.isEmpty {
                ContentUnavailableView(
                    "No Milestones",
                    systemImage: "flag",
                    description: Text("No milestones have been defined")
                )
            }
        }
        .padding()
    }
    
    // MARK: - Progress Tab
    
    private var progressTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Progress Overview
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Progress Tracking", systemImage: "chart.line.uptrend.xyaxis")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    Text("Progress tracking will be available after the first evaluation period")
                        .font(AppleDesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Placeholder progress chart
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .imageScale(.large)
                                    .foregroundStyle(.secondary)
                                Text("Progress data will appear here")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
                .padding()
            }
            
            // Evaluation Schedule
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Evaluation Schedule", systemImage: "calendar")
                        .font(AppleDesignSystem.Typography.headline)
                    
                    ForEach(ilp.timeline.phases) { phase in
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(phase.name)
                                        .font(AppleDesignSystem.Typography.subheadline)
                                    Text("\(phase.startDate, format: .dateTime.month().day()) - \(phase.endDate, format: .dateTime.month().day())")
                                        .font(AppleDesignSystem.Typography.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(phase.activities.count) activities")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                }
                .padding()
            }
        }
        .padding()
    }
    
    // MARK: - Helper Properties
    
    private var planTypeIcon: String {
        switch ilp.planType {
        case .auto: return "wand.and.stars"
        case .remediation: return "arrow.up.circle"
        case .enrichment: return "star.circle"
        }
    }
    
    private var planTypeColor: Color {
        switch ilp.planType {
        case .auto: return AppleDesignSystem.SystemPalette.blue
        case .remediation: return AppleDesignSystem.SystemPalette.orange
        case .enrichment: return AppleDesignSystem.SystemPalette.green
        }
    }
    
    private var objectiveCategories: [String] {
        /// categories property
        var categories = Set<String>()
        categories.insert("All")
        
        for objective in ilp.learningObjectives {
            /// standard property
            if let standard = objective.standard {
                /// components property
                let components = standard.split(separator: ".")
                if !components.isEmpty {
                    categories.insert(String(components[0]))
                }
            }
        }
        
        return Array(categories).sorted()
    }
    
    private var filteredObjectives: [LearningObjective] {
        if selectedObjectiveCategory == "All" {
            return ilp.learningObjectives
        }
        
        return ilp.learningObjectives.filter { objective in
            /// standard property
            guard let standard = objective.standard else { return false }
            return standard.hasPrefix(selectedObjectiveCategory)
        }
    }
    
    private func print() {
        // Print functionality would be implemented here
        NSApp.keyWindow?.printWindow(nil)
    }
}

// MARK: - Supporting Views

/// FocusAreaDetailCard represents...
struct FocusAreaDetailCard: View {
    /// area property
    let area: WeakArea
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(severityColor(area.gap))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(area.component)
                        .font(AppleDesignSystem.Typography.headline)
                    Text(area.description)
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(area.severity * 100))%")
                        .font(AppleDesignSystem.Typography.headline)
                        .foregroundStyle(severityColor(area.severity))
                    Text("severity")
                        .font(AppleDesignSystem.Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !area.components.isEmpty {
                HStack {
                    ForEach(area.components.prefix(3), id: \.self) { component in
                        Text(component)
                            .font(AppleDesignSystem.Typography.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(Capsule())
                    }
                    
                    if area.components.count > 3 {
                        Text("+\(area.components.count - 3)")
                            .font(AppleDesignSystem.Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func severityColor(_ severity: Double) -> Color {
        switch severity {
        case 0.8...: return AppleDesignSystem.SystemPalette.red
        case 0.6..<0.8: return AppleDesignSystem.SystemPalette.orange
        case 0.4..<0.6: return AppleDesignSystem.SystemPalette.yellow
        default: return AppleDesignSystem.SystemPalette.green
        }
    }
    
    private func iconForSubject(_ subject: String) -> String {
        if subject.lowercased().contains("math") {
            return "function"
        } else if subject.lowercased().contains("ela") || subject.lowercased().contains("english") {
            return "text.book.closed"
        } else {
            return "book"
        }
    }
}

/// ILPStatCard represents...
struct ILPStatCard: View {
    /// title property
    let title: String
    /// value property
    let value: String
    /// icon property
    let icon: String
    /// color property
    let color: Color
    
    /// body property
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.large)
            
            Text(value)
                .font(AppleDesignSystem.Typography.title3)
                .bold()
            
            Text(title)
                .font(AppleDesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// LearningObjectiveCard represents...
struct LearningObjectiveCard: View {
    /// objective property
    let objective: LearningObjective
    @State private var isExpanded = false
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(AppleDesignSystem.SystemPalette.blue)
                
                VStack(alignment: .leading) {
                    Text(objective.description)
                        .font(AppleDesignSystem.Typography.subheadline)
                    
                    Text("Standard: \(objective.standardId)")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider()
                
                /// expectations property
                let expectations = objective.expectations
                VStack(alignment: .leading, spacing: 8) {
                    /// knowledge property
                    if let knowledge = expectations.knowledge, !knowledge.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Knowledge")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .bold()
                                ForEach(knowledge, id: \.self) { item in
                                    Text("• \(item)")
                                        .font(AppleDesignSystem.Typography.caption)
                                }
                            }
                        }
                        
                        /// understanding property
                        if let understanding = expectations.understanding, !understanding.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Understanding")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .bold()
                                ForEach(understanding, id: \.self) { item in
                                    Text("• \(item)")
                                        .font(AppleDesignSystem.Typography.caption)
                                }
                            }
                        }
                        
                        /// skills property
                        if let skills = expectations.skills, !skills.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Skills")
                                    .font(AppleDesignSystem.Typography.caption)
                                    .bold()
                                ForEach(skills, id: \.self) { item in
                                    Text("• \(item)")
                                        .font(AppleDesignSystem.Typography.caption)
                                }
                            }
                        }
                    }
                    .padding(.leading, 20)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// InterventionStrategyCard represents...
struct InterventionStrategyCard: View {
    /// strategy property
    let strategy: InterventionStrategy
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(tierColor(strategy.tier))
                
                VStack(alignment: .leading) {
                    Text("Tier \(strategy.tier.rawValue) Intervention")
                        .font(AppleDesignSystem.Typography.headline)
                    Text("Focus: \(strategy.focus.joined(separator: ", "))")
                        .font(AppleDesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(strategy.frequency)
                        .font(AppleDesignSystem.Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(Capsule())
                    
                    Text(strategy.duration)
                        .font(AppleDesignSystem.Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !strategy.instructionalApproach.isEmpty || !strategy.materials.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    if !strategy.instructionalApproach.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Approaches:")
                                .font(AppleDesignSystem.Typography.caption)
                                .bold()
                            
                            ForEach(strategy.instructionalApproach, id: \.self) { approach in
                                HStack {
                                    Image(systemName: "arrow.right")
                                        .imageScale(.small)
                                        .foregroundStyle(.secondary)
                                    Text(approach)
                                        .font(AppleDesignSystem.Typography.caption)
                                }
                            }
                        }
                    }
                    
                    if !strategy.materials.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Materials:")
                                .font(AppleDesignSystem.Typography.caption)
                                .bold()
                            
                            ForEach(strategy.materials.prefix(3), id: \.self) { material in
                                HStack {
                                    Image(systemName: "book")
                                        .imageScale(.small)
                                        .foregroundStyle(.secondary)
                                    Text(material)
                                        .font(AppleDesignSystem.Typography.caption)
                                }
                            }
                        }
                    }
                }
            }
            
            HStack {
                Label("Group: \(strategy.groupSize)", systemImage: "person.3")
                    .font(AppleDesignSystem.Typography.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(strategy.progressMonitoring, systemImage: "chart.line.uptrend.xyaxis")
                    .font(AppleDesignSystem.Typography.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func tierColor(_ tier: InterventionStrategy.InterventionTier) -> Color {
        switch tier {
        case .intensive: return AppleDesignSystem.SystemPalette.red
        case .strategic: return AppleDesignSystem.SystemPalette.orange
        case .universal: return AppleDesignSystem.SystemPalette.blue
        }
    }
}

/// MilestoneCard represents...
struct MilestoneCard: View {
    /// milestone property
    let milestone: Milestone
    /// isExpanded property
    let isExpanded: Bool
    /// onToggle property
    let onToggle: () -> Void
    
    /// body property
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(AppleDesignSystem.SystemPalette.green)
                
                VStack(alignment: .leading) {
                    Text(milestone.title)
                        .font(AppleDesignSystem.Typography.headline)
                    Text("Target: \(milestone.targetDate, format: .dateTime.month().day().year())")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Success Criteria:")
                        .font(AppleDesignSystem.Typography.caption)
                        .bold()
                    
                    // Display milestone details
                    Text("Assessment: \(milestone.assessmentType)")
                        .font(AppleDesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// TimelineView represents...
struct TimelineView: View {
    /// milestones property
    let milestones: [Milestone]
    
    /// body property
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Timeline line
                Path { path in
                    path.move(to: CGPoint(x: 20, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width - 20, y: geometry.size.height / 2))
                }
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                
                // Milestone points
                HStack(spacing: 0) {
                    ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                        VStack {
                            Circle()
                                .fill(AppleDesignSystem.SystemPalette.green)
                                .frame(width: 12, height: 12)
                            
                            Text(milestone.title)
                                .font(AppleDesignSystem.Typography.caption2)
                                .lineLimit(1)
        .truncationMode(.tail)
        .truncationMode(.tail)
                            
                            Text(milestone.targetDate, format: .dateTime.month().day())
                                .font(AppleDesignSystem.Typography.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

/// ExportOptionsSheet represents...
struct ExportOptionsSheet: View {
    /// ilp property
    let ilp: IndividualLearningPlan
    /// dismiss property
    @Environment(\.dismiss) var dismiss
    
    /// body property
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Options")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 12) {
                Button(action: { exportAs(.pdf) }) {
                    HStack {
                        Image(systemName: "doc.richtext")
                            .imageScale(.large)
                        Text("Export as PDF")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button(action: { exportAs(.markdown) }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .imageScale(.large)
                        Text("Export as Markdown")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: { exportAs(.csv) }) {
                    HStack {
                        Image(systemName: "tablecells")
                            .imageScale(.large)
                        Text("Export as CSV")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
        .padding()
    }
    
    private func exportAs(_ format: ExportFormat) {
        // Export functionality
        dismiss()
    }
}