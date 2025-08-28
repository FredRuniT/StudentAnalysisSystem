import Foundation

public actor AssessmentComponent: Sendable {
    /// studentID property
    public let studentID: String
    /// year property
    public let year: Int
    /// grade property
    public let grade: Int
    /// testType property
    public let testType: TestProvider
    /// subject property
    public let subject: String
    /// season property
    public let season: String?
    
    // Component scores (RC1OP-RC5OP or D1OP-D8OP with OP/PP/PC variants)
    private var componentScores: [String: Double]
    
    // Proficiency level (PL1-PL5)
    /// proficiencyLevel property
    public let proficiencyLevel: String?
    
    // Demographics and factors
    /// demographics property
    public let demographics: StudentDemographics?
    
    public init(
        studentID: String,
        year: Int,
        grade: Int,
        testType: TestProvider,
        subject: String,
        season: String? = nil,
        componentScores: [String: Double],
        demographics: StudentDemographics? = nil,
        proficiencyLevel: String? = nil
    ) {
        self.studentID = studentID
        self.year = year
        self.grade = grade
        self.testType = testType
        self.subject = subject
        self.season = season
        self.componentScores = componentScores
        self.demographics = demographics
        self.proficiencyLevel = proficiencyLevel
    }
    
    /// getScore function description
    public func getScore(for component: String) -> Double? {
        componentScores[component]
    }
    
    /// getAllScores function description
    public func getAllScores() -> [String: Double] {
        componentScores
    }
}

/// StudentDemographics represents...
public struct StudentDemographics: Codable, Sendable {
    /// iep property
    public let iep: Bool?
    /// lep property
    public let lep: String? // N, Y, F
    /// disability property
    public let disability: Int?
    /// ethnicity property
    public let ethnicity: String?
    /// gender property
    public let gender: String?
    /// economicallyDisadvantaged property
    public let economicallyDisadvantaged: Bool?
}

/// TestProvider description
public enum TestProvider: String, Codable, Sendable {
    case questar = "QUESTAR"
    case nwea = "NWEA"
    
    /// componentPrefix property
    public var componentPrefix: String {
        switch self {
        case .questar: return "RC"
        case .nwea: return "D"
        }
    }
    
    /// maxComponents property
    public var maxComponents: Int {
        switch self {
        case .questar: return 5
        case .nwea: return 8
        }
    }
}

// Core type definitions
/// ComponentIdentifier represents...
public struct ComponentIdentifier: Hashable, Sendable, CustomStringConvertible, Codable {
    /// grade property
    public let grade: Int
    /// subject property
    public let subject: String
    /// component property
    public let component: String
    /// testProvider property
    public let testProvider: TestProvider
    
    public init(
        grade: Int,
        subject: String,
        component: String,
        testProvider: TestProvider
    ) {
        self.grade = grade
        self.subject = subject
        self.component = component
        self.testProvider = testProvider
    }
    
    /// description property
    public var description: String {
        "Grade \(grade) \(subject) \(component)"
    }
    
    /// toPair function description
    public func toPair() -> ComponentPair {
        ComponentPair(
            grade: grade,
            year: nil,
            subject: subject,
            component: component,
            testProvider: testProvider
        )
    }
}

/// ComponentPair represents...
public struct ComponentPair: Sendable {
    /// grade property
    public let grade: Int
    /// year property
    public let year: Int?
    /// subject property
    public let subject: String
    /// component property
    public let component: String
    /// testProvider property
    public let testProvider: TestProvider
    
    public init(
        grade: Int,
        year: Int?,
        subject: String,
        component: String,
        testProvider: TestProvider
    ) {
        self.grade = grade
        self.year = year
        self.subject = subject
        self.component = component
        self.testProvider = testProvider
    }
}

/// RiskLevel description
public enum RiskLevel: String, Sendable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
}
