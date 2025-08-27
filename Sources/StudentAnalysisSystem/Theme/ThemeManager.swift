

import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @AppStorage("selectedThemeMode") private var themeModeString: String = "system" {
        didSet {
            updateThemeMode()
        }
    }
    
    @AppStorage("selectedTheme") private var selectedThemeId: String = "apple" {
        didSet {
            updateSelectedTheme()
        }
    }
    
    @Published var selectedThemeMode: ThemeMode = .system
    @Published var colorScheme: ColorScheme = .light
    @Published var currentTheme: Theme = AppleTheme()
    
    // Bridge to settings package
    private var settingsThemeObserver: NSObjectProtocol?
    
    // Available themes
    private let availableThemes: [Theme] = [
        AppleTheme(),
        TacticalTheme()
    ]
    
    var themes: [Theme] {
        availableThemes
    }
    
    var primaryColor: Color {
        currentTheme.colors.brandPrimary
    }
    
    init() {
        // Detect and set initial system color scheme
        detectInitialColorScheme()
        // Initialize theme mode from stored string
        updateThemeMode()
        // Initialize selected theme
        updateSelectedTheme()
        // Sync with settings package theme on startup
        syncFromSettings()
        setupSettingsObserver()
    }
    
    private func updateThemeMode() {
        if let mode = ThemeMode(rawValue: themeModeString) {
            selectedThemeMode = mode
            // Update the stored string to sync with settings
            updateSettingsTheme(mode)
            objectWillChange.send()
        }
    }
    
    private func updateSettingsTheme(_ mode: ThemeMode) {
        let themeOption: ThemeOption
        switch mode {
        case .system:
            themeOption = .system
        case .light:
            themeOption = .light
        case .dark:
            themeOption = .dark
        }
        
        // Update settings package storage
        UserDefaults.standard.set(themeOption.rawValue, forKey: "selectedTheme")
        
        // Notify settings package of the change
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: themeOption
        )
    }
    
    private func detectInitialColorScheme() {
        #if os(macOS)
        // Detect current macOS system appearance
        let isDarkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        colorScheme = isDarkMode ? .dark : .light
        #else
        // For iOS, we'll rely on the color scheme detector since we can't easily detect it at init
        colorScheme = .light
        #endif
    }
    
    private func syncFromSettings() {
        // Load theme from settings package UserDefaults
        if let themeString = UserDefaults.standard.string(forKey: "selectedTheme"),
           let themeOption = ThemeOption(rawValue: themeString) {
            syncFromSettingsTheme(themeOption)
        }
    }
    
    deinit {
        if let observer = settingsThemeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupSettingsObserver() {
        // Listen for theme changes from settings
        settingsThemeObserver = NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let themeOption = notification.object as? ThemeOption {
                self?.syncFromSettingsTheme(themeOption)
            }
        }
    }
    
    private func syncFromSettingsTheme(_ themeOption: ThemeOption) {
        let themeMode: ThemeMode
        switch themeOption {
        case .system:
            themeMode = .system
        case .light:
            themeMode = .light
        case .dark:
            themeMode = .dark
        }
        
        if selectedThemeMode != themeMode {
            selectedThemeMode = themeMode
            objectWillChange.send()
        }
    }
    
    func updateColorScheme(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
        objectWillChange.send()
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        selectedThemeMode = mode
        themeModeString = mode.rawValue
        updateSettingsTheme(mode)
        objectWillChange.send()
    }
    
    // MARK: - Theme Selection
    private func updateSelectedTheme() {
        if let theme = availableThemes.first(where: { $0.id == selectedThemeId }) {
            currentTheme = theme
            objectWillChange.send()
        }
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        selectedThemeId = theme.id
        objectWillChange.send()
    }
    
    func setTheme(byId themeId: String) {
        if let theme = availableThemes.first(where: { $0.id == themeId }) {
            setTheme(theme)
        }
    }
    
    
    func preferredColorScheme(for systemScheme: ColorScheme) -> ColorScheme? {
        switch selectedThemeMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case system, light, dark
    
    var name: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}


// MARK: - Environment Extension
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

extension View {
    func withThemeManager() -> some View {
        environmentObject(ThemeManager())
    }
    
    /// Detects color scheme changes and calls the provided closure
    func colorSchemeDetector(onChange: @escaping (ColorScheme) -> Void) -> some View {
        self.background(
            ColorSchemeDetectorView(onChange: onChange)
        )
    }
}

// MARK: - Color Scheme Detector View
private struct ColorSchemeDetectorView: View {
    @Environment(\.colorScheme) var colorScheme
    let onChange: (ColorScheme) -> Void
    
    var body: some View {
        Color.clear
            .onAppear {
                onChange(colorScheme)
            }
            .onChange(of: colorScheme) { _, newScheme in
                onChange(newScheme)
            }
        .themed()
    }
}