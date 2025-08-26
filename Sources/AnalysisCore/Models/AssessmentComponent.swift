import Foundation

public actor AssessmentComponent: Sendable {
    public let studentID: String
    public let year: Int
    public let grade: Int
    public let testType: TestProvider
    public let subject: String
    public let season: String?
    
    // Component scores (RC1OP-RC5OP or D1OP-D8OP with OP/PP/PC variants)
    private var componentScores: [String: Double]
    
    // Demographics and factors
    public let demographics: StudentDemographics?
    
    public init(
        studentID: String,
        year: Int,
        grade: Int,
        testType: TestProvider,
        subject: String,
        season: String? = nil,
        componentScores: [String: Double],
        demographics: StudentDemographics? = nil
    ) {
        self.studentID = studentID
        self.year = year
        self.grade = grade
        self.testType = testType
        self.subject = subject
        self.season = season
        self.componentScores = componentScores
        self.demographics = demographics
    }
    
    public func getScore(for component: String) -> Double? {
        componentScores[component]
    }
    
    public func getAllScores() -> [String: Double] {
        componentScores
    }
}

public struct StudentDemographics: Codable, Sendable {
    public let iep: Bool?
    public let lep: String? // N, Y, F
    public let disability: Int?
    public let ethnicity: String?
    public let gender: String?
    public let economicallyDisadvantaged: Bool?
}

public enum TestProvider: String, Codable, Sendable {
    case questar = "QUESTAR"
    case nwea = "NWEA"
    
    public var componentPrefix: String {
        switch self {
        case .questar: return "RC"
        case .nwea: return "D"
        }
    }
    
    public var maxComponents: Int {
        switch self {
        case .questar: return 5
        case .nwea: return 8
        }
    }
}

// Core type definitions
public struct ComponentIdentifier: Hashable, Sendable, CustomStringConvertible {
    public let grade: Int
    public let subject: String
    public let component: String
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
    
    public var description: String {
        "Grade \(grade) \(subject) \(component)"
    }
    
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

public struct ComponentPair: Sendable {
    public let grade: Int
    public let year: Int?
    public let subject: String
    public let component: String
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

public enum RiskLevel: String, Sendable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
}
