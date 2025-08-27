import SwiftUI

@main
struct StudentAnalysisSystemApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        #endif
        
        #if os(macOS)
        Settings {
            ConfigurationView()
        }
        #endif
    }
}