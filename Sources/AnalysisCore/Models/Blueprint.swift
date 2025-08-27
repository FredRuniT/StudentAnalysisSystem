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

/// Represents detailed learning standard with student performance expectations
public struct LearningStandard: Codable, Equatable {
    public let subject: String
    public let grade: String
    public let domain: String?
    public let strand: String?
    public let reportingCategory: String
    public let standard: StandardDetail
    public let studentPerformance: StudentPerformance
    public let relatedKeywords: RelatedKeywords
    
    private enum CodingKeys: String, CodingKey {
        case subject
        case grade
        case domain
        case strand
        case reportingCategory = "reporting_category"
        case standard
        case studentPerformance = "student_performance"
        case relatedKeywords = "related_keywords"
    }
    
    public init(subject: String, grade: String, domain: String?, strand: String?, 
                reportingCategory: String, standard: StandardDetail, 
                studentPerformance: StudentPerformance, relatedKeywords: RelatedKeywords) {
        self.subject = subject
        self.grade = grade
        self.domain = domain
        self.strand = strand
        self.reportingCategory = reportingCategory
        self.standard = standard
        self.studentPerformance = studentPerformance
        self.relatedKeywords = relatedKeywords
    }
}

/// Details of a specific standard
public struct StandardDetail: Codable, Equatable {
    public let id: String
    public let type: String
    public let description: String
    
    public init(id: String, type: String, description: String) {
        self.id = id
        self.type = type
        self.description = description
    }
}

/// Student performance expectations for a standard
public struct StudentPerformance: Codable, Equatable {
    public let categories: PerformanceCategories
    
    public init(categories: PerformanceCategories) {
        self.categories = categories
    }
}

/// Categories of student performance expectations
public struct PerformanceCategories: Codable, Equatable {
    public let knowledge: PerformanceItems
    public let understanding: PerformanceItems
    public let skills: PerformanceItems
    
    public init(knowledge: PerformanceItems, understanding: PerformanceItems, skills: PerformanceItems) {
        self.knowledge = knowledge
        self.understanding = understanding
        self.skills = skills
    }
}

/// Individual performance items within a category
public struct PerformanceItems: Codable, Equatable {
    public let label: String?
    public let items: [String]
    
    public init(label: String? = nil, items: [String]) {
        self.label = label
        self.items = items
    }
}

/// Keywords related to a standard
public struct RelatedKeywords: Codable, Equatable {
    public let terms: [String]
    
    public init(terms: [String]) {
        self.terms = terms
    }
}

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
public enum FocusArea: String, Codable {
    case knowledge = "Knowledge Gap"
    case understanding = "Conceptual Understanding"
    case skills = "Skill Application"
    case practice = "Additional Practice"
    case enrichment = "Enrichment"
}

// PerformanceLevel is now defined in MississippiProficiencyLevels.swift as a type alias
// Using the unified Mississippi proficiency levels system