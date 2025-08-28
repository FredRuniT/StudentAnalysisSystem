import Foundation

// MARK: - Blueprint Models

/// Represents a MAAP test blueprint for a specific grade and subject
public struct Blueprint: Codable, Equatable {
    public let schoolYear: String
    public let subject: String  // Changed from Subject enum to String
    public let programName: String
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
    public let name: String
    public let code: String
    public let standards: [StandardReference]
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
    public let code: String
    public let numbers: [Int]
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
    public let currentGrade: Int
    public let nextGrade: Int
    public let subject: String  // Changed from Subject enum to String
    public let prerequisiteStandards: [String]  // Standards that must be mastered
    public let targetStandards: [String]        // Standards to prepare for
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
    public let component: String
    public let reportingCategory: String
    public let relatedStandards: [String]
    public let performanceLevel: PerformanceLevel
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
    public let standardId: String
    public let focusArea: FocusArea
    public let specificSkills: [String]
    public let suggestedActivities: [String]
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