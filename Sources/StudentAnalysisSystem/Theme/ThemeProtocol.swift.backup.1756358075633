import SwiftUI

// MARK: - Theme Protocol
/// Protocol that defines a complete theme system
/// Allows custom themes while maintaining Apple HIG structure
protocol Theme {
    // MARK: - Identity
    var name: String { get }
    var id: String { get }
    
    // MARK: - Color System
    var colors: ThemeColors { get }
    
    // MARK: - Typography (inherits from Apple but allows customization)
    var typography: ThemeTypography { get }
    
    // MARK: - Layout & Spacing (can be customized)
    var layout: ThemeLayout { get }
    
    // MARK: - Visual Properties
    var corners: ThemeCorners { get }
    var shadows: ThemeShadows { get }
}

// MARK: - Theme Color System
protocol ThemeColors {
    // MARK: - Background Colors
    var primaryBackground: Color { get }
    var secondaryBackground: Color { get }
    var tertiaryBackground: Color { get }
    
    // MARK: - Text Colors
    var primaryText: Color { get }
    var secondaryText: Color { get }
    var tertiaryText: Color { get }
    
    // MARK: - Brand Colors
    var brandPrimary: Color { get }
    var brandSecondary: Color { get }
    var brandAccent: Color { get }
    
    // MARK: - Semantic Colors
    var success: Color { get }
    var error: Color { get }
    var warning: Color { get }
    var info: Color { get }
    
    // MARK: - Interactive Colors
    var buttonPrimary: Color { get }
    var buttonSecondary: Color { get }
    var inputBackground: Color { get }
    var inputBorder: Color { get }
    var separator: Color { get }
}

// MARK: - Theme Typography
protocol ThemeTypography {
    // MARK: - Titles
    var largeTitle: Font { get }
    var title1: Font { get }
    var title2: Font { get }
    var title3: Font { get }
    
    // MARK: - Body Text
    var headline: Font { get }
    var body: Font { get }
    var bodyEmphasized: Font { get }
    var callout: Font { get }
    var subheadline: Font { get }
    
    // MARK: - Small Text
    var footnote: Font { get }
    var caption: Font { get }
    var caption2: Font { get }
}

// MARK: - Theme Layout
protocol ThemeLayout {
    // MARK: - Spacing Scale
    var spacingXS: CGFloat { get }
    var spacingSmall: CGFloat { get }
    var spacingMedium: CGFloat { get }
    var spacingLarge: CGFloat { get }
    var spacingXL: CGFloat { get }
    var spacingXXL: CGFloat { get }
    
    // MARK: - Container Padding
    var containerPadding: EdgeInsets { get }
    var cardPadding: EdgeInsets { get }
    var buttonPadding: EdgeInsets { get }
}

// MARK: - Theme Corners
protocol ThemeCorners {
    var small: CGFloat { get }
    var medium: CGFloat { get }
    var large: CGFloat { get }
    var extraLarge: CGFloat { get }
}

// MARK: - Theme Shadows
protocol ThemeShadows {
    var small: (color: Color, radius: CGFloat, offset: CGSize) { get }
    var medium: (color: Color, radius: CGFloat, offset: CGSize) { get }
    var large: (color: Color, radius: CGFloat, offset: CGSize) { get }
}