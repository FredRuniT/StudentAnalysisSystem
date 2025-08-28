import SwiftUI

// MARK: - Apple Theme Implementation
/// Default theme that uses Apple's design system
/// This maintains HIG compliance while allowing for custom overrides
struct AppleTheme: Theme {
    /// name property
    let name = "Apple"
    /// id property
    let id = "apple"
    
    /// colors property
    let colors: ThemeColors = AppleThemeColors()
    /// typography property
    let typography: ThemeTypography = AppleThemeTypography()
    /// layout property
    let layout: ThemeLayout = AppleThemeLayout()
    /// corners property
    let corners: ThemeCorners = AppleThemeCorners()
    /// shadows property
    let shadows: ThemeShadows = AppleThemeShadows()
}

// MARK: - Apple Theme Colors
/// AppleThemeColors represents...
struct AppleThemeColors: ThemeColors {
    // MARK: - Background Colors
    /// primaryBackground property
    var primaryBackground: Color { AppleDesignSystem.SystemColors.background }
    /// secondaryBackground property
    var secondaryBackground: Color { AppleDesignSystem.SystemColors.secondaryBackground }
    /// tertiaryBackground property
    var tertiaryBackground: Color { AppleDesignSystem.SystemColors.tertiaryBackground }
    
    // MARK: - Text Colors
    /// primaryText property
    var primaryText: Color { AppleDesignSystem.SystemColors.label }
    /// secondaryText property
    var secondaryText: Color { AppleDesignSystem.SystemColors.secondaryLabel }
    /// tertiaryText property
    var tertiaryText: Color { AppleDesignSystem.SystemColors.tertiaryLabel }
    
    // MARK: - Brand Colors
    /// brandPrimary property
    var brandPrimary: Color { AppleDesignSystem.BrandColors.primary }
    /// brandSecondary property
    var brandSecondary: Color { AppleDesignSystem.BrandColors.secondary }
    /// brandAccent property
    var brandAccent: Color { AppleDesignSystem.SystemColors.accent }
    
    // MARK: - Semantic Colors
    /// success property
    var success: Color { AppleDesignSystem.SystemPalette.success }
    /// error property
    var error: Color { AppleDesignSystem.SystemPalette.error }
    /// warning property
    var warning: Color { AppleDesignSystem.SystemPalette.warning }
    /// info property
    var info: Color { AppleDesignSystem.SystemPalette.blue }
    
    // MARK: - Interactive Colors
    /// buttonPrimary property
    var buttonPrimary: Color { AppleDesignSystem.ComponentColors.primaryButtonBackground }
    /// buttonSecondary property
    var buttonSecondary: Color { AppleDesignSystem.ComponentColors.secondaryButtonBackground }
    /// inputBackground property
    var inputBackground: Color { AppleDesignSystem.ComponentColors.inputBackground }
    /// inputBorder property
    var inputBorder: Color { AppleDesignSystem.ComponentColors.inputBorder }
    /// separator property
    var separator: Color { AppleDesignSystem.SystemColors.separator }
}

// MARK: - Apple Theme Typography
/// AppleThemeTypography represents...
struct AppleThemeTypography: ThemeTypography {
    /// largeTitle property
    var largeTitle: Font { AppleDesignSystem.Typography.largeTitle }
    /// title1 property
    var title1: Font { AppleDesignSystem.Typography.title }
    /// title2 property
    var title2: Font { AppleDesignSystem.Typography.title2 }
    /// title3 property
    var title3: Font { AppleDesignSystem.Typography.title3 }
    
    /// headline property
    var headline: Font { AppleDesignSystem.Typography.headline }
    /// body property
    var body: Font { AppleDesignSystem.Typography.body }
    /// bodyEmphasized property
    var bodyEmphasized: Font { AppleDesignSystem.Typography.body.weight(.medium) }
    /// callout property
    var callout: Font { AppleDesignSystem.Typography.callout }
    /// subheadline property
    var subheadline: Font { AppleDesignSystem.Typography.subheadline }
    
    /// footnote property
    var footnote: Font { AppleDesignSystem.Typography.footnote }
    /// caption property
    var caption: Font { AppleDesignSystem.Typography.caption }
    /// caption2 property
    var caption2: Font { AppleDesignSystem.Typography.caption2 }
}

// MARK: - Apple Theme Layout
/// AppleThemeLayout represents...
struct AppleThemeLayout: ThemeLayout {
    /// spacingXS property
    var spacingXS: CGFloat { AppleDesignSystem.Spacing.xs }
    /// spacingSmall property
    var spacingSmall: CGFloat { AppleDesignSystem.Spacing.small }
    /// spacingMedium property
    var spacingMedium: CGFloat { AppleDesignSystem.Spacing.medium }
    /// spacingLarge property
    var spacingLarge: CGFloat { AppleDesignSystem.Spacing.large }
    /// spacingXL property
    var spacingXL: CGFloat { AppleDesignSystem.Spacing.xl }
    /// spacingXXL property
    var spacingXXL: CGFloat { AppleDesignSystem.Spacing.xxl }
    
    /// containerPadding property
    var containerPadding: EdgeInsets { EdgeInsets(top: spacingMedium, leading: spacingMedium, bottom: spacingMedium, trailing: spacingMedium) }
    /// cardPadding property
    var cardPadding: EdgeInsets { EdgeInsets(top: spacingMedium, leading: spacingMedium, bottom: spacingMedium, trailing: spacingMedium) }
    /// buttonPadding property
    var buttonPadding: EdgeInsets { EdgeInsets(top: spacingSmall, leading: spacingMedium, bottom: spacingSmall, trailing: spacingMedium) }
}

// MARK: - Apple Theme Corners
/// AppleThemeCorners represents...
struct AppleThemeCorners: ThemeCorners {
    /// small property
    var small: CGFloat { AppleDesignSystem.Corners.small }
    /// medium property
    var medium: CGFloat { AppleDesignSystem.Corners.medium }
    /// large property
    var large: CGFloat { AppleDesignSystem.Corners.large }
    /// extraLarge property
    var extraLarge: CGFloat { AppleDesignSystem.Corners.xl }
}

// MARK: - Apple Theme Shadows
/// AppleThemeShadows represents...
struct AppleThemeShadows: ThemeShadows {
    /// small property
    var small: (color: Color, radius: CGFloat, offset: CGSize) {
        (AppleDesignSystem.Shadows.small, 2, CGSize(width: 0, height: 1))
    }
    
    /// medium property
    var medium: (color: Color, radius: CGFloat, offset: CGSize) {
        (AppleDesignSystem.Shadows.medium, 4, CGSize(width: 0, height: 2))
    }
    
    /// large property
    var large: (color: Color, radius: CGFloat, offset: CGSize) {
        (AppleDesignSystem.Shadows.large, 8, CGSize(width: 0, height: 4))
    }
}