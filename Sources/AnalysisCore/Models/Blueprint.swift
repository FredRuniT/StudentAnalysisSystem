import Foundation

// MARK: - Blueprint Models

/// Represents a MAAP test blueprint for a specific grade and subject
public struct Blueprint: Codable, Equatable {
    /// schoolYear property
    public let schoolYear: String
    /// subject property
    public let subject: String  // Changed from Subject enum to String
    /// programName property
    public let programName: String
    /// reportingCategories property
    public let reportingCategories: [ReportingCategory]
    
    private enum CodingKeys: String, CodingKey {
        case schoolYear = "school_year"
        case subject
        case programName = "program_name"
        case reportingCategories = "reporting_categories"
    }
    
    public init(schoolYear: String, subject: String, programName: String, reportingCategories: [ReportingCategory]) {
        self.schoolYear = schoolYear
        self.subject = subject
        self.programName = programName
        self.reportingCategories = reportingCategories
    }
}

/// Represents a reporting category within a blueprint
public struct ReportingCategory: Codable, Equatable {
    /// name property
    public let name: String
    /// code property
    public let code: String
    /// standards property
    public let standards: [StandardReference]
    /// percentageRange property
    public let percentageRange: [Double]
    
    private enum CodingKeys: String, CodingKey {
        case name
        case code
        case standards
        case percentageRange = "percentage_range"
    }
    
    public init(name: String, code: String, standards: [StandardReference], percentageRange: [Double]) {
        self.name = name
        self.code = code
        self.standards = standards
        self.percentageRange = percentageRange
    }
    
    /// Minimum percentage of test items from this category
    public var minPercentage: Double { percentageRange.first ?? 0 }
    
    /// Maximum percentage of test items from this category
    public var maxPercentage: Double { percentageRange.last ?? 0 }
}

/// Reference to specific standards within a reporting category
public struct StandardReference: Codable, Equatable {
    /// code property
    public let code: String
    /// numbers property
    public let numbers: [Int]
    /// isModeling property
    public let isModeling: Bool
    
    private enum CodingKeys: String, CodingKey {
        case code
        case numbers
        case isModeling = "is_modeling"
    }
    
    public init(code: String, numbers: [Int], isModeling: Bool) {
        self.code = code
        self.numbers = numbers
        self.isModeling = isModeling
    }
    
    /// Generate full standard codes (e.g., "3.OA.1", "3.OA.2")
    public var fullStandardCodes: [String] {
        numbers.map { "\(code).\($0)" }
    }
}

// MARK: - Scaffolding/Standards Models

// LearningStandard and related types are now defined in ScaffoldingModels.swift
// Using type alias for compatibility
public typealias LearningStandard = ScaffoldingDocument

// MARK: - Grade Progression Models

/// Represents the progression path from one grade to the next
public struct GradeProgression {
    /// currentGrade property
    public let currentGrade: Int
    /// nextGrade property
    public let nextGrade: Int
    /// subject property
    public let subject: String  // Changed from Subject enum to String
    /// prerequisiteStandards property
    public let prerequisiteStandards: [String]  // Standards that must be mastered
    /// targetStandards property
    public let targetStandards: [String]        // Standards to prepare for
    /// bridgeStandards property
    public let bridgeStandards: [String]        // Standards that connect grades
    
    public init(currentGrade: Int, nextGrade: Int, subject: String,
                prerequisiteStandards: [String], targetStandards: [String], 
                bridgeStandards: [String]) {
        self.currentGrade = currentGrade
        self.nextGrade = nextGrade
        self.subject = subject
        self.prerequisiteStandards = prerequisiteStandards
        self.targetStandards = targetStandards
        self.bridgeStandards = bridgeStandards
    }
}

/// Maps component performance to specific learning needs
public struct ComponentLearningMap {
    /// component property
    public let component: String
    /// reportingCategory property
    public let reportingCategory: String
    /// relatedStandards property
    public let relatedStandards: [String]
    /// performanceLevel property
    public let performanceLevel: PerformanceLevel
    /// recommendedFocus property
    public let recommendedFocus: [LearningFocus]
    
    public init(component: String, reportingCategory: String, 
                relatedStandards: [String], performanceLevel: PerformanceLevel,
                recommendedFocus: [LearningFocus]) {
        self.component = component
        self.reportingCategory = reportingCategory
        self.relatedStandards = relatedStandards
        self.performanceLevel = performanceLevel
        self.recommendedFocus = recommendedFocus
    }
}

/// Specific learning focus based on student performance
public struct LearningFocus {
    /// standardId property
    public let standardId: String
    /// focusArea property
    public let focusArea: FocusArea
    /// specificSkills property
    public let specificSkills: [String]
    /// suggestedActivities property
    public let suggestedActivities: [String]
    /// estimatedTimeWeeks property
    public let estimatedTimeWeeks: Int
    
    public init(standardId: String, focusArea: FocusArea, 
                specificSkills: [String], suggestedActivities: [String],
                estimatedTimeWeeks: Int) {
        self.standardId = standardId
        self.focusArea = focusArea
        self.specificSkills = specificSkills
        self.suggestedActivities = suggestedActivities
        self.estimatedTimeWeeks = estimatedTimeWeeks
    }
}

/// Areas where student needs focus
public enum FocusArea: String, Codable, Sendable {
    case knowledge = "Knowledge Gap"
    case understanding = "Conceptual Understanding"
    case skills = "Skill Application"
    case practice = "Additional Practice"
    case enrichment = "Enrichment"
}

// PerformanceLevel is now defined in MississippiProficiencyLevels.swift as a type alias
// Using the unified Mississippi proficiency levels system