import SwiftUI

// MARK: - Theme Protocol
/// Protocol that defines a complete theme system
/// Allows custom themes while maintaining Apple HIG structure
protocol Theme {
    // MARK: - Identity
    /// name property
    var name: String { get }
    /// id property
    var id: String { get }
    
    // MARK: - Color System
    /// colors property
    var colors: ThemeColors { get }
    
    // MARK: - Typography (inherits from Apple but allows customization)
    /// typography property
    var typography: ThemeTypography { get }
    
    // MARK: - Layout & Spacing (can be customized)
    /// layout property
    var layout: ThemeLayout { get }
    
    // MARK: - Visual Properties
    /// corners property
    var corners: ThemeCorners { get }
    /// shadows property
    var shadows: ThemeShadows { get }
}

// MARK: - Theme Color System
protocol ThemeColors {
    // MARK: - Background Colors
    /// primaryBackground property
    var primaryBackground: Color { get }
    /// secondaryBackground property
    var secondaryBackground: Color { get }
    /// tertiaryBackground property
    var tertiaryBackground: Color { get }
    
    // MARK: - Text Colors
    /// primaryText property
    var primaryText: Color { get }
    /// secondaryText property
    var secondaryText: Color { get }
    /// tertiaryText property
    var tertiaryText: Color { get }
    
    // MARK: - Brand Colors
    /// brandPrimary property
    var brandPrimary: Color { get }
    /// brandSecondary property
    var brandSecondary: Color { get }
    /// brandAccent property
    var brandAccent: Color { get }
    
    // MARK: - Semantic Colors
    /// success property
    var success: Color { get }
    /// error property
    var error: Color { get }
    /// warning property
    var warning: Color { get }
    /// info property
    var info: Color { get }
    
    // MARK: - Interactive Colors
    /// buttonPrimary property
    var buttonPrimary: Color { get }
    /// buttonSecondary property
    var buttonSecondary: Color { get }
    /// inputBackground property
    var inputBackground: Color { get }
    /// inputBorder property
    var inputBorder: Color { get }
    /// separator property
    var separator: Color { get }
}

// MARK: - Theme Typography
protocol ThemeTypography {
    // MARK: - Titles
    /// largeTitle property
    var largeTitle: Font { get }
    /// title1 property
    var title1: Font { get }
    /// title2 property
    var title2: Font { get }
    /// title3 property
    var title3: Font { get }
    
    // MARK: - Body Text
    /// headline property
    var headline: Font { get }
    /// body property
    var body: Font { get }
    /// bodyEmphasized property
    var bodyEmphasized: Font { get }
    /// callout property
    var callout: Font { get }
    /// subheadline property
    var subheadline: Font { get }
    
    // MARK: - Small Text
    /// footnote property
    var footnote: Font { get }
    /// caption property
    var caption: Font { get }
    /// caption2 property
    var caption2: Font { get }
}

// MARK: - Theme Layout
protocol ThemeLayout {
    // MARK: - Spacing Scale
    /// spacingXS property
    var spacingXS: CGFloat { get }
    /// spacingSmall property
    var spacingSmall: CGFloat { get }
    /// spacingMedium property
    var spacingMedium: CGFloat { get }
    /// spacingLarge property
    var spacingLarge: CGFloat { get }
    /// spacingXL property
    var spacingXL: CGFloat { get }
    /// spacingXXL property
    var spacingXXL: CGFloat { get }
    
    // MARK: - Container Padding
    /// containerPadding property
    var containerPadding: EdgeInsets { get }
    /// cardPadding property
    var cardPadding: EdgeInsets { get }
    /// buttonPadding property
    var buttonPadding: EdgeInsets { get }
}

// MARK: - Theme Corners
protocol ThemeCorners {
    /// small property
    var small: CGFloat { get }
    /// medium property
    var medium: CGFloat { get }
    /// large property
    var large: CGFloat { get }
    /// extraLarge property
    var extraLarge: CGFloat { get }
}

// MARK: - Theme Shadows
protocol ThemeShadows {
    /// small property
    var small: (color: Color, radius: CGFloat, offset: CGSize) { get }
    /// medium property
    var medium: (color: Color, radius: CGFloat, offset: CGSize) { get }
    /// large property
    var large: (color: Color, radius: CGFloat, offset: CGSize) { get }
}