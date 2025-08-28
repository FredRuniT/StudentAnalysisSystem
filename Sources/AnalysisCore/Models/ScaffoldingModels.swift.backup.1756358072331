import Foundation

// MARK: - Scaffolding Document Models
// Models for Mississippi Academic Standards scaffolding documents
// These provide Knowledge, Understanding, and Skills (K/U/S) expectations for each standard

/// Represents a complete scaffolding document for a standard
@available(iOS 15.0, macOS 12.0, *)
public struct ScaffoldingDocument: Codable, Sendable, Equatable, Identifiable {
    public let id: String
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subject = try container.decode(String.self, forKey: .subject)
        grade = try container.decode(String.self, forKey: .grade)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        strand = try container.decodeIfPresent(String.self, forKey: .strand)
        reportingCategory = try container.decode(String.self, forKey: .reportingCategory)
        standard = try container.decode(StandardDetail.self, forKey: .standard)
        studentPerformance = try container.decode(StudentPerformance.self, forKey: .studentPerformance)
        relatedKeywords = try container.decode(RelatedKeywords.self, forKey: .relatedKeywords)
        
        // Generate unique ID from standard ID
        self.id = standard.id
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(subject, forKey: .subject)
        try container.encode(grade, forKey: .grade)
        try container.encodeIfPresent(domain, forKey: .domain)
        try container.encodeIfPresent(strand, forKey: .strand)
        try container.encode(reportingCategory, forKey: .reportingCategory)
        try container.encode(standard, forKey: .standard)
        try container.encode(studentPerformance, forKey: .studentPerformance)
        try container.encode(relatedKeywords, forKey: .relatedKeywords)
    }
}

/// Details about a specific academic standard
public struct StandardDetail: Codable, Sendable, Equatable {
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
public struct StudentPerformance: Codable, Sendable, Equatable {
    public let categories: PerformanceCategories
    
    public init(categories: PerformanceCategories) {
        self.categories = categories
    }
}

/// The three categories of student performance: Knowledge, Understanding, Skills
public struct PerformanceCategories: Codable, Sendable, Equatable {
    public let knowledge: PerformanceCategory
    public let understanding: PerformanceCategory
    public let skills: PerformanceCategory
    
    public init(knowledge: PerformanceCategory, understanding: PerformanceCategory, skills: PerformanceCategory) {
        self.knowledge = knowledge
        self.understanding = understanding
        self.skills = skills
    }
}

/// Individual performance category with label and items
public struct PerformanceCategory: Codable, Sendable, Equatable {
    public let label: String?
    public let items: [String]
    
    public init(label: String? = nil, items: [String]) {
        self.label = label
        self.items = items
    }
}

/// Related keywords and terms for a standard
public struct RelatedKeywords: Codable, Sendable, Equatable {
    public let terms: [String]
    
    public init(terms: [String]) {
        self.terms = terms
    }
}

// MARK: - Learning Expectations Model
// Simplified access to K/U/S expectations

public struct LearningExpectations: Codable, Sendable, Equatable {
    public let knowledge: [String]
    public let understanding: [String]
    public let skills: [String]
    
    public init(knowledge: [String], understanding: [String], skills: [String]) {
        self.knowledge = knowledge
        self.understanding = understanding
        self.skills = skills
    }
    
    /// Create from performance categories
    public init(from categories: PerformanceCategories) {
        self.knowledge = categories.knowledge.items
        self.understanding = categories.understanding.items
        self.skills = categories.skills.items
    }
}

// MARK: - Standard Progression Model
// Tracks how standards progress across grade levels

public struct StandardProgression: Codable, Sendable, Equatable {
    public let domain: String
    public let currentGrade: Int
    public let nextGrade: Int
    public let currentStandards: [String]
    public let nextStandards: [String]
    public let prerequisites: [String]
    public let bridges: [String]
    
    public init(
        domain: String,
        currentGrade: Int,
        nextGrade: Int,
        currentStandards: [String],
        nextStandards: [String],
        prerequisites: [String],
        bridges: [String]
    ) {
        self.domain = domain
        self.currentGrade = currentGrade
        self.nextGrade = nextGrade
        self.currentStandards = currentStandards
        self.nextStandards = nextStandards
        self.prerequisites = prerequisites
        self.bridges = bridges
    }
}

// MARK: - Scaffolding Repository
// Manager for loading and accessing scaffolding documents

@available(iOS 15.0, macOS 12.0, *)
public actor ScaffoldingRepository {
    private var documents: [String: ScaffoldingDocument] = [:]
    private var documentsByGrade: [String: [String: [ScaffoldingDocument]]] = [:] // grade -> subject -> documents
    
    public init() {}
    
    /// Load scaffolding documents from JSON files
    public func loadDocuments(from directory: URL) async throws {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        
        for file in files where file.pathExtension == "json" {
            let data = try Data(contentsOf: file)
            let decoder = JSONDecoder()
            
            // Try to decode as array of documents
            if let docs = try? decoder.decode([ScaffoldingDocument].self, from: data) {
                for doc in docs {
                    await store(document: doc)
                }
            }
            // Try to decode as single document
            else if let doc = try? decoder.decode(ScaffoldingDocument.self, from: data) {
                await store(document: doc)
            }
        }
    }
    
    /// Store a scaffolding document
    private func store(document: ScaffoldingDocument) async {
        documents[document.standard.id] = document
        
        // Organize by grade and subject
        if documentsByGrade[document.grade] == nil {
            documentsByGrade[document.grade] = [:]
        }
        if documentsByGrade[document.grade]?[document.subject] == nil {
            documentsByGrade[document.grade]?[document.subject] = []
        }
        documentsByGrade[document.grade]?[document.subject]?.append(document)
    }
    
    /// Get a specific scaffolding document by standard ID
    public func getDocument(standardId: String) async -> ScaffoldingDocument? {
        return documents[standardId]
    }
    
    /// Get all documents for a specific grade and subject
    public func getDocuments(grade: String, subject: String) async -> [ScaffoldingDocument] {
        return documentsByGrade[grade]?[subject] ?? []
    }
    
    /// Get learning expectations for a standard
    public func getLearningExpectations(standardId: String) async -> LearningExpectations? {
        guard let doc = documents[standardId] else { return nil }
        return LearningExpectations(from: doc.studentPerformance.categories)
    }
    
    /// Find documents by reporting category
    public func getDocumentsByReportingCategory(
        grade: String,
        subject: String,
        reportingCategory: String
    ) async -> [ScaffoldingDocument] {
        let docs = await getDocuments(grade: grade, subject: subject)
        return docs.filter { $0.reportingCategory == reportingCategory }
    }
    
    /// Search for standards by keywords
    public func searchByKeywords(_ keywords: [String], grade: String? = nil, subject: String? = nil) async -> [ScaffoldingDocument] {
        var results: [ScaffoldingDocument] = []
        
        for (_, doc) in documents {
            // Apply grade and subject filters if provided
            if let grade = grade, doc.grade != grade { continue }
            if let subject = subject, doc.subject != subject { continue }
            
            // Check if any keywords match
            let docKeywords = Set(doc.relatedKeywords.terms.map { $0.lowercased() })
            let searchKeywords = Set(keywords.map { $0.lowercased() })
            
            if !docKeywords.isDisjoint(with: searchKeywords) {
                results.append(doc)
            }
        }
        
        return results
    }
    
    /// Get progression path between grades for a domain
    public func getProgression(
        from currentGrade: Int,
        to targetGrade: Int,
        domain: String,
        subject: String
    ) async -> StandardProgression? {
        let currentDocs = await getDocuments(grade: String(currentGrade), subject: subject)
            .filter { $0.domain == domain || $0.strand == domain }
        
        let targetDocs = await getDocuments(grade: String(targetGrade), subject: subject)
            .filter { $0.domain == domain || $0.strand == domain }
        
        guard !currentDocs.isEmpty && !targetDocs.isEmpty else { return nil }
        
        let currentStandards = currentDocs.map { $0.standard.id }
        let targetStandards = targetDocs.map { $0.standard.id }
        
        // Identify prerequisites based on standard numbering patterns
        let prerequisites = currentStandards.filter { standard in
            // Standards with lower numbers are often prerequisites
            targetStandards.contains { target in
                let currentNum = Int(standard.components(separatedBy: ".").last ?? "") ?? 0
                let targetNum = Int(target.components(separatedBy: ".").last ?? "") ?? 0
                return currentNum < targetNum
            }
        }
        
        // Bridge standards are those that directly connect grades
        let bridges = currentStandards.filter { standard in
            targetStandards.contains { target in
                // Same domain/strand, sequential numbering
                standard.components(separatedBy: ".").first == target.components(separatedBy: ".").first
            }
        }
        
        return StandardProgression(
            domain: domain,
            currentGrade: currentGrade,
            nextGrade: targetGrade,
            currentStandards: currentStandards,
            nextStandards: targetStandards,
            prerequisites: prerequisites,
            bridges: bridges
        )
    }
    
    /// Get all loaded standards count
    public func getDocumentCount() async -> Int {
        return documents.count
    }
}