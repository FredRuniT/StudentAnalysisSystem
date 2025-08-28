import SwiftUI

@main
struct StudentAnalysisSystemApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
        
        #if os(macOS)
        Settings {
            ConfigurationView()
                .environmentObject(themeManager)
        }
        #endif
    }
}