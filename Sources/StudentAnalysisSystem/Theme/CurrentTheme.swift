import SwiftUI

// MARK: - Current Theme Access
/// Provides easy access to the current theme throughout the app
/// Usage: CurrentTheme.colors.primaryBackground
struct CurrentTheme {
    @EnvironmentObject private static var themeManager = ThemeManager()
    
    static var colors: ThemeColors {
        themeManager.currentTheme.colors
    }
    
    static var typography: ThemeTypography {
        themeManager.currentTheme.typography
    }
    
    static var layout: ThemeLayout {
        themeManager.currentTheme.layout
    }
    
    static var corners: ThemeCorners {
        themeManager.currentTheme.corners
    }
    
    static var shadows: ThemeShadows {
        themeManager.currentTheme.shadows
    }
    
    static var current: Theme {
        themeManager.currentTheme
    }
}

// MARK: - Environment Extension for Theme Access
private struct CurrentThemeKey: EnvironmentKey {
    static let defaultValue: Theme = AppleTheme()
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
    
    var backgroundColor: Color {
        switch self {
        case .primary: return CurrentTheme.colors.buttonPrimary
        case .secondary: return CurrentTheme.colors.buttonSecondary
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return CurrentTheme.colors.primaryBackground
        case .secondary: return CurrentTheme.colors.primaryText
        }
    }
}