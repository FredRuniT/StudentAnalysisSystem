import SwiftUI

// MARK: - Tactical Intelligence Theme
/// A dark spy-tech theme inspired by military intelligence dashboards
/// Features monospace typography, high contrast, and tactical color accents
struct TacticalTheme: Theme {
    /// name property
    let name = "Tactical Intelligence"
    /// id property
    let id = "tactical"
    
    /// colors property
    let colors: ThemeColors = TacticalThemeColors()
    /// typography property
    let typography: ThemeTypography = TacticalThemeTypography()
    /// layout property
    let layout: ThemeLayout = TacticalThemeLayout()
    /// corners property
    let corners: ThemeCorners = TacticalThemeCorners()
    /// shadows property
    let shadows: ThemeShadows = TacticalThemeShadows()
}

// MARK: - Tactical Theme Colors
/// TacticalThemeColors represents...
struct TacticalThemeColors: ThemeColors {
    // MARK: - Background Colors (Deep Black Base)
    /// primaryBackground property
    var primaryBackground: Color { Color(hex: "#000000") ?? .black }
    /// secondaryBackground property
    var secondaryBackground: Color { Color(hex: "#0A0A0A") ?? .black }
    /// tertiaryBackground property
    var tertiaryBackground: Color { Color(hex: "#1A1A1A") ?? .black }
    
    // MARK: - Text Colors (Cool White with Opacity)
    /// primaryText property
    var primaryText: Color { Color.white.opacity(0.9) }
    /// secondaryText property
    var secondaryText: Color { Color(hex: "#808080") ?? .gray }
    /// tertiaryText property
    var tertiaryText: Color { Color(hex: "#666666") ?? .gray }
    
    // MARK: - Brand Colors (Tactical Accents)
    /// brandPrimary property
    var brandPrimary: Color { Color(hex: "#00FFFF") ?? .cyan } // Cyan - primary tactical accent
    /// brandSecondary property
    var brandSecondary: Color { Color(hex: "#39FF14") ?? AppleDesignSystem.SystemPalette.green } // Electric green - secondary
    /// brandAccent property
    var brandAccent: Color { Color(hex: "#00FFFF") ?? .cyan } // Cyan accent
    
    // MARK: - Semantic Colors (High Contrast)
    /// success property
    var success: Color { Color(hex: "#39FF14") ?? AppleDesignSystem.SystemPalette.green } // Electric green
    /// error property
    var error: Color { Color(hex: "#FF0000") ?? AppleDesignSystem.SystemPalette.red } // Pure red
    /// warning property
    var warning: Color { Color(hex: "#FFA500") ?? AppleDesignSystem.SystemPalette.orange } // Amber
    /// info property
    var info: Color { Color(hex: "#00FFFF") ?? .cyan } // Cyan
    
    // MARK: - Interactive Colors
    /// buttonPrimary property
    var buttonPrimary: Color { Color(hex: "#00FFFF") ?? .cyan }
    /// buttonSecondary property
    var buttonSecondary: Color { (Color(hex: "#333333") ?? .gray).opacity(0.8) }
    /// inputBackground property
    var inputBackground: Color { (Color(hex: "#1A1A1A") ?? .black).opacity(0.8) }
    /// inputBorder property
    var inputBorder: Color { Color(hex: "#333333") ?? .gray }
    /// separator property
    var separator: Color { Color(hex: "#333333") ?? .gray }
}

// MARK: - Tactical Theme Typography (Monospace Focus)
/// TacticalThemeTypography represents...
struct TacticalThemeTypography: ThemeTypography {
    // MARK: - Monospace Font System
    private var monoFont: String {
        #if os(macOS)
        return "SF Mono"
        #else
        return "Menlo" // iOS fallback
        #endif
    }
    
    // MARK: - Titles (Compact for Information Density)
    /// largeTitle property
    var largeTitle: Font { .custom(monoFont, size: 22).weight(.medium) }
    /// title1 property
    var title1: Font { .custom(monoFont, size: 20).weight(.medium) }
    /// title2 property
    var title2: Font { .custom(monoFont, size: 18).weight(.medium) }
    /// title3 property
    var title3: Font { .custom(monoFont, size: 16).weight(.medium) }
    
    // MARK: - Body Text (Dense and Technical)
    /// headline property
    var headline: Font { .custom(monoFont, size: 14).weight(.semibold) }
    /// body property
    var body: Font { .custom(monoFont, size: 12) }
    /// bodyEmphasized property
    var bodyEmphasized: Font { .custom(monoFont, size: 12).weight(.medium) }
    /// callout property
    var callout: Font { .custom(monoFont, size: 11) }
    /// subheadline property
    var subheadline: Font { .custom(monoFont, size: 11).weight(.medium) }
    
    // MARK: - Small Text (Terminal Style)
    /// footnote property
    var footnote: Font { .custom(monoFont, size: 10) }
    /// caption property
    var caption: Font { .custom(monoFont, size: 9) }
    /// caption2 property
    var caption2: Font { .custom(monoFont, size: 8) }
}

// MARK: - Tactical Theme Layout (Dense Information)
/// TacticalThemeLayout represents...
struct TacticalThemeLayout: ThemeLayout {
    // MARK: - Tight Spacing Scale (Information Dense)
    /// spacingXS property
    var spacingXS: CGFloat { 2 }
    /// spacingSmall property
    var spacingSmall: CGFloat { 4 }
    /// spacingMedium property
    var spacingMedium: CGFloat { 8 }
    /// spacingLarge property
    var spacingLarge: CGFloat { 12 }
    /// spacingXL property
    var spacingXL: CGFloat { 16 }
    /// spacingXXL property
    var spacingXXL: CGFloat { 24 }
    
    // MARK: - Container Padding (Minimal)
    /// containerPadding property
    var containerPadding: EdgeInsets { 
        EdgeInsets(top: spacingMedium, leading: spacingMedium, bottom: spacingMedium, trailing: spacingMedium) 
    }
    /// cardPadding property
    var cardPadding: EdgeInsets { 
        EdgeInsets(top: spacingSmall, leading: spacingMedium, bottom: spacingSmall, trailing: spacingMedium) 
    }
    /// buttonPadding property
    var buttonPadding: EdgeInsets { 
        EdgeInsets(top: spacingXS, leading: spacingSmall, bottom: spacingXS, trailing: spacingSmall) 
    }
}

// MARK: - Tactical Theme Corners (Minimal/Sharp)
/// TacticalThemeCorners represents...
struct TacticalThemeCorners: ThemeCorners {
    /// small property
    var small: CGFloat { 2 } // Very minimal
    /// medium property
    var medium: CGFloat { 3 } // Sharp, technical look
    /// large property
    var large: CGFloat { 4 } // Still sharp
    /// extraLarge property
    var extraLarge: CGFloat { 6 } // Maximum tactical roundness
}

// MARK: - Tactical Theme Shadows (Glows instead of shadows)
/// TacticalThemeShadows represents...
struct TacticalThemeShadows: ThemeShadows {
    /// small property
    var small: (color: Color, radius: CGFloat, offset: CGSize) {
        ((Color(hex: "#00FFFF") ?? .cyan).opacity(0.2), 1, CGSize.zero) // Cyan glow
    }
    
    /// medium property
    var medium: (color: Color, radius: CGFloat, offset: CGSize) {
        ((Color(hex: "#00FFFF") ?? .cyan).opacity(0.3), 2, CGSize.zero) // Brighter cyan glow
    }
    
    /// large property
    var large: (color: Color, radius: CGFloat, offset: CGSize) {
        ((Color(hex: "#00FFFF") ?? .cyan).opacity(0.4), 4, CGSize.zero) // Intense cyan glow
    }
}

// MARK: - Tactical Theme Extensions
extension TacticalTheme {
    /// Additional tactical-specific colors for special effects
    struct SpecialEffects {
        /// scanlineColor property
        static let scanlineColor = Color.white.opacity(0.05)
        /// noiseOverlay property
        static let noiseOverlay = Color.white.opacity(0.02)
        /// terminalGreen property
        static let terminalGreen = Color(hex: "#39FF14") ?? AppleDesignSystem.SystemPalette.green
        /// alertRed property
        static let alertRed = Color(hex: "#FF0000") ?? AppleDesignSystem.SystemPalette.red
        /// warningAmber property
        static let warningAmber = Color(hex: "#FFA500") ?? AppleDesignSystem.SystemPalette.orange
        /// dataBlue property
        static let dataBlue = Color(hex: "#0080FF") ?? AppleDesignSystem.SystemPalette.blue
    }
    
    /// Grid overlay settings for tactical aesthetic
    struct GridSystem {
        /// lineWidth property
        static let lineWidth: CGFloat = 0.5
        /// spacing property
        static let spacing: CGFloat = 20
        /// opacity property
        static let opacity: Double = 0.1
        /// color property
        static let color = Color(hex: "#333333") ?? Color.gray
    }
}

// MARK: - Hex color support provided by Color+Hex.swift

// MARK: - Tactical UI Components
extension View {
    /// Applies tactical scanning line effect
    func tacticalScanlines() -> some View {
        self.overlay(
            TacticalScanlinesOverlay()
        )
    }
    
    /// Applies tactical glow effect
    func tacticalGlow(color: Color = Color(hex: "#00FFFF") ?? .cyan, radius: CGFloat = 2) -> some View {
        self.shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
    
    /// Applies tactical border
    func tacticalBorder(color: Color = Color(hex: "#333333") ?? .gray, width: CGFloat = 1) -> some View {
        self.overlay(
            Rectangle()
                .stroke(color, lineWidth: width)
        )
    }
}

// MARK: - Tactical Scanlines Overlay
private struct TacticalScanlinesOverlay: View {
    /// body property
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<100, id: \.self) { _ in
                Rectangle()
                    .fill(TacticalTheme.SpecialEffects.scanlineColor)
                    .frame(height: 1)
            }
        }
        .allowsHitTesting(false)
    }
}