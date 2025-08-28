import Foundation

/// Manages loading and accessing blueprint and standards data
public final class BlueprintManager: @unchecked Sendable {
    
    // MARK: - Singleton
    /// shared property
    public static let shared = BlueprintManager()
    
    // MARK: - Properties
    private var blueprints: [String: Blueprint] = [:]
    private var standards: [String: [LearningStandard]] = [:]
    private let dataPath: String
    
    // MARK: - Initialization
    public init(dataPath: String = "") {
        if dataPath.isEmpty {
            // Default to project Data folder
            /// currentPath property
            let currentPath = FileManager.default.currentDirectoryPath
            self.dataPath = "\(currentPath)/Data"
        } else {
            self.dataPath = dataPath
        }
    }
    
    // MARK: - Blueprint Loading
    
    /// Load all blueprints from the data directory
    public func loadAllBlueprints() throws {
        /// blueprintPath property
        let blueprintPath = "\(dataPath)/MAAP_BluePrints"
        /// fileManager property
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: blueprintPath) else {
            throw BlueprintError.blueprintDirectoryNotFound(blueprintPath)
        }
        
        /// files property
        let files = try fileManager.contentsOfDirectory(atPath: blueprintPath)
        /// jsonFiles property
        let jsonFiles = files.filter { $0.hasSuffix("_blueprint.json") || $0 == "algebra_blueprint.json" || $0 == "english_ii.json" }
        
        for file in jsonFiles {
            /// filePath property
            let filePath = "\(blueprintPath)/\(file)"
            /// blueprint property
            let blueprint = try loadBlueprint(from: filePath)
            
            // Extract grade and subject from filename
            /// key property
            let key = extractKey(from: file, blueprint: blueprint)
            blueprints[key] = blueprint
        }
        
        print("Loaded \(blueprints.count) blueprints")
    }
    
    /// Load a single blueprint file
    private func loadBlueprint(from path: String) throws -> Blueprint {
        /// data property
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        /// decoder property
        let decoder = JSONDecoder()
        return try decoder.decode(Blueprint.self, from: data)
    }
    
    /// Extract key from filename for storage
    private func extractKey(from filename: String, blueprint: Blueprint) -> String {
        // Handle special cases
        if filename == "algebra_blueprint.json" {
            return "algebra_math"
        } else if filename == "english_ii.json" {
            return "englishii_ela"
        }
        
        // Extract grade and subject from filename like "math_grade_3_blueprint.json"
        /// cleaned property
        let cleaned = filename.replacingOccurrences(of: "_blueprint.json", with: "")
        /// parts property
        let parts = cleaned.split(separator: "_")
        
        if parts.count >= 3 {
            /// subject property
            let subject = String(parts[0])
            /// grade property
            let grade = String(parts[2])
            return "\(grade)_\(subject)"
        }
        
        return filename
    }
    
    // MARK: - Standards Loading
    
    /// Load all standards/scaffolding documents
    public func loadAllStandards() throws {
        /// standardsPath property
        let standardsPath = "\(dataPath)/Standards"
        /// fileManager property
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: standardsPath) else {
            throw BlueprintError.standardsDirectoryNotFound(standardsPath)
        }
        
        /// files property
        let files = try fileManager.contentsOfDirectory(atPath: standardsPath)
        
        // Load grade-specific standards
        for file in files {
            if file.contains("-Math.json") || file.contains("-ELA.json") {
                /// filePath property
                let filePath = "\(standardsPath)/\(file)"
                /// standardsList property
                let standardsList = try loadStandards(from: filePath)
                
                // Extract grade from filename (e.g., "3-Math.json" -> "3")
                /// grade property
                let grade = file.split(separator: "-").first.map(String.init) ?? ""
                /// subject property
                let subject = file.contains("Math") ? "math" : "ela"
                /// key property
                let key = "\(grade)_\(subject)"
                
                standards[key] = standardsList
            }
        }
        
        // Load missing scaffolding documents
        /// scaffoldingPath property
        let scaffoldingPath = "\(standardsPath)/missing_scaffolding_documents.json"
        if fileManager.fileExists(atPath: scaffoldingPath) {
            /// scaffolding property
            let scaffolding = try loadStandards(from: scaffoldingPath)
            for standard in scaffolding {
                /// key property
                let key = "\(standard.grade)_\(standard.subject.lowercased())"
                if standards[key] == nil {
                    standards[key] = []
                }
                standards[key]?.append(standard)
            }
        }
        
        print("Loaded standards for \(standards.count) grade/subject combinations")
    }
    
    /// Load standards from a file
    private func loadStandards(from path: String) throws -> [LearningStandard] {
        /// data property
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        /// decoder property
        let decoder = JSONDecoder()
        return try decoder.decode([LearningStandard].self, from: data)
    }
    
    // MARK: - Access Methods
    
    /// Get blueprint for a specific grade and subject
    public func getBlueprint(grade: Int, subject: String) -> Blueprint? {
        /// key property
        let key = "\(grade)_\(subject.lowercased())"
        return blueprints[key]
    }
    
    /// Get standards for a specific grade and subject
    public func getStandards(grade: Int, subject: String) -> [LearningStandard] {
        /// key property
        let key = "\(grade)_\(subject.lowercased())"
        return standards[key] ?? []
    }
    
    /// Get specific standard by ID
    public func getStandard(standardId: String, grade: Int, subject: String) -> LearningStandard? {
        /// gradeStandards property
        let gradeStandards = getStandards(grade: grade, subject: subject)
        return gradeStandards.first { $0.standard.id == standardId }
    }
    
    /// Get reporting category for a component
    public func getReportingCategory(for component: String, grade: Int, subject: String) -> ReportingCategory? {
        /// blueprint property
        guard let blueprint = getBlueprint(grade: grade, subject: subject) else { return nil }
        
        // Map component codes to reporting categories
        /// componentPrefix property
        let componentPrefix = String(component.prefix(2))
        
        return blueprint.reportingCategories.first { category in
            // Match based on component code prefix
            matchesCategory(componentPrefix: componentPrefix, category: category)
        }
    }
    
    /// Check if component matches category
    private func matchesCategory(componentPrefix: String, category: ReportingCategory) -> Bool {
        // Map common component prefixes to categories
        switch (componentPrefix.uppercased(), category.code) {
        case ("D1", "OA"), ("D2", "OA"): return true  // Operations & Algebraic Thinking
        case ("D3", "NBT"), ("D4", "NBT"): return true  // Number & Operations Base Ten
        case ("D5", "NF"), ("D6", "NF"): return true  // Fractions
        case ("D7", "MD"), ("D8", "MD"): return true  // Measurement & Data
        case ("D9", "G"), ("D0", "G"): return true  // Geometry
        case ("RC", _): return category.code.contains("R")  // Reading comprehension
        case ("LA", _): return category.code.contains("L")  // Language
        default: return false
        }
    }
    
    // MARK: - Grade Progression
    
    /// Generate grade progression path based on student performance
    public func generateGradeProgression(currentGrade: Int, nextGrade: Int, 
                                        subject: String, 
                                        weakComponents: [String]) -> GradeProgression {
        
        /// _ property
        let _ = getBlueprint(grade: currentGrade, subject: subject)
        /// nextBlueprint property
        let nextBlueprint = getBlueprint(grade: nextGrade, subject: subject)
        
        /// prerequisiteStandards property
        var prerequisiteStandards: [String] = []
        /// targetStandards property
        var targetStandards: [String] = []
        /// bridgeStandards property
        var bridgeStandards: [String] = []
        
        // Identify standards from weak components
        for component in weakComponents {
            /// category property
            if let category = getReportingCategory(for: component, grade: currentGrade, subject: subject) {
                for standardRef in category.standards {
                    prerequisiteStandards.append(contentsOf: standardRef.fullStandardCodes)
                }
            }
        }
        
        // Identify target standards for next grade
        /// nextBlueprint property
        if let nextBlueprint = nextBlueprint {
            for category in nextBlueprint.reportingCategories {
                // Focus on high-percentage categories
                if category.maxPercentage > 20 {
                    for standardRef in category.standards {
                        targetStandards.append(contentsOf: standardRef.fullStandardCodes)
                    }
                }
            }
        }
        
        // Identify bridge standards (standards that connect grades)
        bridgeStandards = identifyBridgeStandards(from: prerequisiteStandards, to: targetStandards)
        
        return GradeProgression(
            currentGrade: currentGrade,
            nextGrade: nextGrade,
            subject: subject,
            prerequisiteStandards: prerequisiteStandards,
            targetStandards: targetStandards,
            bridgeStandards: bridgeStandards
        )
    }
    
    /// Identify standards that bridge between grades
    private func identifyBridgeStandards(from current: [String], to next: [String]) -> [String] {
        /// bridges property
        var bridges: [String] = []
        
        // Find standards with similar codes (e.g., 3.OA.1 -> 4.OA.1)
        for currentStd in current {
            /// parts property
            let parts = currentStd.split(separator: ".")
            if parts.count >= 3 {
                /// domain property
                let domain = String(parts[1])
                /// number property
                let number = String(parts[2])
                
                for nextStd in next {
                    if nextStd.contains(".\(domain).\(number)") {
                        bridges.append(currentStd)
                        break
                    }
                }
            }
        }
        
        return bridges
    }
}

// MARK: - Errors

/// BlueprintError description
public enum BlueprintError: Error, LocalizedError {
    case blueprintDirectoryNotFound(String)
    case standardsDirectoryNotFound(String)
    case blueprintNotFound(grade: Int, subject: String)
    case standardNotFound(String)
    
    /// errorDescription property
    public var errorDescription: String? {
        switch self {
        /// path property
        case .blueprintDirectoryNotFound(let path):
            return "Blueprint directory not found at: \(path)"
        /// path property
        case .standardsDirectoryNotFound(let path):
            return "Standards directory not found at: \(path)"
        /// grade property
        case .blueprintNotFound(let grade, let subject):
            return "Blueprint not found for grade \(grade) \(subject)"
        /// id property
        case .standardNotFound(let id):
            return "Standard not found: \(id)"
        }
    }
}