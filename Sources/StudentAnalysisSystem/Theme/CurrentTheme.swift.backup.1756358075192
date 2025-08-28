import SwiftUI

// MARK: - Current Theme Access
/// Provides easy access to the current theme throughout the app
/// Usage: CurrentTheme.colors.primaryBackground
@MainActor
struct CurrentTheme {
    // Use a static reference instead of @EnvironmentObject for global access
    private static let defaultTheme = AppleTheme()
    
    static var colors: ThemeColors {
        defaultTheme.colors
    }
    
    static var typography: ThemeTypography {
        defaultTheme.typography
    }
    
    static var layout: ThemeLayout {
        defaultTheme.layout
    }
    
    static var corners: ThemeCorners {
        defaultTheme.corners
    }
    
    static var shadows: ThemeShadows {
        defaultTheme.shadows
    }
    
    static var current: Theme {
        defaultTheme
    }
}

// MARK: - Environment Extension for Theme Access
private struct CurrentThemeKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: Theme = AppleTheme()
}

extension EnvironmentValues {
    var currentTheme: Theme {
        get { self[CurrentThemeKey.self] }
        set { self[CurrentThemeKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme Usage
extension View {
    /// Injects the current theme into the environment
    func withCurrentTheme(_ themeManager: ThemeManager) -> some View {
        self.environment(\.currentTheme, themeManager.currentTheme)
    }
    
    /// Quick access to theme-based styling
    func themedBackground() -> some View {
        self.background(CurrentTheme.colors.primaryBackground)
    }
    
    func themedCard() -> some View {
        self
            .background(CurrentTheme.colors.secondaryBackground)
            .cornerRadius(CurrentTheme.corners.medium)
            .tacticalBorder() // Only applies if using TacticalTheme
    }
    
    func themedText(style: ThemeTextStyle = .primary) -> some View {
        self.foregroundColor(style.color)
    }
}

// MARK: - Theme Text Styles
enum ThemeTextStyle {
    case primary, secondary, tertiary, success, error, warning, info
    
    @MainActor
    var color: Color {
        switch self {
        case .primary: return CurrentTheme.colors.primaryText
        case .secondary: return CurrentTheme.colors.secondaryText
        case .tertiary: return CurrentTheme.colors.tertiaryText
        case .success: return CurrentTheme.colors.success
        case .error: return CurrentTheme.colors.error
        case .warning: return CurrentTheme.colors.warning
        case .info: return CurrentTheme.colors.info
        }
    }
}

// MARK: - Theme Button Styles
enum ThemeButtonStyle {
    case primary, secondary
    
    @MainActor
    var backgroundColor: Color {
        switch self {
        case .primary: return CurrentTheme.colors.buttonPrimary
        case .secondary: return CurrentTheme.colors.buttonSecondary
        }
    }
    
    @MainActor
    var foregroundColor: Color {
        switch self {
        case .primary: return CurrentTheme.colors.primaryBackground
        case .secondary: return CurrentTheme.colors.primaryText
        }
    }
}