import SwiftUI

// Adaptive color extensions are now part of AppleDesignSystem.AdaptiveColors
// This file provides backward compatibility aliases

extension Color {
    /// adaptiveBackground property
    static var adaptiveBackground: Color {
        AppleDesignSystem.SystemColors.background
    }
    
    /// adaptiveSecondaryBackground property
    static var adaptiveSecondaryBackground: Color {
        AppleDesignSystem.SystemColors.secondaryBackground
    }
    
    /// adaptiveLabel property
    static var adaptiveLabel: Color {
        AppleDesignSystem.SystemColors.label
    }
    
    /// adaptiveSecondaryLabel property
    static var adaptiveSecondaryLabel: Color {
        AppleDesignSystem.SystemColors.secondaryLabel
    }
    
    /// adaptiveSeparator property
    static var adaptiveSeparator: Color {
        AppleDesignSystem.SystemColors.separator
    }
}