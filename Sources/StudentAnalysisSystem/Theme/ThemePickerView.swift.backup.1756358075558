import SwiftUI

// MARK: - Theme Picker View
struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current theme preview
                currentThemePreview
                
                Divider()
                
                // Theme selection list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(themeManager.themes, id: \.id) { theme in
                            ThemeOptionCard(
                                theme: theme,
                                isSelected: theme.id == themeManager.currentTheme.id,
                                onSelect: {
                                    themeManager.setTheme(theme)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Theme")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .themed()
    }
    
    private var currentThemePreview: some View {
        VStack(spacing: 12) {
            Text("Current Theme")
                .font(CurrentTheme.typography.headline)
                .foregroundColor(CurrentTheme.colors.secondaryText)
            
            Text(themeManager.currentTheme.name)
                .font(CurrentTheme.typography.title2)
                .foregroundColor(CurrentTheme.colors.primaryText)
            
            // Mini preview
            HStack(spacing: 8) {
                Circle()
                    .fill(CurrentTheme.colors.brandPrimary)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(CurrentTheme.colors.success)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(CurrentTheme.colors.warning)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(CurrentTheme.colors.error)
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(CurrentTheme.colors.secondaryBackground)
    }
}

// MARK: - Theme Option Card
private struct ThemeOptionCard: View {
    let theme: Theme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Theme preview
                VStack(spacing: 8) {
                    // Color palette preview
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(theme.colors.primaryBackground)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Rectangle()
                                    .stroke(theme.colors.separator, lineWidth: 1)
                            )
                        
                        Rectangle()
                            .fill(theme.colors.brandPrimary)
                            .frame(width: 20, height: 20)
                        
                        Rectangle()
                            .fill(theme.colors.success)
                            .frame(width: 20, height: 20)
                        
                        Rectangle()
                            .fill(theme.colors.error)
                            .frame(width: 20, height: 20)
                    }
                    
                    // Typography preview
                    Text("Aa")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.primaryText)
                        .padding(AppleDesignSystem.Spacing.xs)
                        .background(theme.colors.secondaryBackground)
                        .cornerRadius(theme.corners.small)
                }
                
                // Theme info
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(CurrentTheme.typography.headline)
                        .foregroundColor(CurrentTheme.colors.primaryText)
                    
                    Text(themeDescription(for: theme))
                        .font(CurrentTheme.typography.caption)
                        .foregroundColor(CurrentTheme.colors.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CurrentTheme.colors.success)
                        .font(AppleDesignSystem.Typography.title2)
                }
            }
            .padding()
            .background(CurrentTheme.colors.secondaryBackground)
            .cornerRadius(CurrentTheme.corners.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CurrentTheme.corners.medium)
                    .stroke(
                        isSelected ? CurrentTheme.colors.brandPrimary : CurrentTheme.colors.separator,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func themeDescription(for theme: Theme) -> String {
        switch theme.id {
        case "apple":
            return "Apple's Human Interface Guidelines with system colors and typography"
        case "tactical":
            return "Dark intelligence dashboard with monospace typography and tactical accents"
        default:
            return "Custom theme"
        }
    }
}

// MARK: - Theme Settings Section
struct ThemeSettingsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingThemePicker = false
    
    var body: some View {
        Section("Appearance") {
            // Light/Dark mode selector
            HStack {
                Label("Appearance", systemImage: "paintbrush")
                Spacer()
                Picker("Theme Mode", selection: $themeManager.selectedThemeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Label(mode.name, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Theme selector
            Button(action: {
                showingThemePicker = true
            }) {
                HStack {
                    Label("Theme", systemImage: "eyedropper.full")
                    Spacer()
                    Text(themeManager.currentTheme.name)
                        .foregroundColor(CurrentTheme.colors.secondaryText)
                    Image(systemName: "chevron.right")
                        .foregroundColor(CurrentTheme.colors.tertiaryText)
                        .font(AppleDesignSystem.Typography.caption)
                }
                .foregroundColor(CurrentTheme.colors.primaryText)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environmentObject(themeManager)
        }
    }
}

#Preview {
    ThemePickerView()
        .environmentObject(ThemeManager())
}