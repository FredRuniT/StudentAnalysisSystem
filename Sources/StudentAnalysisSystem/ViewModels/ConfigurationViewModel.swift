import AnalysisCore
import Combine
import SwiftUI

@MainActor
/// ConfigurationViewModel represents...
class ConfigurationViewModel: ObservableObject {
    /// configuration property
    @Published var configuration: SystemConfiguration
    private let configurationManager: ConfigurationManager
    private let configurationURL: URL
    
    init() {
        // Initialize with default configuration
        self.configuration = SystemConfiguration.default
        self.configurationManager = ConfigurationManager()
        
        // Set configuration path
        /// documentsPath property
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.configurationURL = documentsPath.appendingPathComponent("StudentAnalysisSystem/configuration.json")
        
        // Load existing configuration
        Task {
            await loadConfiguration()
        }
    }
    
    /// loadConfiguration function description
    func loadConfiguration() async {
        do {
            try await configurationManager.loadConfiguration()
            self.configuration = await configurationManager.getConfiguration()
        } catch {
            print("Failed to load configuration: \(error)")
            // Use default configuration if loading fails
            self.configuration = SystemConfiguration.default
        }
    }
    
    /// saveConfiguration function description
    func saveConfiguration() async {
        do {
            try await configurationManager.updateConfiguration(configuration)
            print("Configuration saved successfully")
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    /// resetToDefaults function description
    func resetToDefaults() async {
        do {
            try await configurationManager.resetToDefault()
            self.configuration = SystemConfiguration.default
        } catch {
            print("Failed to reset configuration: \(error)")
        }
    }
    
    /// exportConfiguration function description
    func exportConfiguration(to url: URL) throws {
        /// encoder property
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        /// data property
        let data = try encoder.encode(configuration)
        try data.write(to: url)
    }
    
    /// importConfiguration function description
    func importConfiguration(from url: URL) throws {
        /// data property
        let data = try Data(contentsOf: url)
        /// decoder property
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.configuration = try decoder.decode(SystemConfiguration.self, from: data)
    }
}