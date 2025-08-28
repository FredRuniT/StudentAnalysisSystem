
import SwiftUI

// MARK: - Theme Library
/// Central registry for all available themes in the app builder
/// This makes it easy to add new themes and manage them centrally
struct ThemeLibrary {
    
    
    // MARK: - Theme Definition
    struct ThemeDefinition {
        let id: String
        let name: String
        let description: String
        let className: String
        let preview: ThemePreview
    }
    
    // MARK: - Theme Preview
    struct ThemePreview {
        let primaryColor: Color
        let secondaryColor: Color
        let backgroundColor: Color
        let fontStyle: Font.Design // .default, .monospaced, .serif, .rounded
    }
    
    // MARK: - Available Themes
    static let themes: [ThemeDefinition] = [
        ThemeDefinition(
            id: "apple",
            name: "Apple Design System",
            description: "Following Apple's Human Interface Guidelines with system colors and adaptive typography",
            className: "AppleTheme()",
            preview: ThemePreview(
                primaryColor: AppleDesignSystem.BrandColors.primary,
                secondaryColor: AppleDesignSystem.BrandColors.secondary,
                backgroundColor: AppleDesignSystem.SystemColors.background,
                fontStyle: .default
            )
        ),
        
        ThemeDefinition(
            id: "tactical",
            name: "Tactical Intelligence",
            description: "Dark intelligence dashboard with monospace typography and tactical accents",
            className: "TacticalTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#00FFFF") ?? .cyan, // Cyan
                secondaryColor: Color(hex: "#39FF14") ?? .green, // Electric green
                backgroundColor: Color.black,
                fontStyle: .monospaced
            )
        ),
        
        // Future themes can be added here:
        /*
        ThemeDefinition(
            id: "neon",
            name: "Neon Nights",
            description: "Vibrant neon colors with dark backgrounds inspired by cyberpunk aesthetics",
            className: "NeonTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#FF006E"), // Hot pink
                secondaryColor: Color(hex: "#00F5FF"), // Cyan
                backgroundColor: Color(hex: "#0A0A0A"),
                fontStyle: .default
            )
        ),
        
        ThemeDefinition(
            id: "minimal",
            name: "Minimal",
            description: "Clean, minimalist design with plenty of whitespace and subtle accents",
            className: "MinimalTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#2C3E50"),
                secondaryColor: Color(hex: "#95A5A6"),
                backgroundColor: Color(hex: "#FAFAFA"),
                fontStyle: .default
            )
        ),
        
        ThemeDefinition(
            id: "glass",
            name: "Glassmorphism",
            description: "Translucent materials with blur effects and subtle gradients",
            className: "GlassmorphismTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#6366F1"),
                secondaryColor: Color(hex: "#A78BFA"),
                backgroundColor: Color(hex: "#F8FAFC"),
                fontStyle: .rounded
            )
        ),
        
        ThemeDefinition(
            id: "retro",
            name: "Retro Terminal",
            description: "Classic terminal aesthetic with amber/green phosphor colors",
            className: "RetroTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#FFB000"), // Amber
                secondaryColor: Color(hex: "#00FF00"), // Green
                backgroundColor: Color(hex: "#0C0C0C"),
                fontStyle: .monospaced
            )
        ),
        
        ThemeDefinition(
            id: "nature",
            name: "Nature",
            description: "Organic colors inspired by forests and natural landscapes",
            className: "NatureTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#228B22"), // Forest green
                secondaryColor: Color(hex: "#8B4513"), // Saddle brown
                backgroundColor: Color(hex: "#F5F5DC"), // Beige
                fontStyle: .serif
            )
        ),
        
        ThemeDefinition(
            id: "corporate",
            name: "Corporate Professional",
            description: "Professional business theme with conservative colors",
            className: "CorporateTheme()",
            preview: ThemePreview(
                primaryColor: Color(hex: "#1E3A8A"), // Navy blue
                secondaryColor: Color(hex: "#64748B"), // Slate
                backgroundColor: Color.white,
                fontStyle: .default
            )
        )
        */
    ]
    
    // MARK: - Helper Methods
    
    /// Get theme definition by ID
    static func theme(for id: String) -> ThemeDefinition? {
        themes.first { $0.id == id }
    }
    
    /// Get class name for theme ID
    static func className(for id: String) -> String {
        theme(for: id)?.className ?? "AppleTheme()"
    }
    
    /// Get all theme IDs
    static var allThemeIDs: [String] {
        themes.map { $0.id }
    }
    
    /// Generate theme options for dropdown/picker
    static var themeOptions: [(id: String, name: String)] {
        themes.map { ($0.id, $0.name) }
    }
}

