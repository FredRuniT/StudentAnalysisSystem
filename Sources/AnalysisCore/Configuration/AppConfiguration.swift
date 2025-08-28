import Foundation

/// AppConfiguration manages application-wide configurable parameters
/// This replaces hardcoded values throughout the system to ensure modularity
public struct AppConfiguration: Codable, Sendable {
    
    // MARK: - Test Provider Configuration
    /// TestProvider represents...
    public struct TestProvider: Codable, Sendable {
        /// name property
        public let name: String
        /// identifier property
        public let identifier: String
        /// componentPattern property
        public let componentPattern: String
        /// columnMappings property
        public let columnMappings: [String: String]
        /// gradePrefix property
        public let gradePrefix: String
        /// subjectCodes property
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
    /// ProficiencyLevels represents...
    public struct ProficiencyLevels: Codable, Sendable {
        /// LevelRange represents...
        public struct LevelRange: Codable, Sendable {
            /// name property
            public let name: String
            /// displayName property
            public let displayName: String
            /// range property
            public let range: ClosedRange<Double>
            /// color property
            public let color: String
            
            public init(name: String, displayName: String, range: ClosedRange<Double>, color: String) {
                self.name = name
                self.displayName = displayName
                self.range = range
                self.color = color
            }
        }
        
        /// levels property
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
    /// GradeConfiguration represents...
    public struct GradeConfiguration: Codable, Sendable {
        /// supportedRange property
        public let supportedRange: ClosedRange<Int>
        /// displayNames property
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
    /// DataDirectories represents...
    public struct DataDirectories: Codable, Sendable {
        /// baseDirectory property
        public let baseDirectory: String
        /// assessmentDataPath property
        public let assessmentDataPath: String
        /// standardsPath property
        public let standardsPath: String
        /// blueprintsPath property
        public let blueprintsPath: String
        /// outputPath property
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
    /// ComponentMappings represents...
    public struct ComponentMappings: Codable, Sendable {
        /// reportingCategories property
        public let reportingCategories: [String: String]
        /// componentPatterns property
        public let componentPatterns: [String: String]
        /// subjectMappings property
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
    /// SchoolYearConfiguration represents...
    public struct SchoolYearConfiguration: Codable, Sendable {
        /// currentYear property
        public let currentYear: String
        /// format property
        public let format: String
        /// startMonth property
        public let startMonth: Int
        /// endMonth property
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
    /// applicationName property
    public let applicationName: String
    /// testProviders property
    public let testProviders: [TestProvider]
    /// activeProvider property
    public let activeProvider: String
    /// gradeConfiguration property
    public let gradeConfiguration: GradeConfiguration
    /// proficiencyLevels property
    public let proficiencyLevels: ProficiencyLevels
    /// dataDirectories property
    public let dataDirectories: DataDirectories
    /// componentMappings property
    public let componentMappings: ComponentMappings
    /// schoolYear property
    public let schoolYear: SchoolYearConfiguration
    /// correlationThreshold property
    public let correlationThreshold: Double
    /// confidenceThreshold property
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
    /// defaultTestProviders property
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
    /// Item property
    public static let `default` = AppConfiguration()
    
    // MARK: - Convenience Methods
    /// activeTestProvider property
    public var activeTestProvider: TestProvider? {
        return testProviders.first { $0.identifier == activeProvider }
    }
    
    /// supportedGrades function description
    public func supportedGrades() -> [Int] {
        return Array(gradeConfiguration.supportedRange)
    }
    
    /// proficiencyLevel function description
    public func proficiencyLevel(for score: Double) -> ProficiencyLevels.LevelRange? {
        return proficiencyLevels.levels.first { $0.range.contains(score) }
    }
    
    /// reportingCategory function description
    public func reportingCategory(for component: String) -> String? {
        /// prefix property
        let prefix = String(component.prefix(2))
        return componentMappings.reportingCategories[prefix]
    }
}

// MARK: - App Configuration Manager
@MainActor
/// AppConfigurationManager represents...
public class AppConfigurationManager: ObservableObject {
    @Published public private(set) var configuration: AppConfiguration
    private let configurationPath: URL
    
    public init(configurationPath: URL? = nil) {
        self.configurationPath = configurationPath ?? Self.defaultConfigurationPath
        self.configuration = AppConfiguration.default
    }
    
    private static var defaultConfigurationPath: URL {
        /// documentsPath property
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("StudentAnalysisSystem/app_configuration.json")
    }
    
    /// Load configuration from file
    public func loadConfiguration() async throws {
        guard FileManager.default.fileExists(atPath: configurationPath.path) else {
            print("App configuration file not found at \(configurationPath.path). Using defaults.")
            return
        }
        
        /// data property
        let data = try Data(contentsOf: configurationPath)
        /// decoder property
        let decoder = JSONDecoder()
        configuration = try decoder.decode(AppConfiguration.self, from: data)
        print("App configuration loaded from \(configurationPath.path)")
    }
    
    /// Save current configuration to file
    public func saveConfiguration() async throws {
        /// encoder property
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        /// data property
        let data = try encoder.encode(configuration)
        
        // Create directory if it doesn't exist
        /// directory property
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
        /// updatedConfig property
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