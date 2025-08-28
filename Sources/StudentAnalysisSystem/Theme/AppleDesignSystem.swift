import AppKit
import SwiftUI
#if os(macOS)
#endif

/// AppleDesignSystem represents...
struct AppleDesignSystem {
    // MARK: - System Colors (Apple Human Interface Guidelines)
    /// Use these semantic colors for UI structure - they automatically adapt to light/dark mode
    /// and respect user accessibility settings like Increase Contrast
    struct SystemColors {
        // MARK: - Text Colors
        /// Primary text color for main content
        static let label = Color.primary
        /// Secondary text color for less prominent content
        static let secondaryLabel = Color.secondary
        /// Tertiary text color for supplementary content
        #if os(macOS)
        /// tertiaryLabel property
        static let tertiaryLabel = Color(NSColor.tertiaryLabelColor)
        /// quaternaryLabel property
        static let quaternaryLabel = Color(NSColor.quaternaryLabelColor)
        #else
        /// tertiaryLabel property
        static let tertiaryLabel = Color(UIColor.tertiaryLabel)
        /// quaternaryLabel property
        static let quaternaryLabel = Color(UIColor.quaternaryLabel)
        #endif
        
        // MARK: - Background Colors
        /// Primary background color
        #if os(macOS)
        /// background property
        static let background = Color(NSColor.windowBackgroundColor)
        /// secondaryBackground property
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        /// tertiaryBackground property
        static let tertiaryBackground = Color(NSColor.underPageBackgroundColor)
        #else
        /// background property
        static let background = Color(UIColor.systemBackground)
        /// secondaryBackground property
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        /// tertiaryBackground property
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        #endif
        
        // MARK: - System UI Colors
        /// System accent color (adapts to user preference)
        #if os(macOS)
        /// accent property
        static let accent = Color(NSColor.controlAccentColor)
        #else
        /// accent property
        static let accent = Color.accentColor
        #endif
        
        /// Separator lines
        #if os(macOS)
        /// separator property
        static let separator = Color(NSColor.separatorColor)
        #else
        /// separator property
        static let separator = Color(UIColor.separator)
        #endif
        
        // MARK: - Fill Colors
        /// Fill colors for UI elements
        #if os(macOS)
        /// fill property
        static let fill = Color(NSColor.controlColor)
        /// secondaryFill property
        static let secondaryFill = Color(NSColor.controlBackgroundColor)
        /// tertiaryFill property
        static let tertiaryFill = Color(NSColor.tertiarySystemFill)
        /// quaternaryFill property
        static let quaternaryFill = Color(NSColor.quaternarySystemFill)
        /// quaternarySystemFill property
        static let quaternarySystemFill = Color(NSColor.quaternarySystemFill)
        #else
        /// fill property
        static let fill = Color(UIColor.systemFill)
        /// secondaryFill property
        static let secondaryFill = Color(UIColor.secondarySystemFill)
        /// tertiaryFill property
        static let tertiaryFill = Color(UIColor.tertiarySystemFill)
        /// quaternaryFill property
        static let quaternaryFill = Color(UIColor.quaternarySystemFill)
        /// quaternarySystemFill property
        static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)
        #endif
        
        // MARK: - Grouped Background Colors (iOS)
        #if !os(macOS)
        /// groupedBackground property
        static let groupedBackground = Color(UIColor.systemGroupedBackground)
        /// secondaryGroupedBackground property
        static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
        /// tertiaryGroupedBackground property
        static let tertiaryGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
        #endif
    }
    
    // MARK: - Apple System Color Palette
    /// Standard Apple color palette - use these for semantic meaning and consistent design
    struct SystemPalette {
        /// red property
        static let red = Color.red
        /// orange property
        static let orange = Color.orange
        /// yellow property
        static let yellow = Color.yellow
        /// green property
        static let green = Color.green
        /// mint property
        static let mint = Color.mint
        /// teal property
        static let teal = Color.teal
        /// cyan property
        static let cyan = Color.cyan
        /// blue property
        static let blue = Color.blue
        /// indigo property
        static let indigo = Color.indigo
        /// purple property
        static let purple = Color.purple
        /// pink property
        static let pink = Color.pink
        /// brown property
        static let brown = Color.brown
        
        // Semantic usage colors
        /// success property
        static let success = Color.green
        /// error property
        static let error = Color.red
        /// warning property
        static let warning = Color.orange
    }
    
    // MARK: - Brand Colors
    /// Use sparingly for brand identity and primary actions only
    /// These should complement, not replace, system colors
    struct BrandColors {
        /// Primary brand color - use for key actions and brand highlights
        static let primary = Color("BrandPrimary")
        /// Secondary brand color - use for supporting brand elements
        static let secondary = Color("BrandSecondary")
        /// Tertiary brand color - use for subtle brand touches
        static let tertiary = Color("TertiaryColor")
        
        // Legacy compatibility - prefer SystemPalette for semantic colors
        /// success property
        static let success = Color("SuccessColor")
        /// error property
        static let error = Color("ErrorColor")
        /// warning property
        static let warning = Color("WarningColor")
    }
    
    // MARK: - UI Component Colors
    /// Pre-configured colors for common UI components following Apple HIG
    struct ComponentColors {
        // MARK: - Text
        /// primaryText property
        static let primaryText = SystemColors.label
        /// secondaryText property
        static let secondaryText = SystemColors.secondaryLabel
        /// tertiaryText property
        static let tertiaryText = SystemColors.tertiaryLabel
        /// placeholderText property
        static var placeholderText: Color {
            #if os(macOS)
            return Color(NSColor.placeholderTextColor)
            #else
            return Color(UIColor.placeholderText)
            #endif
        }
        
        // MARK: - Cards
        /// cardBackground property
        static let cardBackground = SystemColors.secondaryBackground
        /// cardBorder property
        static let cardBorder = SystemColors.separator
        
        // MARK: - Input Fields
        /// inputBackground property
        static var inputBackground: Color {
            #if os(macOS)
            return Color(NSColor.textBackgroundColor)
            #else
            return SystemColors.background
            #endif
        }
        /// inputBorder property
        static let inputBorder = SystemColors.separator
        
        // MARK: - Buttons
        /// Primary button - uses brand color
        static let primaryButtonBackground = BrandColors.primary
        /// primaryButtonText property
        static let primaryButtonText = Color.white
        
        /// Secondary button - uses system colors
        static let secondaryButtonBackground = SystemColors.secondaryBackground
        /// secondaryButtonText property
        static let secondaryButtonText = SystemColors.label
        
        // MARK: - Navigation
        /// tabBarBackground property
        static let tabBarBackground = SystemColors.background
        /// tabBarSelected property
        static let tabBarSelected = SystemColors.accent
        /// tabBarUnselected property
        static let tabBarUnselected = SystemColors.secondaryLabel
    }
    
    // MARK: - Typography
    /// Typography represents...
    struct Typography {
        /// largeTitle property
        static let largeTitle = Font.largeTitle
        /// title property
        static let title = Font.title
        /// title2 property
        static let title2 = Font.title2
        /// title3 property
        static let title3 = Font.title3
        /// headline property
        static let headline = Font.headline
        /// subheadline property
        static let subheadline = Font.subheadline
        /// body property
        static let body = Font.body
        /// callout property
        static let callout = Font.callout
        /// caption property
        static let caption = Font.caption
        /// caption2 property
        static let caption2 = Font.caption2
        /// footnote property
        static let footnote = Font.footnote
    }
    
    // MARK: - Spacing
    /// Spacing represents...
    struct Spacing {
        /// xs property
        static let xs: CGFloat = 4
        /// small property
        static let small: CGFloat = 8
        /// medium property
        static let medium: CGFloat = 16
        /// large property
        static let large: CGFloat = 24
        /// xl property
        static let xl: CGFloat = 32
        /// xxl property
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    /// Corners represents...
    struct Corners {
        /// small property
        static let small: CGFloat = 6
        /// medium property
        static let medium: CGFloat = 12
        /// large property
        static let large: CGFloat = 20
        /// xl property
        static let xl: CGFloat = 28
    }
    
    // MARK: - Shadows
    /// Shadows represents...
    struct Shadows {
        /// small property
        static let small = Color.black.opacity(0.1)
        /// medium property
        static let medium = Color.black.opacity(0.2)
        /// large property
        static let large = Color.black.opacity(0.3)
    }
    
    // MARK: - Form Layout (Design Tokens)
    /// Forms represents...
    struct Forms {
        /// Standard height for form fields (text fields, pickers, etc.) - from design tokens
        static let fieldHeight: CGFloat = 24
        /// Minimum height for multiline text areas - from design tokens
        static let textAreaMinHeight: CGFloat = 48
        /// Standard vertical spacing between form fields - from design tokens
        static let fieldSpacing: CGFloat = 16
        /// Horizontal padding inside form fields - from design tokens
        static let fieldPadding: CGFloat = 8
        /// Corner radius for form elements - from design tokens
        static let cornerRadius: CGFloat = 6
    }
    
    #if os(macOS)
    // MARK: - Material Design System
    /// Materials represents...
    struct Materials {
        // MARK: - Material Colors
        /// Primary label color that adapts to materials
        static var label: Color {
            Color(NSColor.labelColor)
        }
        
        /// Secondary label color for less prominent text
        static var secondaryLabel: Color {
            Color(NSColor.secondaryLabelColor)
        }
        
        /// Tertiary label color for supplementary text
        static var tertiaryLabel: Color {
            Color(NSColor.tertiaryLabelColor)
        }
        
        /// Quaternary label color for disabled text
        static var quaternaryLabel: Color {
            Color(NSColor.quaternaryLabelColor)
        }
        
        // MARK: - Background Colors
        /// Control background color that works with materials
        static var controlBackground: Color {
            Color(NSColor.controlBackgroundColor)
        }
        
        /// Text background color
        static var textBackground: Color {
            Color(NSColor.textBackgroundColor)
        }
        
        // MARK: - Separator Colors
        /// Separator color that works well on materials
        static var separator: Color {
            Color(NSColor.separatorColor)
        }
        
        // MARK: - Accent Colors
        /// System accent color
        static var accent: Color {
            Color(NSColor.controlAccentColor)
        }
        
        // MARK: - Selection Colors
        /// Selected content background
        static var selectedContentBackground: Color {
            Color(NSColor.selectedContentBackgroundColor)
        }
        
        /// Unemphasized selected content background
        static var unemphasizedSelectedContentBackground: Color {
            Color(NSColor.unemphasizedSelectedContentBackgroundColor)
        }
        
        // MARK: - Control Colors
        /// Control color for interactive elements
        static var control: Color {
            Color(NSColor.controlColor)
        }
        
        /// Control text color
        static var controlText: Color {
            Color(NSColor.controlTextColor)
        }
        
        // MARK: - Window Colors
        /// Window background color
        static var windowBackground: Color {
            Color(NSColor.windowBackgroundColor)
        }
        
        /// Under page background color
        static var underPageBackground: Color {
            Color(NSColor.underPageBackgroundColor)
        }
        
        // MARK: - Material Effects
        /// Regular material effect - provides subtle background with transparency
        static let regular = Material.regular
        
        /// Thick material effect - provides stronger background opacity
        static let thick = Material.thick
        
        /// Thin material effect - provides minimal background opacity
        static let thin = Material.thin
        
        /// Ultra thin material effect - provides very light background opacity
        static let ultraThin = Material.ultraThin
    }
    
    // MARK: - Visual Effect Background
    /// A SwiftUI wrapper for NSVisualEffectView that provides native macOS material backgrounds
    struct VisualEffectBackground: NSViewRepresentable {
        private let material: NSVisualEffectView.Material
        private let blendingMode: NSVisualEffectView.BlendingMode
        private let isEmphasized: Bool
        private let state: NSVisualEffectView.State
        
        init(
            material: NSVisualEffectView.Material,
            blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
            emphasized: Bool = false,
            state: NSVisualEffectView.State = .active
        ) {
            self.material = material
            self.blendingMode = blendingMode
            self.isEmphasized = emphasized
            self.state = state
        }
        
        /// makeNSView function description
        func makeNSView(context: Context) -> NSVisualEffectView {
            /// view property
            let view = NSVisualEffectView()
            view.autoresizingMask = [.width, .height]
            return view
        }
        
        /// updateNSView function description
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            nsView.material = material
            nsView.blendingMode = blendingMode
            nsView.isEmphasized = isEmphasized
            nsView.state = state
        }
    }
    
    // MARK: - Material Type Helper
    /// A type-safe wrapper for common material types
    enum MaterialType {
        case sidebar
        case contentBackground
        case windowBackground
        case headerView
        case menu
        case popover
        case titlebar
        case selection
        case underPageBackground
        case hudWindow
        
        /// nsMaterial property
        var nsMaterial: NSVisualEffectView.Material {
            switch self {
            case .sidebar: return .sidebar
            case .contentBackground: return .contentBackground
            case .windowBackground: return .windowBackground
            case .headerView: return .headerView
            case .menu: return .menu
            case .popover: return .popover
            case .titlebar: return .titlebar
            case .selection: return .selection
            case .underPageBackground: return .underPageBackground
            case .hudWindow: return .hudWindow
            }
        }
    }
    
    // MARK: - Material Thickness Types
    /// Thickness-based materials that provide different levels of blur intensity
    enum MaterialThickness: CaseIterable {
        case ultraThin
        case thin
        case regular
        case thick
        case ultraThick
        
        /// SwiftUI material representation
        @available(macOS 12.0, *)
        /// swiftUIMaterial property
        var swiftUIMaterial: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            }
        }
        
        /// displayName property
        var displayName: String {
            switch self {
            case .ultraThin: return "Ultra Thin"
            case .thin: return "Thin"
            case .regular: return "Regular"
            case .thick: return "Thick"
            case .ultraThick: return "Ultra Thick"
            }
        }
    }
    #endif
}

// MARK: - View Extensions for Materials
extension View {
    
    #if os(macOS)
    
    // MARK: - Thickness-Based Materials (SwiftUI)
    /// Applies an ultra-thin material background
    @available(macOS 12.0, *)
    /// ultraThinMaterial function description
    func ultraThinMaterial() -> some View {
        self.background(.ultraThinMaterial)
    }
    
    /// Applies a thin material background
    @available(macOS 12.0, *)
    /// thinMaterial function description
    func thinMaterial() -> some View {
        self.background(.thinMaterial)
    }
    
    /// Applies a regular material background
    @available(macOS 12.0, *)
    /// regularMaterial function description
    func regularMaterial() -> some View {
        self.background(.regularMaterial)
    }
    
    /// Applies a thick material background
    @available(macOS 12.0, *)
    /// thickMaterial function description
    func thickMaterial() -> some View {
        self.background(.thickMaterial)
    }
    
    /// Applies an ultra-thick material background
    @available(macOS 12.0, *)
    /// ultraThickMaterial function description
    func ultraThickMaterial() -> some View {
        self.background(.ultraThickMaterial)
    }
    
    /// Applies a material background using the thickness enum
    @available(macOS 12.0, *)
    /// materialBackground function description
    func materialBackground(_ thickness: AppleDesignSystem.MaterialThickness) -> some View {
        self.background(thickness.swiftUIMaterial)
    }
    
    // MARK: - Semantic Materials (NSVisualEffectView)
    /// Applies a semantic material background using NSVisualEffectView
    func semanticMaterialBackground(
        _ type: AppleDesignSystem.MaterialType,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false,
        ignoresSafeArea: Bool = true
    ) -> some View {
        background(
            AppleDesignSystem.VisualEffectBackground(
                material: type.nsMaterial,
                blendingMode: blendingMode,
                emphasized: emphasized
            )
            .ignoresSafeArea(ignoresSafeArea ? .all : [])
        )
    }
    
    // MARK: - Convenience Methods (keeping existing patterns)
    /// Applies a sidebar material background
    func sidebar() -> some View {
        semanticMaterialBackground(.sidebar)
    }
    
    /// Applies a menu material background
    func menu() -> some View {
        semanticMaterialBackground(.menu)
    }
    
    /// Applies a popover material background
    func popover() -> some View {
        semanticMaterialBackground(.popover)
    }
    
    /// Applies a header view material background
    func headerView() -> some View {
        semanticMaterialBackground(.headerView)
    }
    
    /// Applies a selection material background
    func selection() -> some View {
        semanticMaterialBackground(.selection)
    }
    
    /// Applies a content background material
    func contentBackground() -> some View {
        semanticMaterialBackground(.contentBackground)
    }
    
    /// Applies a window background material
    func windowBackground() -> some View {
        semanticMaterialBackground(.windowBackground)
    }
    
    #endif
}

// MARK: - Custom Text Field Styles
/// StandardFormTextFieldStyle represents...
struct StandardFormTextFieldStyle: TextFieldStyle {
    /// _body function description
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            // Background with corner radius
            RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius)
                .fill(AppleDesignSystem.ComponentColors.inputBackground)
                .frame(height: AppleDesignSystem.Forms.fieldHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius)
                        .stroke(AppleDesignSystem.ComponentColors.inputBorder, lineWidth: 1)
                )
            
            // TextField with transparent background, clipped to shape
            configuration
                .padding(.horizontal, AppleDesignSystem.Forms.fieldPadding)
                .frame(height: AppleDesignSystem.Forms.fieldHeight)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius))
        }
    }
}

/// MultilineFormTextFieldStyle represents...
struct MultilineFormTextFieldStyle: TextFieldStyle {
    /// _body function description
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            // Background with corner radius
            RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius)
                .fill(AppleDesignSystem.ComponentColors.inputBackground)
                .frame(minHeight: AppleDesignSystem.Forms.textAreaMinHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius)
                        .stroke(AppleDesignSystem.ComponentColors.inputBorder, lineWidth: 1)
                )
            
            // TextField with transparent background, clipped to shape
            configuration
                .padding(AppleDesignSystem.Forms.fieldPadding)
                .frame(minHeight: AppleDesignSystem.Forms.textAreaMinHeight, alignment: .topLeading)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius))
        }
    }
}


/// CardMultilineFormTextFieldStyle represents...
struct CardMultilineFormTextFieldStyle: TextFieldStyle {
    /// _body function description
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppleDesignSystem.Forms.fieldPadding)
            .frame(minHeight: AppleDesignSystem.Forms.textAreaMinHeight, alignment: .topLeading)
            .background(AppleDesignSystem.ComponentColors.inputBackground)
            .cornerRadius(AppleDesignSystem.Forms.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppleDesignSystem.Forms.cornerRadius)
                    .stroke(AppleDesignSystem.ComponentColors.inputBorder, lineWidth: 1)
            )
    }
}

extension TextFieldStyle where Self == StandardFormTextFieldStyle {
    /// A standard form text field style with consistent height from the design system
    static var standardForm: StandardFormTextFieldStyle { StandardFormTextFieldStyle() }
}

extension TextFieldStyle where Self == MultilineFormTextFieldStyle {
    /// A multiline form text field style with minimum height from the design system
    static var multilineForm: MultilineFormTextFieldStyle { MultilineFormTextFieldStyle() }
}

extension TextFieldStyle where Self == CardMultilineFormTextFieldStyle {
    /// A multiline text field style for use inside rounded corner cards (no borders or corner radius to avoid visual conflicts)
    static var cardMultilineForm: CardMultilineFormTextFieldStyle { CardMultilineFormTextFieldStyle() }
}
