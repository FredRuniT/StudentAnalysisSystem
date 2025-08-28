import Foundation
import SwiftUI

/// Singleton service providing easy access to configuration throughout the application
@MainActor
/// ConfigurationService represents...
public class ConfigurationService: ObservableObject {
    /// shared property
    public static let shared = ConfigurationService()
    
    @Published public private(set) var appConfig: AppConfiguration
    @Published public private(set) var systemConfig: SystemConfiguration
    
    private let appConfigManager: AppConfigurationManager
    private let systemConfigManager: ConfigurationManager
    
    private init() {
        self.appConfigManager = AppConfigurationManager()
        self.systemConfigManager = ConfigurationManager()
        self.appConfig = AppConfiguration.default
        self.systemConfig = SystemConfiguration.default
    }
    
    /// Initialize configuration service by loading from files
    public func initialize() async throws {
        try await appConfigManager.loadConfiguration()
        try await systemConfigManager.loadConfiguration()
        
        self.appConfig = appConfigManager.configuration
        self.systemConfig = await systemConfigManager.getConfiguration()
        
        print("ConfigurationService initialized successfully")
    }
    
    // MARK: - App Configuration Access
    
    /// Current test provider configuration
    public var activeTestProvider: AppConfiguration.TestProvider? {
        return appConfig.activeTestProvider
    }
    
    /// Supported grade range
    public var supportedGrades: [Int] {
        return appConfig.supportedGrades()
    }
    
    /// Current school year
    public var currentSchoolYear: String {
        return appConfig.schoolYear.currentYear
    }
    
    /// Proficiency level for score
    public func proficiencyLevel(for score: Double) -> AppConfiguration.ProficiencyLevels.LevelRange? {
        return appConfig.proficiencyLevel(for: score)
    }
    
    /// Reporting category for component
    public func reportingCategory(for component: String) -> String? {
        return appConfig.reportingCategory(for: component)
    }
    
    /// Data directory paths
    public var dataDirectories: AppConfiguration.DataDirectories {
        return appConfig.dataDirectories
    }
    
    /// Component mappings
    public var componentMappings: AppConfiguration.ComponentMappings {
        return appConfig.componentMappings
    }
    
    // MARK: - System Configuration Access
    
    /// Correlation analysis parameters
    public var correlationParameters: SystemConfiguration.CorrelationParameters {
        return systemConfig.correlation
    }
    
    /// ILP generation parameters
    public var ilpParameters: SystemConfiguration.ILPParameters {
        return systemConfig.ilp
    }
    
    /// Performance parameters
    public var performanceParameters: SystemConfiguration.PerformanceParameters {
        return systemConfig.performance
    }
    
    // MARK: - Configuration Updates
    
    /// Update app configuration
    public func updateAppConfiguration(_ newConfig: AppConfiguration) async throws {
        try await appConfigManager.updateConfiguration(newConfig)
        self.appConfig = newConfig
    }
    
    /// Update system configuration
    public func updateSystemConfiguration(_ newConfig: SystemConfiguration) async throws {
        try await systemConfigManager.updateConfiguration(newConfig)
        self.systemConfig = await systemConfigManager.getConfiguration()
    }
    
    /// Set active test provider
    public func setActiveProvider(_ providerId: String) async throws {
        try await appConfigManager.setActiveProvider(providerId)
        self.appConfig = appConfigManager.configuration
    }
    
    /// Reset configurations to defaults
    public func resetToDefaults() async throws {
        try await appConfigManager.resetToDefault()
        try await systemConfigManager.resetToDefault()
        
        self.appConfig = AppConfiguration.default
        self.systemConfig = await systemConfigManager.getConfiguration()
    }
    
    // MARK: - Convenience Methods for Common Operations
    
    /// Check if grade is supported
    public func isGradeSupported(_ grade: Int) -> Bool {
        return appConfig.gradeConfiguration.supportedRange.contains(grade)
    }
    
    /// Get display name for grade
    public func gradeDisplayName(_ grade: Int) -> String {
        return appConfig.gradeConfiguration.displayNames[grade] ?? "Grade \(grade)"
    }
    
    /// Get correlation threshold
    public var correlationThreshold: Double {
        return max(appConfig.correlationThreshold, systemConfig.correlation.minimumCorrelation)
    }
    
    /// Get confidence threshold
    public var confidenceThreshold: Double {
        return max(appConfig.confidenceThreshold, systemConfig.correlation.confidenceLevel)
    }
    
    /// Get full path for data directory
    public func dataPath(for subdirectory: String) -> String {
        return "\(appConfig.dataDirectories.baseDirectory)/\(subdirectory)"
    }
    
    /// Get assessment data path
    public var assessmentDataPath: String {
        return dataPath(for: appConfig.dataDirectories.assessmentDataPath)
    }
    
    /// Get standards data path
    public var standardsPath: String {
        return dataPath(for: appConfig.dataDirectories.standardsPath)
    }
    
    /// Get blueprints data path
    public var blueprintsPath: String {
        return dataPath(for: appConfig.dataDirectories.blueprintsPath)
    }
    
    /// Get output path
    public var outputPath: String {
        return appConfig.dataDirectories.outputPath
    }
}

// MARK: - ViewModifier for easy injection
/// WithConfiguration represents...
public struct WithConfiguration: ViewModifier {
    /// body function description
    public func body(content: Content) -> some View {
        content
            .environmentObject(ConfigurationService.shared)
    }
}

extension View {
    /// Inject configuration service into the view hierarchy
    public func withConfiguration() -> some View {
        modifier(WithConfiguration())
    }
}