import AppKit
import SwiftUI

#if os(macOS)
#endif

/// ThemedView represents...
struct ThemedView: ViewModifier {
    /// themeManager property
    @EnvironmentObject var themeManager: ThemeManager
    /// systemColorScheme property
    @Environment(\.colorScheme) var systemColorScheme

    /// body function description
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(preferredColorScheme)
            .onAppear {
                themeManager.updateColorScheme(systemColorScheme)
            }
            .onChange(of: themeManager.selectedThemeMode) { _, _ in
                // Force UI update when theme mode changes
            }
    }

    private var preferredColorScheme: ColorScheme? {
        switch themeManager.selectedThemeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

extension View {
    /// themed function description
    func themed() -> some View {
        modifier(ThemedView())
    }
}

#if os(macOS)
// MARK: - Material Background Extensions
extension View {
    /// Applies a material background effect to the view
    /// - Parameters:
    ///   - material: The NSVisualEffectView.Material to apply
    ///   - blendingMode: The blending mode for the material (default: .behindWindow)
    ///   - emphasized: Whether the material should be emphasized (default: false)
    ///   - ignoresSafeArea: Whether to ignore safe area insets (default: true for proper material coverage)
    /// - Returns: A view with the material background applied
    func materialBackground(
        _ material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false,
        ignoresSafeArea: Bool = true
    ) -> some View {
        background(
            AppleDesignSystem.VisualEffectBackground(
                material: material,
                blendingMode: blendingMode,
                emphasized: emphasized
            )
            .ignoresSafeArea(ignoresSafeArea ? .all : [])
        )
    }
    
    /// Applies a material background using the type-safe MaterialType enum
    func materialBackground(
        _ type: AppleDesignSystem.MaterialType,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false
    ) -> some View {
        materialBackground(
            type.nsMaterial,
            blendingMode: blendingMode,
            emphasized: emphasized
        )
    }
    
    /// Applies a sidebar material background (convenience method)
    /// Uses NSVisualEffectView.Material.sidebar for proper macOS sidebar appearance
    func sidebarMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.sidebar, blendingMode: .behindWindow, emphasized: emphasized)
    }
    
    /// Applies a content background material (convenience method)
    /// Uses NSVisualEffectView.Material.contentBackground for main content areas
    func contentBackgroundMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.contentBackground, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies a window background material (convenience method)
    /// Uses NSVisualEffectView.Material.windowBackground for window backgrounds
    func windowBackgroundMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.windowBackground, blendingMode: .behindWindow, emphasized: emphasized)
    }
    
    /// Applies a header view material (convenience method)
    /// Uses NSVisualEffectView.Material.headerView for header/toolbar areas
    func headerMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.headerView, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies a menu material (convenience method)
    /// Uses NSVisualEffectView.Material.menu for menus
    func menuMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.menu, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies a toolbar material (convenience method)
    /// Uses NSVisualEffectView.Material.titlebar for toolbars
    func toolbarMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.titlebar, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies popover material (convenience method)
    /// Uses NSVisualEffectView.Material.popover for popovers
    func popoverMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.popover, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies HUD window material (convenience method)
    /// Uses NSVisualEffectView.Material.hudWindow for HUD windows
    func hudMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.hudWindow, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies sheet material (convenience method)
    /// Uses NSVisualEffectView.Material.sheet for sheet windows
    func sheetMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.sheet, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies selection material (convenience method)
    /// Uses NSVisualEffectView.Material.selection for selection indicators
    func selectionMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.selection, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies tooltip material (convenience method)
    /// Uses NSVisualEffectView.Material.toolTip for tooltips
    func tooltipMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.toolTip, blendingMode: .withinWindow, emphasized: emphasized)
    }
    
    /// Applies under page background material (convenience method)
    /// Uses NSVisualEffectView.Material.underPageBackground for document backgrounds
    func underPageBackgroundMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.underPageBackground, blendingMode: .behindWindow, emphasized: emphasized)
    }
    
    /// Applies under window background material (convenience method)
    /// Uses NSVisualEffectView.Material.underWindowBackground for under window areas
    func underWindowBackgroundMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.underWindowBackground, blendingMode: .behindWindow, emphasized: emphasized)
    }
    
    /// Applies full screen UI material (convenience method)
    /// Uses NSVisualEffectView.Material.fullScreenUI for full screen interfaces
    func fullScreenUIMaterial(emphasized: Bool = false) -> some View {
        materialBackground(.fullScreenUI, blendingMode: .behindWindow, emphasized: emphasized)
    }
}

// MARK: - Material-Aware Text Styles
extension Text {
    /// Applies primary label styling for use on materials
    func materialLabel() -> some View {
        self.foregroundColor(AppleDesignSystem.Materials.label)
    }
    
    /// Applies secondary label styling for use on materials
    func materialSecondaryLabel() -> some View {
        self.foregroundColor(AppleDesignSystem.Materials.secondaryLabel)
    }
    
    /// Applies tertiary label styling for use on materials
    func materialTertiaryLabel() -> some View {
        self.foregroundColor(AppleDesignSystem.Materials.tertiaryLabel)
    }
}

// MARK: - Material-Aware Shape Styles
extension ShapeStyle where Self == Color {
    /// Primary label color for use on materials
    static var materialLabel: Color { AppleDesignSystem.Materials.label }
    
    /// Secondary label color for use on materials
    static var materialSecondaryLabel: Color { AppleDesignSystem.Materials.secondaryLabel }
    
    /// Separator color for use on materials
    static var materialSeparator: Color { AppleDesignSystem.Materials.separator }
    
    /// Control background for use on materials
    static var materialControlBackground: Color { AppleDesignSystem.Materials.controlBackground }
}

// MARK: - Vibrancy Helper
/// VibrantForeground represents...
struct VibrantForeground: ViewModifier {
    /// isProminent property
    let isProminent: Bool
    
    /// body function description
    func body(content: Content) -> some View {
        content
            .foregroundColor(isProminent ? AppleDesignSystem.Materials.label : AppleDesignSystem.Materials.secondaryLabel)
            .blendMode(.plusLighter)
    }
}

extension View {
    /// Makes the view's foreground content vibrant for display on materials
    func vibrantForeground(prominent: Bool = true) -> some View {
        modifier(VibrantForeground(isProminent: prominent))
    }
}
#endif