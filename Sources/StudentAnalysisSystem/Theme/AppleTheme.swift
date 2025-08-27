import SwiftUI

// MARK: - Apple Theme Implementation
/// Default theme that uses Apple's design system
/// This maintains HIG compliance while allowing for custom overrides
struct AppleTheme: Theme {
    let name = "Apple"
    let id = "apple"
    
    let colors: ThemeColors = AppleThemeColors()
    let typography: ThemeTypography = AppleThemeTypography()
    let layout: ThemeLayout = AppleThemeLayout()
    let corners: ThemeCorners = AppleThemeCorners()
    let shadows: ThemeShadows = AppleThemeShadows()
}

// MARK: - Apple Theme Colors
struct AppleThemeColors: ThemeColors {
    // MARK: - Background Colors
    var primaryBackground: Color { AppleDesignSystem.SystemColors.background }
    var secondaryBackground: Color { AppleDesignSystem.SystemColors.secondaryBackground }
    var tertiaryBackground: Color { AppleDesignSystem.SystemColors.tertiaryBackground }
    
    // MARK: - Text Colors
    var primaryText: Color { AppleDesignSystem.SystemColors.label }
    var secondaryText: Color { AppleDesignSystem.SystemColors.secondaryLabel }
    var tertiaryText: Color { AppleDesignSystem.SystemColors.tertiaryLabel }
    
    // MARK: - Brand Colors
    var brandPrimary: Color { AppleDesignSystem.BrandColors.primary }
    var brandSecondary: Color { AppleDesignSystem.BrandColors.secondary }
    var brandAccent: Color { AppleDesignSystem.SystemColors.accent }
    
    // MARK: - Semantic Colors
    var success: Color { AppleDesignSystem.SystemPalette.success }
    var error: Color { AppleDesignSystem.SystemPalette.error }
    var warning: Color { AppleDesignSystem.SystemPalette.warning }
    var info: Color { AppleDesignSystem.SystemPalette.blue }
    
    // MARK: - Interactive Colors
    var buttonPrimary: Color { AppleDesignSystem.ComponentColors.primaryButtonBackground }
    var buttonSecondary: Color { AppleDesignSystem.ComponentColors.secondaryButtonBackground }
    var inputBackground: Color { AppleDesignSystem.ComponentColors.inputBackground }
    var inputBorder: Color { AppleDesignSystem.ComponentColors.inputBorder }
    var separator: Color { AppleDesignSystem.SystemColors.separator }
}

// MARK: - Apple Theme Typography
struct AppleThemeTypography: ThemeTypography {
    var largeTitle: Font { AppleDesignSystem.Typography.largeTitle }
    var title1: Font { AppleDesignSystem.Typography.title }
    var title2: Font { AppleDesignSystem.Typography.title2 }
    var title3: Font { AppleDesignSystem.Typography.title3 }
    
    var headline: Font { AppleDesignSystem.Typography.headline }
    var body: Font { AppleDesignSystem.Typography.body }
    var bodyEmphasized: Font { AppleDesignSystem.Typography.body.weight(.medium) }
    var callout: Font { AppleDesignSystem.Typography.callout }
    var subheadline: Font { AppleDesignSystem.Typography.subheadline }
    
    var footnote: Font { AppleDesignSystem.Typography.footnote }
    var caption: Font { AppleDesignSystem.Typography.caption }
    var caption2: Font { AppleDesignSystem.Typography.caption2 }
}

// MARK: - Apple Theme Layout
struct AppleThemeLayout: ThemeLayout {
    var spacingXS: CGFloat { AppleDesignSystem.Spacing.xs }
    var spacingSmall: CGFloat { AppleDesignSystem.Spacing.small }
    var spacingMedium: CGFloat { AppleDesignSystem.Spacing.medium }
    var spacingLarge: CGFloat { AppleDesignSystem.Spacing.large }
    var spacingXL: CGFloat { AppleDesignSystem.Spacing.xl }
    var spacingXXL: CGFloat { AppleDesignSystem.Spacing.xxl }
    
    var containerPadding: EdgeInsets { EdgeInsets(top: spacingMedium, leading: spacingMedium, bottom: spacingMedium, trailing: spacingMedium) }
    var cardPadding: EdgeInsets { EdgeInsets(top: spacingMedium, leading: spacingMedium, bottom: spacingMedium, trailing: spacingMedium) }
    var buttonPadding: EdgeInsets { EdgeInsets(top: spacingSmall, leading: spacingMedium, bottom: spacingSmall, trailing: spacingMedium) }
}

// MARK: - Apple Theme Corners
struct AppleThemeCorners: ThemeCorners {
    var small: CGFloat { AppleDesignSystem.Corners.small }
    var medium: CGFloat { AppleDesignSystem.Corners.medium }
    var large: CGFloat { AppleDesignSystem.Corners.large }
    var extraLarge: CGFloat { AppleDesignSystem.Corners.xl }
}

// MARK: - Apple Theme Shadows
struct AppleThemeShadows: ThemeShadows {
    var small: (color: Color, radius: CGFloat, offset: CGSize) {
        (AppleDesignSystem.Shadows.small, 2, CGSize(width: 0, height: 1))
    }
    
    var medium: (color: Color, radius: CGFloat, offset: CGSize) {
        (AppleDesignSystem.Shadows.medium, 4, CGSize(width: 0, height: 2))
    }
    
    var large: (color: Color, radius: CGFloat, offset: CGSize) {
        (AppleDesignSystem.Shadows.large, 8, CGSize(width: 0, height: 4))
    }
}