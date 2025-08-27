import Foundation

/// Mississippi MAAP Test Proficiency Levels
/// This is the single source of truth for all proficiency level determinations
/// Based on official Mississippi state requirements
public struct MississippiProficiencyLevels {
    
    /// The five official Mississippi proficiency levels
    public enum Level: String, Codable, CaseIterable, Comparable, Sendable {
        case minimal = "Minimal"
        case basic = "Basic"
        case passing = "Passing"
        case proficient = "Proficient"
        case advanced = "Advanced"
        
        /// Numeric value for comparison (1-5)
        public var numericValue: Int {
            switch self {
            case .minimal: return 1
            case .basic: return 2
            case .passing: return 3
            case .proficient: return 4
            case .advanced: return 5
            }
        }
        
        /// Percentage threshold for general calculations
        public var threshold: Double {
            switch self {
            case .minimal: return 0.0
            case .basic: return 0.25
            case .passing: return 0.50
            case .proficient: return 0.70
            case .advanced: return 0.85
            }
        }
        
        /// Compare levels
        public static func < (lhs: Level, rhs: Level) -> Bool {
            return lhs.numericValue < rhs.numericValue
        }
        
        /// Initialize from legacy proficiency level names
        public init?(fromLegacy legacy: String) {
            switch legacy.lowercased() {
            case "minimal", "below basic", "belowbasic":
                self = .minimal
            case "basic":
                self = .basic
            case "passing", "pass":
                self = .passing
            case "proficient", "proficiency":
                self = .proficient
            case "advanced":
                self = .advanced
            default:
                return nil
            }
        }
    }
    
    /// Sub-levels used for more granular scoring (1A, 1B, 2A, 2B, etc.)
    public enum SubLevel: String, Codable, Sendable {
        case oneA = "1A"
        case oneB = "1B"
        case twoA = "2A"
        case twoB = "2B"
        case threeA = "3A"
        case threeB = "3B"
        case four = "4"
        case five = "5"
        
        /// Map sub-level to main proficiency level
        public var mainLevel: Level {
            switch self {
            case .oneA, .oneB:
                return .minimal
            case .twoA, .twoB:
                return .basic
            case .threeA, .threeB:
                return .passing
            case .four:
                return .proficient
            case .five:
                return .advanced
            }
        }
    }
    
    /// Score range for a specific proficiency level
    public struct ScoreRange: Codable, Sendable {
        public let minScore: Int
        public let maxScore: Int
        public let level: Level
        public let subLevel: SubLevel?
        
        public init(minScore: Int, maxScore: Int, level: Level, subLevel: SubLevel? = nil) {
            self.minScore = minScore
            self.maxScore = maxScore
            self.level = level
            self.subLevel = subLevel
        }
        
        /// Check if a score falls within this range
        public func contains(_ score: Int) -> Bool {
            return score >= minScore && score <= maxScore
        }
    }
    
    /// Performance levels for a specific grade and subject
    public struct GradeSubjectLevels: Codable, Sendable {
        public let grade: Int
        public let subject: String
        public let scoreRanges: [ScoreRange]
        
        public init(grade: Int, subject: String, scoreRanges: [ScoreRange]) {
            self.grade = grade
            self.subject = subject
            self.scoreRanges = scoreRanges
        }
        
        /// Get proficiency level for a given score
        public func getProficiencyLevel(for score: Int) -> (level: Level, subLevel: SubLevel?) {
            guard let range = scoreRanges.first(where: { $0.contains(score) }) else {
                // Default to minimal if score is below all ranges
                if let lowestRange = scoreRanges.min(by: { $0.minScore < $1.minScore }),
                   score < lowestRange.minScore {
                    return (.minimal, .oneA)
                }
                // Default to advanced if score is above all ranges
                if let highestRange = scoreRanges.max(by: { $0.maxScore < $1.maxScore }),
                   score > highestRange.maxScore {
                    return (.advanced, .five)
                }
                // Fallback
                return (.minimal, nil)
            }
            return (range.level, range.subLevel)
        }
    }
    
    /// All performance level data
    private static let performanceLevels: [String: GradeSubjectLevels] = {
        var levels: [String: GradeSubjectLevels] = [:]
        
        // Grade 3 ELA
        levels["3_ELA"] = GradeSubjectLevels(grade: 3, subject: "ELA", scoreRanges: [
            ScoreRange(minScore: 301, maxScore: 317, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 318, maxScore: 334, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 335, maxScore: 342, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 343, maxScore: 349, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 350, maxScore: 357, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 358, maxScore: 364, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 365, maxScore: 386, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 387, maxScore: 399, level: .advanced, subLevel: .five)
        ])
        
        // Grade 4 ELA
        levels["4_ELA"] = GradeSubjectLevels(grade: 4, subject: "ELA", scoreRanges: [
            ScoreRange(minScore: 401, maxScore: 414, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 415, maxScore: 428, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 429, maxScore: 439, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 440, maxScore: 449, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 450, maxScore: 457, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 458, maxScore: 464, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 465, maxScore: 487, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 488, maxScore: 499, level: .advanced, subLevel: .five)
        ])
        
        // Grade 5 ELA
        levels["5_ELA"] = GradeSubjectLevels(grade: 5, subject: "ELA", scoreRanges: [
            ScoreRange(minScore: 501, maxScore: 519, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 520, maxScore: 538, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 539, maxScore: 544, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 545, maxScore: 549, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 550, maxScore: 557, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 558, maxScore: 564, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 565, maxScore: 581, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 582, maxScore: 599, level: .advanced, subLevel: .five)
        ])
        
        // Grade 6 ELA
        levels["6_ELA"] = GradeSubjectLevels(grade: 6, subject: "ELA", scoreRanges: [
            ScoreRange(minScore: 601, maxScore: 618, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 619, maxScore: 635, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 636, maxScore: 642, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 643, maxScore: 649, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 650, maxScore: 657, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 658, maxScore: 664, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 665, maxScore: 678, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 679, maxScore: 699, level: .advanced, subLevel: .five)
        ])
        
        // Grade 7 ELA
        levels["7_ELA"] = GradeSubjectLevels(grade: 7, subject: "ELA", scoreRanges: [
            ScoreRange(minScore: 701, maxScore: 719, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 720, maxScore: 737, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 738, maxScore: 743, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 744, maxScore: 749, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 750, maxScore: 757, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 758, maxScore: 764, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 765, maxScore: 775, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 776, maxScore: 799, level: .advanced, subLevel: .five)
        ])
        
        // Grade 8 ELA
        levels["8_ELA"] = GradeSubjectLevels(grade: 8, subject: "ELA", scoreRanges: [
            ScoreRange(minScore: 801, maxScore: 819, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 820, maxScore: 837, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 838, maxScore: 843, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 844, maxScore: 849, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 850, maxScore: 857, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 858, maxScore: 864, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 865, maxScore: 888, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 889, maxScore: 899, level: .advanced, subLevel: .five)
        ])
        
        // Grade 3 Math
        levels["3_Math"] = GradeSubjectLevels(grade: 3, subject: "Math", scoreRanges: [
            ScoreRange(minScore: 301, maxScore: 316, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 317, maxScore: 332, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 333, maxScore: 341, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 342, maxScore: 349, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 350, maxScore: 357, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 358, maxScore: 364, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 365, maxScore: 383, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 384, maxScore: 399, level: .advanced, subLevel: .five)
        ])
        
        // Grade 4 Math
        levels["4_Math"] = GradeSubjectLevels(grade: 4, subject: "Math", scoreRanges: [
            ScoreRange(minScore: 401, maxScore: 418, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 419, maxScore: 435, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 436, maxScore: 442, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 443, maxScore: 449, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 450, maxScore: 457, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 458, maxScore: 464, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 465, maxScore: 483, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 484, maxScore: 499, level: .advanced, subLevel: .five)
        ])
        
        // Grade 5 Math
        levels["5_Math"] = GradeSubjectLevels(grade: 5, subject: "Math", scoreRanges: [
            ScoreRange(minScore: 501, maxScore: 520, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 521, maxScore: 539, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 540, maxScore: 544, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 545, maxScore: 549, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 550, maxScore: 557, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 558, maxScore: 564, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 565, maxScore: 578, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 579, maxScore: 599, level: .advanced, subLevel: .five)
        ])
        
        // Grade 6 Math
        levels["6_Math"] = GradeSubjectLevels(grade: 6, subject: "Math", scoreRanges: [
            ScoreRange(minScore: 601, maxScore: 618, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 619, maxScore: 635, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 636, maxScore: 642, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 643, maxScore: 649, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 650, maxScore: 657, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 658, maxScore: 664, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 665, maxScore: 686, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 687, maxScore: 699, level: .advanced, subLevel: .five)
        ])
        
        // Grade 7 Math
        levels["7_Math"] = GradeSubjectLevels(grade: 7, subject: "Math", scoreRanges: [
            ScoreRange(minScore: 701, maxScore: 718, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 719, maxScore: 735, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 736, maxScore: 742, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 743, maxScore: 749, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 750, maxScore: 757, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 758, maxScore: 764, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 765, maxScore: 792, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 793, maxScore: 799, level: .advanced, subLevel: .five)
        ])
        
        // Grade 8 Math
        levels["8_Math"] = GradeSubjectLevels(grade: 8, subject: "Math", scoreRanges: [
            ScoreRange(minScore: 801, maxScore: 819, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 820, maxScore: 837, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 838, maxScore: 843, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 844, maxScore: 849, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 850, maxScore: 857, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 858, maxScore: 864, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 865, maxScore: 888, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 889, maxScore: 899, level: .advanced, subLevel: .five)
        ])
        
        // Grade 5 Science
        levels["5_SCIENCE"] = GradeSubjectLevels(grade: 5, subject: "SCIENCE", scoreRanges: [
            ScoreRange(minScore: 500, maxScore: 540, level: .minimal, subLevel: nil),
            ScoreRange(minScore: 541, maxScore: 549, level: .basic, subLevel: nil),
            ScoreRange(minScore: 550, maxScore: 564, level: .passing, subLevel: nil),
            ScoreRange(minScore: 565, maxScore: 588, level: .proficient, subLevel: nil),
            ScoreRange(minScore: 589, maxScore: 650, level: .advanced, subLevel: nil)
        ])
        
        // Grade 8 Science
        levels["8_SCIENCE"] = GradeSubjectLevels(grade: 8, subject: "SCIENCE", scoreRanges: [
            ScoreRange(minScore: 800, maxScore: 840, level: .minimal, subLevel: nil),
            ScoreRange(minScore: 841, maxScore: 849, level: .basic, subLevel: nil),
            ScoreRange(minScore: 850, maxScore: 864, level: .passing, subLevel: nil),
            ScoreRange(minScore: 865, maxScore: 888, level: .proficient, subLevel: nil),
            ScoreRange(minScore: 889, maxScore: 950, level: .advanced, subLevel: nil)
        ])
        
        // High School subjects
        levels["Biology"] = GradeSubjectLevels(grade: 10, subject: "Biology", scoreRanges: [
            ScoreRange(minScore: 1000, maxScore: 1037, level: .minimal, subLevel: nil),
            ScoreRange(minScore: 1038, maxScore: 1049, level: .basic, subLevel: nil),
            ScoreRange(minScore: 1050, maxScore: 1064, level: .passing, subLevel: nil),
            ScoreRange(minScore: 1065, maxScore: 1094, level: .proficient, subLevel: nil),
            ScoreRange(minScore: 1095, maxScore: 1180, level: .advanced, subLevel: nil)
        ])
        
        levels["US_History"] = GradeSubjectLevels(grade: 11, subject: "US_History", scoreRanges: [
            ScoreRange(minScore: 1000, maxScore: 1036, level: .minimal, subLevel: nil),
            ScoreRange(minScore: 1037, maxScore: 1049, level: .basic, subLevel: nil),
            ScoreRange(minScore: 1050, maxScore: 1064, level: .passing, subLevel: nil),
            ScoreRange(minScore: 1065, maxScore: 1088, level: .proficient, subLevel: nil),
            ScoreRange(minScore: 1089, maxScore: 1150, level: .advanced, subLevel: nil)
        ])
        
        levels["Algebra I"] = GradeSubjectLevels(grade: 9, subject: "Algebra I", scoreRanges: [
            ScoreRange(minScore: 1001, maxScore: 1019, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 1020, maxScore: 1038, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 1039, maxScore: 1044, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 1045, maxScore: 1049, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 1050, maxScore: 1057, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 1058, maxScore: 1064, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 1065, maxScore: 1087, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 1088, maxScore: 1099, level: .advanced, subLevel: .five)
        ])
        
        levels["English II"] = GradeSubjectLevels(grade: 10, subject: "English II", scoreRanges: [
            ScoreRange(minScore: 1001, maxScore: 1018, level: .minimal, subLevel: .oneA),
            ScoreRange(minScore: 1019, maxScore: 1036, level: .minimal, subLevel: .oneB),
            ScoreRange(minScore: 1037, maxScore: 1043, level: .basic, subLevel: .twoA),
            ScoreRange(minScore: 1044, maxScore: 1049, level: .basic, subLevel: .twoB),
            ScoreRange(minScore: 1050, maxScore: 1057, level: .passing, subLevel: .threeA),
            ScoreRange(minScore: 1058, maxScore: 1064, level: .passing, subLevel: .threeB),
            ScoreRange(minScore: 1065, maxScore: 1080, level: .proficient, subLevel: .four),
            ScoreRange(minScore: 1081, maxScore: 1099, level: .advanced, subLevel: .five)
        ])
        
        return levels
    }()
    
    /// Get proficiency level for a specific score, grade, and subject
    public static func getProficiencyLevel(score: Int, grade: Int, subject: String) -> (level: Level, subLevel: SubLevel?) {
        // Try exact match first
        let key = "\(grade)_\(subject.uppercased())"
        if let gradeSubjectLevel = performanceLevels[key] {
            return gradeSubjectLevel.getProficiencyLevel(for: score)
        }
        
        // Try without grade for high school subjects
        if let gradeSubjectLevel = performanceLevels[subject] {
            return gradeSubjectLevel.getProficiencyLevel(for: score)
        }
        
        // Try alternate subject names
        let alternateSubject = subject.replacingOccurrences(of: "MATH", with: "Math")
            .replacingOccurrences(of: "math", with: "Math")
            .replacingOccurrences(of: "ela", with: "ELA")
        
        let alternateKey = "\(grade)_\(alternateSubject)"
        if let gradeSubjectLevel = performanceLevels[alternateKey] {
            return gradeSubjectLevel.getProficiencyLevel(for: score)
        }
        
        // Fallback based on percentage if no specific mapping found
        return getProficiencyLevelFromPercentage(Double(score))
    }
    
    /// Get proficiency level from a percentage score (0-100)
    public static func getProficiencyLevelFromPercentage(_ percentage: Double) -> (level: Level, subLevel: SubLevel?) {
        switch percentage {
        case 85...100:
            return (.advanced, nil)
        case 70..<85:
            return (.proficient, nil)
        case 50..<70:
            return (.passing, nil)
        case 25..<50:
            return (.basic, nil)
        default:
            return (.minimal, nil)
        }
    }
    
    /// Convert from legacy proficiency level string
    public static func convertFromLegacy(_ legacyLevel: String) -> Level {
        return Level(fromLegacy: legacyLevel) ?? .minimal
    }
    
    /// Get all available grade/subject combinations
    public static func getAvailableGradeSubjects() -> [(grade: Int, subject: String)] {
        return performanceLevels.compactMap { key, value in
            return (grade: value.grade, subject: value.subject)
        }
    }
}

// MARK: - Type Aliases for Migration
// These help with migrating from old enum names
public typealias ProficiencyLevel = MississippiProficiencyLevels.Level
public typealias PerformanceLevel = MississippiProficiencyLevels.Level