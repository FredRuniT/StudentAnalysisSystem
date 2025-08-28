import SwiftUI

// MARK: - Tactical Intelligence Theme
/// A dark spy-tech theme inspired by military intelligence dashboards
/// Features monospace typography, high contrast, and tactical color accents
struct TacticalTheme: Theme {
    let name = "Tactical Intelligence"
    let id = "tactical"
    
    let colors: ThemeColors = TacticalThemeColors()
    let typography: ThemeTypography = TacticalThemeTypography()
    let layout: ThemeLayout = TacticalThemeLayout()
    let corners: ThemeCorners = TacticalThemeCorners()
    let shadows: ThemeShadows = TacticalThemeShadows()
}

// MARK: - Tactical Theme Colors
struct TacticalThemeColors: ThemeColors {
    // MARK: - Background Colors (Deep Black Base)
    var primaryBackground: Color { Color(hex: "#000000") ?? .black }
    var secondaryBackground: Color { Color(hex: "#0A0A0A") ?? .black }
    var tertiaryBackground: Color { Color(hex: "#1A1A1A") ?? .black }
    
    // MARK: - Text Colors (Cool White with Opacity)
    var primaryText: Color { Color.white.opacity(0.9) }
    var secondaryText: Color { Color(hex: "#808080") ?? .gray }
    var tertiaryText: Color { Color(hex: "#666666") ?? .gray }
    
    // MARK: - Brand Colors (Tactical Accents)
    var brandPrimary: Color { Color(hex: "#00FFFF") ?? .cyan } // Cyan - primary tactical accent
    var brandSecondary: Color { Color(hex: "#39FF14") ?? AppleDesignSystem.SystemPalette.green } // Electric green - secondary
    var brandAccent: Color { Color(hex: "#00FFFF") ?? .cyan } // Cyan accent
    
    // MARK: - Semantic Colors (High Contrast)
    var success: Color { Color(hex: "#39FF14") ?? AppleDesignSystem.SystemPalette.green } // Electric green
    var error: Color { Color(hex: "#FF0000") ?? AppleDesignSystem.SystemPalette.red } // Pure red
    var warning: Color { Color(hex: "#FFA500") ?? AppleDesignSystem.SystemPalette.orange } // Amber
    var info: Color { Color(hex: "#00FFFF") ?? .cyan } // Cyan
    
    // MARK: - Interactive Colors
    var buttonPrimary: Color { Color(hex: "#00FFFF") ?? .cyan }
    var buttonSecondary: Color { (Color(hex: "#333333") ?? .gray).opacity(0.8) }
    var inputBackground: Color { (Color(hex: "#1A1A1A") ?? .black).opacity(0.8) }
    var inputBorder: Color { Color(hex: "#333333") ?? .gray }
    var separator: Color { Color(hex: "#333333") ?? .gray }
}

// MARK: - Tactical Theme Typography (Monospace Focus)
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
    var largeTitle: Font { .custom(monoFont, size: 22).weight(.medium) }
    var title1: Font { .custom(monoFont, size: 20).weight(.medium) }
    var title2: Font { .custom(monoFont, size: 18).weight(.medium) }
    var title3: Font { .custom(monoFont, size: 16).weight(.medium) }
    
    // MARK: - Body Text (Dense and Technical)
    var headline: Font { .custom(monoFont, size: 14).weight(.semibold) }
    var body: Font { .custom(monoFont, size: 12) }
    var bodyEmphasized: Font { .custom(monoFont, size: 12).weight(.medium) }
    var callout: Font { .custom(monoFont, size: 11) }
    var subheadline: Font { .custom(monoFont, size: 11).weight(.medium) }
    
    // MARK: - Small Text (Terminal Style)
    var footnote: Font { .custom(monoFont, size: 10) }
    var caption: Font { .custom(monoFont, size: 9) }
    var caption2: Font { .custom(monoFont, size: 8) }
}

// MARK: - Tactical Theme Layout (Dense Information)
struct TacticalThemeLayout: ThemeLayout {
    // MARK: - Tight Spacing Scale (Information Dense)
    var spacingXS: CGFloat { 2 }
    var spacingSmall: CGFloat { 4 }
    var spacingMedium: CGFloat { 8 }
    var spacingLarge: CGFloat { 12 }
    var spacingXL: CGFloat { 16 }
    var spacingXXL: CGFloat { 24 }
    
    // MARK: - Container Padding (Minimal)
    var containerPadding: EdgeInsets { 
        EdgeInsets(top: spacingMedium, leading: spacingMedium, bottom: spacingMedium, trailing: spacingMedium) 
    }
    var cardPadding: EdgeInsets { 
        EdgeInsets(top: spacingSmall, leading: spacingMedium, bottom: spacingSmall, trailing: spacingMedium) 
    }
    var buttonPadding: EdgeInsets { 
        EdgeInsets(top: spacingXS, leading: spacingSmall, bottom: spacingXS, trailing: spacingSmall) 
    }
}

// MARK: - Tactical Theme Corners (Minimal/Sharp)
struct TacticalThemeCorners: ThemeCorners {
    var small: CGFloat { 2 } // Very minimal
    var medium: CGFloat { 3 } // Sharp, technical look
    var large: CGFloat { 4 } // Still sharp
    var extraLarge: CGFloat { 6 } // Maximum tactical roundness
}

// MARK: - Tactical Theme Shadows (Glows instead of shadows)
struct TacticalThemeShadows: ThemeShadows {
    var small: (color: Color, radius: CGFloat, offset: CGSize) {
        ((Color(hex: "#00FFFF") ?? .cyan).opacity(0.2), 1, CGSize.zero) // Cyan glow
    }
    
    var medium: (color: Color, radius: CGFloat, offset: CGSize) {
        ((Color(hex: "#00FFFF") ?? .cyan).opacity(0.3), 2, CGSize.zero) // Brighter cyan glow
    }
    
    var large: (color: Color, radius: CGFloat, offset: CGSize) {
        ((Color(hex: "#00FFFF") ?? .cyan).opacity(0.4), 4, CGSize.zero) // Intense cyan glow
    }
}

// MARK: - Tactical Theme Extensions
extension TacticalTheme {
    /// Additional tactical-specific colors for special effects
    struct SpecialEffects {
        static let scanlineColor = Color.white.opacity(0.05)
        static let noiseOverlay = Color.white.opacity(0.02)
        static let terminalGreen = Color(hex: "#39FF14") ?? AppleDesignSystem.SystemPalette.green
        static let alertRed = Color(hex: "#FF0000") ?? AppleDesignSystem.SystemPalette.red
        static let warningAmber = Color(hex: "#FFA500") ?? AppleDesignSystem.SystemPalette.orange
        static let dataBlue = Color(hex: "#0080FF") ?? AppleDesignSystem.SystemPalette.blue
    }
    
    /// Grid overlay settings for tactical aesthetic
    struct GridSystem {
        static let lineWidth: CGFloat = 0.5
        static let spacing: CGFloat = 20
        static let opacity: Double = 0.1
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