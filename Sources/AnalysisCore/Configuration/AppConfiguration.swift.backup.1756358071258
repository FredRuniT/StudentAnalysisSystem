import Foundation

/// AppConfiguration manages application-wide configurable parameters
/// This replaces hardcoded values throughout the system to ensure modularity
public struct AppConfiguration: Codable, Sendable {
    
    // MARK: - Test Provider Configuration
    public struct TestProvider: Codable, Sendable {
        public let name: String
        public let identifier: String
        public let componentPattern: String
        public let columnMappings: [String: String]
        public let gradePrefix: String
        public let subjectCodes: [String: String]
        
        public init(
            name: String,
            identifier: String,
            componentPattern: String = "",
            columnMappings: [String: String] = [:],
            gradePrefix: String = "Grade_",
            subjectCodes: [String: String] = [:]
        ) {
            self.name = name
            self.identifier = identifier
            self.componentPattern = componentPattern
            self.columnMappings = columnMappings
            self.gradePrefix = gradePrefix
            self.subjectCodes = subjectCodes
        }
    }
    
    // MARK: - Proficiency Level Configuration
    public struct ProficiencyLevels: Codable, Sendable {
        public struct LevelRange: Codable, Sendable {
            public let name: String
            public let displayName: String
            public let range: ClosedRange<Double>
            public let color: String
            
            public init(name: String, displayName: String, range: ClosedRange<Double>, color: String) {
                self.name = name
                self.displayName = displayName
                self.range = range
                self.color = color
            }
        }
        
        public let levels: [LevelRange]
        
        public init(levels: [LevelRange]) {
            self.levels = levels
        }
        
        /// Default Mississippi MAAP proficiency levels
        public static let mississippiMAP: ProficiencyLevels = ProficiencyLevels(levels: [
            LevelRange(name: "minimal", displayName: "Minimal", range: 0.0...649.0, color: "#FF4444"),
            LevelRange(name: "basic", displayName: "Basic", range: 650.0...699.0, color: "#FF8844"),
            LevelRange(name: "passing", displayName: "Passing", range: 700.0...749.0, color: "#FFAA44"),
            LevelRange(name: "proficient", displayName: "Proficient", range: 750.0...799.0, color: "#44AA44"),
            LevelRange(name: "advanced", displayName: "Advanced", range: 800.0...999.0, color: "#44FF44")
        ])
    }
    
    // MARK: - Grade Configuration
    public struct GradeConfiguration: Codable, Sendable {
        public let supportedRange: ClosedRange<Int>
        public let displayNames: [Int: String]
        
        public init(
            supportedRange: ClosedRange<Int> = 3...8,
            displayNames: [Int: String] = [:]
        ) {
            self.supportedRange = supportedRange
            self.displayNames = displayNames
        }
    }
    
    // MARK: - Data Directory Configuration
    public struct DataDirectories: Codable, Sendable {
        public let baseDirectory: String
        public let assessmentDataPath: String
        public let standardsPath: String
        public let blueprintsPath: String
        public let outputPath: String
        
        public init(
            baseDirectory: String = "Data",
            assessmentDataPath: String = "MAAP_Test_Data",
            standardsPath: String = "Standards",
            blueprintsPath: String = "MAAP_BluePrints",
            outputPath: String = "Output"
        ) {
            self.baseDirectory = baseDirectory
            self.assessmentDataPath = assessmentDataPath
            self.standardsPath = standardsPath
            self.blueprintsPath = blueprintsPath
            self.outputPath = outputPath
        }
    }
    
    // MARK: - Component Mapping Configuration
    public struct ComponentMappings: Codable, Sendable {
        public let reportingCategories: [String: String]
        public let componentPatterns: [String: String]
        public let subjectMappings: [String: String]
        
        public init(
            reportingCategories: [String: String] = [:],
            componentPatterns: [String: String] = [:],
            subjectMappings: [String: String] = [:]
        ) {
            self.reportingCategories = reportingCategories
            self.componentPatterns = componentPatterns
            self.subjectMappings = subjectMappings
        }
        
        /// Default MAAP component mappings
        public static let maapDefault: ComponentMappings = ComponentMappings(
            reportingCategories: [
                "D1": "Operations & Algebraic Thinking",
                "D2": "Operations & Algebraic Thinking", 
                "D3": "Number & Operations Base Ten",
                "D4": "Number & Operations Base Ten",
                "D5": "Fractions",
                "D6": "Fractions",
                "D7": "Measurement & Data",
                "D8": "Measurement & Data",
                "D9": "Geometry",
                "D0": "Geometry",
                "RC": "Reading Comprehension",
                "LA": "Language Arts"
            ],
            componentPatterns: [
                "math": "D\\d+(OP|NBT|NF|MD|G)",
                "ela": "RC\\d+(OP|A|B|C)|LA\\d+(OP|A|B|C)"
            ],
            subjectMappings: [
                "MATH": "Mathematics",
                "ELA": "English Language Arts",
                "READING": "Reading"
            ]
        )
    }
    
    // MARK: - School Year Configuration
    public struct SchoolYearConfiguration: Codable, Sendable {
        public let currentYear: String
        public let format: String
        public let startMonth: Int
        public let endMonth: Int
        
        public init(
            currentYear: String = "2024-2025",
            format: String = "YYYY-YYYY",
            startMonth: Int = 8,
            endMonth: Int = 5
        ) {
            self.currentYear = currentYear
            self.format = format
            self.startMonth = startMonth
            self.endMonth = endMonth
        }
    }
    
    // MARK: - Main Configuration Properties
    public let applicationName: String
    public let testProviders: [TestProvider]
    public let activeProvider: String
    public let gradeConfiguration: GradeConfiguration
    public let proficiencyLevels: ProficiencyLevels
    public let dataDirectories: DataDirectories
    public let componentMappings: ComponentMappings
    public let schoolYear: SchoolYearConfiguration
    public let correlationThreshold: Double
    public let confidenceThreshold: Double
    
    // MARK: - Initialization
    public init(
        applicationName: String = "Student Analysis System",
        testProviders: [TestProvider] = Self.defaultTestProviders,
        activeProvider: String = "MAAP",
        gradeConfiguration: GradeConfiguration = GradeConfiguration(),
        proficiencyLevels: ProficiencyLevels = .mississippiMAP,
        dataDirectories: DataDirectories = DataDirectories(),
        componentMappings: ComponentMappings = .maapDefault,
        schoolYear: SchoolYearConfiguration = SchoolYearConfiguration(),
        correlationThreshold: Double = 0.3,
        confidenceThreshold: Double = 0.7
    ) {
        self.applicationName = applicationName
        self.testProviders = testProviders
        self.activeProvider = activeProvider
        self.gradeConfiguration = gradeConfiguration
        self.proficiencyLevels = proficiencyLevels
        self.dataDirectories = dataDirectories
        self.componentMappings = componentMappings
        self.schoolYear = schoolYear
        self.correlationThreshold = correlationThreshold
        self.confidenceThreshold = confidenceThreshold
    }
    
    // MARK: - Default Test Providers
    public static let defaultTestProviders: [TestProvider] = [
        TestProvider(
            name: "Mississippi Academic Assessment Program",
            identifier: "MAAP",
            componentPattern: "D\\d+(OP|NBT|NF|MD|G)",
            columnMappings: [
                "student_id": "Student_ID",
                "grade": "Grade",
                "subject": "Subject",
                "score": "Scale_Score"
            ],
            gradePrefix: "Grade_",
            subjectCodes: [
                "MATH": "Mathematics",
                "ELA": "English Language Arts"
            ]
        ),
        TestProvider(
            name: "NWEA MAP Growth",
            identifier: "NWEA",
            componentPattern: "\\w+\\d+[A-Z]*",
            columnMappings: [
                "student_id": "StudentID",
                "grade": "Grade",
                "subject": "TestSubject",
                "score": "TestRITScore"
            ],
            gradePrefix: "Grade_",
            subjectCodes: [
                "Mathematics": "MATH",
                "Reading": "ELA"
            ]
        ),
        TestProvider(
            name: "QUESTAR Assessment",
            identifier: "QUESTAR",
            componentPattern: "RC\\d+[A-Z]*|LA\\d+[A-Z]*",
            columnMappings: [
                "student_id": "STUDENT_ID",
                "grade": "GRADE_LEVEL", 
                "subject": "TEST_SUBJECT",
                "score": "SCALE_SCORE"
            ],
            gradePrefix: "Grade_",
            subjectCodes: [
                "MATH": "Mathematics",
                "READING": "Reading Comprehension"
            ]
        )
    ]
    
    // MARK: - Default Configuration
    public static let `default` = AppConfiguration()
    
    // MARK: - Convenience Methods
    public var activeTestProvider: TestProvider? {
        return testProviders.first { $0.identifier == activeProvider }
    }
    
    public func supportedGrades() -> [Int] {
        return Array(gradeConfiguration.supportedRange)
    }
    
    public func proficiencyLevel(for score: Double) -> ProficiencyLevels.LevelRange? {
        return proficiencyLevels.levels.first { $0.range.contains(score) }
    }
    
    public func reportingCategory(for component: String) -> String? {
        let prefix = String(component.prefix(2))
        return componentMappings.reportingCategories[prefix]
    }
}

// MARK: - App Configuration Manager
@MainActor
public class AppConfigurationManager: ObservableObject {
    @Published public private(set) var configuration: AppConfiguration
    private let configurationPath: URL
    
    public init(configurationPath: URL? = nil) {
        self.configurationPath = configurationPath ?? Self.defaultConfigurationPath
        self.configuration = AppConfiguration.default
    }
    
    private static var defaultConfigurationPath: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("StudentAnalysisSystem/app_configuration.json")
    }
    
    /// Load configuration from file
    public func loadConfiguration() async throws {
        guard FileManager.default.fileExists(atPath: configurationPath.path) else {
            print("App configuration file not found at \(configurationPath.path). Using defaults.")
            return
        }
        
        let data = try Data(contentsOf: configurationPath)
        let decoder = JSONDecoder()
        configuration = try decoder.decode(AppConfiguration.self, from: data)
        print("App configuration loaded from \(configurationPath.path)")
    }
    
    /// Save current configuration to file
    public func saveConfiguration() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(configuration)
        
        // Create directory if it doesn't exist
        let directory = configurationPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        try data.write(to: configurationPath)
        print("App configuration saved to \(configurationPath.path)")
    }
    
    /// Update configuration
    public func updateConfiguration(_ newConfiguration: AppConfiguration) async throws {
        configuration = newConfiguration
        try await saveConfiguration()
    }
    
    /// Update active test provider
    public func setActiveProvider(_ providerId: String) async throws {
        let updatedConfig = AppConfiguration(
            applicationName: configuration.applicationName,
            testProviders: configuration.testProviders,
            activeProvider: providerId,
            gradeConfiguration: configuration.gradeConfiguration,
            proficiencyLevels: configuration.proficiencyLevels,
            dataDirectories: configuration.dataDirectories,
            componentMappings: configuration.componentMappings,
            schoolYear: configuration.schoolYear,
            correlationThreshold: configuration.correlationThreshold,
            confidenceThreshold: configuration.confidenceThreshold
        )
        try await updateConfiguration(updatedConfig)
    }
    
    /// Reset to default configuration
    public func resetToDefault() async throws {
        try await updateConfiguration(AppConfiguration.default)
    }
}